import XCTest
@testable import BDScoringModule

final class ScoringConfigValidationTests: XCTestCase {
    
    // MARK: - WeightConfig Tests
    
    func testValidWeightConfig() {
        let weights = WeightConfig.defaultConfiguration()
        let validation = weights.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertEqual(validation.completeness, 1.0)
    }
    
    func testWeightConfigNormalization() {
        var weights = WeightConfig(
            assetQuality: 0.3,
            marketOutlook: 0.3,
            capitalIntensity: 0.2,
            strategicFit: 0.2,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        let validation = weights.validateAndNormalize()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(weights.isValid)
        
        let total = weights.assetQuality + weights.marketOutlook + weights.capitalIntensity + 
                   weights.strategicFit + weights.financialReadiness + weights.regulatoryRisk
        XCTAssertEqual(total, 1.0, accuracy: 0.001)
    }
    
    func testNegativeWeight() {
        let weights = WeightConfig(
            assetQuality: -0.1,  // Invalid negative weight
            marketOutlook: 0.3,
            capitalIntensity: 0.2,
            strategicFit: 0.2,
            financialReadiness: 0.2,
            regulatoryRisk: 0.2
        )
        
        let validation = weights.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "assetQuality" })
        XCTAssertEqual(validation.errors.first { $0.field == "assetQuality" }?.severity, .error)
    }
    
    func testWeightExceedsOne() {
        let weights = WeightConfig(
            assetQuality: 1.5,  // Invalid weight > 1.0
            marketOutlook: 0.2,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        )
        
        let validation = weights.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "assetQuality" })
    }
    
    func testTotalWeightTooLow() {
        let weights = WeightConfig(
            assetQuality: 0.1,
            marketOutlook: 0.1,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.1,
            regulatoryRisk: 0.1
        ) // Total = 0.6, should be 1.0
        
        let validation = weights.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "totalWeight" })
    }
    
    func testTotalWeightTooHigh() {
        let weights = WeightConfig(
            assetQuality: 0.3,
            marketOutlook: 0.3,
            capitalIntensity: 0.3,
            strategicFit: 0.3,
            financialReadiness: 0.3,
            regulatoryRisk: 0.3
        ) // Total = 1.8, should be 1.0
        
        let validation = weights.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "totalWeight" })
    }
    
    func testZeroWeightWarning() {
        let weights = WeightConfig(
            assetQuality: 0.0,  // Zero weight should generate warning
            marketOutlook: 0.25,
            capitalIntensity: 0.25,
            strategicFit: 0.25,
            financialReadiness: 0.125,
            regulatoryRisk: 0.125
        )
        
        let validation = weights.validate()
        
        XCTAssertTrue(validation.isValid) // Should be valid but with warning
        XCTAssertTrue(validation.warnings.contains { $0.field == "assetQuality" })
    }
    
    func testHighWeightWarning() {
        let weights = WeightConfig(
            assetQuality: 0.6,  // > 50% should generate warning
            marketOutlook: 0.1,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        
        let validation = weights.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "weightBalance" })
    }
    
    func testWeightDisparityWarning() {
        let weights = WeightConfig(
            assetQuality: 0.5,   // Large disparity
            marketOutlook: 0.05, // vs small weights
            capitalIntensity: 0.05,
            strategicFit: 0.05,
            financialReadiness: 0.175,
            regulatoryRisk: 0.175
        )
        
        let validation = weights.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "weightBalance" })
    }
    
    func testPresetConfigurations() {
        let defaultConfig = WeightConfig.defaultConfiguration()
        let conservativeConfig = WeightConfig.conservativeConfiguration()
        let aggressiveConfig = WeightConfig.aggressiveConfiguration()
        
        XCTAssertTrue(defaultConfig.validate().isValid)
        XCTAssertTrue(conservativeConfig.validate().isValid)
        XCTAssertTrue(aggressiveConfig.validate().isValid)
        
        XCTAssertTrue(defaultConfig.isValid)
        XCTAssertTrue(conservativeConfig.isValid)
        XCTAssertTrue(aggressiveConfig.isValid)
    }
    
    // MARK: - ScoringParameters Tests
    
    func testValidScoringParameters() {
        let parameters = ScoringParameters.defaultParameters()
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertEqual(validation.completeness, 1.0)
    }
    
    func testInvalidRiskAdjustment() {
        let parameters = ScoringParameters(
            riskAdjustment: -0.5,  // Invalid negative
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "riskAdjustment" })
    }
    
    func testExtremeRiskAdjustment() {
        let parameters = ScoringParameters(
            riskAdjustment: 5.0,  // Too high
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "riskAdjustment" })
    }
    
    func testRiskAdjustmentWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 0.3,  // Outside typical range
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "riskAdjustment" })
    }
    
    func testInvalidTimeHorizon() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: -5,  // Invalid negative
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "timeHorizon" })
    }
    
    func testExtremeTimeHorizon() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 25,  // Too long
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "timeHorizon" })
    }
    
    func testShortTimeHorizonWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 2,  // Short for biotech
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "timeHorizon" })
    }
    
    func testLongTimeHorizonWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 15,  // Long for reliable prediction
            discountRate: 0.12,
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "timeHorizon" })
    }
    
    func testInvalidDiscountRate() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: -0.05,  // Invalid negative
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "discountRate" })
    }
    
    func testExtremeDiscountRate() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 1.5,  // > 100%
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "discountRate" })
    }
    
    func testDiscountRateWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 0.35,  // Outside typical biotech range
            confidenceThreshold: 0.7
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "discountRate" })
    }
    
    func testInvalidConfidenceThreshold() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 1.5  // > 1.0
        )
        
        let validation = parameters.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "confidenceThreshold" })
    }
    
    func testLowConfidenceThresholdWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.3  // Too low
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "confidenceThreshold" })
    }
    
    func testHighConfidenceThresholdWarning() {
        let parameters = ScoringParameters(
            riskAdjustment: 1.0,
            timeHorizon: 5,
            discountRate: 0.12,
            confidenceThreshold: 0.95  // Very high
        )
        
        let validation = parameters.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.warnings.contains { $0.field == "confidenceThreshold" })
    }
    
    func testPresetParameterConfigurations() {
        let defaultParams = ScoringParameters.defaultParameters()
        let conservativeParams = ScoringParameters.conservativeParameters()
        let aggressiveParams = ScoringParameters.aggressiveParameters()
        
        XCTAssertTrue(defaultParams.validate().isValid)
        XCTAssertTrue(conservativeParams.validate().isValid)
        XCTAssertTrue(aggressiveParams.validate().isValid)
    }
    
    // MARK: - ScoringConfig Tests
    
    func testValidScoringConfig() {
        let config = ScoringConfig.defaultConfiguration()
        let validation = config.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertGreaterThan(validation.completeness, 0.9)
    }
    
    func testMissingConfigName() {
        var config = ScoringConfig.defaultConfiguration()
        config.name = ""
        
        let validation = config.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "name" })
        XCTAssertEqual(validation.errors.first { $0.field == "name" }?.severity, .critical)
    }
    
    func testConfigWithInvalidWeights() {
        var config = ScoringConfig.defaultConfiguration()
        config.weights.assetQuality = -0.1  // Invalid weight
        
        let validation = config.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("weights.assetQuality") })
    }
    
    func testConfigWithInvalidParameters() {
        var config = ScoringConfig.defaultConfiguration()
        config.parameters.timeHorizon = -5  // Invalid parameter
        
        let validation = config.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("parameters.timeHorizon") })
    }
    
    func testPresetScoringConfigurations() {
        let defaultConfig = ScoringConfig.defaultConfiguration()
        let conservativeConfig = ScoringConfig.conservativeConfiguration()
        let aggressiveConfig = ScoringConfig.aggressiveConfiguration()
        
        XCTAssertTrue(defaultConfig.validate().isValid)
        XCTAssertTrue(conservativeConfig.validate().isValid)
        XCTAssertTrue(aggressiveConfig.validate().isValid)
        
        XCTAssertTrue(defaultConfig.isDefault)
        XCTAssertFalse(conservativeConfig.isDefault)
        XCTAssertFalse(aggressiveConfig.isDefault)
    }
    
    // MARK: - ScoringConfigurationManager Tests
    
    func testConfigurationManagerInitialization() {
        let manager = ScoringConfigurationManager()
        let configs = manager.getAllConfigurations()
        
        XCTAssertEqual(configs.count, 3) // Default, Conservative, Aggressive
        XCTAssertNotNil(manager.getDefaultConfiguration())
    }
    
    func testAddValidConfiguration() {
        let manager = ScoringConfigurationManager()
        let newConfig = ScoringConfig(
            name: "Custom Configuration",
            weights: WeightConfig.defaultConfiguration(),
            parameters: ScoringParameters.defaultParameters(),
            isDefault: false
        )
        
        let validation = manager.addConfiguration(newConfig)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(manager.getAllConfigurations().count, 4)
    }
    
    func testAddInvalidConfiguration() {
        let manager = ScoringConfigurationManager()
        var invalidConfig = ScoringConfig.defaultConfiguration()
        invalidConfig.name = "" // Invalid name
        
        let validation = manager.addConfiguration(invalidConfig)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(manager.getAllConfigurations().count, 3) // Should not be added
    }
    
    func testAddDuplicateConfigurationName() {
        let manager = ScoringConfigurationManager()
        let duplicateConfig = ScoringConfig(
            name: "Default Configuration", // Same name as existing
            weights: WeightConfig.defaultConfiguration(),
            parameters: ScoringParameters.defaultParameters(),
            isDefault: false
        )
        
        let validation = manager.addConfiguration(duplicateConfig)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "name" })
    }
    
    func testUpdateConfiguration() {
        let manager = ScoringConfigurationManager()
        guard var config = manager.getDefaultConfiguration() else {
            XCTFail("Default configuration not found")
            return
        }
        
        config.name = "Updated Default Configuration"
        let validation = manager.updateConfiguration(config)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(manager.getConfiguration(id: config.id)?.name, "Updated Default Configuration")
    }
    
    func testUpdateNonexistentConfiguration() {
        let manager = ScoringConfigurationManager()
        let nonexistentConfig = ScoringConfig(
            name: "Nonexistent",
            weights: WeightConfig.defaultConfiguration(),
            parameters: ScoringParameters.defaultParameters(),
            isDefault: false
        )
        
        let validation = manager.updateConfiguration(nonexistentConfig)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "id" })
    }
    
    func testRemoveConfiguration() {
        let manager = ScoringConfigurationManager()
        let customConfig = ScoringConfig(
            name: "To Be Removed",
            weights: WeightConfig.defaultConfiguration(),
            parameters: ScoringParameters.defaultParameters(),
            isDefault: false
        )
        
        _ = manager.addConfiguration(customConfig)
        let success = manager.removeConfiguration(id: customConfig.id)
        
        XCTAssertTrue(success)
        XCTAssertNil(manager.getConfiguration(id: customConfig.id))
    }
    
    func testCannotRemoveDefaultConfiguration() {
        let manager = ScoringConfigurationManager()
        guard let defaultConfig = manager.getDefaultConfiguration() else {
            XCTFail("Default configuration not found")
            return
        }
        
        let success = manager.removeConfiguration(id: defaultConfig.id)
        
        XCTAssertFalse(success)
        XCTAssertNotNil(manager.getDefaultConfiguration())
    }
    
    func testValidateAllConfigurations() {
        let manager = ScoringConfigurationManager()
        let results = manager.validateAllConfigurations()
        
        XCTAssertEqual(results.count, 3)
        
        for (_, validation) in results {
            XCTAssertTrue(validation.isValid)
        }
    }
}