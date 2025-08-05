import Foundation

// Test compilation for performance monitoring and optimization components
// This file verifies that all performance-related services compile correctly

func testPerformanceMonitoringCompilation() {
    // Test PerformanceMonitoringService
    let performanceMonitor = PerformanceMonitoringService.shared
    
    // Test operation tracking
    let operationId = performanceMonitor.startOperation("test_operation")
    performanceMonitor.endOperation(operationId, success: true)
    
    // Test performance metrics
    let (average, count) = performanceMonitor.getAveragePerformance(for: "test_operation")
    print("Average performance: \(average)s, Count: \(count)")
    
    // Test performance trends
    let trends = performanceMonitor.getPerformanceTrends(for: "test_operation")
    print("Performance trends: \(trends.count) data points")
    
    // Test performance report
    let report = performanceMonitor.generatePerformanceReport()
    print("Performance report generated: \(report.count) characters")
    
    // Test measurement operations
    let result = performanceMonitor.measureOperation("sync_test") {
        return "test_result"
    }
    print("Sync measurement result: \(result)")
}

func testCachingServiceCompilation() {
    // Test CachingService
    let cachingService = CachingService.shared
    
    // Test basic cache operations
    cachingService.set("test_key", value: "test_value")
    let cachedValue: String? = cachingService.get("test_key")
    print("Cached value: \(cachedValue ?? "nil")")
    
    // Test cache removal
    cachingService.remove("test_key")
    cachingService.clear()
    cachingService.clearAll()
    
    // Test cache statistics
    let stats = cachingService.cacheStats
    print("Cache stats: \(stats)")
    
    // Test cache extensions
    let testCompanyData = createTestCompanyData()
    cachingService.cacheCompanyData(testCompanyData, for: "test_company")
    let retrievedData = cachingService.getCachedCompanyData(for: "test_company")
    print("Company data cached and retrieved: \(retrievedData?.basicInfo.name ?? "nil")")
    
    // Test comparables caching
    let testComparables: [Comparable] = []
    cachingService.cacheComparables(testComparables, for: "test_criteria")
    let retrievedComparables = cachingService.getCachedComparables(for: "test_criteria")
    print("Comparables cached and retrieved: \(retrievedComparables?.count ?? 0)")
}

func testPerformanceIntegrationCompilation() {
    // Test BDScoringEngine with performance monitoring
    let scoringEngine = BDScoringEngine()
    let testCompanyData = createTestCompanyData()
    let testConfig = createTestScoringConfig()
    
    // This would be tested in async context
    print("BDScoringEngine initialized with performance monitoring")
    
    // Test ReportGenerator with performance monitoring
    let reportGenerator = ReportGenerator()
    print("ReportGenerator initialized with performance monitoring")
    
    // Test performance thresholds
    print("Scoring threshold: \(PerformanceThresholds.scoringOperation)s")
    print("Report generation threshold: \(PerformanceThresholds.reportGeneration)s")
    print("Batch processing threshold: \(PerformanceThresholds.batchProcessing)s")
    print("Comparable search threshold: \(PerformanceThresholds.comparableSearch)s")
    print("Database query threshold: \(PerformanceThresholds.databaseQuery)s")
}

func testPerformanceMetricsCompilation() {
    // Test PerformanceMetrics structure
    let metrics = PerformanceMetrics(
        operationType: "test_operation",
        duration: 1.5,
        memoryUsage: 1024 * 1024,
        success: true,
        additionalData: ["key": "value"]
    )
    
    print("Performance metrics created:")
    print("- Operation: \(metrics.operationType)")
    print("- Duration: \(metrics.duration)s")
    print("- Memory: \(metrics.memoryUsage) bytes")
    print("- Success: \(metrics.success)")
    print("- Timestamp: \(metrics.timestamp)")
    print("- Additional data: \(metrics.additionalData)")
}

func testCacheConfigurationCompilation() {
    // Test cache configurations
    let defaultConfig = CacheConfiguration.default
    let comparablesConfig = CacheConfiguration.comparables
    let companyDataConfig = CacheConfiguration.companyData
    let reportsConfig = CacheConfiguration.reports
    
    print("Cache configurations:")
    print("- Default: maxSize=\(defaultConfig.maxSize), TTL=\(defaultConfig.defaultTTL)s")
    print("- Comparables: maxSize=\(comparablesConfig.maxSize), TTL=\(comparablesConfig.defaultTTL)s")
    print("- Company Data: maxSize=\(companyDataConfig.maxSize), TTL=\(companyDataConfig.defaultTTL)s")
    print("- Reports: maxSize=\(reportsConfig.maxSize), TTL=\(reportsConfig.defaultTTL)s")
}

func testCacheStatsCompilation() {
    // Test CacheStats structure
    var stats = CacheStats()
    stats.hits = 10
    stats.misses = 5
    stats.sets = 15
    stats.expirations = 2
    
    print("Cache statistics:")
    print("- Hits: \(stats.hits)")
    print("- Misses: \(stats.misses)")
    print("- Sets: \(stats.sets)")
    print("- Expirations: \(stats.expirations)")
    print("- Hit Rate: \(String(format: "%.1f", stats.hitRate * 100))%")
    print("- Total Operations: \(stats.totalOperations)")
}

// Helper functions for testing
func createTestCompanyData() -> CompanyData {
    return CompanyData(
        basicInfo: CompanyBasicInfo(
            name: "Test Biotech Company",
            ticker: "TEST",
            sector: "Biotechnology",
            therapeuticAreas: ["Oncology"],
            stage: .phaseII
        ),
        pipeline: CompanyPipeline(
            programs: [
                Program(
                    name: "Test Program",
                    indication: "Cancer",
                    stage: .phaseII,
                    mechanism: "Monoclonal Antibody",
                    differentiators: ["Novel target"],
                    risks: [],
                    timeline: []
                )
            ],
            totalPrograms: 1
        ),
        financials: CompanyFinancials(
            cashPosition: 50000000,
            burnRate: 5000000,
            lastFunding: FundingRound(
                amount: 75000000,
                date: Date(),
                type: "Series B"
            ),
            runway: 10
        ),
        market: CompanyMarket(
            addressableMarket: 5000000000,
            competitors: [],
            marketDynamics: MarketDynamics(
                growthRate: 0.15,
                competitiveIntensity: "High"
            )
        ),
        regulatory: CompanyRegulatory(
            approvals: [],
            clinicalTrials: [],
            regulatoryStrategy: RegulatoryStrategy(
                pathway: "Standard",
                timeline: 36,
                risks: []
            )
        )
    )
}

func createTestScoringConfig() -> ScoringConfig {
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

// Main compilation test function
func runPerformanceCompilationTests() {
    print("=== Performance Monitoring Compilation Tests ===")
    
    testPerformanceMonitoringCompilation()
    testCachingServiceCompilation()
    testPerformanceIntegrationCompilation()
    testPerformanceMetricsCompilation()
    testCacheConfigurationCompilation()
    testCacheStatsCompilation()
    
    print("=== All Performance Compilation Tests Completed ===")
}