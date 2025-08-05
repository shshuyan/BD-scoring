import XCTest
@testable import BDScoringModule

class PerformanceTrackingServiceTests: XCTestCase {
    var performanceTrackingService: PerformanceTrackingService!
    var historicalDataService: HistoricalDataService!
    var testDatabasePath: String!
    
    override func setUp() {
        super.setUp()
        
        // Create a temporary database for testing
        let tempDirectory = NSTemporaryDirectory()
        testDatabasePath = "\(tempDirectory)test_performance_\(UUID().uuidString).db"
        historicalDataService = HistoricalDataService(databasePath: testDatabasePath)
        performanceTrackingService = PerformanceTrackingService(historicalDataService: historicalDataService)
    }
    
    override func tearDown() {
        performanceTrackingService = nil
        historicalDataService = nil
        
        // Clean up test database
        if let path = testDatabasePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        super.tearDown()
    }
    
    // MARK: - Outcome Recording Tests
    
    func testRecordActualOutcome() {
        // Given
        let companyId = UUID()
        let scoringResult = createTestScoringResult(companyId: companyId, recommendation: .buy)
        
        // Save historical score first
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        
        let outcome = ActualOutcome(
            eventType: .acquisition,
            date: Date(),
            valuation: 500.0,
            details: "Acquired by Big Pharma"
        )
        
        // When
        let success = performanceTrackingService.recordActualOutcome(
            companyId: companyId,
            outcome: outcome,
            originalPrediction: .buy
        )
        
        // Then
        XCTAssertTrue(success, "Should successfully record actual outcome")
        
        // Verify the outcome was saved with accuracy calculation
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        XCTAssertEqual(retrievedOutcomes.count, 1, "Should have one recorded outcome")
        
        let retrievedOutcome = retrievedOutcomes.first!
        XCTAssertEqual(retrievedOutcome.eventType, outcome.eventType.rawValue)
        XCTAssertNotNil(retrievedOutcome.predictionAccuracy, "Should have calculated prediction accuracy")
        XCTAssertGreaterThan(retrievedOutcome.predictionAccuracy!, 0.0, "Accuracy should be positive")
    }
    
    func testRecordActualOutcomeWithoutHistoricalScore() {
        // Given
        let companyId = UUID()
        let outcome = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 500.0, details: nil)
        
        // When
        let success = performanceTrackingService.recordActualOutcome(companyId: companyId, outcome: outcome)
        
        // Then
        XCTAssertFalse(success, "Should fail when no historical score exists")
    }
    
    func testRecordBatchOutcomes() {
        // Given
        let companyId1 = UUID()
        let companyId2 = UUID()
        let companyId3 = UUID() // This one won't have a historical score
        
        let scoringResult1 = createTestScoringResult(companyId: companyId1)
        let scoringResult2 = createTestScoringResult(companyId: companyId2)
        
        // Save historical scores for first two companies
        _ = historicalDataService.saveHistoricalScore(scoringResult1, companyName: "Company 1", configId: UUID().uuidString)
        _ = historicalDataService.saveHistoricalScore(scoringResult2, companyName: "Company 2", configId: UUID().uuidString)
        
        let outcomes = [
            (companyId: companyId1, outcome: ActualOutcome(eventType: .acquisition, date: Date(), valuation: 400.0, details: nil)),
            (companyId: companyId2, outcome: ActualOutcome(eventType: .ipo, date: Date(), valuation: 600.0, details: nil)),
            (companyId: companyId3, outcome: ActualOutcome(eventType: .partnership, date: Date(), valuation: 200.0, details: nil))
        ]
        
        // When
        let result = performanceTrackingService.recordBatchOutcomes(outcomes)
        
        // Then
        XCTAssertEqual(result.totalProcessed, 3, "Should process all three outcomes")
        XCTAssertEqual(result.successCount, 2, "Should succeed for two companies with historical scores")
        XCTAssertEqual(result.failureCount, 1, "Should fail for one company without historical score")
        XCTAssertEqual(result.successRate, 2.0/3.0, accuracy: 0.001, "Success rate should be 2/3")
        XCTAssertEqual(result.errors.count, 1, "Should have one error message")
    }
    
    // MARK: - Accuracy Calculation Tests
    
    func testPredictionAccuracyForCorrectRecommendation() {
        // Given
        let companyId = UUID()
        let scoringResult = createTestScoringResult(companyId: companyId, recommendation: .strongBuy, overallScore: 4.2)
        
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        
        let outcome = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 500.0, details: nil)
        
        // When
        let success = performanceTrackingService.recordActualOutcome(
            companyId: companyId,
            outcome: outcome,
            originalPrediction: .strongBuy
        )
        
        // Then
        XCTAssertTrue(success)
        
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        let accuracy = retrievedOutcomes.first!.predictionAccuracy!
        
        // Should have high accuracy for correct strong buy -> acquisition prediction
        XCTAssertGreaterThan(accuracy, 0.7, "Accuracy should be high for correct prediction")
    }
    
    func testPredictionAccuracyForIncorrectRecommendation() {
        // Given
        let companyId = UUID()
        let scoringResult = createTestScoringResult(companyId: companyId, recommendation: .sell, overallScore: 2.0)
        
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        
        let outcome = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 500.0, details: nil)
        
        // When
        let success = performanceTrackingService.recordActualOutcome(
            companyId: companyId,
            outcome: outcome,
            originalPrediction: .sell
        )
        
        // Then
        XCTAssertTrue(success)
        
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        let accuracy = retrievedOutcomes.first!.predictionAccuracy!
        
        // Should have lower accuracy for incorrect sell -> acquisition prediction
        XCTAssertLessThan(accuracy, 0.5, "Accuracy should be low for incorrect prediction")
    }
    
    func testTimingAccuracy() {
        // Given
        let companyId = UUID()
        let predictionDate = Date()
        let scoringResult = createTestScoringResult(companyId: companyId, timestamp: predictionDate)
        
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        
        // Outcome happens 15 days after prediction (within optimal window)
        let outcomeDate = Calendar.current.date(byAdding: .day, value: 15, to: predictionDate)!
        let outcome = ActualOutcome(eventType: .acquisition, date: outcomeDate, valuation: 500.0, details: nil)
        
        // When
        let success = performanceTrackingService.recordActualOutcome(companyId: companyId, outcome: outcome)
        
        // Then
        XCTAssertTrue(success)
        
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        let accuracy = retrievedOutcomes.first!.predictionAccuracy!
        
        // Should have good accuracy due to good timing
        XCTAssertGreaterThan(accuracy, 0.6, "Should have good accuracy for timely prediction")
    }
    
    // MARK: - Performance Report Tests
    
    func testGeneratePerformanceReport() {
        // Given
        setupTestDataForPerformanceReport()
        
        // When
        let report = performanceTrackingService.generatePerformanceReport(for: .monthly)
        
        // Then
        XCTAssertEqual(report.period, .monthly)
        XCTAssertNotNil(report.overallAccuracy)
        XCTAssertNotNil(report.recommendationAccuracy)
        XCTAssertNotNil(report.scoreCorrelation)
        XCTAssertNotNil(report.predictionCoverage)
        XCTAssertFalse(report.insights.isEmpty, "Should generate insights")
        
        // Verify performance grade is calculated
        let grade = report.performanceGrade
        XCTAssertTrue([PerformanceGrade.excellent, .good, .fair, .poor].contains(grade))
    }
    
    func testPerformanceGradeCalculation() {
        // Given - Create a report with known values
        let report = PerformanceReport(
            period: .monthly,
            startDate: Date(),
            endDate: Date(),
            overallAccuracy: 0.85,
            recommendationAccuracy: 0.80,
            scoreCorrelation: 0.75,
            predictionCoverage: 0.90,
            accuracyTrend: .improving,
            recommendationTrend: .stable,
            insights: [],
            generatedAt: Date()
        )
        
        // When
        let grade = report.performanceGrade
        
        // Then
        XCTAssertEqual(grade, .excellent, "Should be excellent with high scores")
    }
    
    // MARK: - Trend Analysis Tests
    
    func testAnalyzeTrends() {
        // Given
        setupTestMetricsForTrendAnalysis()
        
        // When
        let trendAnalysis = performanceTrackingService.analyzeTrends(
            for: "monthly_overall_accuracy",
            period: .monthly,
            lookbackMonths: 6
        )
        
        // Then
        XCTAssertEqual(trendAnalysis.metricName, "monthly_overall_accuracy")
        XCTAssertEqual(trendAnalysis.period, .monthly)
        XCTAssertGreaterThan(trendAnalysis.dataPoints, 0, "Should have data points")
        XCTAssertTrue([TrendDirection.improving, .stable, .declining].contains(trendAnalysis.trend))
    }
    
    func testTrendDirectionCalculation() {
        // Given - Create metrics with improving trend
        let metricName = "test_accuracy"
        let now = Date()
        
        // Save metrics with increasing values over time
        for i in 1...5 {
            let date = Calendar.current.date(byAdding: .month, value: -i, to: now)!
            let value = 0.5 + (Double(5-i) * 0.1) // Increasing from 0.5 to 0.9
            _ = historicalDataService.savePerformanceMetric(name: metricName, value: value, calculationDate: date)
        }
        
        // When
        let trendAnalysis = performanceTrackingService.analyzeTrends(for: metricName, lookbackMonths: 6)
        
        // Then
        XCTAssertEqual(trendAnalysis.trend, .improving, "Should detect improving trend")
        XCTAssertNotNil(trendAnalysis.latestValue, "Should have latest value")
        XCTAssertNotNil(trendAnalysis.totalChange, "Should calculate total change")
        XCTAssertNotNil(trendAnalysis.percentageChange, "Should calculate percentage change")
    }
    
    // MARK: - Benchmark Evaluation Tests
    
    func testEvaluateAgainstBenchmarks() {
        // Given
        let report = PerformanceReport(
            period: .monthly,
            startDate: Date(),
            endDate: Date(),
            overallAccuracy: 0.75, // Above target (0.7)
            recommendationAccuracy: 0.60, // Below target (0.65)
            scoreCorrelation: 0.85, // Excellent (above 0.8)
            predictionCoverage: 0.30, // Below minimum acceptable (0.4)
            accuracyTrend: .improving,
            recommendationTrend: .stable,
            insights: [],
            generatedAt: Date()
        )
        
        // When
        let evaluations = performanceTrackingService.evaluateAgainstBenchmarks(report: report)
        
        // Then
        XCTAssertEqual(evaluations.count, 4, "Should evaluate all four main metrics")
        
        // Check specific evaluations
        let overallAccuracyEval = evaluations.first { $0.benchmark.metricName == "overall_accuracy" }!
        XCTAssertEqual(overallAccuracyEval.result, .target, "Overall accuracy should meet target")
        XCTAssertTrue(overallAccuracyEval.isAboveTarget, "Should be above target")
        
        let coverageEval = evaluations.first { $0.benchmark.metricName == "prediction_coverage" }!
        XCTAssertEqual(coverageEval.result, .belowStandard, "Coverage should be below standard")
        XCTAssertFalse(coverageEval.isAboveTarget, "Should be below target")
    }
    
    func testGenerateImprovementRecommendations() {
        // Given
        let report = PerformanceReport(
            period: .monthly,
            startDate: Date(),
            endDate: Date(),
            overallAccuracy: 0.40, // Below acceptable
            recommendationAccuracy: 0.30, // Below acceptable
            scoreCorrelation: 0.85, // Excellent
            predictionCoverage: 0.50, // Acceptable
            accuracyTrend: .declining,
            recommendationTrend: .declining,
            insights: [],
            generatedAt: Date()
        )
        
        let evaluations = performanceTrackingService.evaluateAgainstBenchmarks(report: report)
        
        // When
        let recommendations = performanceTrackingService.generateImprovementRecommendations(evaluations: evaluations)
        
        // Then
        XCTAssertGreaterThan(recommendations.count, 0, "Should generate recommendations for poor performance")
        
        // Should prioritize high-impact improvements
        let highPriorityRecommendations = recommendations.filter { $0.priority == .high }
        XCTAssertGreaterThan(highPriorityRecommendations.count, 0, "Should have high priority recommendations")
        
        // Verify recommendations have required fields
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.description.isEmpty, "Should have description")
            XCTAssertFalse(recommendation.actions.isEmpty, "Should have actions")
            XCTAssertFalse(recommendation.timeframe.isEmpty, "Should have timeframe")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestScoringResult(
        companyId: UUID = UUID(),
        recommendation: InvestmentRecommendation = .buy,
        overallScore: Double = 3.5,
        timestamp: Date = Date()
    ) -> ScoringResult {
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
            recommendations: ["Test recommendation"],
            timestamp: timestamp,
            investmentRecommendation: recommendation,
            riskLevel: .medium
        )
    }
    
    private func setupTestDataForPerformanceReport() {
        // Create some test companies with outcomes
        for i in 1...5 {
            let companyId = UUID()
            let scoringResult = createTestScoringResult(companyId: companyId)
            
            _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Company \(i)", configId: UUID().uuidString)
            
            let outcome = ActualOutcome(
                eventType: i % 2 == 0 ? .acquisition : .ipo,
                date: Date(),
                valuation: Double(400 + i * 100),
                details: nil
            )
            
            _ = performanceTrackingService.recordActualOutcome(companyId: companyId, outcome: outcome)
        }
    }
    
    private func setupTestMetricsForTrendAnalysis() {
        let metricName = "monthly_overall_accuracy"
        let now = Date()
        
        // Create metrics for the last 6 months
        for i in 1...6 {
            let date = Calendar.current.date(byAdding: .month, value: -i, to: now)!
            let value = 0.6 + (Double(i) * 0.05) // Slightly increasing trend
            _ = historicalDataService.savePerformanceMetric(name: metricName, value: value, calculationDate: date)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testRecordOutcomeWithNilValuation() {
        // Given
        let companyId = UUID()
        let scoringResult = createTestScoringResult(companyId: companyId)
        
        _ = historicalDataService.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
        
        let outcome = ActualOutcome(eventType: .partnership, date: Date(), valuation: nil, details: "Strategic partnership")
        
        // When
        let success = performanceTrackingService.recordActualOutcome(companyId: companyId, outcome: outcome)
        
        // Then
        XCTAssertTrue(success, "Should handle nil valuation gracefully")
        
        let retrievedOutcomes = historicalDataService.getActualOutcomes(for: companyId)
        XCTAssertEqual(retrievedOutcomes.count, 1)
        XCTAssertNil(retrievedOutcomes.first!.valuation, "Valuation should be nil")
    }
    
    func testEmptyBatchOutcomes() {
        // Given
        let emptyOutcomes: [(companyId: UUID, outcome: ActualOutcome)] = []
        
        // When
        let result = performanceTrackingService.recordBatchOutcomes(emptyOutcomes)
        
        // Then
        XCTAssertEqual(result.totalProcessed, 0)
        XCTAssertEqual(result.successCount, 0)
        XCTAssertEqual(result.failureCount, 0)
        XCTAssertEqual(result.successRate, 0.0)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testTrendAnalysisWithNoData() {
        // Given - No metrics saved
        
        // When
        let trendAnalysis = performanceTrackingService.analyzeTrends(for: "nonexistent_metric")
        
        // Then
        XCTAssertEqual(trendAnalysis.dataPoints, 0)
        XCTAssertEqual(trendAnalysis.average, 0.0)
        XCTAssertEqual(trendAnalysis.volatility, 0.0)
        XCTAssertNil(trendAnalysis.latestValue)
        XCTAssertNil(trendAnalysis.totalChange)
        XCTAssertNil(trendAnalysis.percentageChange)
    }
}