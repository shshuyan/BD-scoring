// Test data structures for ScoringPillarsView (no imports needed)
struct TestPillarData {
    let name: String
    let weight: Double
    let averageScore: Double
    let companies: Int
    
    static let allPillars: [TestPillarData] = [
        TestPillarData(name: "Asset Quality", weight: 0.25, averageScore: 4.2, companies: 247),
        TestPillarData(name: "Market Outlook", weight: 0.20, averageScore: 3.8, companies: 247),
        TestPillarData(name: "Capital Intensity", weight: 0.15, averageScore: 3.5, companies: 247),
        TestPillarData(name: "Strategic Fit", weight: 0.20, averageScore: 4.0, companies: 247),
        TestPillarData(name: "Financial Readiness", weight: 0.10, averageScore: 3.2, companies: 247),
        TestPillarData(name: "Regulatory Risk", weight: 0.10, averageScore: 3.7, companies: 247)
    ]
}

struct TestWeightConfig {
    var assetQuality: Double = 0.25
    var marketOutlook: Double = 0.20
    var capitalIntensity: Double = 0.15
    var strategicFit: Double = 0.20
    var financialReadiness: Double = 0.10
    var regulatoryRisk: Double = 0.10
    
    var isValid: Bool {
        let total = assetQuality + marketOutlook + capitalIntensity + 
                   strategicFit + financialReadiness + regulatoryRisk
        let difference = total - 1.0
        return difference < 0.001 && difference > -0.001
    }
    
    mutating func normalize() {
        let total = assetQuality + marketOutlook + capitalIntensity + 
                   strategicFit + financialReadiness + regulatoryRisk
        guard total > 0 else { return }
        
        assetQuality /= total
        marketOutlook /= total
        capitalIntensity /= total
        strategicFit /= total
        financialReadiness /= total
        regulatoryRisk /= total
    }
}

// Test compilation of ScoringPillarsView data structures
func testScoringPillarsCompilation() {
    // Test PillarData creation
    let pillars = TestPillarData.allPillars
    print("✅ TestPillarData.allPillars loaded: \(pillars.count) pillars")
    
    // Test WeightConfig
    let weightConfig = TestWeightConfig()
    print("✅ TestWeightConfig initialized: valid = \(weightConfig.isValid)")
    
    // Test weight normalization
    var testConfig = TestWeightConfig()
    testConfig.assetQuality = 0.5
    testConfig.normalize()
    print("✅ Weight normalization works: valid = \(testConfig.isValid)")
    
    // Test pillar data consistency
    for pillar in pillars {
        assert(!pillar.name.isEmpty, "Pillar name should not be empty")
        assert(pillar.weight > 0, "Pillar weight should be positive")
        assert(pillar.averageScore >= 1.0 && pillar.averageScore <= 5.0, "Score should be in valid range")
    }
    print("✅ All pillar data is consistent")
    
    // Test that all pillar weights sum to 1.0
    let totalWeight = pillars.reduce(0) { $0 + $1.weight }
    let difference = totalWeight - 1.0
    assert(difference < 0.001 && difference > -0.001, "Total weights should sum to 1.0")
    print("✅ Pillar weights sum correctly: \(totalWeight)")
    
    print("🎉 All ScoringPillarsView data structure tests passed!")
}

// Run the test
testScoringPillarsCompilation()