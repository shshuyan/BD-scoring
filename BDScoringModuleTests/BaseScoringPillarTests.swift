import XCTest
@testable import BDScoringModule

// MARK: - Test Implementation of BaseScoringPillar

class TestScoringPillar: BaseScoringPillar {
    
    var shouldThrowError = false
    var mockScore: PillarScore?
    
    override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        if shouldThrowError {
            throw ScoringError.calculationError("Test error")
        }
        
        if let mockScore = mockScore {
            return mockScore
        }
        
        // Default test implementation
        let factors = [
            createScoringFactor(
                name: "Test Factor 1",
                weight: 0.6,
                score: 3.5,
                rationale: "Test rationale 1"
            ),
            createScoringFactor(
                name: "Test Factor 2",
                weight: 0.4,
                score: 4.0,
                rationale: "Test rationale 2"
            )
        ]
        
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let confidence = calculateConfidence(
            dataCompleteness: calculateDataCompleteness(data),
            dataQuality: 0.8,
            methodologyReliability: 0.9
        )
        
        return PillarScore(
            rawScore: normalizeScore(weightedScore),
            confidence: confidence,
            factors: factors,
            warnings: generateWarnings(
                score: weightedScore,
                confidence: confidence,
                dataCompleteness: calculateDataCompleteness(data)
            ),
            explanation: "Test pillar calculation"
        )
    }
    
    override func getMethodologyDescription() -> String {
        return "Test methodology for unit testing"
    }
    
    override func getKnownLimitations() -> [String] {
        return ["Test limitation 1", "Test limitation 2"]
    }
}

// MARK: - BaseScoringPillarTests

final class BaseScoringPillarTests: XCTestCase {
    
    var testPillar: TestScoringPillar!
    var sampleCompanyData: CompanyData!
    var sampleMarketContext: MarketContext!
    
    override func setUp() {
        super.setUp()
        
        let pillarInfo = PillarInfo(
            name: "Test Pillar",
            description: "Test pillar for unit testing",
            defaultWeight: 0.25,
            requiredFields: [
                "basicInfo.name",
                "basicInfo.sector",
                "pipeline.programs"
            ],
            optionalFields: [
                "financials.cashPosition",
                "market.addressableMarket"
            ]
        )
        
        testPillar = TestScoringPillar(pillarInfo: pillarInfo)
        sampleCompanyData = createSampleCompanyData()
        sampleMarketContext = createSampleMarketContext()
    }
    
    override func tearDown() {
        testPillar = nil
        sampleCompanyData = nil
        sampleMarketContext = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(testPillar.pillarInfo.name, "Test Pillar")
        XCTAssertEqual(testPillar.pillarInfo.description, "Test pillar for unit testing")
        XCTAssertEqual(testPillar.pillarInfo.defaultWeight, 0.25)
    }
    
    // MARK: - Required Fields Tests
    
    func testGetRequiredFields() {
        let requiredFields = testPillar.getRequiredFields()
        
        XCTAssertEqual(requiredFields.count, 3)
        XCTAssertTrue(requiredFields.contains("basicInfo.name"))
        XCTAssertTrue(requiredFields.contains("basicInfo.sector"))
        XCTAssertTrue(requiredFields.contains("pipeline.programs"))
    }
    
    // MARK: - Data Validation Tests
    
    func testValidateDataWithCompleteData() {
        let result = testPillar.validateData(sampleCompanyData)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThan(result.completeness, 0.5)
    }
    
    func testValidateDataWithMissingRequiredFields() {
        var incompleteData = sampleCompanyData!
        incompleteData.basicInfo.name = "" // Make required field empty
        
        let result = testPillar.validateData(incompleteData)
        
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
        
        let nameError = result.errors.first { $0.field == "basicInfo.name" }
        XCTAssertNotNil(nameError)
        XCTAssertEqual(nameError?.severity, .critical)
    }
    
    func testValidateDataWithLowCompleteness() {
        var incompleteData = sampleCompanyData!
        incompleteData.financials.cashPosition = 0 // Remove optional field
        incompleteData.market.addressableMarket = 0 // Remove optional field
        
        let result = testPillar.validateData(incompleteData)
        
        XCTAssertLessThan(result.completeness, 0.7)
        
        let completenessWarning = result.warnings.first { $0.field == "overall" }
        XCTAssertNotNil(completenessWarning)
        XCTAssertTrue(completenessWarning!.message.contains("completeness is low"))
    }
    
    // MARK: - Score Calculation Tests
    
    func testCalculateScoreSuccess() async throws {
        let score = try await testPillar.calculateScore(data: sampleCompanyData, context: sampleMarketContext)
        
        XCTAssertGreaterThanOrEqual(score.rawScore, 1.0)
        XCTAssertLessThanOrEqual(score.rawScore, 5.0)
        XCTAssertGreaterThanOrEqual(score.confidence, 0.0)
        XCTAssertLessThanOrEqual(score.confidence, 1.0)
        XCTAssertEqual(score.factors.count, 2)
        XCTAssertNotNil(score.explanation)
    }
    
    func testCalculateScoreError() async {
        testPillar.shouldThrowError = true
        
        do {
            _ = try await testPillar.calculateScore(data: sampleCompanyData, context: sampleMarketContext)
            XCTFail("Expected error to be thrown")
        } catch let error as ScoringError {
            if case .calculationError(let message) = error {
                XCTAssertEqual(message, "Test error")
            } else {
                XCTFail("Unexpected error type")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Score Explanation Tests
    
    func testExplainScore() async throws {
        let score = try await testPillar.calculateScore(data: sampleCompanyData, context: sampleMarketContext)
        let explanation = testPillar.explainScore(score)
        
        XCTAssertFalse(explanation.summary.isEmpty)
        XCTAssertEqual(explanation.factors.count, score.factors.count)
        XCTAssertEqual(explanation.methodology, "Test methodology for unit testing")
        XCTAssertEqual(explanation.limitations.count, 2)
        
        // Verify factor contributions are calculated correctly
        for (index, factor) in explanation.factors.enumerated() {
            let originalFactor = score.factors[index]
            let expectedContribution = originalFactor.weight * originalFactor.score
            XCTAssertEqual(factor.contribution, expectedContribution, accuracy: 0.001)
        }
    }
    
    // MARK: - Helper Method Tests
    
    func testNormalizeScore() {
        // Test score within range
        XCTAssertEqual(testPillar.normalizeScore(3.5), 3.5)
        
        // Test score above maximum
        XCTAssertEqual(testPillar.normalizeScore(6.0), 5.0)
        
        // Test score below minimum
        XCTAssertEqual(testPillar.normalizeScore(0.5), 1.0)
        
        // Test edge cases
        XCTAssertEqual(testPillar.normalizeScore(1.0), 1.0)
        XCTAssertEqual(testPillar.normalizeScore(5.0), 5.0)
    }
    
    func testCalculateConfidence() {
        // Test with high quality data
        let highConfidence = testPillar.calculateConfidence(
            dataCompleteness: 1.0,
            dataQuality: 1.0,
            methodologyReliability: 1.0
        )
        XCTAssertEqual(highConfidence, 1.0, accuracy: 0.001)
        
        // Test with low quality data
        let lowConfidence = testPillar.calculateConfidence(
            dataCompleteness: 0.3,
            dataQuality: 0.5,
            methodologyReliability: 0.6
        )
        XCTAssertLessThan(lowConfidence, 0.6)
        
        // Test bounds
        let zeroConfidence = testPillar.calculateConfidence(
            dataCompleteness: 0.0,
            dataQuality: 0.0,
            methodologyReliability: 0.0
        )
        XCTAssertEqual(zeroConfidence, 0.0)
    }
    
    func testCreateScoringFactor() {
        let factor = testPillar.createScoringFactor(
            name: "Test Factor",
            weight: 1.5, // Above maximum
            score: 6.0,  // Above maximum
            rationale: "Test rationale"
        )
        
        XCTAssertEqual(factor.name, "Test Factor")
        XCTAssertEqual(factor.weight, 1.0) // Should be normalized
        XCTAssertEqual(factor.score, 5.0)  // Should be normalized
        XCTAssertEqual(factor.rationale, "Test rationale")
    }
    
    func testGenerateWarnings() {
        // Test low confidence warning
        let lowConfidenceWarnings = testPillar.generateWarnings(
            score: 3.0,
            confidence: 0.2,
            dataCompleteness: 0.8
        )
        XCTAssertTrue(lowConfidenceWarnings.contains { $0.contains("Low confidence") })
        
        // Test low completeness warning
        let lowCompletenessWarnings = testPillar.generateWarnings(
            score: 3.0,
            confidence: 0.8,
            dataCompleteness: 0.3
        )
        XCTAssertTrue(lowCompletenessWarnings.contains { $0.contains("data gaps") })
        
        // Test low score warning
        let lowScoreWarnings = testPillar.generateWarnings(
            score: 1.5,
            confidence: 0.8,
            dataCompleteness: 0.8
        )
        XCTAssertTrue(lowScoreWarnings.contains { $0.contains("Low score") })
    }
    
    // MARK: - Data Completeness Tests
    
    func testCalculateDataCompleteness() {
        // Test with complete data
        let completeness = testPillar.calculateDataCompleteness(sampleCompanyData)
        XCTAssertGreaterThan(completeness, 0.5)
        XCTAssertLessThanOrEqual(completeness, 1.0)
        
        // Test with incomplete data
        var incompleteData = sampleCompanyData!
        incompleteData.financials.cashPosition = 0
        incompleteData.market.addressableMarket = 0
        
        let lowCompleteness = testPillar.calculateDataCompleteness(incompleteData)
        XCTAssertLessThan(lowCompleteness, completeness)
    }
    
    // MARK: - Field Presence Tests
    
    func testIsFieldPresent() {
        // Test present fields
        XCTAssertTrue(testPillar.isFieldPresent("basicInfo.name", in: sampleCompanyData))
        XCTAssertTrue(testPillar.isFieldPresent("basicInfo.sector", in: sampleCompanyData))
        XCTAssertTrue(testPillar.isFieldPresent("pipeline.programs", in: sampleCompanyData))
        
        // Test with empty data
        var emptyData = sampleCompanyData!
        emptyData.basicInfo.name = ""
        XCTAssertFalse(testPillar.isFieldPresent("basicInfo.name", in: emptyData))
        
        // Test unknown field (should return true by default)
        XCTAssertTrue(testPillar.isFieldPresent("unknown.field", in: sampleCompanyData))
    }
    
    // MARK: - Error Handling Tests
    
    func testScoringErrorTypes() {
        let invalidDataError = ScoringError.invalidData("Test message")
        XCTAssertEqual(invalidDataError.localizedDescription, "Invalid data: Test message")
        
        let missingFieldError = ScoringError.missingRequiredField("testField")
        XCTAssertEqual(missingFieldError.localizedDescription, "Missing required field: testField")
        
        let calculationError = ScoringError.calculationError("Calculation failed")
        XCTAssertEqual(calculationError.localizedDescription, "Calculation error: Calculation failed")
        
        let configError = ScoringError.configurationError("Config invalid")
        XCTAssertEqual(configError.localizedDescription, "Configuration error: Config invalid")
        
        let networkError = ScoringError.networkError("Network failed")
        XCTAssertEqual(networkError.localizedDescription, "Network error: Network failed")
    }
    
    // MARK: - PillarInfoFactory Tests
    
    func testPillarInfoFactory() {
        let assetQualityInfo = PillarInfoFactory.createAssetQualityInfo()
        XCTAssertEqual(assetQualityInfo.name, "Asset Quality")
        XCTAssertEqual(assetQualityInfo.defaultWeight, 0.25)
        XCTAssertFalse(assetQualityInfo.requiredFields.isEmpty)
        
        let marketOutlookInfo = PillarInfoFactory.createMarketOutlookInfo()
        XCTAssertEqual(marketOutlookInfo.name, "Market Outlook")
        XCTAssertEqual(marketOutlookInfo.defaultWeight, 0.20)
        
        let capitalIntensityInfo = PillarInfoFactory.createCapitalIntensityInfo()
        XCTAssertEqual(capitalIntensityInfo.name, "Capital Intensity")
        XCTAssertEqual(capitalIntensityInfo.defaultWeight, 0.15)
        
        let strategicFitInfo = PillarInfoFactory.createStrategicFitInfo()
        XCTAssertEqual(strategicFitInfo.name, "Strategic Fit")
        XCTAssertEqual(strategicFitInfo.defaultWeight, 0.20)
        
        let financialReadinessInfo = PillarInfoFactory.createFinancialReadinessInfo()
        XCTAssertEqual(financialReadinessInfo.name, "Financial Readiness")
        XCTAssertEqual(financialReadinessInfo.defaultWeight, 0.10)
        
        let regulatoryRiskInfo = PillarInfoFactory.createRegulatoryRiskInfo()
        XCTAssertEqual(regulatoryRiskInfo.name, "Regulatory Risk")
        XCTAssertEqual(regulatoryRiskInfo.defaultWeight, 0.10)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleCompanyData() -> CompanyData {
        return CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: "Test Biotech Company",
                ticker: "TBC",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .clinicalStage,
                foundedYear: 2015,
                headquarters: "Boston, MA",
                employeeCount: 150,
                website: "https://testbiotech.com"
            ),
            pipeline: Pipeline(
                programs: [
                    Program(
                        id: UUID(),
                        name: "TBC-001",
                        indication: "Solid Tumors",
                        stage: .phaseII,
                        mechanism: "PD-1 Inhibitor",
                        differentiators: ["Novel mechanism", "Improved safety profile"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 1,
                leadProgram: Program(
                    id: UUID(),
                    name: "TBC-001",
                    indication: "Solid Tumors",
                    stage: .phaseII,
                    mechanism: "PD-1 Inhibitor",
                    differentiators: ["Novel mechanism"],
                    risks: [],
                    timeline: []
                )
            ),
            financials: Financials(
                cashPosition: 50000000,
                burnRate: 5000000,
                lastFunding: FundingRound(
                    id: UUID(),
                    type: .seriesB,
                    amount: 75000000,
                    date: Date(),
                    investors: [],
                    valuation: 300000000
                ),
                runway: 10,
                totalFunding: 125000000,
                lastReportDate: Date()
            ),
            market: Market(
                addressableMarket: 5000000000,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0.15,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .emerging
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    keyMilestones: [],
                    estimatedTimeline: 36,
                    riskFactors: []
                )
            ),
            lastUpdated: Date()
        )
    }
    
    private func createSampleMarketContext() -> MarketContext {
        return MarketContext(
            benchmarkData: [],
            marketConditions: MarketConditions(
                biotechIndex: 1000.0,
                ipoActivity: .moderate,
                fundingEnvironment: .moderate,
                regulatoryClimate: .neutral
            ),
            comparableCompanies: [],
            industryMetrics: IndustryMetrics(
                averageValuation: 500000000,
                medianTimeline: 48,
                successRate: 0.3,
                averageRunway: 18
            )
        )
    }
}