import XCTest
@testable import BDScoringModule

final class CompanyDataValidationTests: XCTestCase {
    
    // MARK: - Test Data Helpers
    
    private func createValidCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech Inc.",
                ticker: "TBIO",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "A leading biotech company focused on innovative cancer treatments"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [createValidProgram()]
            ),
            financials: CompanyData.Financials(
                cashPosition: 150.0,
                burnRate: 10.0,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: 75.0,
                    date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                    investors: ["VC Fund A", "Strategic Partner B"]
                )
            ),
            market: CompanyData.Market(
                addressableMarket: 5.2,
                competitors: [
                    Competitor(
                        name: "Competitor A",
                        stage: .phase3,
                        marketShare: 15.0,
                        strengths: ["Strong IP", "Experienced team"],
                        weaknesses: ["Limited pipeline"]
                    )
                ],
                marketDynamics: MarketDynamics(
                    growthRate: 12.5,
                    barriers: ["High regulatory requirements"],
                    drivers: ["Aging population", "Unmet medical need"],
                    reimbursement: .favorable
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [createValidClinicalTrial()],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .fastTrack,
                    timeline: 36,
                    risks: ["Regulatory delays"],
                    mitigations: ["Early FDA engagement"]
                )
            )
        )
    }
    
    private func createValidProgram() -> Program {
        return Program(
            name: "TBIO-001",
            indication: "Non-small cell lung cancer",
            stage: .phase2,
            mechanism: "PD-1 inhibitor",
            differentiators: ["Novel binding site", "Improved safety profile"],
            risks: [
                Risk(
                    description: "Competitive landscape risk",
                    probability: .medium,
                    impact: .medium,
                    mitigation: "Differentiated mechanism of action"
                )
            ],
            timeline: [
                Milestone(
                    name: "Phase II initiation",
                    expectedDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                    status: .upcoming,
                    description: "Start Phase II clinical trial"
                )
            ]
        )
    }
    
    private func createValidClinicalTrial() -> ClinicalTrial {
        return ClinicalTrial(
            name: "TBIO-001-P2",
            phase: .phase2,
            indication: "NSCLC",
            status: .recruiting,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
            expectedCompletion: Calendar.current.date(byAdding: .month, value: 18, to: Date()),
            patientCount: 120
        )
    }
    
    // MARK: - Basic Info Validation Tests
    
    func testValidBasicInfo() {
        let companyData = createValidCompanyData()
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertGreaterThan(validation.completeness, 0.8)
    }
    
    func testMissingCompanyName() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.name = ""
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "basicInfo.name" })
        XCTAssertEqual(validation.errors.first { $0.field == "basicInfo.name" }?.severity, .critical)
    }
    
    func testMissingSector() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.sector = ""
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "basicInfo.sector" })
    }
    
    func testEmptyTherapeuticAreas() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.therapeuticAreas = []
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "basicInfo.therapeuticAreas" })
    }
    
    func testMissingTickerWarning() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.ticker = nil
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.isValid) // Should still be valid, just with warning
        XCTAssertTrue(validation.warnings.contains { $0.field == "basicInfo.ticker" })
    }
    
    // MARK: - Pipeline Validation Tests
    
    func testEmptyPipeline() {
        var companyData = createValidCompanyData()
        companyData.pipeline = CompanyData.Pipeline(programs: [])
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "pipeline.programs" })
        XCTAssertEqual(validation.errors.first { $0.field == "pipeline.programs" }?.severity, .critical)
    }
    
    func testProgramValidation() {
        var program = createValidProgram()
        program.name = ""
        
        var companyData = createValidCompanyData()
        companyData.pipeline = CompanyData.Pipeline(programs: [program])
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("pipeline.programs[0].name") })
    }
    
    func testProgramCompletenessWarnings() {
        var program = createValidProgram()
        program.differentiators = []
        program.risks = []
        program.timeline = []
        
        var companyData = createValidCompanyData()
        companyData.pipeline = CompanyData.Pipeline(programs: [program])
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.isValid) // Should be valid but with warnings
        XCTAssertGreaterThan(validation.warnings.count, 0)
        XCTAssertTrue(validation.warnings.contains { $0.field.contains("differentiators") })
        XCTAssertTrue(validation.warnings.contains { $0.field.contains("risks") })
        XCTAssertTrue(validation.warnings.contains { $0.field.contains("timeline") })
    }
    
    // MARK: - Financial Validation Tests
    
    func testNegativeCashPosition() {
        var companyData = createValidCompanyData()
        companyData.financials.cashPosition = -10.0
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "financials.cashPosition" })
    }
    
    func testZeroCashPositionWarning() {
        var companyData = createValidCompanyData()
        companyData.financials.cashPosition = 0.0
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "financials.cashPosition" })
    }
    
    func testNegativeBurnRate() {
        var companyData = createValidCompanyData()
        companyData.financials.burnRate = -5.0
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "financials.burnRate" })
    }
    
    func testShortRunwayWarning() {
        var companyData = createValidCompanyData()
        companyData.financials.cashPosition = 8.0  // 8 months runway
        companyData.financials.burnRate = 1.0
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "financials.runway" })
    }
    
    func testOldFundingWarning() {
        var companyData = createValidCompanyData()
        companyData.financials.lastFunding?.date = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "financials.lastFunding.date" })
    }
    
    func testInvalidFundingAmount() {
        var companyData = createValidCompanyData()
        companyData.financials.lastFunding?.amount = -10.0
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "financials.lastFunding.amount" })
    }
    
    // MARK: - Market Validation Tests
    
    func testNegativeAddressableMarket() {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = -1.0
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "market.addressableMarket" })
    }
    
    func testSmallMarketWarning() {
        var companyData = createValidCompanyData()
        companyData.market.addressableMarket = 0.05  // $50M market
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "market.addressableMarket" })
    }
    
    func testUnusualGrowthRateWarning() {
        var companyData = createValidCompanyData()
        companyData.market.marketDynamics.growthRate = 250.0  // 250% growth
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "market.marketDynamics.growthRate" })
    }
    
    func testNoCompetitorsWarning() {
        var companyData = createValidCompanyData()
        companyData.market.competitors = []
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "market.competitors" })
    }
    
    func testInvalidCompetitorMarketShare() {
        var companyData = createValidCompanyData()
        companyData.market.competitors[0].marketShare = 150.0  // 150% market share
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("marketShare") })
    }
    
    // MARK: - Regulatory Validation Tests
    
    func testNegativeRegulatoryTimeline() {
        var companyData = createValidCompanyData()
        companyData.regulatory.regulatoryStrategy.timeline = -12
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "regulatory.regulatoryStrategy.timeline" })
    }
    
    func testVeryLongTimelineWarning() {
        var companyData = createValidCompanyData()
        companyData.regulatory.regulatoryStrategy.timeline = 200  // 200 months
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field == "regulatory.regulatoryStrategy.timeline" })
    }
    
    func testClinicalTrialValidation() {
        var trial = createValidClinicalTrial()
        trial.name = ""
        trial.indication = ""
        
        var companyData = createValidCompanyData()
        companyData.regulatory.clinicalTrials = [trial]
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("name") })
        XCTAssertTrue(validation.errors.contains { $0.field.contains("indication") })
    }
    
    func testClinicalTrialDateValidation() {
        var trial = createValidClinicalTrial()
        trial.startDate = Date()
        trial.expectedCompletion = Calendar.current.date(byAdding: .month, value: -6, to: Date())! // Past date
        
        var companyData = createValidCompanyData()
        companyData.regulatory.clinicalTrials = [trial]
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("expectedCompletion") })
    }
    
    func testInvalidPatientCount() {
        var trial = createValidClinicalTrial()
        trial.patientCount = -10
        
        var companyData = createValidCompanyData()
        companyData.regulatory.clinicalTrials = [trial]
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field.contains("patientCount") })
    }
    
    func testPhase1PatientCountWarning() {
        var trial = createValidClinicalTrial()
        trial.phase = .phase1
        trial.patientCount = 150  // Large for Phase I
        
        var companyData = createValidCompanyData()
        companyData.regulatory.clinicalTrials = [trial]
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field.contains("patientCount") })
    }
    
    func testPhase3SmallPatientCountWarning() {
        var trial = createValidClinicalTrial()
        trial.phase = .phase3
        trial.patientCount = 50  // Small for Phase III
        
        var companyData = createValidCompanyData()
        companyData.regulatory.clinicalTrials = [trial]
        
        let validation = companyData.validate()
        
        XCTAssertTrue(validation.warnings.contains { $0.field.contains("patientCount") })
    }
    
    // MARK: - Completeness Tests
    
    func testCompletenessCalculation() {
        let companyData = createValidCompanyData()
        let validation = companyData.validate()
        
        XCTAssertGreaterThan(validation.completeness, 0.8)
        XCTAssertLessThanOrEqual(validation.completeness, 1.0)
    }
    
    func testIncompleteDataCompleteness() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.ticker = nil
        companyData.basicInfo.description = nil
        companyData.financials.lastFunding = nil
        companyData.market.competitors = []
        
        let validation = companyData.validate()
        
        XCTAssertLessThan(validation.completeness, 0.8)
        XCTAssertGreaterThan(validation.completeness, 0.0)
    }
    
    // MARK: - Edge Cases
    
    func testMinimalValidCompanyData() {
        let minimalData = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Minimal Biotech",
                ticker: nil,
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .preclinical,
                description: nil
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "MIN-001",
                        indication: "Cancer",
                        stage: .preclinical,
                        mechanism: "Unknown",
                        differentiators: [],
                        risks: [],
                        timeline: []
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 1.0,
                burnRate: 0.1,
                lastFunding: nil
            ),
            market: CompanyData.Market(
                addressableMarket: 1.0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 5.0,
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
                    timeline: 60,
                    risks: [],
                    mitigations: []
                )
            )
        )
        
        let validation = minimalData.validate()
        
        XCTAssertTrue(validation.isValid)
        XCTAssertGreaterThan(validation.warnings.count, 0) // Should have warnings for missing optional data
        XCTAssertLessThan(validation.completeness, 0.6) // Low completeness but still valid
    }
    
    func testMultipleValidationErrors() {
        var companyData = createValidCompanyData()
        companyData.basicInfo.name = ""
        companyData.basicInfo.sector = ""
        companyData.financials.cashPosition = -10.0
        companyData.market.addressableMarket = -1.0
        
        let validation = companyData.validate()
        
        XCTAssertFalse(validation.isValid)
        XCTAssertGreaterThanOrEqual(validation.errors.count, 4)
    }
}