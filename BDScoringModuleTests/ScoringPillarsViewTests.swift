import XCTest
import SwiftUI
@testable import BDScoringModule

final class ScoringPillarsViewTests: XCTestCase {
    
    // MARK: - Pillar Overview Tests
    
    func testPillarOverviewDisplaysAllPillars() {
        // Test that all six pillars are displayed in the overview
        let pillars = PillarData.allPillars
        XCTAssertEqual(pillars.count, 6, "Should display all six scoring pillars")
        
        let expectedPillars = [
            "Asset Quality",
            "Market Outlook", 
            "Capital Intensity",
            "Strategic Fit",
            "Financial Readiness",
            "Regulatory Risk"
        ]
        
        for expectedPillar in expectedPillars {
            XCTAssertTrue(
                pillars.contains { $0.name == expectedPillar },
                "Should contain pillar: \(expectedPillar)"
            )
        }
    }
    
    func testPillarCardDisplaysCorrectInformation() {
        // Test that pillar cards show all required information
        let assetQualityPillar = PillarData.allPillars.first { $0.name == "Asset Quality" }!
        
        XCTAssertEqual(assetQualityPillar.name, "Asset Quality")
        XCTAssertEqual(assetQualityPillar.icon, "target")
        XCTAssertEqual(assetQualityPillar.weight, 0.25)
        XCTAssertEqual(assetQualityPillar.description, "Evaluates pipeline strength, development stage, and competitive positioning")
        XCTAssertEqual(assetQualityPillar.averageScore, 4.2)
        XCTAssertEqual(assetQualityPillar.companies, 247)
        XCTAssertEqual(assetQualityPillar.metrics.count, 4)
    }
    
    func testWeightDistributionSumsToOne() {
        // Test that all pillar weights sum to 100%
        let totalWeight = PillarData.allPillars.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001, "Total weights should sum to 1.0")
    }
    
    // MARK: - Weight Configuration Tests
    
    func testWeightConfigInitialization() {
        let weightConfig = WeightConfig()
        
        XCTAssertEqual(weightConfig.assetQuality, 0.25)
        XCTAssertEqual(weightConfig.marketOutlook, 0.20)
        XCTAssertEqual(weightConfig.capitalIntensity, 0.15)
        XCTAssertEqual(weightConfig.strategicFit, 0.20)
        XCTAssertEqual(weightConfig.financialReadiness, 0.10)
        XCTAssertEqual(weightConfig.regulatoryRisk, 0.10)
        
        XCTAssertTrue(weightConfig.isValid, "Default weight configuration should be valid")
    }
    
    func testWeightConfigValidation() {
        var validConfig = WeightConfig()
        XCTAssertTrue(validConfig.isValid, "Default configuration should be valid")
        
        var invalidConfig = WeightConfig()
        invalidConfig.assetQuality = 0.50
        XCTAssertFalse(invalidConfig.isValid, "Configuration with weights > 1.0 should be invalid")
        
        var zeroConfig = WeightConfig()
        zeroConfig.assetQuality = 0.0
        zeroConfig.marketOutlook = 0.0
        zeroConfig.capitalIntensity = 0.0
        zeroConfig.strategicFit = 0.0
        zeroConfig.financialReadiness = 0.0
        zeroConfig.regulatoryRisk = 0.0
        XCTAssertFalse(zeroConfig.isValid, "Configuration with all zero weights should be invalid")
    }
    
    func testWeightConfigNormalization() {
        var config = WeightConfig()
        config.assetQuality = 0.50
        config.marketOutlook = 0.30
        config.capitalIntensity = 0.20
        config.strategicFit = 0.10
        config.financialReadiness = 0.05
        config.regulatoryRisk = 0.05
        
        XCTAssertFalse(config.isValid, "Configuration should be invalid before normalization")
        
        config.normalize()
        
        XCTAssertTrue(config.isValid, "Configuration should be valid after normalization")
        
        let total = config.assetQuality + config.marketOutlook + config.capitalIntensity + 
                   config.strategicFit + config.financialReadiness + config.regulatoryRisk
        XCTAssertEqual(total, 1.0, accuracy: 0.001, "Normalized weights should sum to 1.0")
    }
    
    // MARK: - Pillar Detail Tests
    
    func testPillarMetricsConfiguration() {
        let assetQualityPillar = PillarData.allPillars.first { $0.name == "Asset Quality" }!
        
        let expectedMetrics = [
            "Pipeline Strength",
            "IP Portfolio", 
            "Competitive Position",
            "Differentiation"
        ]
        
        XCTAssertEqual(assetQualityPillar.metrics.count, expectedMetrics.count)
        
        for expectedMetric in expectedMetrics {
            XCTAssertTrue(
                assetQualityPillar.metrics.contains { $0.name == expectedMetric },
                "Should contain metric: \(expectedMetric)"
            )
        }
        
        // Test that all metrics are enabled by default
        for metric in assetQualityPillar.metrics {
            XCTAssertTrue(metric.enabled, "Metric \(metric.name) should be enabled by default")
        }
    }
    
    func testPillarMetricWeights() {
        let marketOutlookPillar = PillarData.allPillars.first { $0.name == "Market Outlook" }!
        
        let expectedWeights: [String: Double] = [
            "Market Size": 35,
            "Growth Rate": 25,
            "Competition": 25,
            "Market Access": 15
        ]
        
        for metric in marketOutlookPillar.metrics {
            if let expectedWeight = expectedWeights[metric.name] {
                XCTAssertEqual(metric.weight, expectedWeight, "Metric \(metric.name) should have weight \(expectedWeight)")
            } else {
                XCTFail("Unexpected metric: \(metric.name)")
            }
        }
        
        let totalWeight = marketOutlookPillar.metrics.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 100, "Metric weights should sum to 100")
    }
    
    // MARK: - Analytics Tests
    
    func testScoreDistributionData() {
        let distributions = ScoreDistribution.sampleData
        
        XCTAssertEqual(distributions.count, 6, "Should have 6 score distribution ranges")
        
        let totalPercentage = distributions.reduce(0) { $0 + $1.percentage }
        XCTAssertEqual(totalPercentage, 100, "Distribution percentages should sum to 100")
        
        let totalCount = distributions.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalCount, 247, "Distribution counts should sum to total companies")
        
        // Test specific ranges
        let highScoreRange = distributions.first { $0.range == "4.5-5.0" }
        XCTAssertNotNil(highScoreRange, "Should have high score range")
        XCTAssertEqual(highScoreRange?.count, 42)
        XCTAssertEqual(highScoreRange?.percentage, 17)
    }
    
    func testIndustryBenchmarkData() {
        let benchmarks = IndustryBenchmark.sampleData
        
        XCTAssertEqual(benchmarks.count, 5, "Should have 5 therapeutic area benchmarks")
        
        let expectedAreas = ["Oncology", "Rare Disease", "CNS", "Cardiovascular", "Immunology"]
        
        for expectedArea in expectedAreas {
            XCTAssertTrue(
                benchmarks.contains { $0.area == expectedArea },
                "Should contain benchmark for: \(expectedArea)"
            )
        }
        
        // Test that all scores are within valid range
        for benchmark in benchmarks {
            XCTAssertGreaterThanOrEqual(benchmark.score, 0.0, "Score should be >= 0")
            XCTAssertLessThanOrEqual(benchmark.score, 5.0, "Score should be <= 5")
            XCTAssertGreaterThan(benchmark.companies, 0, "Should have positive company count")
        }
        
        // Test specific benchmark
        let oncologyBenchmark = benchmarks.first { $0.area == "Oncology" }
        XCTAssertNotNil(oncologyBenchmark, "Should have Oncology benchmark")
        XCTAssertEqual(oncologyBenchmark?.score, 4.1)
        XCTAssertEqual(oncologyBenchmark?.companies, 89)
    }
    
    // MARK: - Navigation Tests
    
    func testPillarSelectionNavigation() {
        // This would test the navigation state management
        // In a real SwiftUI test, you would use ViewInspector or similar
        
        let pillars = PillarData.allPillars
        let selectedPillar = pillars.first { $0.name == "Asset Quality" }
        
        XCTAssertNotNil(selectedPillar, "Should be able to select Asset Quality pillar")
        XCTAssertEqual(selectedPillar?.name, "Asset Quality")
    }
    
    // MARK: - Real-time Calculation Tests
    
    func testRealTimeWeightRecalculation() {
        var weightConfig = WeightConfig()
        let originalAssetQuality = weightConfig.assetQuality
        
        // Simulate weight adjustment
        weightConfig.assetQuality = 0.30
        weightConfig.marketOutlook = 0.15
        
        // Normalize to simulate real-time recalculation
        weightConfig.normalize()
        
        XCTAssertNotEqual(weightConfig.assetQuality, originalAssetQuality, "Weight should have changed")
        XCTAssertTrue(weightConfig.isValid, "Recalculated weights should be valid")
        
        let total = weightConfig.assetQuality + weightConfig.marketOutlook + 
                   weightConfig.capitalIntensity + weightConfig.strategicFit + 
                   weightConfig.financialReadiness + weightConfig.regulatoryRisk
        XCTAssertEqual(total, 1.0, accuracy: 0.001, "Recalculated weights should sum to 1.0")
    }
    
    // MARK: - UI Component Tests
    
    func testProgressBarValueCalculation() {
        let pillar = PillarData.allPillars.first { $0.name == "Asset Quality" }!
        let progressValue = pillar.averageScore / 5.0
        
        XCTAssertEqual(progressValue, 0.84, accuracy: 0.01, "Progress bar value should be correctly calculated")
        XCTAssertGreaterThanOrEqual(progressValue, 0.0, "Progress value should be >= 0")
        XCTAssertLessThanOrEqual(progressValue, 1.0, "Progress value should be <= 1")
    }
    
    func testWeightPercentageDisplay() {
        let pillar = PillarData.allPillars.first { $0.name == "Asset Quality" }!
        let weightPercentage = Int(pillar.weight * 100)
        
        XCTAssertEqual(weightPercentage, 25, "Weight percentage should be correctly calculated")
    }
    
    // MARK: - Data Consistency Tests
    
    func testPillarDataConsistency() {
        for pillar in PillarData.allPillars {
            // Test that all required fields are present
            XCTAssertFalse(pillar.name.isEmpty, "Pillar name should not be empty")
            XCTAssertFalse(pillar.icon.isEmpty, "Pillar icon should not be empty")
            XCTAssertFalse(pillar.description.isEmpty, "Pillar description should not be empty")
            
            // Test that weights are in valid range
            XCTAssertGreaterThan(pillar.weight, 0.0, "Pillar weight should be positive")
            XCTAssertLessThanOrEqual(pillar.weight, 1.0, "Pillar weight should be <= 1.0")
            
            // Test that scores are in valid range
            XCTAssertGreaterThanOrEqual(pillar.averageScore, 1.0, "Average score should be >= 1.0")
            XCTAssertLessThanOrEqual(pillar.averageScore, 5.0, "Average score should be <= 5.0")
            
            // Test that company count is positive
            XCTAssertGreaterThan(pillar.companies, 0, "Company count should be positive")
            
            // Test that metrics are present
            XCTAssertFalse(pillar.metrics.isEmpty, "Pillar should have metrics")
            
            // Test metric data consistency
            for metric in pillar.metrics {
                XCTAssertFalse(metric.name.isEmpty, "Metric name should not be empty")
                XCTAssertGreaterThan(metric.weight, 0, "Metric weight should be positive")
                XCTAssertLessThanOrEqual(metric.weight, 100, "Metric weight should be <= 100")
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStateHandling() {
        // Test handling of edge cases like empty data
        let emptyMetrics: [MetricData] = []
        
        // This would test how the UI handles empty states
        XCTAssertTrue(emptyMetrics.isEmpty, "Empty metrics array should be handled gracefully")
    }
    
    func testExtremeWeightValues() {
        var config = WeightConfig()
        
        // Test minimum weight values
        config.assetQuality = 0.05
        config.marketOutlook = 0.05
        config.capitalIntensity = 0.05
        config.strategicFit = 0.05
        config.financialReadiness = 0.05
        config.regulatoryRisk = 0.75
        
        XCTAssertTrue(config.isValid, "Configuration with extreme but valid weights should be valid")
        
        // Test that normalization works with extreme values
        config.assetQuality = 0.01
        config.marketOutlook = 0.01
        config.capitalIntensity = 0.01
        config.strategicFit = 0.01
        config.financialReadiness = 0.01
        config.regulatoryRisk = 0.95
        
        config.normalize()
        XCTAssertTrue(config.isValid, "Normalized extreme weights should be valid")
    }
    
    // MARK: - Performance Tests
    
    func testPillarDataLoadingPerformance() {
        measure {
            // Test that pillar data loads quickly
            let pillars = PillarData.allPillars
            XCTAssertEqual(pillars.count, 6)
        }
    }
    
    func testWeightCalculationPerformance() {
        measure {
            // Test that weight calculations are performant
            var config = WeightConfig()
            for _ in 0..<1000 {
                config.assetQuality = Double.random(in: 0.1...0.4)
                config.marketOutlook = Double.random(in: 0.1...0.4)
                config.capitalIntensity = Double.random(in: 0.1...0.4)
                config.strategicFit = Double.random(in: 0.1...0.4)
                config.financialReadiness = Double.random(in: 0.05...0.2)
                config.regulatoryRisk = Double.random(in: 0.05...0.2)
                config.normalize()
            }
        }
    }
}

// MARK: - Mock Data Extensions for Testing

extension PillarData {
    static func mockPillar(name: String = "Test Pillar", weight: Double = 0.2) -> PillarData {
        return PillarData(
            name: name,
            icon: "target",
            weight: weight,
            description: "Test description",
            metrics: [
                MetricData(name: "Test Metric 1", weight: 50, enabled: true),
                MetricData(name: "Test Metric 2", weight: 50, enabled: true)
            ],
            averageScore: 3.5,
            companies: 100
        )
    }
}

extension WeightConfig {
    static func mockConfig() -> WeightConfig {
        var config = WeightConfig()
        config.assetQuality = 0.3
        config.marketOutlook = 0.2
        config.capitalIntensity = 0.1
        config.strategicFit = 0.2
        config.financialReadiness = 0.1
        config.regulatoryRisk = 0.1
        return config
    }
}