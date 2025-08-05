import XCTest
@testable import BDScoringModule

/// Integration tests for batch processing service and endpoints
final class BatchProcessingServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var scoringEngine: BDScoringEngine!
    var batchProcessingService: BatchProcessingService!
    var apiController: APIController!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize services
        scoringEngine = BDScoringEngine()
        batchProcessingService = BatchProcessingService(scoringEngine: scoringEngine)
        apiController = APIController(scoringEngine: scoringEngine)
    }
    
    override func tearDownWithError() throws {
        // Clean up
        scoringEngine = nil
        batchProcessingService = nil
        apiController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Batch Processing Service Tests
    
    func testStartBatchJob_Success() async throws {
        let companies = [
            createTestCompanyData(name: "Company A"),
            createTestCompanyData(name: "Company B")
        ]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let job = await batchProcessingService.startBatchJob(request)
        
        XCTAssertNotNil(job.id)
        XCTAssertEqual(job.totalCompanies, 2)
        XCTAssertEqual(job.processedCompanies, 0)
        XCTAssertEqual(job.status, .pending)
        XCTAssertNotNil(job.startTime)
        XCTAssertNil(job.completionTime)
        
        // Wait a bit for processing to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Check if job status has been updated
        let updatedJob = await batchProcessingService.getBatchStatus(jobId: job.id)
        XCTAssertNotNil(updatedJob)
    }
    
    func testGetBatchStatus() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let job = await batchProcessingService.startBatchJob(request)
        let retrievedJob = await batchProcessingService.getBatchStatus(jobId: job.id)
        
        XCTAssertNotNil(retrievedJob)
        XCTAssertEqual(retrievedJob?.id, job.id)
        XCTAssertEqual(retrievedJob?.totalCompanies, 1)
    }
    
    func testGetBatchStatus_NotFound() async throws {
        let nonExistentJobId = UUID()
        let job = await batchProcessingService.getBatchStatus(jobId: nonExistentJobId)
        
        XCTAssertNil(job)
    }
    
    func testGetActiveBatches() async throws {
        let companies1 = [createTestCompanyData(name: "Company 1")]
        let companies2 = [createTestCompanyData(name: "Company 2")]
        
        let request1 = BatchEvaluationRequest(companies: companies1, config: nil, options: nil)
        let request2 = BatchEvaluationRequest(companies: companies2, config: nil, options: nil)
        
        let job1 = await batchProcessingService.startBatchJob(request1)
        let job2 = await batchProcessingService.startBatchJob(request2)
        
        let activeBatches = await batchProcessingService.getActiveBatches()
        
        XCTAssertGreaterThanOrEqual(activeBatches.count, 2)
        XCTAssertTrue(activeBatches.contains { $0.id == job1.id })
        XCTAssertTrue(activeBatches.contains { $0.id == job2.id })
    }
    
    func testCancelBatchJob() async throws {
        let companies = Array(repeating: createTestCompanyData(), count: 10) // Larger batch to allow cancellation
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let job = await batchProcessingService.startBatchJob(request)
        
        // Try to cancel immediately
        let cancelled = await batchProcessingService.cancelBatchJob(jobId: job.id)
        XCTAssertTrue(cancelled)
        
        // Check job status
        let updatedJob = await batchProcessingService.getBatchStatus(jobId: job.id)
        XCTAssertEqual(updatedJob?.status, .cancelled)
    }
    
    func testCancelBatchJob_NotFound() async throws {
        let nonExistentJobId = UUID()
        let cancelled = await batchProcessingService.cancelBatchJob(jobId: nonExistentJobId)
        
        XCTAssertFalse(cancelled)
    }
    
    func testBatchJobWithOptions() async throws {
        let companies = [createTestCompanyData()]
        let options = BatchOptions(
            continueOnError: true,
            maxConcurrency: 2,
            notifyOnCompletion: false,
            webhookUrl: nil
        )
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: options)
        
        let job = await batchProcessingService.startBatchJob(request)
        
        XCTAssertEqual(job.options.maxConcurrency, 2)
        XCTAssertTrue(job.options.continueOnError)
        XCTAssertFalse(job.options.notifyOnCompletion)
    }
    
    func testCleanupCompletedJobs() async throws {
        // This test would need completed jobs to clean up
        // For now, just test that the method doesn't crash
        await batchProcessingService.cleanupCompletedJobs(olderThan: 1.0)
        
        // No assertion needed - just testing that it doesn't crash
    }
    
    // MARK: - API Controller Batch Processing Tests
    
    func testStartBatchJob_API() async throws {
        let companies = [
            createTestCompanyData(name: "API Company A"),
            createTestCompanyData(name: "API Company B")
        ]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let response = await apiController.startBatchJob(request)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        
        let job = response.data!
        XCTAssertEqual(job.totalCompanies, 2)
        XCTAssertEqual(job.status, .pending)
    }
    
    func testStartBatchJob_API_InvalidData() async throws {
        let request = BatchEvaluationRequest(companies: [], config: nil, options: nil)
        
        let response = await apiController.startBatchJob(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("At least one company is required"))
    }
    
    func testGetBatchJobStatus_API() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let jobId = startResponse.data!.id
        let statusResponse = await apiController.getBatchJobStatus(jobId: jobId)
        
        XCTAssertTrue(statusResponse.success)
        XCTAssertNotNil(statusResponse.data)
        XCTAssertEqual(statusResponse.data!.id, jobId)
    }
    
    func testGetBatchJobStatus_API_NotFound() async throws {
        let nonExistentJobId = UUID()
        let response = await apiController.getBatchJobStatus(jobId: nonExistentJobId)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Batch job not found"))
    }
    
    func testGetActiveBatchJobs_API() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        // Start a batch job
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        // Get active jobs
        let activeJobsResponse = await apiController.getActiveBatchJobs()
        
        XCTAssertTrue(activeJobsResponse.success)
        XCTAssertNotNil(activeJobsResponse.data)
        XCTAssertGreaterThanOrEqual(activeJobsResponse.data!.count, 1)
    }
    
    func testCancelBatchJob_API() async throws {
        let companies = Array(repeating: createTestCompanyData(), count: 5)
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let jobId = startResponse.data!.id
        let cancelResponse = await apiController.cancelBatchJob(jobId: jobId)
        
        XCTAssertTrue(cancelResponse.success)
        XCTAssertTrue(cancelResponse.data!.contains("cancelled successfully"))
    }
    
    func testCancelBatchJob_API_NotFound() async throws {
        let nonExistentJobId = UUID()
        let response = await apiController.cancelBatchJob(jobId: nonExistentJobId)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Cannot cancel batch job"))
    }
    
    func testGetBatchProcessingStatistics_API() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        // Start a batch job to have some statistics
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let statisticsResponse = await apiController.getBatchProcessingStatistics()
        
        XCTAssertTrue(statisticsResponse.success)
        XCTAssertNotNil(statisticsResponse.data)
        
        let statistics = statisticsResponse.data!
        XCTAssertGreaterThanOrEqual(statistics.totalJobs, 1)
        XCTAssertGreaterThanOrEqual(statistics.activeJobs, 0)
        XCTAssertNotNil(statistics.lastUpdated)
    }
    
    func testCleanupCompletedBatchJobs_API() async throws {
        let response = await apiController.cleanupCompletedBatchJobs(olderThanHours: 1)
        
        XCTAssertTrue(response.success)
        XCTAssertTrue(response.data!.contains("Cleanup completed successfully"))
    }
    
    func testGetBatchJobResults_API() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let jobId = startResponse.data!.id
        
        // Wait a bit for processing to potentially complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let resultsResponse = await apiController.getBatchJobResults(jobId: jobId, page: 1, pageSize: 10)
        
        XCTAssertTrue(resultsResponse.success)
        XCTAssertNotNil(resultsResponse.data)
        
        let response = resultsResponse.data!
        XCTAssertEqual(response.jobId, jobId)
        XCTAssertNotNil(response.pagination)
        XCTAssertEqual(response.pagination.page, 1)
        XCTAssertEqual(response.pagination.pageSize, 10)
    }
    
    func testGetBatchJobResults_API_InvalidPagination() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let jobId = startResponse.data!.id
        
        // Test invalid page number
        let invalidPageResponse = await apiController.getBatchJobResults(jobId: jobId, page: 0, pageSize: 10)
        XCTAssertFalse(invalidPageResponse.success)
        XCTAssertTrue(invalidPageResponse.error!.message.contains("Invalid pagination parameters"))
        
        // Test invalid page size
        let invalidPageSizeResponse = await apiController.getBatchJobResults(jobId: jobId, page: 1, pageSize: 101)
        XCTAssertFalse(invalidPageSizeResponse.success)
        XCTAssertTrue(invalidPageSizeResponse.error!.message.contains("Invalid pagination parameters"))
    }
    
    func testGetBatchJobErrors_API() async throws {
        let companies = [createTestCompanyData()]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startResponse = await apiController.startBatchJob(request)
        XCTAssertTrue(startResponse.success)
        
        let jobId = startResponse.data!.id
        
        let errorsResponse = await apiController.getBatchJobErrors(jobId: jobId, page: 1, pageSize: 10)
        
        XCTAssertTrue(errorsResponse.success)
        XCTAssertNotNil(errorsResponse.data)
        
        let response = errorsResponse.data!
        XCTAssertEqual(response.jobId, jobId)
        XCTAssertNotNil(response.pagination)
        XCTAssertEqual(response.pagination.page, 1)
        XCTAssertEqual(response.pagination.pageSize, 10)
    }
    
    // MARK: - Performance Tests
    
    func testBatchProcessing_Performance() async throws {
        let companies = Array(repeating: createTestCompanyData(), count: 5)
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startTime = Date()
        let response = await apiController.startBatchJob(request)
        let responseTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(response.success)
        XCTAssertLessThan(responseTime, 1.0, "Starting batch job should be fast")
        
        // Wait for processing to complete
        let jobId = response.data!.id
        var completed = false
        var attempts = 0
        let maxAttempts = 30 // 30 seconds max wait
        
        while !completed && attempts < maxAttempts {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let statusResponse = await apiController.getBatchJobStatus(jobId: jobId)
            if let job = statusResponse.data {
                completed = job.status == .completed || job.status == .failed || job.status == .partiallyCompleted
            }
            attempts += 1
        }
        
        XCTAssertTrue(completed, "Batch job should complete within 30 seconds")
    }
    
    func testConcurrentBatchJobs() async throws {
        let companies = [createTestCompanyData()]
        
        // Start multiple batch jobs concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<3 {
                group.addTask {
                    let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
                    let response = await self.apiController.startBatchJob(request)
                    XCTAssertTrue(response.success, "Concurrent batch job \(i) should start successfully")
                }
            }
        }
        
        // Check that all jobs are tracked
        let activeJobsResponse = await apiController.getActiveBatchJobs()
        XCTAssertTrue(activeJobsResponse.success)
        XCTAssertGreaterThanOrEqual(activeJobsResponse.data!.count, 3)
    }
    
    // MARK: - Edge Case Tests
    
    func testBatchJobWithInvalidCompanyData() async throws {
        let invalidCompany = CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: "", // Invalid: empty name
                ticker: nil,
                sector: "Biotechnology",
                therapeuticAreas: [],
                stage: .preclinical,
                description: nil
            ),
            pipeline: Pipeline(programs: [], totalPrograms: 0, leadProgram: nil), // Invalid: no programs
            financials: Financials(cashPosition: 0, burnRate: 0, lastFunding: nil, runway: 0),
            market: Market(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .emerging
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 0,
                    keyMilestones: [],
                    risks: []
                )
            )
        )
        
        let request = BatchEvaluationRequest(companies: [invalidCompany], config: nil, options: nil)
        let response = await apiController.startBatchJob(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
    }
    
    func testBatchJobWithMixedValidInvalidData() async throws {
        let validCompany = createTestCompanyData(name: "Valid Company")
        let invalidCompany = CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: "", // Invalid: empty name
                ticker: nil,
                sector: "Biotechnology",
                therapeuticAreas: [],
                stage: .preclinical,
                description: nil
            ),
            pipeline: Pipeline(programs: [], totalPrograms: 0, leadProgram: nil), // Invalid: no programs
            financials: Financials(cashPosition: 0, burnRate: 0, lastFunding: nil, runway: 0),
            market: Market(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .emerging
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 0,
                    keyMilestones: [],
                    risks: []
                )
            )
        )
        
        let options = BatchOptions(continueOnError: true, maxConcurrency: 2, notifyOnCompletion: false, webhookUrl: nil)
        let request = BatchEvaluationRequest(companies: [validCompany, invalidCompany], config: nil, options: options)
        
        let response = await apiController.startBatchJob(request)
        
        // The request validation should catch the invalid company name
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
    }
    
    // MARK: - Helper Methods
    
    private func createTestCompanyData(name: String = "Test Biotech Company") -> CompanyData {
        return CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: name,
                ticker: "TEST",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phase2,
                description: "A test biotech company for batch processing testing"
            ),
            pipeline: Pipeline(
                programs: [
                    Program(
                        id: UUID(),
                        name: "Test Program",
                        indication: "Cancer",
                        stage: .phase2,
                        mechanism: "Monoclonal Antibody",
                        differentiators: ["Novel target"],
                        risks: [
                            Risk(
                                category: "Clinical",
                                description: "Phase 2 trial risk",
                                probability: .medium,
                                impact: .high,
                                mitigation: "Robust trial design"
                            )
                        ],
                        timeline: [
                            Milestone(
                                name: "Phase 2 Completion",
                                date: Calendar.current.date(byAdding: .month, value: 18, to: Date())!,
                                description: "Complete Phase 2 clinical trial"
                            )
                        ]
                    )
                ],
                totalPrograms: 1,
                leadProgram: nil
            ),
            financials: Financials(
                cashPosition: 25_000_000,
                burnRate: 1_500_000,
                lastFunding: FundingRound(
                    type: .seriesA,
                    amount: 50_000_000,
                    date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                    investors: ["Test VC"],
                    valuation: 200_000_000
                ),
                runway: 16
            ),
            market: Market(
                addressableMarket: 2_000_000_000,
                competitors: [
                    Competitor(
                        name: "Test Competitor",
                        stage: .phase3,
                        marketShare: 0.2,
                        strengths: ["Established"],
                        weaknesses: ["Limited pipeline"]
                    )
                ],
                marketDynamics: MarketDynamics(
                    growthRate: 0.12,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .growing
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [
                    ClinicalTrial(
                        id: "NCT87654321",
                        phase: .phase2,
                        status: .active,
                        indication: "Cancer",
                        patientCount: 150,
                        startDate: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
                        estimatedCompletion: Calendar.current.date(byAdding: .month, value: 12, to: Date())!
                    )
                ],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 48,
                    keyMilestones: ["IND Filing", "Phase 2 Start"],
                    risks: ["Regulatory delay"]
                )
            )
        )
    }
}