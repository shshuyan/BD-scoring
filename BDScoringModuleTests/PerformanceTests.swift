import XCTest
@testable import BDScoringModule

class PerformanceTests: XCTestCase {
    var performanceMonitor: PerformanceMonitoringService!
    var cachingService: CachingService!
    var scoringEngine: BDScoringEngine!
    var reportGenerator: ReportGenerator!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceMonitor = PerformanceMonitoringService.shared
        cachingService = CachingService.shared
        scoringEngine = BDScoringEngine()
        reportGenerator = ReportGenerator()
        
        // Clear any existing cache and metrics
        await MainActor.run {
            cachingService.clearAll()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            cachingService.clearAll()
        }
        try await super.tearDown()
    }
    
    // MARK: - Scoring Performance Tests
    
    func testScoringOperationPerformance() async throws {
        // Test individual company scoring meets < 5 second requirement
        let companyData = createTestCompanyData()
        let config = createTestScoringConfig()
        
        let startTime = Date()
        let result = try await scoringEngine.evaluateCompany(companyData, config: config)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, PerformanceThresholds.scoringOperation, 
                         "Scoring operation took \(duration)s, exceeds threshold of \(PerformanceThresholds.scoringOperation)s")
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.overallScore, 0)
    }
    
    func testBatchScoringPerformance() async throws {
        // Test batch processing meets < 30 seconds per company requirement
        let companies = (1...10).map { _ in createTestCompanyData() }
        let config = createTestScoringConfig()
        
        let startTime = Date()
        var results: [ScoringResult] = []
        
        for company in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            results.append(result)
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let averageDurationPerCompany = totalDuration / Double(companies.count)
        
        XCTAssertLessThan(averageDurationPerCompany, PerformanceThresholds.batchProcessing,
                         "Batch processing took \(averageDurationPerCompany)s per company, exceeds threshold of \(PerformanceThresholds.batchProcessing)s")
        XCTAssertEqual(results.count, companies.count)
    }
    
    func testConcurrentScoringPerformance() async throws {
        // Test concurrent scoring operations
        let companyData = createTestCompanyData()
        let config = createTestScoringConfig()
        let concurrentOperations = 10
        
        let startTime = Date()
        
        await withTaskGroup(of: ScoringResult?.self) { group in
            for _ in 0..<concurrentOperations {
                group.addTask {
                    do {
                        return try await self.scoringEngine.evaluateCompany(companyData, config: config)
                    } catch {
                        XCTFail("Concurrent scoring failed: \(error)")
                        return nil
                    }
                }
            }
            
            var completedOperations = 0
            for await result in group {
                if result != nil {
                    completedOperations += 1
                }
            }
            
            let totalDuration = Date().timeIntervalSince(startTime)
            let averageDuration = totalDuration / Double(concurrentOperations)
            
            XCTAssertEqual(completedOperations, concurrentOperations, "Not all concurrent operations completed")
            XCTAssertLessThan(averageDuration, PerformanceThresholds.scoringOperation * 2, 
                             "Concurrent operations took too long on average: \(averageDuration)s")
        }
    }
    
    // MARK: - Report Generation Performance Tests
    
    func testReportGenerationPerformance() async throws {
        // Test report generation meets < 10 second requirement
        let companyData = createTestCompanyData()
        let config = createTestScoringConfig()
        let scoringResult = try await scoringEngine.evaluateCompany(companyData, config: config)
        
        let startTime = Date()
        let report = try await reportGenerator.generateDetailedReport(scoringResult)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, PerformanceThresholds.reportGeneration,
                         "Report generation took \(duration)s, exceeds threshold of \(PerformanceThresholds.reportGeneration)s")
        XCTAssertNotNil(report)
        XCTAssertFalse(report.content.isEmpty)
    }
    
    func testBatchReportGenerationPerformance() async throws {
        // Test multiple report generation
        let companies = (1...5).map { _ in createTestCompanyData() }
        let config = createTestScoringConfig()
        
        var scoringResults: [ScoringResult] = []
        for company in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            scoringResults.append(result)
        }
        
        let startTime = Date()
        var reports: [Report] = []
        
        for result in scoringResults {
            let report = try await reportGenerator.generateDetailedReport(result)
            reports.append(report)
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let averageDurationPerReport = totalDuration / Double(scoringResults.count)
        
        XCTAssertLessThan(averageDurationPerReport, PerformanceThresholds.reportGeneration,
                         "Batch report generation took \(averageDurationPerReport)s per report, exceeds threshold")
        XCTAssertEqual(reports.count, scoringResults.count)
    }
    
    // MARK: - Caching Performance Tests
    
    func testCachingPerformance() async throws {
        let testData = createTestCompanyData()
        let cacheKey = "test_company_123"
        
        // Test cache write performance
        let writeStartTime = Date()
        await MainActor.run {
            cachingService.set(cacheKey, value: testData, in: "companyData")
        }
        let writeDuration = Date().timeIntervalSince(writeStartTime)
        
        XCTAssertLessThan(writeDuration, 0.1, "Cache write took too long: \(writeDuration)s")
        
        // Test cache read performance
        let readStartTime = Date()
        let cachedData: CompanyData? = await MainActor.run {
            cachingService.get(cacheKey, from: "companyData")
        }
        let readDuration = Date().timeIntervalSince(readStartTime)
        
        XCTAssertLessThan(readDuration, 0.01, "Cache read took too long: \(readDuration)s")
        XCTAssertNotNil(cachedData)
        XCTAssertEqual(cachedData?.basicInfo.name, testData.basicInfo.name)
    }
    
    func testCacheHitRateOptimization() async throws {
        let companyData = createTestCompanyData()
        let config = createTestScoringConfig()
        let companyId = "test_company_performance"
        let configHash = "test_config_hash"
        
        // First scoring operation (cache miss)
        let firstResult = try await scoringEngine.evaluateCompany(companyData, config: config)
        await MainActor.run {
            cachingService.cacheScoringResult(firstResult, for: companyId, configHash: configHash)
        }
        
        // Second scoring operation (should hit cache)
        let startTime = Date()
        let cachedResult: ScoringResult? = await MainActor.run {
            cachingService.getCachedScoringResult(for: companyId, configHash: configHash)
        }
        let cacheDuration = Date().timeIntervalSince(startTime)
        
        XCTAssertNotNil(cachedResult)
        XCTAssertLessThan(cacheDuration, 0.01, "Cache retrieval took too long: \(cacheDuration)s")
        XCTAssertEqual(cachedResult?.overallScore, firstResult.overallScore)
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageUnderLoad() async throws {
        let initialMemory = getMemoryUsage()
        let companies = (1...50).map { _ in createTestCompanyData() }
        let config = createTestScoringConfig()
        
        // Process multiple companies
        for company in companies {
            _ = try await scoringEngine.evaluateCompany(company, config: config)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseInMB = Double(memoryIncrease) / (1024 * 1024)
        
        // Memory increase should be reasonable (less than 100MB for 50 companies)
        XCTAssertLessThan(memoryIncreaseInMB, 100, 
                         "Memory usage increased by \(memoryIncreaseInMB)MB, which may indicate a memory leak")
    }
    
    // MARK: - Database Query Performance Tests
    
    func testComparableSearchPerformance() async throws {
        // Test comparable search meets < 2 second requirement
        let criteria = ComparableCriteria(
            therapeuticArea: "Oncology",
            stage: .phaseII,
            marketSize: 1000000000
        )
        
        let startTime = Date()
        let comparables = try await ComparablesService().findComparables(criteria: criteria)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, PerformanceThresholds.comparableSearch,
                         "Comparable search took \(duration)s, exceeds threshold of \(PerformanceThresholds.comparableSearch)s")
        XCTAssertNotNil(comparables)
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformanceMonitoringAccuracy() async throws {
        let operationType = "test_operation"
        let expectedDuration: TimeInterval = 0.5
        
        let operationId = await MainActor.run {
            performanceMonitor.startOperation(operationType)
        }
        
        // Simulate work
        try await Task.sleep(nanoseconds: UInt64(expectedDuration * 1_000_000_000))
        
        await MainActor.run {
            performanceMonitor.endOperation(operationId, success: true)
        }
        
        // Check recorded metrics
        let (averageDuration, count) = await MainActor.run {
            performanceMonitor.getAveragePerformance(for: operationType)
        }
        
        XCTAssertEqual(count, 1)
        XCTAssertGreaterThan(averageDuration, expectedDuration * 0.9) // Allow 10% variance
        XCTAssertLessThan(averageDuration, expectedDuration * 1.1)
    }
    
    // MARK: - Scalability Tests
    
    func testSystemScalabilityUnderLoad() async throws {
        let numberOfOperations = 100
        let companyData = createTestCompanyData()
        let config = createTestScoringConfig()
        
        let startTime = Date()
        var successfulOperations = 0
        var failedOperations = 0
        
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<numberOfOperations {
                group.addTask {
                    do {
                        let operationId = await MainActor.run {
                            self.performanceMonitor.startOperation("scalability_test")
                        }
                        
                        _ = try await self.scoringEngine.evaluateCompany(companyData, config: config)
                        
                        await MainActor.run {
                            self.performanceMonitor.endOperation(operationId, success: true)
                        }
                        
                        return true
                    } catch {
                        return false
                    }
                }
            }
            
            for await success in group {
                if success {
                    successfulOperations += 1
                } else {
                    failedOperations += 1
                }
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let operationsPerSecond = Double(numberOfOperations) / totalDuration
        let successRate = Double(successfulOperations) / Double(numberOfOperations)
        
        XCTAssertGreaterThan(successRate, 0.95, "Success rate under load was only \(successRate * 100)%")
        XCTAssertGreaterThan(operationsPerSecond, 10, "System processed only \(operationsPerSecond) operations per second")
        
        print("Scalability Test Results:")
        print("- Total Operations: \(numberOfOperations)")
        print("- Successful: \(successfulOperations)")
        print("- Failed: \(failedOperations)")
        print("- Success Rate: \(String(format: "%.1f", successRate * 100))%")
        print("- Operations/Second: \(String(format: "%.1f", operationsPerSecond))")
        print("- Total Duration: \(String(format: "%.2f", totalDuration))s")
    }
    
    // MARK: - Helper Methods
    
    private func createTestCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Test Biotech \(UUID().uuidString.prefix(8))",
                ticker: "TEST",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phaseII
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "Test Program 1",
                        indication: "Cancer",
                        stage: .phaseII,
                        mechanism: "Monoclonal Antibody",
                        differentiators: ["Novel target", "Best-in-class"],
                        risks: [Risk(type: "Clinical", description: "Efficacy risk", probability: 0.3)],
                        timeline: [Milestone(name: "Phase III Start", date: Date().addingTimeInterval(365 * 24 * 3600))]
                    )
                ],
                totalPrograms: 1
            ),
            financials: CompanyFinancials(
                cashPosition: 50000000,
                burnRate: 5000000,
                lastFunding: FundingRound(amount: 75000000, date: Date().addingTimeInterval(-180 * 24 * 3600), type: "Series B"),
                runway: 10
            ),
            market: CompanyMarket(
                addressableMarket: 5000000000,
                competitors: [
                    Competitor(name: "Big Pharma Co", marketShare: 0.3, strengths: ["Established presence"])
                ],
                marketDynamics: MarketDynamics(growthRate: 0.15, competitiveIntensity: "High")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [
                    ClinicalTrial(phase: .phaseII, status: "Active", enrollment: 200, primaryEndpoint: "Overall Response Rate")
                ],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Standard", timeline: 36, risks: ["Regulatory delay"])
            )
        )
    }
    
    private func createTestScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.25,
                marketOutlook: 0.20,
                capitalIntensity: 0.15,
                strategicFit: 0.15,
                financialReadiness: 0.15,
                regulatoryRisk: 0.10
            ),
            customParameters: [:]
        )
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}