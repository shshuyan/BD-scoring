import XCTest
@testable import BDScoringModule

class LoadTests: XCTestCase {
    var scoringEngine: BDScoringEngine!
    var reportGenerator: ReportGenerator!
    var performanceMonitor: PerformanceMonitoringService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        scoringEngine = BDScoringEngine()
        reportGenerator = ReportGenerator()
        performanceMonitor = PerformanceMonitoringService.shared
        
        // Clear cache and metrics for clean testing
        await MainActor.run {
            CachingService.shared.clearAll()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            CachingService.shared.clearAll()
        }
        try await super.tearDown()
    }
    
    // MARK: - Concurrent User Load Tests
    
    func testConcurrentUserScoring() async throws {
        // Test system under concurrent user load
        let numberOfUsers = 25
        let operationsPerUser = 4
        let totalOperations = numberOfUsers * operationsPerUser
        
        let startTime = Date()
        var successfulOperations = 0
        var failedOperations = 0
        var allResults: [ScoringResult] = []
        
        await withTaskGroup(of: [ScoringResult].self) { group in
            // Simulate concurrent users
            for userId in 0..<numberOfUsers {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    
                    var userResults: [ScoringResult] = []
                    
                    // Each user performs multiple operations
                    for operationId in 0..<operationsPerUser {
                        do {
                            let companyData = self.createVariedCompanyData(userId: userId, operationId: operationId)
                            let config = self.createRandomScoringConfig()
                            
                            let result = try await self.scoringEngine.evaluateCompany(companyData, config: config)
                            userResults.append(result)
                        } catch {
                            print("User \(userId) operation \(operationId) failed: \(error)")
                        }
                    }
                    
                    return userResults
                }
            }
            
            // Collect all results
            for await userResults in group {
                allResults.append(contentsOf: userResults)
                successfulOperations += userResults.count
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        failedOperations = totalOperations - successfulOperations
        
        // Performance assertions
        let operationsPerSecond = Double(successfulOperations) / totalDuration
        let successRate = Double(successfulOperations) / Double(totalOperations)
        
        XCTAssertGreaterThan(successRate, 0.95, "Success rate should be > 95% under load")
        XCTAssertGreaterThan(operationsPerSecond, 5.0, "Should handle at least 5 operations per second")
        XCTAssertLessThan(totalDuration, 60.0, "Total test should complete within 60 seconds")
        
        // Verify result quality under load
        let averageScore = allResults.map { $0.overallScore }.reduce(0, +) / Double(allResults.count)
        let averageConfidence = allResults.map { $0.confidence.overall }.reduce(0, +) / Double(allResults.count)
        
        XCTAssertGreaterThan(averageScore, 1.0, "Average score should be reasonable")
        XCTAssertLessThan(averageScore, 5.0, "Average score should be within bounds")
        XCTAssertGreaterThan(averageConfidence, 0.5, "Average confidence should be reasonable")
        
        print("✅ Concurrent user load test completed")
        print("   - Total operations: \(totalOperations)")
        print("   - Successful: \(successfulOperations)")
        print("   - Failed: \(failedOperations)")
        print("   - Success rate: \(String(format: "%.1f", successRate * 100))%")
        print("   - Operations/second: \(String(format: "%.1f", operationsPerSecond))")
        print("   - Total duration: \(String(format: "%.1f", totalDuration))s")
        print("   - Average score: \(String(format: "%.2f", averageScore))")
        print("   - Average confidence: \(String(format: "%.1f", averageConfidence * 100))%")
    }
    
    func testConcurrentReportGeneration() async throws {
        // Test concurrent report generation load
        let numberOfReports = 20
        let companies = (0..<numberOfReports).map { createVariedCompanyData(userId: $0, operationId: 0) }
        let config = createStandardScoringConfig()
        
        // First, generate scoring results
        var scoringResults: [ScoringResult] = []
        for company in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            scoringResults.append(result)
        }
        
        // Now test concurrent report generation
        let startTime = Date()
        var successfulReports = 0
        var reports: [Report] = []
        
        await withTaskGroup(of: Report?.self) { group in
            for result in scoringResults {
                group.addTask { [weak self] in
                    do {
                        return try await self?.reportGenerator.generateDetailedReport(result)
                    } catch {
                        print("Report generation failed: \(error)")
                        return nil
                    }
                }
            }
            
            for await report in group {
                if let report = report {
                    reports.append(report)
                    successfulReports += 1
                }
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let reportsPerSecond = Double(successfulReports) / totalDuration
        let successRate = Double(successfulReports) / Double(numberOfReports)
        
        // Performance assertions
        XCTAssertGreaterThan(successRate, 0.90, "Report generation success rate should be > 90%")
        XCTAssertGreaterThan(reportsPerSecond, 1.0, "Should generate at least 1 report per second")
        XCTAssertEqual(reports.count, successfulReports)
        
        // Verify report quality
        let averageReportLength = reports.map { $0.content.count }.reduce(0, +) / reports.count
        XCTAssertGreaterThan(averageReportLength, 1000, "Reports should have substantial content")
        
        print("✅ Concurrent report generation test completed")
        print("   - Reports requested: \(numberOfReports)")
        print("   - Reports generated: \(successfulReports)")
        print("   - Success rate: \(String(format: "%.1f", successRate * 100))%")
        print("   - Reports/second: \(String(format: "%.1f", reportsPerSecond))")
        print("   - Average length: \(averageReportLength) characters")
    }
    
    // MARK: - Batch Processing Load Tests
    
    func testLargeBatchProcessing() async throws {
        // Test processing large batches of companies
        let batchSize = 50
        let companies = (0..<batchSize).map { createVariedCompanyData(userId: $0, operationId: 0) }
        let config = createStandardScoringConfig()
        
        let startTime = Date()
        let results = try await scoringEngine.evaluateCompanies(companies, config: config)
        let totalDuration = Date().timeIntervalSince(startTime)
        
        let averageDurationPerCompany = totalDuration / Double(batchSize)
        let companiesPerSecond = Double(batchSize) / totalDuration
        
        // Performance assertions
        XCTAssertEqual(results.count, batchSize, "Should process all companies")
        XCTAssertLessThan(averageDurationPerCompany, PerformanceThresholds.batchProcessing, 
                         "Average processing time should meet threshold")
        XCTAssertGreaterThan(companiesPerSecond, 1.0, "Should process at least 1 company per second")
        
        // Verify result quality
        let validResults = results.filter { $0.overallScore > 0 && $0.overallScore <= 5.0 }
        XCTAssertEqual(validResults.count, results.count, "All results should be valid")
        
        print("✅ Large batch processing test completed")
        print("   - Batch size: \(batchSize)")
        print("   - Total duration: \(String(format: "%.1f", totalDuration))s")
        print("   - Average per company: \(String(format: "%.3f", averageDurationPerCompany))s")
        print("   - Companies/second: \(String(format: "%.1f", companiesPerSecond))")
    }
    
    func testMultipleBatchProcessing() async throws {
        // Test multiple concurrent batch operations
        let numberOfBatches = 5
        let companiesPerBatch = 10
        
        let startTime = Date()
        var allResults: [[ScoringResult]] = []
        
        await withTaskGroup(of: [ScoringResult].self) { group in
            for batchId in 0..<numberOfBatches {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    
                    let companies = (0..<companiesPerBatch).map { 
                        self.createVariedCompanyData(userId: batchId, operationId: $0) 
                    }
                    let config = self.createStandardScoringConfig()
                    
                    do {
                        return try await self.scoringEngine.evaluateCompanies(companies, config: config)
                    } catch {
                        print("Batch \(batchId) failed: \(error)")
                        return []
                    }
                }
            }
            
            for await batchResults in group {
                allResults.append(batchResults)
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let totalCompanies = numberOfBatches * companiesPerBatch
        let totalProcessed = allResults.flatMap { $0 }.count
        let successRate = Double(totalProcessed) / Double(totalCompanies)
        
        // Performance assertions
        XCTAssertGreaterThan(successRate, 0.95, "Batch processing success rate should be > 95%")
        XCTAssertEqual(allResults.count, numberOfBatches, "Should complete all batches")
        
        print("✅ Multiple batch processing test completed")
        print("   - Batches: \(numberOfBatches)")
        print("   - Companies per batch: \(companiesPerBatch)")
        print("   - Total companies: \(totalCompanies)")
        print("   - Successfully processed: \(totalProcessed)")
        print("   - Success rate: \(String(format: "%.1f", successRate * 100))%")
        print("   - Total duration: \(String(format: "%.1f", totalDuration))s")
    }
    
    // MARK: - Memory and Resource Load Tests
    
    func testMemoryUsageUnderLoad() async throws {
        // Test memory usage during sustained load
        let initialMemory = getMemoryUsage()
        let numberOfOperations = 100
        
        var results: [ScoringResult] = []
        
        for i in 0..<numberOfOperations {
            let companyData = createVariedCompanyData(userId: i, operationId: 0)
            let config = createStandardScoringConfig()
            
            let result = try await scoringEngine.evaluateCompany(companyData, config: config)
            results.append(result)
            
            // Check memory every 25 operations
            if i % 25 == 0 {
                let currentMemory = getMemoryUsage()
                let memoryIncrease = currentMemory - initialMemory
                let memoryIncreaseInMB = Double(memoryIncrease) / (1024 * 1024)
                
                print("   Memory after \(i + 1) operations: +\(String(format: "%.1f", memoryIncreaseInMB))MB")
                
                // Memory should not grow excessively
                XCTAssertLessThan(memoryIncreaseInMB, 200, "Memory usage should not exceed 200MB increase")
            }
        }
        
        let finalMemory = getMemoryUsage()
        let totalMemoryIncrease = finalMemory - initialMemory
        let totalMemoryIncreaseInMB = Double(totalMemoryIncrease) / (1024 * 1024)
        
        // Final memory check
        XCTAssertLessThan(totalMemoryIncreaseInMB, 300, "Total memory increase should be reasonable")
        XCTAssertEqual(results.count, numberOfOperations, "Should complete all operations")
        
        print("✅ Memory usage under load test completed")
        print("   - Operations: \(numberOfOperations)")
        print("   - Total memory increase: \(String(format: "%.1f", totalMemoryIncreaseInMB))MB")
    }
    
    func testCacheEfficiencyUnderLoad() async throws {
        // Test cache efficiency during high load
        let numberOfOperations = 100
        let uniqueCompanies = 10 // Reuse companies to test cache hits
        
        let companies = (0..<uniqueCompanies).map { createVariedCompanyData(userId: $0, operationId: 0) }
        let config = createStandardScoringConfig()
        
        let startTime = Date()
        var results: [ScoringResult] = []
        
        // Perform operations with repeated companies
        for i in 0..<numberOfOperations {
            let companyIndex = i % uniqueCompanies
            let company = companies[companyIndex]
            
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            results.append(result)
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let averageDuration = totalDuration / Double(numberOfOperations)
        
        // Check cache statistics
        let cacheStats = await MainActor.run {
            CachingService.shared.cacheStats["default"] ?? CacheStats()
        }
        
        let expectedCacheHits = numberOfOperations - uniqueCompanies // First occurrence of each company is cache miss
        let actualCacheHits = cacheStats.hits
        
        // Performance assertions
        XCTAssertGreaterThan(actualCacheHits, expectedCacheHits / 2, "Should have significant cache hits")
        XCTAssertLessThan(averageDuration, 1.0, "Average operation should be fast due to caching")
        XCTAssertEqual(results.count, numberOfOperations)
        
        print("✅ Cache efficiency under load test completed")
        print("   - Operations: \(numberOfOperations)")
        print("   - Unique companies: \(uniqueCompanies)")
        print("   - Cache hits: \(actualCacheHits)")
        print("   - Cache misses: \(cacheStats.misses)")
        print("   - Hit rate: \(String(format: "%.1f", cacheStats.hitRate * 100))%")
        print("   - Average duration: \(String(format: "%.3f", averageDuration))s")
    }
    
    // MARK: - Stress Tests
    
    func testSystemStressTest() async throws {
        // Comprehensive stress test combining multiple load types
        let concurrentUsers = 15
        let operationsPerUser = 5
        let batchSize = 20
        
        let startTime = Date()
        var allResults: [ScoringResult] = []
        var allReports: [Report] = []
        
        await withTaskGroup(of: (results: [ScoringResult], reports: [Report]).self) { group in
            // Concurrent individual operations
            for userId in 0..<concurrentUsers {
                group.addTask { [weak self] in
                    guard let self = self else { return ([], []) }
                    
                    var userResults: [ScoringResult] = []
                    var userReports: [Report] = []
                    
                    for operationId in 0..<operationsPerUser {
                        do {
                            let company = self.createVariedCompanyData(userId: userId, operationId: operationId)
                            let config = self.createRandomScoringConfig()
                            
                            let result = try await self.scoringEngine.evaluateCompany(company, config: config)
                            userResults.append(result)
                            
                            let report = try await self.reportGenerator.generateDetailedReport(result)
                            userReports.append(report)
                        } catch {
                            print("Stress test operation failed: \(error)")
                        }
                    }
                    
                    return (userResults, userReports)
                }
            }
            
            // Batch operations
            group.addTask { [weak self] in
                guard let self = self else { return ([], []) }
                
                do {
                    let companies = (0..<batchSize).map { 
                        self.createVariedCompanyData(userId: 999, operationId: $0) 
                    }
                    let config = self.createStandardScoringConfig()
                    
                    let batchResults = try await self.scoringEngine.evaluateCompanies(companies, config: config)
                    return (batchResults, [])
                } catch {
                    print("Batch operation failed: \(error)")
                    return ([], [])
                }
            }
            
            // Collect all results
            for await (results, reports) in group {
                allResults.append(contentsOf: results)
                allReports.append(contentsOf: reports)
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let totalOperations = (concurrentUsers * operationsPerUser) + batchSize
        let successfulOperations = allResults.count
        let successRate = Double(successfulOperations) / Double(totalOperations)
        
        // Stress test assertions
        XCTAssertGreaterThan(successRate, 0.90, "Success rate should be > 90% under stress")
        XCTAssertLessThan(totalDuration, 120.0, "Stress test should complete within 2 minutes")
        XCTAssertGreaterThan(allResults.count, totalOperations / 2, "Should complete majority of operations")
        
        // Verify system stability
        let averageScore = allResults.map { $0.overallScore }.reduce(0, +) / Double(allResults.count)
        let averageConfidence = allResults.map { $0.confidence.overall }.reduce(0, +) / Double(allResults.count)
        
        XCTAssertGreaterThan(averageScore, 1.0, "Average score should remain reasonable under stress")
        XCTAssertLessThan(averageScore, 5.0, "Average score should remain within bounds under stress")
        XCTAssertGreaterThan(averageConfidence, 0.4, "Confidence should remain reasonable under stress")
        
        print("✅ System stress test completed")
        print("   - Total operations requested: \(totalOperations)")
        print("   - Successful operations: \(successfulOperations)")
        print("   - Success rate: \(String(format: "%.1f", successRate * 100))%")
        print("   - Total duration: \(String(format: "%.1f", totalDuration))s")
        print("   - Reports generated: \(allReports.count)")
        print("   - Average score: \(String(format: "%.2f", averageScore))")
        print("   - Average confidence: \(String(format: "%.1f", averageConfidence * 100))%")
    }
    
    // MARK: - Helper Methods
    
    private func createVariedCompanyData(userId: Int, operationId: Int) -> CompanyData {
        let stages: [DevelopmentStage] = [.preclinical, .phase1, .phase2, .phase3]
        let therapeuticAreas = [["Oncology"], ["Immunology"], ["Neurology"], ["Cardiology"]]
        let sectors = ["Biotechnology", "Pharmaceuticals", "Medical Devices"]
        
        let stage = stages[userId % stages.count]
        let areas = therapeuticAreas[userId % therapeuticAreas.count]
        let sector = sectors[userId % sectors.count]
        
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Load Test Company \(userId)-\(operationId)",
                ticker: "LTC\(userId)",
                sector: sector,
                therapeuticAreas: areas,
                stage: stage
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "Program \(operationId)",
                        indication: areas.first ?? "General",
                        stage: stage,
                        mechanism: "Test Mechanism",
                        differentiators: ["Load test differentiator"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 1 + (userId % 3)
            ),
            financials: CompanyFinancials(
                cashPosition: Double(25000000 + (userId * 5000000)),
                burnRate: Double(2000000 + (userId * 500000)),
                lastFunding: FundingRound(
                    amount: Double(50000000 + (userId * 10000000)),
                    date: Date(),
                    type: "Series A"
                ),
                runway: 8 + (userId % 12)
            ),
            market: CompanyMarket(
                addressableMarket: Double(1000000000 + (userId * 500000000)),
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0.1 + (Double(userId % 10) * 0.02),
                    competitiveIntensity: "Medium"
                )
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: "Standard",
                    timeline: 24 + (userId % 24),
                    risks: []
                )
            )
        )
    }
    
    private func createRandomScoringConfig() -> ScoringConfig {
        let randomWeights = [
            WeightConfig(assetQuality: 0.3, marketOutlook: 0.25, capitalIntensity: 0.1, strategicFit: 0.15, financialReadiness: 0.15, regulatoryRisk: 0.05),
            WeightConfig(assetQuality: 0.2, marketOutlook: 0.2, capitalIntensity: 0.15, strategicFit: 0.15, financialReadiness: 0.2, regulatoryRisk: 0.1),
            WeightConfig(assetQuality: 0.25, marketOutlook: 0.15, capitalIntensity: 0.2, strategicFit: 0.1, financialReadiness: 0.25, regulatoryRisk: 0.05)
        ]
        
        let weights = randomWeights.randomElement() ?? WeightConfig()
        
        return ScoringConfig(
            weights: weights,
            customParameters: ["loadTest": "true"]
        )
    }
    
    private func createStandardScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(),
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