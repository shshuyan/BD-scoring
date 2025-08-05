import XCTest
@testable import BDScoringModule

class HistoricalDataServiceTests: XCTestCase {
    var historicalDataService: HistoricalDataService!
    var testDatabasePath: String!
    
    override func setUp() {
        super.setUp()
        
        // Create a temporary database for testing
        let tempDirectory = NSTemporaryDirectory()
        testDatabasePath = "\(tempDirectory)test_historical_scores_\(UUID().uuidString).db"
        historicalDataService = HistoricalDataService(databasePath: testDatabasePath)
    }
    
    override func tearDown() {
        historicalDataService = nil
        
        // Clean up test database
        if let path = testDatabasePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        super.tearDown()
    }
    
    // MARK: - Historical Score Storage Tests
    
    func testSaveHistoricalScore() {
        // Given
        let scoringResult = createTestScoringResult()
        let companyName = "Test Biotech Inc."
        let configId = UUID().uuidString
        
        // When
        let success = historicalDataService.saveHistoricalScore(scoringResult, companyName: companyName, configId: configId)
        
        // Then
        XCTAssertTrue(success, "Should successfully save historical score")
        
        // Verify the score was saved
        let retrievedScores = historicalDataService.getHistoricalScores(for: scoringResult.companyId)
        XCTAssertEqual(retrievedScores.count, 1, "Should retrieve one historical score")
        
        let retrievedScore = retrievedScores.first!
        XCTAssertEqual(retrievedScore.companyName, companyName)
        XCTAssertEqual(retrievedScore.overallScore, scoringResult.overallScore, accuracy: 0.001)
        XCTAssertEqual(retrievedScore.investmentRecommendation, scoringResult.investmentRecommendation.rawValue)
        XCTAssertEqual(retrievedScore.riskLevel, scoringResult.riskLevel.rawValue)
    }
    
    func testGetHistoricalScoresForCompany() {
        // Given
        let companyId = UUID()
        let scoringResult1 = createTestScoringResult(companyId: companyId, overallScore: 3.5)
        let scoringResult2 = createTestScoringResult(companyId: companyId, overallScore: 4.0)
        let scoringResult3 = createTestScoringResult() // Different company
        
        // Save multiple scores
        _ = historicalDataService.saveHistoricalScore(scoringResult1, companyName: "Company A", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult2, companyName: "Company A", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult3, companyName: "Company B", configId: UUID().uuidString)
        
        // When
        let retrievedScores = historicalDataService.getHistoricalScores(for: companyId)
        
        // Then
        XCTAssertEqual(retrievedScores.count, 2, "Should retrieve two scores for the specified company")
        
        // Verify scores are ordered by timestamp (most recent first)
        XCTAssertGreaterThanOrEqual(retrievedScores[0].timestamp, retrievedScores[1].timestamp)
    }
    
    func testGetHistoricalScoresWithDateRange() {
        // Given
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let scoringResult1 = createTestScoringResult(timestamp: twoDaysAgo)
        let scoringResult2 = createTestScoringResult(timestamp: yesterday)
        let scoringResult3 = createTestScoringResult(timestamp: now)
        
        // Save scores with different timestamps
        _ = historicalDataService.saveHistoricalScore(scoringResult1, companyName: "Company A", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult2, companyName: "Company B", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult3, companyName: "Company C", configId: UUID().uuidString)
        
        // When
        let retrievedScores = historicalDataService.getHistoricalScores(from: yesterday, to: now)
        
        // Then
        XCTAssertEqual(retrievedScores.count, 2, "Should retrieve scores within date range")
        
        // Verify all retrieved scores are within the date range
        for score in retrievedScores {
            XCTAssertGreaterThanOrEqual(score.timestamp, yesterday)
            XCTAssertLessThanOrEqual(score.timestamp, now)
        }
    }
    
    func testSaveHistoricalScoreWithLimit() {
        // Given
        let companyId = UUID()
        let limit = 5
        
        // Save more scores than the limit
        for i in 1...10 {
            let scoringResult = createTestScoringResult(companyId: companyId, overallScore: Double(i))
            _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        }
        
        // When
        let retrievedScores = historicalDataService.getHistoricalScores(for: companyId, limit: limit)
        
        // Then
        XCTAssertEqual(retrievedScores.count, limit, "Should respect the limit parameter")
    }
    
    // MARK: - Scoring Configuration Tests
    
    func testSaveScoringConfiguration() {
        // Given
        let config = createTestScoringConfig()
        
        // When
        let success = historicalDataService.saveScoringConfiguration(config)
        
        // Then
        XCTAssertTrue(success, "Should successfully save scoring configuration")
        
        // Verify the configuration was saved
        let retrievedConfigs = historicalDataService.getScoringConfigurations()
        XCTAssertEqual(retrievedConfigs.count, 1, "Should retrieve one configuration")
        
        let retrievedConfig = retrievedConfigs.first!
        XCTAssertEqual(retrievedConfig.name, config.name)
        XCTAssertEqual(retrievedConfig.weights.assetQuality, config.weights.assetQuality, accuracy: 0.001)
        XCTAssertEqual(retrievedConfig.isDefault, config.isDefault)
    }
    
    func testGetScoringConfigurations() {
        // Given
        let config1 = createTestScoringConfig(name: "Config A", isDefault: true)
        let config2 = createTestScoringConfig(name: "Config B", isDefault: false)
        let config3 = createTestScoringConfig(name: "Config C", isDefault: false)
        
        // Save configurations
        _ = historicalDataService.saveScoringConfiguration(config1)
        _ = historicalDataService.saveScoringConfiguration(config2)
        _ = historicalDataService.saveScoringConfiguration(config3)
        
        // When
        let retrievedConfigs = historicalDataService.getScoringConfigurations()
        
        // Then
        XCTAssertEqual(retrievedConfigs.count, 3, "Should retrieve all configurations")
        
        // Verify default configuration comes first
        XCTAssertTrue(retrievedConfigs.first!.isDefault, "Default configuration should be first")
    }
    
    func testUpdateScoringConfiguration() {
        // Given
        var config = createTestScoringConfig()
        _ = historicalDataService.saveScoringConfiguration(config)
        
        // Modify the configuration
        config.name = "Updated Config"
        config.weights.assetQuality = 0.30
        
        // When
        let success = historicalDataService.saveScoringConfiguration(config)
        
        // Then
        XCTAssertTrue(success, "Should successfully update configuration")
        
        let retrievedConfigs = historicalDataService.getScoringConfigurations()
        XCTAssertEqual(retrievedConfigs.count, 1, "Should still have one configuration")
        
        let retrievedConfig = retrievedConfigs.first!
        XCTAssertEqual(retrievedConfig.name, "Updated Config")
        XCTAssertEqual(retrievedConfig.weights.assetQuality, 0.30, accuracy: 0.001)
    }
    
    // MARK: - Actual Outcomes Tests
    
    func testSaveActualOutcome() {
        // Given
        let scoringResult = createTestScoringResult()
        let companyName = "Test Company"
        let configId = UUID().uuidString
        
        // Save historical score first
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: companyName, configId: configId)
        let historicalScores = historicalDataService.getHistoricalScores(for: scoringResult.companyId)
        let historicalScoreId = historicalScores.first!.id
        
        let outcome = ActualOutcome(
            eventType: .acquisition,
            date: Date(),
            valuation: 500.0,
            details: "Acquired by Big Pharma"
        )
        
        // When
        let success = historicalDataService.saveActualOutcome(outcome, for: historicalScoreId, companyId: scoringResult.companyId)
        
        // Then
        XCTAssertTrue(success, "Should successfully save actual outcome")
        
        // Verify the outcome was saved
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: scoringResult.companyId)
        XCTAssertEqual(retrievedOutcomes.count, 1, "Should retrieve one actual outcome")
        
        let retrievedOutcome = retrievedOutcomes.first!
        XCTAssertEqual(retrievedOutcome.eventType, outcome.eventType.rawValue)
        XCTAssertEqual(retrievedOutcome.valuation, outcome.valuation)
        XCTAssertEqual(retrievedOutcome.details, outcome.details)
    }
    
    func testUpdatePredictionAccuracy() {
        // Given
        let scoringResult = createTestScoringResult()
        let companyName = "Test Company"
        let configId = UUID().uuidString
        
        // Save historical score and outcome
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: companyName, configId: configId)
        let historicalScores = historicalDataService.getHistoricalScores(for: scoringResult.companyId)
        let historicalScoreId = historicalScores.first!.id
        
        let outcome = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 500.0, details: nil)
        _ = historicalDataService.saveActualOutcome(outcome, for: historicalScoreId, companyId: scoringResult.companyId)
        
        let accuracy = 0.85
        
        // When
        let success = historicalDataService.updatePredictionAccuracy(historicalScoreId: historicalScoreId, accuracy: accuracy)
        
        // Then
        XCTAssertTrue(success, "Should successfully update prediction accuracy")
        
        // Verify the accuracy was updated
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: scoringResult.companyId)
        XCTAssertEqual(retrievedOutcomes.first!.predictionAccuracy, accuracy, accuracy: 0.001)
    }
    
    func testGetActualOutcomes() {
        // Given
        let companyId = UUID()
        let scoringResult1 = createTestScoringResult(companyId: companyId)
        let scoringResult2 = createTestScoringResult(companyId: companyId)
        
        // Save historical scores
        _ = historicalDataService.saveHistoricalScore(scoringResult1, companyName: "Company A", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult2, companyName: "Company A", configId: UUID().uuidString)
        
        let historicalScores = historicalDataService.getHistoricalScores(for: companyId)
        
        // Save outcomes for both scores
        let outcome1 = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 400.0, details: "First acquisition")
        let outcome2 = ActualOutcome(eventType: .ipo, date: Date(), valuation: 600.0, details: "IPO event")
        
        _ = historicalDataService.saveActualOutcome(outcome1, for: historicalScores[0].id, companyId: companyId)
        _ = historicalDataService.saveActualOutcome(outcome2, for: historicalScores[1].id, companyId: companyId)
        
        // When
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        
        // Then
        XCTAssertEqual(retrievedOutcomes.count, 2, "Should retrieve both outcomes")
        
        // Verify outcomes are ordered by event date (most recent first)
        XCTAssertGreaterThanOrEqual(retrievedOutcomes[0].eventDate, retrievedOutcomes[1].eventDate)
    }
    
    // MARK: - Performance Metrics Tests
    
    func testSavePerformanceMetric() {
        // Given
        let metricName = "prediction_accuracy"
        let metricValue = 0.78
        let calculationDate = Date()
        let details = "Monthly accuracy calculation"
        
        // When
        let success = historicalDataService.savePerformanceMetric(
            name: metricName,
            value: metricValue,
            calculationDate: calculationDate,
            details: details
        )
        
        // Then
        XCTAssertTrue(success, "Should successfully save performance metric")
        
        // Verify the metric was saved
        let retrievedMetrics = historicalDataService.getPerformanceMetrics(name: metricName)
        XCTAssertEqual(retrievedMetrics.count, 1, "Should retrieve one performance metric")
        
        let retrievedMetric = retrievedMetrics.first!
        XCTAssertEqual(retrievedMetric.metricName, metricName)
        XCTAssertEqual(retrievedMetric.metricValue, metricValue, accuracy: 0.001)
        XCTAssertEqual(retrievedMetric.details, details)
    }
    
    func testGetPerformanceMetricsWithDateRange() {
        // Given
        let metricName = "accuracy_score"
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        // Save metrics with different dates
        _ = historicalDataService.savePerformanceMetric(name: metricName, value: 0.70, calculationDate: twoDaysAgo)
        _ = historicalDataService.savePerformanceMetric(name: metricName, value: 0.75, calculationDate: yesterday)
        _ = historicalDataService.savePerformanceMetric(name: metricName, value: 0.80, calculationDate: now)
        
        // When
        let retrievedMetrics = historicalDataService.getPerformanceMetrics(name: metricName, from: yesterday, to: now)
        
        // Then
        XCTAssertEqual(retrievedMetrics.count, 2, "Should retrieve metrics within date range")
        
        // Verify all retrieved metrics are within the date range
        for metric in retrievedMetrics {
            XCTAssertGreaterThanOrEqual(metric.calculationDate, yesterday)
            XCTAssertLessThanOrEqual(metric.calculationDate, now)
        }
    }
    
    func testSavePerformanceMetricWithPeriod() {
        // Given
        let metricName = "quarterly_accuracy"
        let metricValue = 0.82
        let calculationDate = Date()
        let periodStart = Calendar.current.date(byAdding: .month, value: -3, to: calculationDate)!
        let periodEnd = calculationDate
        
        // When
        let success = historicalDataService.savePerformanceMetric(
            name: metricName,
            value: metricValue,
            calculationDate: calculationDate,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        
        // Then
        XCTAssertTrue(success, "Should successfully save performance metric with period")
        
        let retrievedMetrics = historicalDataService.getPerformanceMetrics(name: metricName)
        let retrievedMetric = retrievedMetrics.first!
        
        XCTAssertNotNil(retrievedMetric.periodStart)
        XCTAssertNotNil(retrievedMetric.periodEnd)
        XCTAssertEqual(retrievedMetric.periodStart!.timeIntervalSince1970, periodStart.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(retrievedMetric.periodEnd!.timeIntervalSince1970, periodEnd.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testValidateDataIntegrity() {
        // Given - Create some test data with potential integrity issues
        let scoringResult = createTestScoringResult()
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: "non-existent-config")
        
        // When
        let report = historicalDataService.validateDataIntegrity()
        
        // Then
        XCTAssertEqual(report.missingConfigurations, 1, "Should detect missing configuration")
        XCTAssertTrue(report.hasIssues, "Should report data integrity issues")
    }
    
    func testCleanupOldData() {
        // Given
        let oldDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let recentDate = Date()
        
        let oldScoringResult = createTestScoringResult(timestamp: oldDate)
        let recentScoringResult = createTestScoringResult(timestamp: recentDate)
        
        _ = historicalDataService.saveHistoricalScore(oldScoringResult, companyName: "Old Company", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(recentScoringResult, companyName: "Recent Company", configId: UUID().uuidString)
        
        // When
        let success = historicalDataService.cleanupOldData(retentionDays: 365)
        
        // Then
        XCTAssertTrue(success, "Should successfully cleanup old data")
        
        // Verify old data was removed but recent data remains
        let oldScores = historicalDataService.getHistoricalScores(for: oldScoringResult.companyId)
        let recentScores = historicalDataService.getHistoricalScores(for: recentScoringResult.companyId)
        
        XCTAssertEqual(oldScores.count, 0, "Old scores should be removed")
        XCTAssertEqual(recentScores.count, 1, "Recent scores should remain")
    }
    
    // MARK: - Helper Methods
    
    private func createTestScoringResult(companyId: UUID = UUID(), overallScore: Double = 3.5, timestamp: Date = Date()) -> ScoringResult {
        let pillarScores = PillarScores(
            assetQuality: PillarScore(rawScore: 3.5, confidence: 0.8, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 4.0, confidence: 0.7, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 3.0, confidence: 0.9, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 3.8, confidence: 0.6, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 2.5, confidence: 0.8, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 3.2, confidence: 0.7, factors: [], warnings: [])
        )
        
        let weightedScores = WeightedScores(
            assetQuality: 0.875,
            marketOutlook: 0.8,
            capitalIntensity: 0.45,
            strategicFit: 0.76,
            financialReadiness: 0.25,
            regulatoryRisk: 0.32
        )
        
        let confidence = ConfidenceMetrics(
            overall: 0.75,
            dataCompleteness: 0.8,
            modelAccuracy: 0.7,
            comparableQuality: 0.75
        )
        
        return ScoringResult(
            companyId: companyId,
            overallScore: overallScore,
            pillarScores: pillarScores,
            weightedScores: weightedScores,
            confidence: confidence,
            recommendations: ["Consider for partnership", "Monitor regulatory progress"],
            timestamp: timestamp,
            investmentRecommendation: .buy,
            riskLevel: .medium
        )
    }
    
    private func createTestScoringConfig(name: String = "Test Config", isDefault: Bool = false) -> ScoringConfig {
        let weights = WeightConfig(
            assetQuality: 0.25,
            marketOutlook: 0.20,
            capitalIntensity: 0.15,
            strategicFit: 0.20,
            financialReadiness: 0.10,
            regulatoryRisk: 0.10
        )
        
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        return ScoringConfig(
            name: name,
            weights: weights,
            parameters: parameters,
            isDefault: isDefault
        )
    }
}