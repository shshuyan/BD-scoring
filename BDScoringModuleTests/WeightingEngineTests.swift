import XCTest
@testable import BDScoringModule

class WeightingEngineTests: XCTestCase {
    
    var weightingEngine: BDWeightingEngine!
    var samplePillarScores: PillarScores!
    
    override func setUp() {
        super.setUp()
        weightingEngine = BDWeightingEngine()
        
        // Create sample pillar scores for testing
        samplePillarScores = PillarScores(
            assetQuality: PillarScore(rawScore: 4.0, confidence: 0.8, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 3.5, confidence: 0.7, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 2.5, confidence: 0.9, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 4.5, confidence: 0.85, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 3.0, confidence: 0.6, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 3.8, confidence: 0.75, factors: [], warnings: [])
        )
    }
    
    override func tearDown() {
        weightingEngine = nil
        samplePillarScores = nil
        super.tearDown()
    }
    
    // MARK: - Weight Application Tests
    
    func testApplyWeights_ValidWeights_ReturnsCorrectWeightedScores() {
        // Given
        let weights = WeightConfig(
            assetQuality: 0.3,
            marketOutlook: 0.2,
            capitalIntensity: 0.1,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        let weightedScores = weightingEngine.applyWeights(samplePillarScores, weights: weights)
        
        // Then
        XCTAssertEqual(weightedScores.assetQuality, 4.0 * 0.3, accuracy: 0.001)
        XCTAssertEqual(weightedScores.marketOutlook, 3.5 * 0.2, accuracy: 0.001)
        XCTAssertEqual(weightedScores.capitalIntensity, 2.5 * 0.1, accuracy: 0.001)
        XCTAssertEqual(weightedScores.strategicFit, 4.5 * 0.2, accuracy: 0.001)
        XCTAssertEqual(weightedScores.financialReadiness, 3.0 * 0.1, accuracy: 0.001)
        XCTAssertEqual(weightedScores.regulatoryRisk, 3.8 * 0.1, accuracy: 0.001)
        
        let expectedTotal = (4.0 * 0.3) + (3.5 * 0.2) + (2.5 * 0.1) + (4.5 * 0.2) + (3.0 * 0.1) + (3.8 * 0.1)
        XCTAssertEqual(weightedScores.total, expectedTotal, accuracy: 0.001)
    }
    
    func testApplyWeights_InvalidWeights_NormalizesAndApplies() {
        // Given - weights that don't sum to 1.0
        let weights = WeightConfig(
            assetQuality: 0.5,
            marketOutlook: 0.4,
            capitalIntensity: 0.3,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        let weightedScores = weightingEngine.applyWeights(samplePillarScores, weights: weights)
        
        // Then - should still produce valid weighted scores (normalized internally)
        XCTAssertGreaterThan(weightedScores.total, 0)
        XCTAssertLessThan(weightedScores.total, 10) // Reasonable upper bound
    }
    
    // MARK: - Weight Validation Tests
    
    func testValidateWeights_ValidWeights_ReturnsValid() {
        // Given
        let validWeights = WeightConfig() // Default weights sum to 1.0
        
        // When
        let result = weightingEngine.validateWeights(validWeights)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testValidateWeights_NegativeWeight_ReturnsError() {
        // Given
        let invalidWeights = WeightConfig(
            assetQuality: -0.1,
            marketOutlook: 0.3,
            capitalIntensity: 0.2,
            strategicFit: 0.2,
            financialReadiness: 0.2,
            regulatoryRisk: 0.2
        )
        
        // When
        let result = weightingEngine.validateWeights(invalidWeights)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.field == "assetQuality" && $0.message.contains("negative") })
    }
    
    func testValidateWeights_WeightExceedsOne_ReturnsError() {
        // Given
        let invalidWeights = WeightConfig(
            assetQuality: 1.5,
            marketOutlook: 0.1,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        let result = weightingEngine.validateWeights(invalidWeights)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.field == "assetQuality" && $0.message.contains("exceed") })
    }
    
    func testValidateWeights_WeightsSumIncorrect_ReturnsWarning() {
        // Given
        let weights = WeightConfig(
            assetQuality: 0.2,
            marketOutlook: 0.2,
            capitalIntensity: 0.2,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.05 // Sum = 0.95, not 1.0
        )
        
        // When
        let result = weightingEngine.validateWeights(weights)
        
        // Then
        XCTAssertTrue(result.isValid) // Should be valid but with warnings
        XCTAssertTrue(result.warnings.contains { $0.field == "total" })
    }
    
    func testValidateWeights_ZeroWeight_ReturnsWarning() {
        // Given
        let weights = WeightConfig(
            assetQuality: 0.0, // Zero weight
            marketOutlook: 0.25,
            capitalIntensity: 0.25,
            strategicFit: 0.25,
            financialReadiness: 0.125,
            regulatoryRisk: 0.125
        )
        
        // When
        let result = weightingEngine.validateWeights(weights)
        
        // Then
        XCTAssertTrue(result.warnings.contains { $0.field == "assetQuality" && $0.message.contains("Zero weight") })
    }
    
    func testValidateWeights_AllZeroWeights_ReturnsError() {
        // Given
        let allZeroWeights = WeightConfig(
            assetQuality: 0.0,
            marketOutlook: 0.0,
            capitalIntensity: 0.0,
            strategicFit: 0.0,
            financialReadiness: 0.0,
            regulatoryRisk: 0.0
        )
        
        // When
        let result = weightingEngine.validateWeights(allZeroWeights)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.severity == .critical })
    }
    
    // MARK: - Weight Normalization Tests
    
    func testNormalizeWeights_ValidWeights_NormalizesToOne() {
        // Given
        var weights = WeightConfig(
            assetQuality: 0.5,
            marketOutlook: 0.4,
            capitalIntensity: 0.3,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        weightingEngine.normalizeWeights(&weights)
        
        // Then
        let total = weights.assetQuality + weights.marketOutlook + weights.capitalIntensity + 
                   weights.strategicFit + weights.financialReadiness + weights.regulatoryRisk
        XCTAssertEqual(total, 1.0, accuracy: 0.001)
    }
    
    func testNormalizeWeights_AllZeroWeights_SetsEqualWeights() {
        // Given
        var weights = WeightConfig(
            assetQuality: 0.0,
            marketOutlook: 0.0,
            capitalIntensity: 0.0,
            strategicFit: 0.0,
            financialReadiness: 0.0,
            regulatoryRisk: 0.0
        )
        
        // When
        weightingEngine.normalizeWeights(&weights)
        
        // Then
        XCTAssertEqual(weights.assetQuality, 1.0/6.0, accuracy: 0.001)
        XCTAssertEqual(weights.marketOutlook, 1.0/6.0, accuracy: 0.001)
        XCTAssertEqual(weights.capitalIntensity, 1.0/6.0, accuracy: 0.001)
        XCTAssertEqual(weights.strategicFit, 1.0/6.0, accuracy: 0.001)
        XCTAssertEqual(weights.financialReadiness, 1.0/6.0, accuracy: 0.001)
        XCTAssertEqual(weights.regulatoryRisk, 1.0/6.0, accuracy: 0.001)
    }
    
    // MARK: - Weight Profile Management Tests
    
    func testSaveWeightProfile_ValidWeights_SavesSuccessfully() throws {
        // Given
        let profileName = "TestProfile"
        let weights = WeightConfig()
        
        // When
        try weightingEngine.saveWeightProfile(name: profileName, weights: weights)
        
        // Then
        let savedWeights = weightingEngine.loadWeightProfile(name: profileName)
        XCTAssertNotNil(savedWeights)
        XCTAssertEqual(savedWeights?.assetQuality, weights.assetQuality, accuracy: 0.001)
    }
    
    func testSaveWeightProfile_InvalidWeights_ThrowsError() {
        // Given
        let profileName = "InvalidProfile"
        let invalidWeights = WeightConfig(
            assetQuality: -1.0, // Invalid negative weight
            marketOutlook: 0.2,
            capitalIntensity: 0.2,
            strategicFit: 0.2,
            financialReadiness: 0.2,
            regulatoryRisk: 0.2
        )
        
        // When/Then
        XCTAssertThrowsError(try weightingEngine.saveWeightProfile(name: profileName, weights: invalidWeights)) { error in
            XCTAssertTrue(error is ScoringError)
        }
    }
    
    func testLoadWeightProfile_ExistingProfile_ReturnsWeights() throws {
        // Given
        let profileName = "TestProfile"
        let originalWeights = WeightConfig(
            assetQuality: 0.4,
            marketOutlook: 0.3,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        try weightingEngine.saveWeightProfile(name: profileName, weights: originalWeights)
        
        // When
        let loadedWeights = weightingEngine.loadWeightProfile(name: profileName)
        
        // Then
        XCTAssertNotNil(loadedWeights)
        // Note: weights should be normalized when saved
        let total = loadedWeights!.assetQuality + loadedWeights!.marketOutlook + 
                   loadedWeights!.capitalIntensity + loadedWeights!.strategicFit + 
                   loadedWeights!.financialReadiness + loadedWeights!.regulatoryRisk
        XCTAssertEqual(total, 1.0, accuracy: 0.001)
    }
    
    func testLoadWeightProfile_NonExistentProfile_ReturnsNil() {
        // When
        let loadedWeights = weightingEngine.loadWeightProfile(name: "NonExistentProfile")
        
        // Then
        XCTAssertNil(loadedWeights)
    }
    
    func testGetAvailableProfiles_DefaultProfiles_ReturnsExpectedProfiles() {
        // When
        let profiles = weightingEngine.getAvailableProfiles()
        
        // Then
        XCTAssertTrue(profiles.contains("Conservative"))
        XCTAssertTrue(profiles.contains("Aggressive"))
        XCTAssertTrue(profiles.contains("Balanced"))
        XCTAssertTrue(profiles.contains("Strategic"))
    }
    
    func testDeleteWeightProfile_ExistingProfile_ReturnsTrue() throws {
        // Given
        let profileName = "TestProfile"
        try weightingEngine.saveWeightProfile(name: profileName, weights: WeightConfig())
        
        // When
        let deleted = weightingEngine.deleteWeightProfile(name: profileName)
        
        // Then
        XCTAssertTrue(deleted)
        XCTAssertNil(weightingEngine.loadWeightProfile(name: profileName))
    }
    
    func testDeleteWeightProfile_NonExistentProfile_ReturnsFalse() {
        // When
        let deleted = weightingEngine.deleteWeightProfile(name: "NonExistentProfile")
        
        // Then
        XCTAssertFalse(deleted)
    }
    
    // MARK: - Real-time Recalculation Tests
    
    func testApplyWeightsWithRecalculation_ValidWeights_ReturnsScoresAndValidation() {
        // Given
        let weights = WeightConfig()
        
        // When
        let (weightedScores, validationResult) = weightingEngine.applyWeightsWithRecalculation(samplePillarScores, weights: weights)
        
        // Then
        XCTAssertGreaterThan(weightedScores.total, 0)
        XCTAssertTrue(validationResult.isValid)
    }
    
    func testApplyWeightsWithRecalculation_InvalidWeights_ReturnsScoresAndErrors() {
        // Given
        let invalidWeights = WeightConfig(
            assetQuality: -0.1,
            marketOutlook: 0.3,
            capitalIntensity: 0.3,
            strategicFit: 0.3,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        let (weightedScores, validationResult) = weightingEngine.applyWeightsWithRecalculation(samplePillarScores, weights: invalidWeights)
        
        // Then
        XCTAssertGreaterThan(weightedScores.total, 0) // Should still calculate scores
        XCTAssertFalse(validationResult.isValid)
        XCTAssertFalse(validationResult.errors.isEmpty)
    }
    
    // MARK: - Weight Impact Analysis Tests
    
    func testCalculateWeightImpact_DifferentWeights_ReturnsCorrectAnalysis() {
        // Given
        let originalWeights = WeightConfig() // Default weights
        let newWeights = WeightConfig(
            assetQuality: 0.5, // Increased from 0.25
            marketOutlook: 0.2,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        
        // When
        let impact = weightingEngine.calculateWeightImpact(
            pillarScores: samplePillarScores,
            originalWeights: originalWeights,
            newWeights: newWeights
        )
        
        // Then
        XCTAssertNotEqual(impact.totalScoreDifference, 0, accuracy: 0.001)
        XCTAssertNotEqual(impact.percentageChange, 0, accuracy: 0.001)
        XCTAssertFalse(impact.pillarImpacts.isEmpty)
        XCTAssertTrue(impact.significantChanges.keys.contains("assetQuality"))
    }
    
    func testCalculateWeightImpact_SameWeights_ReturnsZeroImpact() {
        // Given
        let weights = WeightConfig()
        
        // When
        let impact = weightingEngine.calculateWeightImpact(
            pillarScores: samplePillarScores,
            originalWeights: weights,
            newWeights: weights
        )
        
        // Then
        XCTAssertEqual(impact.totalScoreDifference, 0, accuracy: 0.001)
        XCTAssertEqual(impact.percentageChange, 0, accuracy: 0.001)
        XCTAssertTrue(impact.significantChanges.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testApplyWeights_ZeroPillarScores_HandlesGracefully() {
        // Given
        let zeroPillarScores = PillarScores(
            assetQuality: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 0.0, confidence: 0.0, factors: [], warnings: [])
        )
        let weights = WeightConfig()
        
        // When
        let weightedScores = weightingEngine.applyWeights(zeroPillarScores, weights: weights)
        
        // Then
        XCTAssertEqual(weightedScores.total, 0.0, accuracy: 0.001)
    }
    
    func testApplyWeights_MaximumPillarScores_HandlesGracefully() {
        // Given
        let maxPillarScores = PillarScores(
            assetQuality: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 5.0, confidence: 1.0, factors: [], warnings: [])
        )
        let weights = WeightConfig()
        
        // When
        let weightedScores = weightingEngine.applyWeights(maxPillarScores, weights: weights)
        
        // Then
        XCTAssertEqual(weightedScores.total, 5.0, accuracy: 0.001) // Should equal maximum score
    }
}

// MARK: - WeightConfig Extension Tests

class WeightConfigExtensionTests: XCTestCase {
    
    func testFromDictionary_ValidDictionary_CreatesWeightConfig() {
        // Given
        let dictionary: [String: Double] = [
            "assetQuality": 0.3,
            "marketOutlook": 0.2,
            "capitalIntensity": 0.1,
            "strategicFit": 0.2,
            "financialReadiness": 0.1,
            "regulatoryRisk": 0.1
        ]
        
        // When
        let weightConfig = WeightConfig.from(dictionary: dictionary)
        
        // Then
        XCTAssertNotNil(weightConfig)
        XCTAssertEqual(weightConfig?.assetQuality, 0.3)
        XCTAssertEqual(weightConfig?.marketOutlook, 0.2)
        XCTAssertEqual(weightConfig?.capitalIntensity, 0.1)
        XCTAssertEqual(weightConfig?.strategicFit, 0.2)
        XCTAssertEqual(weightConfig?.financialReadiness, 0.1)
        XCTAssertEqual(weightConfig?.regulatoryRisk, 0.1)
    }
    
    func testFromDictionary_MissingKeys_ReturnsNil() {
        // Given
        let incompleteDictionary: [String: Double] = [
            "assetQuality": 0.3,
            "marketOutlook": 0.2
            // Missing other keys
        ]
        
        // When
        let weightConfig = WeightConfig.from(dictionary: incompleteDictionary)
        
        // Then
        XCTAssertNil(weightConfig)
    }
    
    func testToDictionary_ValidWeightConfig_CreatesDictionary() {
        // Given
        let weightConfig = WeightConfig(
            assetQuality: 0.3,
            marketOutlook: 0.2,
            capitalIntensity: 0.1,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        // When
        let dictionary = weightConfig.toDictionary()
        
        // Then
        XCTAssertEqual(dictionary["assetQuality"], 0.3)
        XCTAssertEqual(dictionary["marketOutlook"], 0.2)
        XCTAssertEqual(dictionary["capitalIntensity"], 0.1)
        XCTAssertEqual(dictionary["strategicFit"], 0.2)
        XCTAssertEqual(dictionary["financialReadiness"], 0.1)
        XCTAssertEqual(dictionary["regulatoryRisk"], 0.1)
        XCTAssertEqual(dictionary.count, 6)
    }
}