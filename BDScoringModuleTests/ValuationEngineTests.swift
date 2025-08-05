import XCTest
@testable import BDScoringModule

final class ValuationEngineTests: XCTestCase {
    
    var engine: DefaultValuationEngine!
    var mockComparablesService: MockComparablesService!
    var sampleCompany: CompanyData!
    var sampleComparables: [Comparable]!
    
    override func setUp() {
        super.setUp()
        mockComparablesService = MockComparablesService()
        engine = DefaultValuationEngine(comparablesService: mockComparablesService)
        setupSampleData()
    }
    
    override func tearDown() {
        engine = nil
        mockComparablesService = nil
        sampleCompany = nil
        sampleComparables = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupSampleData() {
        // Create sample company
        sampleCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech",
                ticker: "TBIO",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phase2,
                description: "Test biotech company"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "TB-001",
                        indication: "Breast cancer",
                        stage: .phase2,
                        mechanism: "CDK4/6 inhibitor",
                        differentiators: ["Improved selectivity"],
                        risks: [],
                        timeline: []
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 100.0,
                burnRate: 8.0,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: 60.0,
                    date: Date(),
                    investors: ["VC Fund A"]
                )
            ),
            market: CompanyData.Market(
                addressableMarket: 15.0,
                competitors: [
                    Competitor(
                        name: "Competitor A",
                        stage: .phase3,
                        marketShare: 0.3,
                        strengths: ["Established"],
                        weaknesses: ["Old technology"]
                    )
                ],
                marketDynamics: MarketDynamics(
                    growthRate: 8.5,
                    barriers: [],
                    drivers: [],
                    reimbursement: .favorable
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
        
        // Create sample comparables
        sampleComparables = [
            Comparable(
                companyName: "Comparable A",
                transactionType: .acquisition,
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                valuation: 800.0,
                stage: .phase2,
                therapeuticAreas: ["Oncology"],
                leadProgram: ComparableProgram(
                    name: "CA-001",
                    indication: "Lung cancer",
                    mechanism: "EGFR inhibitor",
                    stage: .phase2,
                    differentiators: ["Novel mechanism"],
                    competitivePosition: .bestInClass
                ),
                marketSize: 12.0,
                financials: ComparableFinancials(
                    cashAtTransaction: 90.0,
                    burnRate: 7.0,
                    runway: 13,
                    lastFundingAmount: 50.0,
                    revenue: nil,
                    employees: 75
                ),
                dealStructure: DealStructure(
                    upfront: 800.0,
                    milestones: 1000.0,
                    royalties: 10.0,
                    equity: nil,
                    terms: ["Exclusive rights"]
                ),
                confidence: 0.85
            ),
            
            Comparable(
                companyName: "Comparable B",
                transactionType: .acquisition,
                date: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
                valuation: 1200.0,
                stage: .phase3,
                therapeuticAreas: ["Oncology"],
                leadProgram: ComparableProgram(
                    name: "CB-002",
                    indication: "Breast cancer",
                    mechanism: "HER2 inhibitor",
                    stage: .phase3,
                    differentiators: ["Best-in-class efficacy"],
                    competitivePosition: .bestInClass
                ),
                marketSize: 18.0,
                financials: ComparableFinancials(
                    cashAtTransaction: 150.0,
                    burnRate: 12.0,
                    runway: 12,
                    lastFundingAmount: 80.0,
                    revenue: nil,
                    employees: 120
                ),
                dealStructure: DealStructure(
                    upfront: 1200.0,
                    milestones: 1500.0,
                    royalties: 15.0,
                    equity: nil,
                    terms: ["Global rights"]
                ),
                confidence: 0.90
            )
        ]
        
        // Setup mock service
        mockComparablesService.mockComparables = sampleComparables
    }
    
    // MARK: - Basic Valuation Tests
    
    func testCalculateValuationWithComparables() async throws {
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertGreaterThan(result.baseValuation, 0)
        XCTAssertEqual(result.companyId, sampleCompany.id)
        XCTAssertEqual(result.methodology, .comparableTransactions)
        XCTAssertGreaterThan(result.confidence, 0)
        XCTAssertFalse(result.scenarios.isEmpty)
        XCTAssertFalse(result.comparables.isEmpty)
        XCTAssertFalse(result.keyDrivers.isEmpty)
        XCTAssertFalse(result.risks.isEmpty)
    }
    
    func testCalculateValuationWithoutComparables() async throws {
        // Given
        mockComparablesService.shouldReturnEmptyResults = true
        
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: [])
        
        // Then
        XCTAssertGreaterThanOrEqual(result.baseValuation, 0)
        XCTAssertEqual(result.companyId, sampleCompany.id)
        XCTAssertFalse(result.scenarios.isEmpty)
    }
    
    func testValuationResultProperties() async throws {
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertFalse(result.valuationRange.isEmpty)
        XCTAssertGreaterThan(result.probabilityWeightedValuation, 0)
        
        // Verify valuation range makes sense
        let scenarios = result.scenarios
        if !scenarios.isEmpty {
            let minScenario = scenarios.min { $0.valuation < $1.valuation }!
            let maxScenario = scenarios.max { $0.valuation < $1.valuation }!
            XCTAssertEqual(result.valuationRange.lowerBound, minScenario.valuation)
            XCTAssertEqual(result.valuationRange.upperBound, maxScenario.valuation)
        }
    }
    
    // MARK: - Scenario Generation Tests
    
    func testGenerateScenarios() {
        // Given
        let baseValuation = 1000.0
        let marketConditions = MarketConditions(
            biotechIndex: 1000.0,
            ipoActivity: .moderate,
            fundingEnvironment: .moderate,
            regulatoryClimate: .neutral
        )
        
        // When
        let scenarios = engine.generateScenarios(
            baseValuation: baseValuation,
            company: sampleCompany,
            marketConditions: marketConditions
        )
        
        // Then
        XCTAssertGreaterThanOrEqual(scenarios.count, 3) // At least Bear, Base, Bull
        
        // Verify scenario names
        let scenarioNames = scenarios.map(\.name)
        XCTAssertTrue(scenarioNames.contains("Bear Case"))
        XCTAssertTrue(scenarioNames.contains("Base Case"))
        XCTAssertTrue(scenarioNames.contains("Bull Case"))
        
        // Verify probabilities sum to reasonable range
        let totalProbability = scenarios.map(\.probability).reduce(0, +)
        XCTAssertGreaterThanOrEqual(totalProbability, 0.8)
        XCTAssertLessThanOrEqual(totalProbability, 1.2)
        
        // Verify valuation ordering (Bear < Base < Bull)
        if let bearCase = scenarios.first(where: { $0.name == "Bear Case" }),
           let baseCase = scenarios.first(where: { $0.name == "Base Case" }),
           let bullCase = scenarios.first(where: { $0.name == "Bull Case" }) {
            XCTAssertLessThan(bearCase.valuation, baseCase.valuation)
            XCTAssertLessThan(baseCase.valuation, bullCase.valuation)
        }
    }
    
    func testScenarioProperties() {
        // Given
        let baseValuation = 1000.0
        let marketConditions = MarketConditions(
            biotechIndex: 1000.0,
            ipoActivity: .moderate,
            fundingEnvironment: .moderate,
            regulatoryClimate: .neutral
        )
        
        // When
        let scenarios = engine.generateScenarios(
            baseValuation: baseValuation,
            company: sampleCompany,
            marketConditions: marketConditions
        )
        
        // Then
        for scenario in scenarios {
            XCTAssertFalse(scenario.name.isEmpty)
            XCTAssertFalse(scenario.description.isEmpty)
            XCTAssertGreaterThan(scenario.valuation, 0)
            XCTAssertGreaterThan(scenario.probability, 0)
            XCTAssertLessThanOrEqual(scenario.probability, 1.0)
            XCTAssertFalse(scenario.keyAssumptions.isEmpty)
            XCTAssertGreaterThan(scenario.timeline, 0)
            
            // Test risk-adjusted valuation
            XCTAssertEqual(scenario.riskAdjustedValuation, scenario.valuation * scenario.probability)
            
            // Test market conditions attractiveness score
            XCTAssertGreaterThan(scenario.marketConditions.attractivenessScore, 0)
            XCTAssertLessThanOrEqual(scenario.marketConditions.attractivenessScore, 1.0)
        }
    }
    
    func testIPOScenarioForLateStageCompany() {
        // Given
        var lateStageCompany = sampleCompany!
        lateStageCompany.basicInfo.stage = .phase3
        
        let baseValuation = 1000.0
        let marketConditions = MarketConditions(
            biotechIndex: 1000.0,
            ipoActivity: .moderate,
            fundingEnvironment: .moderate,
            regulatoryClimate: .neutral
        )
        
        // When
        let scenarios = engine.generateScenarios(
            baseValuation: baseValuation,
            company: lateStageCompany,
            marketConditions: marketConditions
        )
        
        // Then
        let ipoScenario = scenarios.first { $0.name == "IPO Scenario" }
        XCTAssertNotNil(ipoScenario)
        XCTAssertEqual(ipoScenario?.exitStrategy, .ipo)
    }
    
    // MARK: - Methodology-Specific Tests
    
    func testComparableTransactionMethodology() {
        // When
        let calculation = engine.calculateValuationByMethodology(
            company: sampleCompany,
            comparables: sampleComparables,
            methodology: .comparableTransactions
        )
        
        // Then
        XCTAssertEqual(calculation.methodology, .comparableTransactions)
        XCTAssertGreaterThan(calculation.baseValue, 0)
        XCTAssertGreaterThan(calculation.finalValue, 0)
        XCTAssertGreaterThan(calculation.confidence, 0)
        XCTAssertFalse(calculation.assumptions.isEmpty)
        XCTAssertFalse(calculation.limitations.isEmpty)
    }
    
    func testRiskAdjustedNPVMethodology() {
        // When
        let calculation = engine.calculateValuationByMethodology(
            company: sampleCompany,
            comparables: sampleComparables,
            methodology: .riskAdjustedNPV
        )
        
        // Then
        XCTAssertEqual(calculation.methodology, .riskAdjustedNPV)
        XCTAssertGreaterThan(calculation.baseValue, 0)
        XCTAssertGreaterThan(calculation.finalValue, 0)
        XCTAssertGreaterThan(calculation.confidence, 0)
        XCTAssertFalse(calculation.adjustments.isEmpty)
        
        // Verify risk adjustments are present
        let adjustmentNames = calculation.adjustments.map(\.name)
        XCTAssertTrue(adjustmentNames.contains { $0.contains("Clinical Risk") })
        XCTAssertTrue(adjustmentNames.contains { $0.contains("Competitive Risk") })
        XCTAssertTrue(adjustmentNames.contains { $0.contains("Regulatory Risk") })
    }
    
    func testMarketMultiplesMethodology() {
        // When
        let calculation = engine.calculateValuationByMethodology(
            company: sampleCompany,
            comparables: sampleComparables,
            methodology: .marketMultiples
        )
        
        // Then
        XCTAssertEqual(calculation.methodology, .marketMultiples)
        XCTAssertGreaterThan(calculation.baseValue, 0)
        XCTAssertGreaterThan(calculation.finalValue, 0)
        XCTAssertGreaterThan(calculation.confidence, 0)
    }
    
    func testValuationWithNoComparables() {
        // When
        let calculation = engine.calculateValuationByMethodology(
            company: sampleCompany,
            comparables: [],
            methodology: .comparableTransactions
        )
        
        // Then
        XCTAssertEqual(calculation.methodology, .comparableTransactions)
        XCTAssertEqual(calculation.baseValue, 0)
        XCTAssertEqual(calculation.finalValue, 0)
        XCTAssertLessThan(calculation.confidence, 0.5)
        XCTAssertTrue(calculation.assumptions.contains { $0.contains("No comparable") })
    }
    
    // MARK: - Confidence Calculation Tests
    
    func testCalculateValuationConfidenceWithGoodComparables() {
        // Given
        let highQualityComparables = sampleComparables.map { comparable in
            var updated = comparable
            updated.confidence = 0.9
            updated.date = Calendar.current.date(byAdding: .month, value: -6, to: Date())! // Recent
            return updated
        }
        
        // When
        let confidence = engine.calculateValuationConfidence(
            comparables: highQualityComparables,
            company: sampleCompany
        )
        
        // Then
        XCTAssertGreaterThan(confidence, 0.7)
        XCTAssertLessThanOrEqual(confidence, 1.0)
    }
    
    func testCalculateValuationConfidenceWithPoorComparables() {
        // Given
        let lowQualityComparables = sampleComparables.map { comparable in
            var updated = comparable
            updated.confidence = 0.3
            updated.date = Calendar.current.date(byAdding: .year, value: -6, to: Date())! // Old
            return updated
        }
        
        // When
        let confidence = engine.calculateValuationConfidence(
            comparables: lowQualityComparables,
            company: sampleCompany
        )
        
        // Then
        XCTAssertLessThan(confidence, 0.6)
        XCTAssertGreaterThan(confidence, 0.1)
    }
    
    func testCalculateValuationConfidenceWithNoComparables() {
        // When
        let confidence = engine.calculateValuationConfidence(
            comparables: [],
            company: sampleCompany
        )
        
        // Then
        XCTAssertEqual(confidence, 0.3)
    }
    
    func testConfidenceAdjustmentForCompanyStage() {
        // Given
        var earlyStageCompany = sampleCompany!
        earlyStageCompany.basicInfo.stage = .preclinical
        
        var lateStageCompany = sampleCompany!
        lateStageCompany.basicInfo.stage = .phase3
        
        // When
        let earlyConfidence = engine.calculateValuationConfidence(
            comparables: sampleComparables,
            company: earlyStageCompany
        )
        let lateConfidence = engine.calculateValuationConfidence(
            comparables: sampleComparables,
            company: lateStageCompany
        )
        
        // Then
        XCTAssertLessThan(earlyConfidence, lateConfidence)
    }
    
    // MARK: - Valuation Summary Tests
    
    func testGenerateValuationSummary() async throws {
        // Given
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // When
        let summary = engine.generateValuationSummary(result: result)
        
        // Then
        XCTAssertEqual(summary.baseCase, result.baseValuation)
        XCTAssertGreaterThan(summary.bearCase, 0)
        XCTAssertGreaterThan(summary.bullCase, 0)
        XCTAssertLessThan(summary.bearCase, summary.baseCase)
        XCTAssertLessThan(summary.baseCase, summary.bullCase)
        XCTAssertEqual(summary.methodology, result.methodology.rawValue)
        XCTAssertEqual(summary.confidence, result.confidence)
    }
    
    // MARK: - Valuation Drivers Tests
    
    func testValuationDriversIdentification() async throws {
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertFalse(result.keyDrivers.isEmpty)
        
        let driverNames = result.keyDrivers.map(\.name)
        XCTAssertTrue(driverNames.contains("Addressable Market Size"))
        XCTAssertTrue(driverNames.contains("Development Stage"))
        XCTAssertTrue(driverNames.contains("Financial Runway"))
        XCTAssertTrue(driverNames.contains("Pipeline Breadth"))
        
        // Verify driver properties
        for driver in result.keyDrivers {
            XCTAssertFalse(driver.name.isEmpty)
            XCTAssertFalse(driver.description.isEmpty)
            XCTAssertGreaterThan(driver.confidence, 0)
            XCTAssertLessThanOrEqual(driver.confidence, 1.0)
        }
    }
    
    func testValuationDriverImpactCalculation() async throws {
        // Given
        var largeMarketCompany = sampleCompany!
        largeMarketCompany.market.addressableMarket = 25.0 // Large market
        
        // When
        let result = try await engine.calculateValuation(company: largeMarketCompany, comparables: sampleComparables)
        
        // Then
        let marketDriver = result.keyDrivers.first { $0.name == "Addressable Market Size" }
        XCTAssertNotNil(marketDriver)
        XCTAssertEqual(marketDriver?.impact, .veryPositive)
    }
    
    // MARK: - Valuation Risks Tests
    
    func testValuationRisksIdentification() async throws {
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertFalse(result.risks.isEmpty)
        
        let riskNames = result.risks.map(\.name)
        XCTAssertTrue(riskNames.contains("Clinical Development Risk"))
        XCTAssertTrue(riskNames.contains("Regulatory Approval Risk"))
        XCTAssertTrue(riskNames.contains("Competitive Threat"))
        XCTAssertTrue(riskNames.contains("Funding Risk"))
        
        // Verify risk properties
        for risk in result.risks {
            XCTAssertFalse(risk.name.isEmpty)
            XCTAssertGreaterThan(risk.probability, 0)
            XCTAssertLessThanOrEqual(risk.probability, 1.0)
            XCTAssertGreaterThan(risk.impact, 0)
            XCTAssertLessThanOrEqual(risk.impact, 1.0)
        }
    }
    
    func testRiskProbabilityByStage() async throws {
        // Given
        var preclinicalCompany = sampleCompany!
        preclinicalCompany.basicInfo.stage = .preclinical
        
        var phase3Company = sampleCompany!
        phase3Company.basicInfo.stage = .phase3
        
        // When
        let preclinicalResult = try await engine.calculateValuation(company: preclinicalCompany, comparables: sampleComparables)
        let phase3Result = try await engine.calculateValuation(company: phase3Company, comparables: sampleComparables)
        
        // Then
        let preclinicalClinicalRisk = preclinicalResult.risks.first { $0.name == "Clinical Development Risk" }
        let phase3ClinicalRisk = phase3Result.risks.first { $0.name == "Clinical Development Risk" }
        
        XCTAssertNotNil(preclinicalClinicalRisk)
        XCTAssertNotNil(phase3ClinicalRisk)
        XCTAssertGreaterThan(preclinicalClinicalRisk!.probability, phase3ClinicalRisk!.probability)
    }
    
    func testFinancialRiskBasedOnRunway() async throws {
        // Given
        var lowCashCompany = sampleCompany!
        lowCashCompany.financials = CompanyData.Financials(
            cashPosition: 20.0,
            burnRate: 10.0, // 2 months runway
            lastFunding: nil
        )
        
        // When
        let result = try await engine.calculateValuation(company: lowCashCompany, comparables: sampleComparables)
        
        // Then
        let fundingRisk = result.risks.first { $0.name == "Funding Risk" }
        XCTAssertNotNil(fundingRisk)
        XCTAssertGreaterThan(fundingRisk!.probability, 0.6) // High probability for low runway
    }
    
    // MARK: - Edge Cases Tests
    
    func testValuationWithZeroMarketSize() async throws {
        // Given
        var zeroMarketCompany = sampleCompany!
        zeroMarketCompany.market.addressableMarket = 0.0
        
        // When
        let result = try await engine.calculateValuation(company: zeroMarketCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertGreaterThanOrEqual(result.baseValuation, 0)
        XCTAssertLessThan(result.confidence, 0.5) // Should have low confidence
    }
    
    func testValuationWithNegativeFinancials() async throws {
        // Given
        var negativeFinancialsCompany = sampleCompany!
        negativeFinancialsCompany.financials = CompanyData.Financials(
            cashPosition: 0.0,
            burnRate: 0.0,
            lastFunding: nil
        )
        
        // When
        let result = try await engine.calculateValuation(company: negativeFinancialsCompany, comparables: sampleComparables)
        
        // Then
        XCTAssertGreaterThanOrEqual(result.baseValuation, 0)
        
        // Should have high funding risk
        let fundingRisk = result.risks.first { $0.name == "Funding Risk" }
        XCTAssertNotNil(fundingRisk)
        XCTAssertGreaterThan(fundingRisk!.probability, 0.5)
    }
    
    func testValuationWithManyCompetitors() async throws {
        // Given
        var competitiveCompany = sampleCompany!
        competitiveCompany.market.competitors = Array(0..<10).map { i in
            Competitor(
                name: "Competitor \(i)",
                stage: .phase3,
                marketShare: 0.1,
                strengths: ["Established"],
                weaknesses: ["Old tech"]
            )
        }
        
        // When
        let result = try await engine.calculateValuation(company: competitiveCompany, comparables: sampleComparables)
        
        // Then
        let competitiveRisk = result.risks.first { $0.name == "Competitive Threat" }
        XCTAssertNotNil(competitiveRisk)
        XCTAssertGreaterThan(competitiveRisk!.probability, 0.5) // High competitive risk
    }
    
    // MARK: - Performance Tests
    
    func testValuationPerformance() async throws {
        // Given
        let startTime = Date()
        
        // When
        _ = try await engine.calculateValuation(company: sampleCompany, comparables: sampleComparables)
        
        // Then
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
    }
    
    func testScenarioGenerationPerformance() {
        // Given
        let startTime = Date()
        let marketConditions = MarketConditions(
            biotechIndex: 1000.0,
            ipoActivity: .moderate,
            fundingEnvironment: .moderate,
            regulatoryClimate: .neutral
        )
        
        // When
        _ = engine.generateScenarios(baseValuation: 1000.0, company: sampleCompany, marketConditions: marketConditions)
        
        // Then
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 0.1) // Should complete within 100ms
    }
    
    // MARK: - Integration Tests
    
    func testFullValuationWorkflow() async throws {
        // Given
        mockComparablesService.mockComparables = sampleComparables
        
        // When
        let result = try await engine.calculateValuation(company: sampleCompany, comparables: [])
        let summary = engine.generateValuationSummary(result: result)
        
        // Then
        XCTAssertGreaterThan(result.baseValuation, 0)
        XCTAssertGreaterThan(result.confidence, 0)
        XCTAssertFalse(result.scenarios.isEmpty)
        XCTAssertFalse(result.keyDrivers.isEmpty)
        XCTAssertFalse(result.risks.isEmpty)
        
        XCTAssertEqual(summary.baseCase, result.baseValuation)
        XCTAssertGreaterThan(summary.bearCase, 0)
        XCTAssertGreaterThan(summary.bullCase, 0)
    }
}

// MARK: - Mock Comparables Service

class MockComparablesService: ComparablesService {
    var mockComparables: [Comparable] = []
    var shouldReturnEmptyResults = false
    
    func searchComparables(criteria: ComparableCriteria) async throws -> ComparableSearchResult {
        if shouldReturnEmptyResults {
            return ComparableSearchResult(
                comparables: [],
                totalFound: 0,
                searchCriteria: criteria,
                averageConfidence: 0.0,
                searchTimestamp: Date()
            )
        }
        
        let matches = mockComparables.map { comparable in
            ComparableMatch(
                comparable: comparable,
                similarity: 0.8,
                matchingFactors: MatchingFactors(
                    therapeuticAreaMatch: 0.8,
                    stageMatch: 0.8,
                    marketSizeMatch: 0.7,
                    mechanismMatch: 0.6,
                    competitivePositionMatch: 0.7,
                    timeRelevance: 0.8,
                    financialSimilarity: 0.6
                ),
                confidence: comparable.confidence
            )
        }
        
        return ComparableSearchResult(
            comparables: matches,
            totalFound: matches.count,
            searchCriteria: criteria,
            averageConfidence: matches.isEmpty ? 0.0 : matches.map(\.confidence).reduce(0, +) / Double(matches.count),
            searchTimestamp: Date()
        )
    }
    
    func findComparablesForCompany(_ company: CompanyData, maxResults: Int) async throws -> ComparableSearchResult {
        let criteria = ComparableCriteria.default
        let result = try await searchComparables(criteria: criteria)
        let limitedMatches = Array(result.comparables.prefix(maxResults))
        
        return ComparableSearchResult(
            comparables: limitedMatches,
            totalFound: result.totalFound,
            searchCriteria: criteria,
            averageConfidence: result.averageConfidence,
            searchTimestamp: Date()
        )
    }
    
    func addComparable(_ comparable: Comparable) async throws {
        mockComparables.append(comparable)
    }
    
    func updateComparable(_ comparable: Comparable) async throws {
        if let index = mockComparables.firstIndex(where: { $0.id == comparable.id }) {
            mockComparables[index] = comparable
        }
    }
    
    func deleteComparable(id: UUID) async throws {
        mockComparables.removeAll { $0.id == id }
    }
    
    func getComparable(id: UUID) async throws -> Comparable? {
        return mockComparables.first { $0.id == id }
    }
    
    func getAllComparables() async throws -> [Comparable] {
        return mockComparables
    }
    
    func validateComparable(_ comparable: Comparable) -> ComparableValidation {
        return ComparableValidation(
            isValid: true,
            completeness: 0.8,
            confidence: comparable.confidence,
            issues: [],
            recommendations: []
        )
    }
    
    func calculateSimilarity(company: CompanyData, comparable: Comparable) -> Double {
        return 0.8 // Mock similarity
    }
    
    func getDatabaseAnalytics() async throws -> ComparablesAnalytics {
        return ComparablesAnalytics(
            totalComparables: mockComparables.count,
            byTransactionType: [:],
            byTherapeuticArea: [:],
            byStage: [:],
            averageValuation: 1000.0,
            medianValuation: 1000.0,
            valuationRange: 500.0...1500.0,
            dataFreshness: DataFreshness(
                averageAge: 2.0,
                recentTransactions: mockComparables.count,
                oldestTransaction: Date(),
                newestTransaction: Date()
            ),
            qualityMetrics: QualityMetrics(
                averageConfidence: 0.8,
                highConfidenceCount: mockComparables.count,
                completeRecords: mockComparables.count,
                verifiedTransactions: mockComparables.count
            )
        )
    }
}