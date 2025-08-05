import Foundation

/// Service for managing batch processing operations with progress tracking
public class BatchProcessingService {
    
    // MARK: - Properties
    
    private let scoringEngine: BDScoringEngine
    private var activeBatches: [UUID: BatchJob] = [:]
    private let batchQueue = DispatchQueue(label: "batch.processing", qos: .userInitiated)
    private let progressQueue = DispatchQueue(label: "batch.progress", qos: .utility)
    
    // MARK: - Initialization
    
    public init(scoringEngine: BDScoringEngine) {
        self.scoringEngine = scoringEngine
    }
    
    // MARK: - Batch Processing
    
    /// Start a new batch processing job
    public func startBatchJob(_ request: BatchEvaluationRequest) async -> BatchJob {
        let jobId = UUID()
        let job = BatchJob(
            id: jobId,
            status: .pending,
            totalCompanies: request.companies.count,
            processedCompanies: 0,
            successfulEvaluations: 0,
            failedEvaluations: 0,
            results: [],
            errors: [],
            startTime: Date(),
            estimatedCompletion: nil,
            options: request.options ?? BatchOptions()
        )
        
        // Store the job
        await MainActor.run {
            activeBatches[jobId] = job
        }
        
        // Start processing asynchronously
        Task {
            await processBatch(jobId: jobId, request: request)
        }
        
        return job
    }
    
    /// Get the status of a batch job
    public func getBatchStatus(jobId: UUID) async -> BatchJob? {
        return await MainActor.run {
            return activeBatches[jobId]
        }
    }
    
    /// Get all active batch jobs
    public func getActiveBatches() async -> [BatchJob] {
        return await MainActor.run {
            return Array(activeBatches.values)
        }
    }
    
    /// Cancel a batch job
    public func cancelBatchJob(jobId: UUID) async -> Bool {
        return await MainActor.run {
            guard var job = activeBatches[jobId] else { return false }
            
            if job.status == .processing || job.status == .pending {
                job.status = .cancelled
                job.completionTime = Date()
                activeBatches[jobId] = job
                return true
            }
            return false
        }
    }
    
    /// Clean up completed batch jobs older than specified time
    public func cleanupCompletedJobs(olderThan timeInterval: TimeInterval = 3600) async {
        let cutoffTime = Date().addingTimeInterval(-timeInterval)
        
        await MainActor.run {
            activeBatches = activeBatches.filter { _, job in
                guard let completionTime = job.completionTime else { return true }
                return completionTime > cutoffTime
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Process a batch of companies
    private func processBatch(jobId: UUID, request: BatchEvaluationRequest) async {
        // Update job status to processing
        await updateJobStatus(jobId: jobId, status: .processing)
        
        let config = request.config ?? ScoringConfig(
            name: "Default",
            weights: WeightConfig(),
            parameters: ScoringParameters()
        )
        
        let options = request.options ?? BatchOptions()
        var results: [ScoringResult] = []
        var errors: [BatchError] = []
        
        // Calculate estimated completion time
        let estimatedTimePerCompany: TimeInterval = 2.0 // seconds
        let estimatedCompletion = Date().addingTimeInterval(
            Double(request.companies.count) * estimatedTimePerCompany / Double(options.maxConcurrency)
        )
        await updateJobEstimatedCompletion(jobId: jobId, estimatedCompletion: estimatedCompletion)
        
        // Process companies with concurrency control
        let semaphore = DispatchSemaphore(value: options.maxConcurrency)
        
        await withTaskGroup(of: (Int, Result<ScoringResult, Error>).self) { group in
            for (index, company) in request.companies.enumerated() {
                // Check if job was cancelled
                if await isJobCancelled(jobId: jobId) {
                    break
                }
                
                group.addTask {
                    semaphore.wait()
                    defer { semaphore.signal() }
                    
                    do {
                        let result = try await self.scoringEngine.evaluateCompany(company, config: config)
                        return (index, .success(result))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            for await (index, result) in group {
                // Check if job was cancelled
                if await isJobCancelled(jobId: jobId) {
                    break
                }
                
                switch result {
                case .success(let scoringResult):
                    results.append(scoringResult)
                    await updateJobProgress(
                        jobId: jobId,
                        processedCompanies: results.count + errors.count,
                        successfulEvaluations: results.count,
                        failedEvaluations: errors.count
                    )
                    
                case .failure(let error):
                    let company = request.companies[index]
                    let batchError = BatchError(
                        companyId: company.id,
                        companyName: company.basicInfo.name,
                        error: error.localizedDescription,
                        index: index
                    )
                    errors.append(batchError)
                    
                    await updateJobProgress(
                        jobId: jobId,
                        processedCompanies: results.count + errors.count,
                        successfulEvaluations: results.count,
                        failedEvaluations: errors.count
                    )
                    
                    if !options.continueOnError {
                        break
                    }
                }
            }
        }
        
        // Determine final status
        let finalStatus: BatchJobStatus
        if await isJobCancelled(jobId: jobId) {
            finalStatus = .cancelled
        } else if errors.isEmpty {
            finalStatus = .completed
        } else if results.isEmpty {
            finalStatus = .failed
        } else {
            finalStatus = .partiallyCompleted
        }
        
        // Update job with final results
        await finalizeJob(
            jobId: jobId,
            status: finalStatus,
            results: results,
            errors: errors
        )
        
        // Send notification if requested
        if options.notifyOnCompletion, let webhookUrl = options.webhookUrl {
            await sendCompletionNotification(jobId: jobId, webhookUrl: webhookUrl)
        }
    }
    
    /// Update job status
    private func updateJobStatus(jobId: UUID, status: BatchJobStatus) async {
        await MainActor.run {
            activeBatches[jobId]?.status = status
        }
    }
    
    /// Update job progress
    private func updateJobProgress(
        jobId: UUID,
        processedCompanies: Int,
        successfulEvaluations: Int,
        failedEvaluations: Int
    ) async {
        await MainActor.run {
            guard var job = activeBatches[jobId] else { return }
            
            job.processedCompanies = processedCompanies
            job.successfulEvaluations = successfulEvaluations
            job.failedEvaluations = failedEvaluations
            job.progress = Double(processedCompanies) / Double(job.totalCompanies)
            
            activeBatches[jobId] = job
        }
    }
    
    /// Update job estimated completion time
    private func updateJobEstimatedCompletion(jobId: UUID, estimatedCompletion: Date) async {
        await MainActor.run {
            activeBatches[jobId]?.estimatedCompletion = estimatedCompletion
        }
    }
    
    /// Check if job was cancelled
    private func isJobCancelled(jobId: UUID) async -> Bool {
        return await MainActor.run {
            return activeBatches[jobId]?.status == .cancelled
        }
    }
    
    /// Finalize job with results
    private func finalizeJob(
        jobId: UUID,
        status: BatchJobStatus,
        results: [ScoringResult],
        errors: [BatchError]
    ) async {
        await MainActor.run {
            guard var job = activeBatches[jobId] else { return }
            
            job.status = status
            job.results = results
            job.errors = errors
            job.completionTime = Date()
            job.progress = 1.0
            
            activeBatches[jobId] = job
        }
    }
    
    /// Send completion notification via webhook
    private func sendCompletionNotification(jobId: UUID, webhookUrl: String) async {
        guard let job = await getBatchStatus(jobId: jobId),
              let url = URL(string: webhookUrl) else { return }
        
        let notification = BatchCompletionNotification(
            jobId: jobId,
            status: job.status,
            totalCompanies: job.totalCompanies,
            successfulEvaluations: job.successfulEvaluations,
            failedEvaluations: job.failedEvaluations,
            completionTime: job.completionTime ?? Date()
        )
        
        do {
            let jsonData = try JSONEncoder().encode(notification)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Batch completion notification sent successfully for job \(jobId)")
            } else {
                print("⚠️ Failed to send batch completion notification for job \(jobId)")
            }
        } catch {
            print("❌ Error sending batch completion notification for job \(jobId): \(error)")
        }
    }
}

// MARK: - Batch Job Models

/// Represents a batch processing job
public struct BatchJob: Codable, Identifiable {
    public let id: UUID
    public var status: BatchJobStatus
    public let totalCompanies: Int
    public var processedCompanies: Int
    public var successfulEvaluations: Int
    public var failedEvaluations: Int
    public var progress: Double = 0.0
    public var results: [ScoringResult]
    public var errors: [BatchError]
    public let startTime: Date
    public var completionTime: Date?
    public var estimatedCompletion: Date?
    public let options: BatchOptions
    
    /// Processing time in seconds
    public var processingTime: TimeInterval {
        let endTime = completionTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Estimated time remaining in seconds
    public var estimatedTimeRemaining: TimeInterval? {
        guard let estimatedCompletion = estimatedCompletion,
              status == .processing else { return nil }
        
        let remaining = estimatedCompletion.timeIntervalSince(Date())
        return max(0, remaining)
    }
}

/// Status of a batch processing job
public enum BatchJobStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case partiallyCompleted = "partially_completed"
    case cancelled = "cancelled"
}

/// Notification sent when batch processing completes
public struct BatchCompletionNotification: Codable {
    public let jobId: UUID
    public let status: BatchJobStatus
    public let totalCompanies: Int
    public let successfulEvaluations: Int
    public let failedEvaluations: Int
    public let completionTime: Date
}

// MARK: - Extended Batch Options

extension BatchOptions {
    /// Default batch options for different scenarios
    public static let `default` = BatchOptions()
    
    public static let highThroughput = BatchOptions(
        continueOnError: true,
        maxConcurrency: 10,
        notifyOnCompletion: false,
        webhookUrl: nil
    )
    
    public static let reliable = BatchOptions(
        continueOnError: false,
        maxConcurrency: 3,
        notifyOnCompletion: true,
        webhookUrl: nil
    )
    
    public static let background = BatchOptions(
        continueOnError: true,
        maxConcurrency: 5,
        notifyOnCompletion: true,
        webhookUrl: nil
    )
}

// MARK: - Batch Processing Statistics

/// Statistics for batch processing operations
public struct BatchProcessingStatistics: Codable {
    public let totalJobs: Int
    public let activeJobs: Int
    public let completedJobs: Int
    public let failedJobs: Int
    public let averageProcessingTime: TimeInterval
    public let totalCompaniesProcessed: Int
    public let averageSuccessRate: Double
    public let lastUpdated: Date
    
    public init(jobs: [BatchJob]) {
        self.totalJobs = jobs.count
        self.activeJobs = jobs.filter { $0.status == .processing || $0.status == .pending }.count
        self.completedJobs = jobs.filter { $0.status == .completed || $0.status == .partiallyCompleted }.count
        self.failedJobs = jobs.filter { $0.status == .failed }.count
        
        let completedJobsOnly = jobs.filter { $0.completionTime != nil }
        self.averageProcessingTime = completedJobsOnly.isEmpty ? 0 :
            completedJobsOnly.map { $0.processingTime }.reduce(0, +) / Double(completedJobsOnly.count)
        
        self.totalCompaniesProcessed = jobs.map { $0.processedCompanies }.reduce(0, +)
        
        let jobsWithResults = jobs.filter { $0.totalCompanies > 0 }
        self.averageSuccessRate = jobsWithResults.isEmpty ? 0 :
            jobsWithResults.map { Double($0.successfulEvaluations) / Double($0.totalCompanies) }.reduce(0, +) / Double(jobsWithResults.count)
        
        self.lastUpdated = Date()
    }
}