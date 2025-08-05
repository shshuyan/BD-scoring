import Foundation

// Test compilation of HistoricalDataService
func testHistoricalDataServiceCompilation() {
    print("Testing HistoricalDataService compilation...")
    
    // Test that we can create an instance
    let service = HistoricalDataService(databasePath: "test.db")
    
    // Test that we can create test data structures
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
    
    let scoringResult = ScoringResult(
        companyId: UUID(),
        overallScore: 3.5,
        pillarScores: pillarScores,
        weightedScores: weightedScores,
        confidence: confidence,
        recommendations: ["Test recommendation"],
        timestamp: Date(),
        investmentRecommendation: .buy,
        riskLevel: .medium
    )
    
    // Test method calls (these would fail at runtime without proper database, but should compile)
    let _ = service.saveHistoricalScore(scoringResult, companyName: "Test Company", configId: UUID().uuidString)
    let _ = service.getHistoricalScores(for: UUID())
    let _ = service.getHistoricalScores(from: Date(), to: Date())
    
    // Test configuration methods
    let weights = WeightConfig()
    let parameters = ScoringParameters()
    let config = ScoringConfig(name: "Test Config", weights: weights, parameters: parameters)
    let _ = service.saveScoringConfiguration(config)
    let _ = service.getScoringConfigurations()
    
    // Test outcome methods
    let outcome = ActualOutcome(eventType: .acquisition, date: Date(), valuation: 500.0, details: "Test")
    let _ = service.saveActualOutcome(outcome, for: "test-id", companyId: UUID())
    let _ = service.getActualOutcomes(for: UUID())
    let _ = service.updatePredictionAccuracy(historicalScoreId: "test-id", accuracy: 0.85)
    
    // Test performance metrics
    let _ = service.savePerformanceMetric(name: "test_metric", value: 0.75, calculationDate: Date())
    let _ = service.getPerformanceMetrics(name: "test_metric")
    
    // Test data integrity
    let _ = service.validateDataIntegrity()
    let _ = service.cleanupOldData(retentionDays: 365)
    
    print("HistoricalDataService compilation test completed successfully!")
}

// Run the test
testHistoricalDataServiceCompilation()