import XCTest
@testable import BDScoringModule

final class FinancialReadinessPillarTests: XCTestCase {
    
    var financialPillar: FinancialReadinessPillar!
    var sampleMarketContext: MarketContext!
    
    override func setUp() {
        super.setUp()
        financialPillar = FinancialReadinessPillar()
        sampleMarketContext = createSampleMarketContext()
    }
    
    override func tearDown() {
        financialPillar = nil
        sampleMarketContext = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(financialPillar.pillarInfo.name, "Financial Readiness")
        XCTAssertEqual(financialPillar.pillarInfo.description, "Analyzes current cash position and burn rate")
        XCTAssertEqual(financialPillar.pillarInfo.defaultWeight, 0.10)
        
        let requiredFields = financialPillar.getRequiredFields()
        XCTAssertTrue(requiredFields.contains("financials.cashPosition"))
        XCTAssertTrue(requiredFields.contains("financials.burnRate"))
        XCTAssertTrue(requiredFields.contains("financials.runway"))
    }
    
    // MARK: - Data Validation Tests
    
    func testValidateDataWithCompleteFinancialData() {
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 5.0,
            lastFundingDate: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        )
        
        let result = financialPillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertGreaterThan(result.completeness, 0.8)
    }
    
    func testValidateDataWithMissingCashPosition() {
        let companyData = createCompanyData(
            cashPosition: 0.0, // Invalid
            burnRate: 5.0,
            lastFundingDate: Date()
        )
        
        let result = financialPillar.validateData(companyData)
        
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
        
        let cashError = result.errors.first { $0.field == "financials.cashPosition" }
        XCTAssertNotNil(cashError)
        XCTAssertEqual(cashError?.severity, .critical)
    }
    
    func testValidateDataWithMissingBurnRate() {
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 0.0, // Invalid
            lastFundingDate: Date()
        )
        
        let result = financialPillar.validateData(companyData)
        
        XCTAssertFalse(result.isValid)
        
        let burnRateError = result.errors.first { $0.field == "financials.burnRate" }
        XCTAssertNotNil(burnRateError)
        XCTAssertEqual(burnRateError?.severity, .critical)
    }
    
    func testValidateDataWithUnrealisticValues() {
        let companyData = createCompanyData(
            cashPosition: 15000.0, // Very high
            burnRate: 150.0, // Very high
            lastFundingDate: Date()
        )
        
        let result = financialPillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid) // Should still be valid
        XCTAssertFalse(result.warnings.isEmpty) // But should have warnings
        
        let cashWarning = result.warnings.first { $0.field == "financials.cashPosition" }
        XCTAssertNotNil(cashWarning)
        
        let burnWarning = result.warnings.first { $0.field == "financials.burnRate" }
        XCTAssertNotNil(burnWarning)
    }
    
    func testValidateDataWithOutdatedFinancialData() {
        let oldDate = Date().addingTimeInterval(-120 * 24 * 60 * 60) // 120 days ago
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 5.0,
            lastFundingDate: oldDate
        )
        
        let result = financialPillar.validateData(companyData)
        
        XCTAssertTrue(result.isValid)
        
        let freshnessWarning = result.warnings.first { $0.field == "financials.lastFunding.date" }
        XCTAssertNotNil(freshnessWarning)
        XCTAssertTrue(freshnessWarning!.message.contains("outdated"))
    }
    
    // MARK: - Score Calculation Tests
    
    func testCalculateScoreWithExcellentFinancials() async throws {
        let companyData = createCompanyData(
            cashPosition: 500.0, // Excellent cash position
            burnRate: 3.0, // Low burn rate for Phase II
            lastFundingDate: Date().addingTimeInterval(-15 * 24 * 60 * 60), // Recent funding
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        XCTAssertGreaterThan(score.rawScore, 4.0) // Should be high score
        XCTAssertGreaterThan(score.confidence, 0.8) // High confidence
        XCTAssertEqual(score.factors.count, 6) // All factors present
        XCTAssertNotNil(score.explanation)
    }
    
    func testCalculateScoreWithPoorFinancials() async throws {
        let companyData = createCompanyData(
            cashPosition: 20.0, // Low cash position
            burnRate: 8.0, // High burn rate
            lastFundingDate: Date().addingTimeInterval(-180 * 24 * 60 * 60), // Old funding
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        XCTAssertLessThan(score.rawScore, 3.0) // Should be low score
        XCTAssertFalse(score.warnings.isEmpty) // Should have warnings
        
        // Check for specific warnings
        let criticalWarning = score.warnings.first { $0.contains("Critical") || $0.contains("Warning") }
        XCTAssertNotNil(criticalWarning)
    }
    
    func testCalculateScoreWithCriticalRunway() async throws {
        let companyData = createCompanyData(
            cashPosition: 15.0, // Low cash
            burnRate: 5.0, // Normal burn rate
            lastFundingDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Runway should be 3 months (15/5), which is critical
        XCTAssertLessThan(score.rawScore, 2.0)
        
        let criticalWarning = score.warnings.first { $0.contains("Critical") && $0.contains("runway") }
        XCTAssertNotNil(criticalWarning)
    }
    
    // MARK: - Runway Scenario Tests
    
    func testOptimalRunwayScenario() async throws {
        let companyData = createCompanyData(
            cashPosition: 120.0, // 24 months runway
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Should get high score for optimal runway
        let runwayFactor = score.factors.first { $0.name == "Funding Runway" }
        XCTAssertNotNil(runwayFactor)
        XCTAssertGreaterThanOrEqual(runwayFactor!.score, 4.5)
    }
    
    func testMinimumRunwayScenario() async throws {
        let companyData = createCompanyData(
            cashPosition: 60.0, // 12 months runway
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Should get moderate score for minimum runway
        let runwayFactor = score.factors.first { $0.name == "Funding Runway" }
        XCTAssertNotNil(runwayFactor)
        XCTAssertGreaterThanOrEqual(runwayFactor!.score, 2.5)
        XCTAssertLessThan(runwayFactor!.score, 4.0)
    }
    
    func testCriticalRunwayScenario() async throws {
        let companyData = createCompanyData(
            cashPosition: 20.0, // 4 months runway
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Should get low score for critical runway
        let runwayFactor = score.factors.first { $0.name == "Funding Runway" }
        XCTAssertNotNil(runwayFactor)
        XCTAssertLessThan(runwayFactor!.score, 2.0)
        
        // Should have critical runway warning
        let criticalWarning = score.warnings.first { $0.contains("Critical") && $0.contains("runway") }
        XCTAssertNotNil(criticalWarning)
    }
    
    // MARK: - Stage-Specific Tests
    
    func testPreclinicalStageScoring() async throws {
        let companyData = createCompanyData(
            cashPosition: 50.0,
            burnRate: 2.0, // Low burn for preclinical
            lastFundingDate: Date(),
            stage: .preclinical
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Cash position should be scored relative to preclinical stage
        let cashFactor = score.factors.first { $0.name == "Cash Position" }
        XCTAssertNotNil(cashFactor)
        XCTAssertGreaterThan(cashFactor!.score, 3.0) // Should be good for preclinical
    }
    
    func testPhase3StageScoring() async throws {
        let companyData = createCompanyData(
            cashPosition: 200.0,
            burnRate: 15.0, // Higher burn for Phase III
            lastFundingDate: Date(),
            stage: .phase3
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        // Burn rate should be acceptable for Phase III
        let burnFactor = score.factors.first { $0.name == "Burn Rate Efficiency" }
        XCTAssertNotNil(burnFactor)
        XCTAssertGreaterThanOrEqual(burnFactor!.score, 3.0)
        
        // Capital intensity should be high for Phase III
        let capitalFactor = score.factors.first { $0.name == "Capital Intensity" }
        XCTAssertNotNil(capitalFactor)
        XCTAssertLessThan(capitalFactor!.score, 4.0) // High intensity = lower score
    }
    
    // MARK: - Data Freshness Tests
    
    func testVeryFreshData() async throws {
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 5.0,
            lastFundingDate: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let freshnessFactor = score.factors.first { $0.name == "Data Freshness" }
        XCTAssertNotNil(freshnessFactor)
        XCTAssertEqual(freshnessFactor!.score, 5.0) // Should be perfect
    }
    
    func testStaleData() async throws {
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 5.0,
            lastFundingDate: Date().addingTimeInterval(-200 * 24 * 60 * 60), // 200 days ago
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let freshnessFactor = score.factors.first { $0.name == "Data Freshness" }
        XCTAssertNotNil(freshnessFactor)
        XCTAssertLessThan(freshnessFactor!.score, 2.0) // Should be low
    }
    
    // MARK: - Capital Intensity Tests
    
    func testLowCapitalIntensity() async throws {
        let companyData = createCompanyDataWithPipeline(
            cashPosition: 100.0,
            burnRate: 5.0,
            stage: .preclinical,
            programCount: 1 // Simple pipeline
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let capitalFactor = score.factors.first { $0.name == "Capital Intensity" }
        XCTAssertNotNil(capitalFactor)
        XCTAssertGreaterThan(capitalFactor!.score, 4.0) // Low intensity = high score
    }
    
    func testHighCapitalIntensity() async throws {
        let companyData = createCompanyDataWithPipeline(
            cashPosition: 100.0,
            burnRate: 5.0,
            stage: .phase3,
            programCount: 5 // Complex pipeline
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let capitalFactor = score.factors.first { $0.name == "Capital Intensity" }
        XCTAssertNotNil(capitalFactor)
        XCTAssertLessThan(capitalFactor!.score, 3.0) // High intensity = low score
    }
    
    // MARK: - Financing Need Prediction Tests
    
    func testNoImmediateFinancingNeed() async throws {
        let companyData = createCompanyData(
            cashPosition: 150.0, // 30 months runway
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let financingFactor = score.factors.first { $0.name == "Financing Need Timing" }
        XCTAssertNotNil(financingFactor)
        XCTAssertGreaterThan(financingFactor!.score, 4.0) // No pressure
    }
    
    func testImmediateFinancingNeed() async throws {
        let companyData = createCompanyData(
            cashPosition: 25.0, // 5 months runway
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        
        let financingFactor = score.factors.first { $0.name == "Financing Need Timing" }
        XCTAssertNotNil(financingFactor)
        XCTAssertLessThan(financingFactor!.score, 2.0) // High pressure
    }
    
    // MARK: - Error Handling Tests
    
    func testCalculateScoreWithInvalidData() async {
        let invalidData = createCompanyData(
            cashPosition: 0.0, // Invalid
            burnRate: 0.0, // Invalid
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        do {
            _ = try await financialPillar.calculateScore(data: invalidData, context: sampleMarketContext)
            XCTFail("Expected error to be thrown")
        } catch let error as ScoringError {
            if case .invalidData(let message) = error {
                XCTAssertTrue(message.contains("Financial Readiness"))
            } else {
                XCTFail("Unexpected error type")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Score Explanation Tests
    
    func testExplainScore() async throws {
        let companyData = createCompanyData(
            cashPosition: 100.0,
            burnRate: 5.0,
            lastFundingDate: Date(),
            stage: .phase2
        )
        
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        let explanation = financialPillar.explainScore(score)
        
        XCTAssertFalse(explanation.summary.isEmpty)
        XCTAssertTrue(explanation.summary.contains("Financial Readiness"))
        XCTAssertEqual(explanation.factors.count, score.factors.count)
        XCTAssertTrue(explanation.methodology.contains("cash position"))
        XCTAssertTrue(explanation.methodology.contains("burn rate"))
        XCTAssertFalse(explanation.limitations.isEmpty)
        
        // Verify factor contributions
        for (index, factor) in explanation.factors.enumerated() {
            let originalFactor = score.factors[index]
            let expectedContribution = originalFactor.weight * originalFactor.score
            XCTAssertEqual(factor.contribution, expectedContribution, accuracy: 0.001)
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteFinancialAnalysisWorkflow() async throws {
        let companyData = createCompanyData(
            cashPosition: 75.0,
            burnRate: 4.0,
            lastFundingDate: Date().addingTimeInterval(-45 * 24 * 60 * 60),
            stage: .phase2
        )
        
        // Validate data
        let validation = financialPillar.validateData(companyData)
        XCTAssertTrue(validation.isValid)
        
        // Calculate score
        let score = try await financialPillar.calculateScore(data: companyData, context: sampleMarketContext)
        XCTAssertGreaterThanOrEqual(score.rawScore, 1.0)
        XCTAssertLessThanOrEqual(score.rawScore, 5.0)
        
        // Explain score
        let explanation = financialPillar.explainScore(score)
        XCTAssertFalse(explanation.summary.isEmpty)
        
        // Verify all factors are present and weighted correctly
        let totalWeight = score.factors.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Helper Methods
    
    private func createCompanyData(
        cashPosition: Double,
        burnRate: Double,
        lastFundingDate: Date,
        stage: DevelopmentStage = .phase2
    ) -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech",
                ticker: "TBC",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: stage,
                description: "Test company"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "TBC-001",
                        indication: "Solid Tumors",
                        stage: stage,
                        mechanism: "Novel Target",
                        differentiators: ["First-in-class"],
                        risks: [],
                        timeline: []
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: cashPosition,
                burnRate: burnRate,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: cashPosition * 1.5,
                    date: lastFundingDate,
                    investors: ["Test VC"]
                )
            ),
            market: CompanyData.Market(
                addressableMarket: 5.0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0.15,
                    barriers: [],
                    drivers: [],
                    reimbursement: .moderate
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 36,
                    risks: [],
                    mitigations: []
                )
            )
        )
    }
    
    private func createCompanyDataWithPipeline(
        cashPosition: Double,
        burnRate: Double,
        stage: DevelopmentStage,
        programCount: Int
    ) -> CompanyData {
        var programs: [Program] = []
        for i in 0..<programCount {
            programs.append(Program(
                name: "TBC-00\(i+1)",
                indication: "Indication \(i+1)",
                stage: stage,
                mechanism: "Mechanism \(i+1)",
                differentiators: ["Differentiator \(i+1)"],
                risks: [],
                timeline: []
            ))
        }
        
        var companyData = createCompanyData(
            cashPosition: cashPosition,
            burnRate: burnRate,
            lastFundingDate: Date(),
            stage: stage
        )
        companyData.pipeline = CompanyData.Pipeline(programs: programs)
        
        return companyData
    }
    
    private func createSampleMarketContext() -> MarketContext {
        return MarketContext(
            benchmarkData: [
                BenchmarkData(
                    therapeuticArea: "Oncology",
                    stage: .phase2,
                    averageScore: 3.2,
                    standardDeviation: 0.8,
                    sampleSize: 50
                )
            ],
            marketConditions: MarketConditions(
                biotechIndex: 1000.0,
                ipoActivity: .moderate,
                fundingEnvironment: .moderate,
                regulatoryClimate: .neutral
            ),
            comparableCompanies: [],
            industryMetrics: IndustryMetrics(
                averageValuation: 500.0,
                medianTimeline: 48,
                successRate: 0.3,
                averageRunway: 18
            )
        )
    }
}