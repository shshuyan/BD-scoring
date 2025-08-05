import XCTest
@testable import BDScoringModule

class MarketOutlookPillarTests: XCTestCase {
    
    var pillar: MarketOutlookPillar!
    var mockContext: MarketContext!
    
    override func setUp() {
        super.setUp()
        pillar = MarketOutlookPillar()
        mockContext = createMockMarketContext()
    }
    
    override func tearDown() {
        pillar = nil
        mockContext = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(pillar.pillarInfo.name, "Market Outlook")
        XCTAssertEqual(pillar.pillarInfo.defaultWeight, 0.20)
        XCTAssertTrue(pillar.pillarInfo.requiredFields.contains("market.addressableMarket"))
        XCTAssertTrue(pillar.pillarInfo.requiredFields.contains("basicInfo.therapeuticAreas"))
    }
    
    // MARK: - Data Validation Tests
    
    func testValidateData_ValidData() {
        let companyData = createValidCompanyData()
        let result = pillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThan(result.completeness, 0.5)
    }
    
    func testValidateData_MissingAddressableMarket() {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0
        
        let result = pillar.validateData(companyData)
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.field == "market.addressableMarket" })
    }
    
    func testValidateData_MissingTherapeuticAreas() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.therapeuticAreas = []
        
        let result = pillar.validateData(companyData)
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.field == "basicInfo.therapeuticAreas" })
    }
    
    func testValidateData_NegativeGrowthRate() {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.growthRate = -0.05
        
        let result = pillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid) // Should be valid but with warnings
        XCTAssertTrue(result.warnings.contains { $0.field == "market.marketDynamics.growthRate" })
    }
    
    func testValidateData_UnknownReimbursement() {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.reimbursement = .unknown
        
        let result = pillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.contains { $0.field == "market.marketDynamics.reimbursement" })
    }
    
    func testValidateData_VerySmallMarket() {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0.05 // $50M
        
        let result = pillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.contains { $0.field == "market.addressableMarket" })
    }
    
    // MARK: - Scoring Tests
    
    func testCalculateScore_ExcellentMarket() async throws {
        let companyData = createExcellentMarketCompany()
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertGreaterThan(score.rawScore, 4.0)
        XCTAssertGreaterThan(score.confidence, 0.7)
        XCTAssertEqual(score.factors.count, 6)
        XCTAssertNotNil(score.explanation)
    }
    
    func testCalculateScore_PoorMarket() async throws {
        let companyData = createPoorMarketCompany()
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertLessThan(score.rawScore, 2.5)
        XCTAssertGreaterThan(score.warnings.count, 0)
    }
    
    func testCalculateScore_AverageMarket() async throws {
        let companyData = createAverageMarketCompany()
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertGreaterThan(score.rawScore, 2.5)
        XCTAssertLessThan(score.rawScore, 4.0)
    }
    
    func testCalculateScore_InvalidData() async {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0
        
        do {
            _ = try await pillar.calculateScore(data: companyData, context: mockContext)
            XCTFail("Should throw error for invalid data")
        } catch ScoringError.invalidData {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Market Size Scoring Tests
    
    func testMarketSizeScoring_ExcellentSize() async throws {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 15.0 // $15B
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let marketSizeFactor = score.factors.first { $0.name == "Market Size" }
        
        XCTAssertNotNil(marketSizeFactor)
        XCTAssertEqual(marketSizeFactor?.score, 5.0)
        XCTAssertEqual(marketSizeFactor?.weight, 0.30)
    }
    
    func testMarketSizeScoring_GoodSize() async throws {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 7.0 // $7B
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let marketSizeFactor = score.factors.first { $0.name == "Market Size" }
        
        XCTAssertNotNil(marketSizeFactor)
        XCTAssertEqual(marketSizeFactor?.score, 4.0)
    }
    
    func testMarketSizeScoring_SmallSize() async throws {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0.5 // $500M
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let marketSizeFactor = score.factors.first { $0.name == "Market Size" }
        
        XCTAssertNotNil(marketSizeFactor)
        XCTAssertEqual(marketSizeFactor?.score, 2.0)
    }
    
    // MARK: - Growth Potential Scoring Tests
    
    func testGrowthPotentialScoring_HighGrowth() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.growthRate = 0.20 // 20%
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let growthFactor = score.factors.first { $0.name == "Growth Potential" }
        
        XCTAssertNotNil(growthFactor)
        XCTAssertEqual(growthFactor?.score, 5.0)
        XCTAssertEqual(growthFactor?.weight, 0.25)
    }
    
    func testGrowthPotentialScoring_NegativeGrowth() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.growthRate = -0.05 // -5%
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let growthFactor = score.factors.first { $0.name == "Growth Potential" }
        
        XCTAssertNotNil(growthFactor)
        XCTAssertEqual(growthFactor?.score, 1.0)
    }
    
    func testGrowthPotentialScoring_WithDrivers() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.growthRate = 0.10 // 10%
        companyData.market.marketDynamics.drivers = ["Strong unmet need", "Aging population", "Innovation"]
        companyData.market.marketDynamics.barriers = ["Regulatory hurdles"]
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let growthFactor = score.factors.first { $0.name == "Growth Potential" }
        
        XCTAssertNotNil(growthFactor)
        XCTAssertGreaterThan(growthFactor?.score ?? 0, 4.0) // Should be boosted by drivers
    }
    
    // MARK: - Competitive Landscape Scoring Tests
    
    func testCompetitiveLandscapeScoring_NoCompetitors() async throws {
        var companyData = createValidCompanyData()
        companyData.market.competitors = []
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let competitiveFactor = score.factors.first { $0.name == "Competitive Landscape" }
        
        XCTAssertNotNil(competitiveFactor)
        XCTAssertEqual(competitiveFactor?.score, 5.0)
        XCTAssertEqual(competitiveFactor?.weight, 0.20)
    }
    
    func testCompetitiveLandscapeScoring_HighCompetition() async throws {
        var companyData = createValidCompanyData()
        companyData.market.competitors = createManyCompetitors(count: 12)
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let competitiveFactor = score.factors.first { $0.name == "Competitive Landscape" }
        
        XCTAssertNotNil(competitiveFactor)
        XCTAssertEqual(competitiveFactor?.score, 1.0)
    }
    
    func testCompetitiveLandscapeScoring_AdvancedCompetitors() async throws {
        var companyData = createValidCompanyData()
        companyData.market.competitors = [
            createCompetitor(name: "Competitor 1", stage: .approved),
            createCompetitor(name: "Competitor 2", stage: .phase3),
            createCompetitor(name: "Competitor 3", stage: .marketed)
        ]
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let competitiveFactor = score.factors.first { $0.name == "Competitive Landscape" }
        
        XCTAssertNotNil(competitiveFactor)
        XCTAssertLessThan(competitiveFactor?.score ?? 5.0, 3.0) // Should be reduced due to advanced competitors
    }
    
    // MARK: - Regulatory Pathway Scoring Tests
    
    func testRegulatoryPathwayScoring_Breakthrough() async throws {
        var companyData = createValidCompanyData()
        companyData.regulatory.regulatoryStrategy.pathway = .breakthrough
        companyData.regulatory.regulatoryStrategy.timeline = 18
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let regulatoryFactor = score.factors.first { $0.name == "Regulatory Pathway" }
        
        XCTAssertNotNil(regulatoryFactor)
        XCTAssertEqual(regulatoryFactor?.score, 5.0)
        XCTAssertEqual(regulatoryFactor?.weight, 0.15)
    }
    
    func testRegulatoryPathwayScoring_StandardWithLongTimeline() async throws {
        var companyData = createValidCompanyData()
        companyData.regulatory.regulatoryStrategy.pathway = .standard
        companyData.regulatory.regulatoryStrategy.timeline = 72
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let regulatoryFactor = score.factors.first { $0.name == "Regulatory Pathway" }
        
        XCTAssertNotNil(regulatoryFactor)
        XCTAssertLessThan(regulatoryFactor?.score ?? 5.0, 3.0)
    }
    
    // MARK: - Reimbursement Environment Scoring Tests
    
    func testReimbursementScoring_Favorable() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.reimbursement = .favorable
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let reimbursementFactor = score.factors.first { $0.name == "Reimbursement Environment" }
        
        XCTAssertNotNil(reimbursementFactor)
        XCTAssertEqual(reimbursementFactor?.score, 5.0)
        XCTAssertEqual(reimbursementFactor?.weight, 0.05)
    }
    
    func testReimbursementScoring_Challenging() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.reimbursement = .challenging
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let reimbursementFactor = score.factors.first { $0.name == "Reimbursement Environment" }
        
        XCTAssertNotNil(reimbursementFactor)
        XCTAssertEqual(reimbursementFactor?.score, 2.0)
    }
    
    // MARK: - Market Dynamics Scoring Tests
    
    func testMarketDynamicsScoring_StrongDrivers() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.drivers = ["Unmet need", "Breakthrough innovation", "Aging population", "Policy support"]
        companyData.market.marketDynamics.barriers = ["Cost"]
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let dynamicsFactor = score.factors.first { $0.name == "Market Dynamics" }
        
        XCTAssertNotNil(dynamicsFactor)
        XCTAssertEqual(dynamicsFactor?.score, 5.0)
        XCTAssertEqual(dynamicsFactor?.weight, 0.05)
    }
    
    func testMarketDynamicsScoring_MoreBarriers() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.drivers = ["Innovation"]
        companyData.market.marketDynamics.barriers = ["High cost", "Regulatory complexity", "Market access", "Competition"]
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        let dynamicsFactor = score.factors.first { $0.name == "Market Dynamics" }
        
        XCTAssertNotNil(dynamicsFactor)
        XCTAssertEqual(dynamicsFactor?.score, 1.0)
    }
    
    // MARK: - Limited Data Conditions Tests
    
    func testCalculateScore_LimitedCompetitorData() async throws {
        var companyData = createValidCompanyData()
        companyData.market.competitors = []
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertGreaterThan(score.rawScore, 0)
        XCTAssertTrue(score.warnings.isEmpty) // No competitors should not generate warnings in scoring
        XCTAssertLessThan(score.confidence, 1.0) // Confidence should be reduced
    }
    
    func testCalculateScore_LimitedMarketDynamicsData() async throws {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.drivers = []
        companyData.market.marketDynamics.barriers = []
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertGreaterThan(score.rawScore, 0)
        XCTAssertLessThan(score.confidence, 1.0)
    }
    
    func testCalculateScore_MinimalData() async throws {
        let companyData = createMinimalValidCompanyData()
        
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        XCTAssertGreaterThan(score.rawScore, 0)
        XCTAssertLessThan(score.confidence, 0.7) // Low confidence due to minimal data
        XCTAssertGreaterThan(score.warnings.count, 0)
    }
    
    // MARK: - Score Explanation Tests
    
    func testExplainScore() async throws {
        let companyData = createValidCompanyData()
        let score = try await pillar.calculateScore(data: companyData, context: mockContext)
        
        let explanation = pillar.explainScore(score)
        
        XCTAssertFalse(explanation.summary.isEmpty)
        XCTAssertEqual(explanation.factors.count, score.factors.count)
        XCTAssertFalse(explanation.methodology.isEmpty)
        XCTAssertGreaterThan(explanation.limitations.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockMarketContext() -> MarketContext {
        return MarketContext(
            benchmarkData: [],
            marketConditions: MarketConditions(
                biotechIndex: 100.0,
                ipoActivity: .moderate,
                fundingEnvironment: .moderate,
                regulatoryClimate: .neutral
            ),
            comparableCompanies: [],
            industryMetrics: IndustryMetrics(
                averageValuation: 500.0,
                medianTimeline: 36,
                successRate: 0.3,
                averageRunway: 24
            )
        )
    }
    
    private func createValidCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech",
                ticker: "TEST",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "Test company"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [createTestProgram()]
            ),
            financials: CompanyData.Financials(
                cashPosition: 100.0,
                burnRate: 5.0,
                lastFunding: nil
            ),
            market: CompanyData.Market(
                addressableMarket: 5.0,
                competitors: [createCompetitor(name: "Competitor 1", stage: .phase2)],
                marketDynamics: MarketDynamics(
                    growthRate: 0.10,
                    barriers: ["Regulatory complexity"],
                    drivers: ["Unmet medical need", "Innovation"],
                    reimbursement: .moderate
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 36,
                    risks: ["Clinical trial risk"],
                    mitigations: ["Strong preclinical data"]
                )
            )
        )
    }
    
    private func createExcellentMarketCompany() -> CompanyData {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 15.0 // $15B
        companyData.market.marketDynamics.growthRate = 0.20 // 20%
        companyData.market.competitors = [] // No competition
        companyData.market.marketDynamics.reimbursement = .favorable
        companyData.market.marketDynamics.drivers = ["Unmet need", "Breakthrough innovation", "Aging population"]
        companyData.market.marketDynamics.barriers = []
        companyData.regulatory.regulatoryStrategy.pathway = .breakthrough
        companyData.regulatory.regulatoryStrategy.timeline = 18
        return companyData
    }
    
    private func createPoorMarketCompany() -> CompanyData {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0.05 // $50M
        companyData.market.marketDynamics.growthRate = -0.05 // -5%
        companyData.market.competitors = createManyCompetitors(count: 15)
        companyData.market.marketDynamics.reimbursement = .challenging
        companyData.market.marketDynamics.drivers = []
        companyData.market.marketDynamics.barriers = ["High cost", "Regulatory barriers", "Market access", "Competition"]
        companyData.regulatory.regulatoryStrategy.timeline = 84
        return companyData
    }
    
    private func createAverageMarketCompany() -> CompanyData {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 2.0 // $2B
        companyData.market.marketDynamics.growthRate = 0.06 // 6%
        companyData.market.competitors = [
            createCompetitor(name: "Competitor 1", stage: .phase2),
            createCompetitor(name: "Competitor 2", stage: .phase1)
        ]
        return companyData
    }
    
    private func createMinimalValidCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Minimal Biotech",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .preclinical
            ),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(cashPosition: 10.0, burnRate: 1.0),
            market: CompanyData.Market(
                addressableMarket: 1.0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0.05,
                    barriers: [],
                    drivers: [],
                    reimbursement: .unknown
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 48,
                    risks: [],
                    mitigations: []
                )
            )
        )
    }
    
    private func createTestProgram() -> Program {
        return Program(
            name: "Test Program",
            indication: "Cancer",
            stage: .phase2,
            mechanism: "Targeted therapy",
            differentiators: ["Novel target"],
            risks: [],
            timeline: []
        )
    }
    
    private func createCompetitor(name: String, stage: DevelopmentStage) -> Competitor {
        return Competitor(
            name: name,
            stage: stage,
            marketShare: nil,
            strengths: ["Established presence"],
            weaknesses: ["Limited pipeline"]
        )
    }
    
    private func createManyCompetitors(count: Int) -> [Competitor] {
        return (1...count).map { i in
            createCompetitor(name: "Competitor \(i)", stage: .phase2)
        }
    }
}