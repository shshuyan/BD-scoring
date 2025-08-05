import Foundation

/// Main API controller for BD Scoring Module REST endpoints
public class APIController {
    
    // MARK: - Properties
    
    private let scoringEngine: BDScoringEngine
    private let reportGenerator: ReportGenerator?
    private let dataService: DataService?
    private let validationService: ValidationService?
    private let batchProcessingService: BatchProcessingService
    
    // MARK: - Initialization
    
    public init(
        scoringEngine: BDScoringEngine,
        reportGenerator: ReportGenerator? = nil,
        dataService: DataService? = nil,
        validationService: ValidationService? = nil
    ) {
        self.scoringEngine = scoringEngine
        self.reportGenerator = reportGenerator
        self.dataService = dataService
        self.validationService = validationService
        self.batchProcessingService = BatchProcessingService(scoringEngine: scoringEngine)
    }
    
    // MARK: - API Endpoint Handlers
    
    /// Health check endpoint
    public func healthCheck() async -> StandardAPIResponse<HealthResponse> {
        let startTime = Date()
        
        // Check system health
        let uptime = ProcessInfo.processInfo.systemUptime
        let version = "1.0.0" // This would come from build configuration
        
        // Check dependencies (placeholder - would check actual services)
        let dependencies = [
            DependencyStatus(name: "Database", status: "healthy", responseTime: 0.05, lastChecked: Date()),
            DependencyStatus(name: "Scoring Engine", status: "healthy", responseTime: 0.02, lastChecked: Date())
        ]
        
        // System metrics (placeholder - would come from actual monitoring)
        let metrics = SystemMetrics(
            totalEvaluations: 1000,
            averageResponseTime: 0.5,
            errorRate: 0.01,
            activeConnections: 10,
            memoryUsage: 0.6,
            cpuUsage: 0.3
        )
        
        let health = HealthResponse(
            status: "healthy",
            version: version,
            uptime: uptime,
            dependencies: dependencies,
            metrics: metrics
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        return StandardAPIResponse.success(health, processingTime: processingTime)
    }
    
    /// Evaluate a single company
    public func evaluateCompany(_ request: CompanyEvaluationRequest) async -> StandardAPIResponse<CompanyEvaluationResponse> {
        let startTime = Date()
        
        do {
            // Validate request
            try request.validate()
            
            // Use provided config or default
            let config = request.config ?? ScoringConfig(
                name: "Default",
                weights: WeightConfig(),
                parameters: ScoringParameters()
            )
            
            // Perform evaluation
            let result = try await scoringEngine.evaluateCompany(request.companyData, config: config)
            
            // Get additional insights
            let insights = try await scoringEngine.getPillarInsights(request.companyData)
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            let response = CompanyEvaluationResponse(
                result: result,
                insights: insights,
                recommendations: result.recommendations,
                confidence: result.confidence,
                processingTime: processingTime
            )
            
            // Save result if data service is available
            if let dataService = dataService {
                try await dataService.saveScoringResult(result)
            }
            
            return StandardAPIResponse.success(response, processingTime: processingTime)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch let error as ScoringError {
            return StandardAPIResponse.error(APIError.badRequest(error.localizedDescription))
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to evaluate company: \(error.localizedDescription)"))
        }
    }
    
    /// Evaluate multiple companies in batch
    public func batchEvaluate(_ request: BatchEvaluationRequest) async -> StandardAPIResponse<BatchEvaluationResponse> {
        let startTime = Date()
        
        do {
            // Validate request
            try request.validate()
            
            let jobId = UUID()
            let options = request.options ?? BatchOptions()
            
            // Use provided config or default
            let config = request.config ?? ScoringConfig(
                name: "Default",
                weights: WeightConfig(),
                parameters: ScoringParameters()
            )
            
            var results: [ScoringResult] = []
            var errors: [BatchError] = []
            
            // Process companies with concurrency control
            let semaphore = DispatchSemaphore(value: options.maxConcurrency)
            
            await withTaskGroup(of: (Int, Result<ScoringResult, Error>).self) { group in
                for (index, company) in request.companies.enumerated() {
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
                    switch result {
                    case .success(let scoringResult):
                        results.append(scoringResult)
                    case .failure(let error):
                        let company = request.companies[index]
                        let batchError = BatchError(
                            companyId: company.id,
                            companyName: company.basicInfo.name,
                            error: error.localizedDescription,
                            index: index
                        )
                        errors.append(batchError)
                        
                        if !options.continueOnError {
                            break
                        }
                    }
                }
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Calculate summary
            let summary = BatchSummary(
                totalCompanies: request.companies.count,
                successfulEvaluations: results.count,
                failedEvaluations: errors.count,
                averageScore: results.isEmpty ? nil : results.map { $0.overallScore }.reduce(0, +) / Double(results.count),
                averageConfidence: results.isEmpty ? nil : results.map { $0.confidence.overall }.reduce(0, +) / Double(results.count),
                processingTime: processingTime
            )
            
            // Determine batch status
            let status: BatchStatus
            if errors.isEmpty {
                status = .completed
            } else if results.isEmpty {
                status = .failed
            } else {
                status = .partiallyCompleted
            }
            
            let response = BatchEvaluationResponse(
                jobId: jobId,
                status: status,
                results: results,
                errors: errors,
                summary: summary,
                processingTime: processingTime
            )
            
            // Save results if data service is available
            if let dataService = dataService {
                for result in results {
                    try? await dataService.saveScoringResult(result)
                }
            }
            
            return StandardAPIResponse.success(response, processingTime: processingTime)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to process batch evaluation: \(error.localizedDescription)"))
        }
    }
    
    /// Get scoring configurations
    public func getConfigurations() async -> StandardAPIResponse<ConfigurationResponse> {
        // This would load configurations from storage
        // For now, return default configuration
        let defaultConfig = ScoringConfig(
            name: "Default",
            weights: WeightConfig(),
            parameters: ScoringParameters(),
            isDefault: true
        )
        
        let response = ConfigurationResponse(
            configurations: [defaultConfig],
            defaultConfiguration: defaultConfig
        )
        
        return StandardAPIResponse.success(response)
    }
    
    /// Create a new scoring configuration
    public func createConfiguration(_ request: ScoringConfigRequest) async -> StandardAPIResponse<ScoringConfig> {
        do {
            try request.validate()
            
            let config = ScoringConfig(
                name: request.name,
                weights: request.weights,
                parameters: request.parameters ?? ScoringParameters(),
                isDefault: request.isDefault
            )
            
            // Save configuration (would use data service)
            // For now, just return the created config
            
            return StandardAPIResponse.success(config)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to create configuration: \(error.localizedDescription)"))
        }
    }
    
    /// Generate a report
    public func generateReport(_ request: ReportGenerationRequest) async -> StandardAPIResponse<ReportResponse> {
        do {
            try request.validate()
            
            guard let reportGenerator = reportGenerator else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Report generation service not available"))
            }
            
            // Generate report (would use report generator service)
            // For now, return a placeholder response
            let reportResponse = ReportResponse(
                reportId: UUID(),
                downloadUrl: nil,
                format: request.format,
                size: nil,
                generatedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            
            return StandardAPIResponse.success(reportResponse)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to generate report: \(error.localizedDescription)"))
        }
    }
    
    /// Create a new company
    public func createCompany(_ company: CompanyData) async -> StandardAPIResponse<CompanyData> {
        do {
            // Validate company data
            if let validationService = validationService {
                let validation = validationService.validateCompanyData(company)
                guard validation.isValid else {
                    let errorMessages = validation.errors.map { $0.message }
                    return StandardAPIResponse.error(APIError.validationError("Invalid company data: \(errorMessages.joined(separator: ", "))"))
                }
            }
            
            guard let dataService = dataService else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
            }
            
            try await dataService.saveCompany(company)
            return StandardAPIResponse.success(company)
            
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to save company: \(error.localizedDescription)"))
        }
    }
    
    /// Get a company by ID
    public func getCompany(id: UUID) async -> StandardAPIResponse<CompanyData> {
        guard let dataService = dataService else {
            return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
        }
        
        do {
            let company = try await dataService.loadCompany(id: id)
            return StandardAPIResponse.success(company)
        } catch {
            return StandardAPIResponse.error(APIError.notFound("Company not found"))
        }
    }
    
    /// Update a company
    public func updateCompany(_ company: CompanyData) async -> StandardAPIResponse<CompanyData> {
        do {
            // Validate company data
            if let validationService = validationService {
                let validation = validationService.validateCompanyData(company)
                guard validation.isValid else {
                    let errorMessages = validation.errors.map { $0.message }
                    return StandardAPIResponse.error(APIError.validationError("Invalid company data: \(errorMessages.joined(separator: ", "))"))
                }
            }
            
            guard let dataService = dataService else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
            }
            
            try await dataService.saveCompany(company)
            return StandardAPIResponse.success(company)
            
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to update company: \(error.localizedDescription)"))
        }
    }
    
    /// Delete a company
    public func deleteCompany(id: UUID) async -> StandardAPIResponse<String> {
        guard let dataService = dataService else {
            return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
        }
        
        do {
            try await dataService.deleteCompany(id: id)
            return StandardAPIResponse.success("Company deleted successfully")
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to delete company: \(error.localizedDescription)"))
        }
    }
    
    /// Update actual outcome for historical tracking
    public func updateOutcome(_ request: OutcomeUpdateRequest) async -> StandardAPIResponse<String> {
        do {
            try request.validate()
            
            guard let dataService = dataService else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
            }
            
            // Update actual outcome for historical tracking
            // This would be implemented in the data service
            // For now, return success
            
            return StandardAPIResponse.success("Outcome updated successfully")
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to update outcome: \(error.localizedDescription)"))
        }
    }
    
    /// Get historical data for a company
    public func getCompanyHistory(id: UUID, query: HistoricalDataQuery) async -> StandardAPIResponse<HistoricalDataResponse> {
        do {
            try query.validate()
            
            guard let dataService = dataService else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
            }
            
            // Get historical data for company
            // This would be implemented in the data service
            // For now, return placeholder
            let response = HistoricalDataResponse(
                companyId: id,
                scoringHistory: [],
                actualOutcomes: [],
                accuracyMetrics: nil
            )
            
            return StandardAPIResponse.success(response)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to get company history: \(error.localizedDescription)"))
        }
    }
    
    /// Get accuracy metrics
    public func getAccuracyMetrics() async -> StandardAPIResponse<AccuracyMetrics> {
        // Calculate and return accuracy metrics
        // This would analyze historical predictions vs actual outcomes
        // For now, return placeholder metrics
        let metrics = AccuracyMetrics(
            overallAccuracy: 0.75,
            pillarAccuracies: [
                "Asset Quality": 0.80,
                "Market Outlook": 0.72,
                "Financial Readiness": 0.85,
                "Strategic Fit": 0.68,
                "Capital Intensity": 0.78,
                "Regulatory Risk": 0.70
            ],
            predictionCount: 150,
            averageError: 0.25,
            confidenceCalibration: 0.82
        )
        
        return StandardAPIResponse.success(metrics)
    }
    
    /// List companies with filtering and pagination
    public func listCompanies(query: CompanyListQuery) async -> StandardAPIResponse<[CompanyData]> {
        do {
            try query.validate()
            
            guard let dataService = dataService else {
                return StandardAPIResponse.error(APIError.serviceUnavailable("Data service not available"))
            }
            
            // List companies with filtering and pagination
            // This would be implemented in the data service
            // For now, return empty list
            let companies: [CompanyData] = []
            
            return StandardAPIResponse.success(companies)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to list companies: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Enhanced Batch Processing Endpoints
    
    /// Start a new batch processing job with progress tracking
    public func startBatchJob(_ request: BatchEvaluationRequest) async -> StandardAPIResponse<BatchJob> {
        do {
            try request.validate()
            
            let job = await batchProcessingService.startBatchJob(request)
            return StandardAPIResponse.success(job)
            
        } catch let error as APIError {
            return StandardAPIResponse.error(error)
        } catch {
            return StandardAPIResponse.error(APIError.internalError("Failed to start batch job: \(error.localizedDescription)"))
        }
    }
    
    /// Get the status of a batch processing job
    public func getBatchJobStatus(jobId: UUID) async -> StandardAPIResponse<BatchJob> {
        guard let job = await batchProcessingService.getBatchStatus(jobId: jobId) else {
            return StandardAPIResponse.error(APIError.notFound("Batch job not found"))
        }
        
        return StandardAPIResponse.success(job)
    }
    
    /// Get all active batch jobs
    public func getActiveBatchJobs() async -> StandardAPIResponse<[BatchJob]> {
        let jobs = await batchProcessingService.getActiveBatches()
        return StandardAPIResponse.success(jobs)
    }
    
    /// Cancel a batch processing job
    public func cancelBatchJob(jobId: UUID) async -> StandardAPIResponse<String> {
        let cancelled = await batchProcessingService.cancelBatchJob(jobId: jobId)
        
        if cancelled {
            return StandardAPIResponse.success("Batch job cancelled successfully")
        } else {
            return StandardAPIResponse.error(APIError.badRequest("Cannot cancel batch job - job not found or not in cancellable state"))
        }
    }
    
    /// Get batch processing statistics
    public func getBatchProcessingStatistics() async -> StandardAPIResponse<BatchProcessingStatistics> {
        let jobs = await batchProcessingService.getActiveBatches()
        let statistics = BatchProcessingStatistics(jobs: jobs)
        return StandardAPIResponse.success(statistics)
    }
    
    /// Clean up completed batch jobs
    public func cleanupCompletedBatchJobs(olderThanHours: Int = 1) async -> StandardAPIResponse<String> {
        let timeInterval = TimeInterval(olderThanHours * 3600)
        await batchProcessingService.cleanupCompletedJobs(olderThan: timeInterval)
        return StandardAPIResponse.success("Cleanup completed successfully")
    }
    
    /// Get batch job results with pagination
    public func getBatchJobResults(jobId: UUID, page: Int = 1, pageSize: Int = 20) async -> StandardAPIResponse<BatchJobResultsResponse> {
        guard let job = await batchProcessingService.getBatchStatus(jobId: jobId) else {
            return StandardAPIResponse.error(APIError.notFound("Batch job not found"))
        }
        
        // Validate pagination parameters
        guard page > 0 && pageSize > 0 && pageSize <= 100 else {
            return StandardAPIResponse.error(APIError.validationError("Invalid pagination parameters"))
        }
        
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, job.results.count)
        
        let paginatedResults = startIndex < job.results.count ? 
            Array(job.results[startIndex..<endIndex]) : []
        
        let totalPages = (job.results.count + pageSize - 1) / pageSize
        
        let response = BatchJobResultsResponse(
            jobId: jobId,
            results: paginatedResults,
            pagination: PaginationInfo(
                page: page,
                pageSize: pageSize,
                totalItems: job.results.count,
                totalPages: totalPages,
                hasNext: page < totalPages,
                hasPrevious: page > 1
            ),
            jobStatus: job.status,
            totalResults: job.results.count
        )
        
        return StandardAPIResponse.success(response)
    }
    
    /// Get batch job errors with pagination
    public func getBatchJobErrors(jobId: UUID, page: Int = 1, pageSize: Int = 20) async -> StandardAPIResponse<BatchJobErrorsResponse> {
        guard let job = await batchProcessingService.getBatchStatus(jobId: jobId) else {
            return StandardAPIResponse.error(APIError.notFound("Batch job not found"))
        }
        
        // Validate pagination parameters
        guard page > 0 && pageSize > 0 && pageSize <= 100 else {
            return StandardAPIResponse.error(APIError.validationError("Invalid pagination parameters"))
        }
        
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, job.errors.count)
        
        let paginatedErrors = startIndex < job.errors.count ? 
            Array(job.errors[startIndex..<endIndex]) : []
        
        let totalPages = (job.errors.count + pageSize - 1) / pageSize
        
        let response = BatchJobErrorsResponse(
            jobId: jobId,
            errors: paginatedErrors,
            pagination: PaginationInfo(
                page: page,
                pageSize: pageSize,
                totalItems: job.errors.count,
                totalPages: totalPages,
                hasNext: page < totalPages,
                hasPrevious: page > 1
            ),
            jobStatus: job.status,
            totalErrors: job.errors.count
        )
        
        return StandardAPIResponse.success(response)
    }
}

// MARK: - API Route Definitions

/// Defines the available API routes and their handlers
public struct APIRoutes {
    public static let routes: [String: String] = [
        "GET /api/v1/health": "Health check endpoint",
        "POST /api/v1/scoring/evaluate": "Evaluate single company",
        "POST /api/v1/scoring/batch": "Batch evaluate companies (legacy)",
        "POST /api/v1/batch/start": "Start batch processing job with progress tracking",
        "GET /api/v1/batch/jobs": "Get all active batch jobs",
        "GET /api/v1/batch/jobs/:id": "Get batch job status",
        "DELETE /api/v1/batch/jobs/:id": "Cancel batch job",
        "GET /api/v1/batch/jobs/:id/results": "Get batch job results with pagination",
        "GET /api/v1/batch/jobs/:id/errors": "Get batch job errors with pagination",
        "GET /api/v1/batch/statistics": "Get batch processing statistics",
        "POST /api/v1/batch/cleanup": "Clean up completed batch jobs",
        "GET /api/v1/config": "Get scoring configurations",
        "POST /api/v1/config": "Create scoring configuration",
        "POST /api/v1/reports/generate": "Generate report",
        "GET /api/v1/companies": "List companies",
        "POST /api/v1/companies": "Create company",
        "GET /api/v1/companies/:id": "Get company by ID",
        "PUT /api/v1/companies/:id": "Update company",
        "DELETE /api/v1/companies/:id": "Delete company",
        "GET /api/v1/history/company/:id": "Get company history",
        "POST /api/v1/history/outcome": "Update outcome",
        "GET /api/v1/history/accuracy": "Get accuracy metrics"
    ]
}

// MARK: - API Documentation

/// API documentation and examples
public struct APIDocumentation {
    
    public static let overview = """
    BD & IPO Scoring Module REST API
    
    This API provides endpoints for evaluating biotech companies, managing scoring configurations,
    generating reports, and tracking historical performance.
    
    Base URL: http://localhost:8080/api/v1
    Content-Type: application/json
    """
    
    public static let examples = """
    Example: Evaluate a company
    POST /api/v1/scoring/evaluate
    {
        "companyData": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "basicInfo": {
                "name": "Example Biotech",
                "sector": "Biotechnology",
                "therapeuticAreas": ["Oncology"],
                "stage": "phase2"
            },
            "pipeline": {
                "programs": [...],
                "totalPrograms": 1
            },
            "financials": {
                "cashPosition": 50000000,
                "burnRate": 2000000,
                "runway": 25
            },
            "market": {...},
            "regulatory": {...}
        }
    }
    
    Response:
    {
        "success": true,
        "data": {
            "result": {
                "overallScore": 3.8,
                "pillarScores": {...},
                "confidence": {...}
            },
            "recommendations": [...],
            "processingTime": 0.5
        }
    }
    
    Example: Start batch processing job
    POST /api/v1/batch/start
    {
        "companies": [
            { "id": "...", "basicInfo": {...}, ... },
            { "id": "...", "basicInfo": {...}, ... }
        ],
        "options": {
            "continueOnError": true,
            "maxConcurrency": 5,
            "notifyOnCompletion": true,
            "webhookUrl": "https://example.com/webhook"
        }
    }
    
    Response:
    {
        "success": true,
        "data": {
            "id": "batch-job-uuid",
            "status": "pending",
            "totalCompanies": 2,
            "processedCompanies": 0,
            "progress": 0.0,
            "startTime": "2023-12-01T10:00:00Z",
            "estimatedCompletion": "2023-12-01T10:05:00Z"
        }
    }
    
    Example: Get batch job status
    GET /api/v1/batch/jobs/{jobId}
    
    Response:
    {
        "success": true,
        "data": {
            "id": "batch-job-uuid",
            "status": "processing",
            "totalCompanies": 2,
            "processedCompanies": 1,
            "successfulEvaluations": 1,
            "failedEvaluations": 0,
            "progress": 0.5,
            "processingTime": 30.5,
            "estimatedTimeRemaining": 25.0
        }
    }
    """
}