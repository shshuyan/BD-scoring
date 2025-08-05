import XCTest
@testable import BDScoringModule

class EndToEndTests: XCTestCase {
    var scoringEngine: BDScoringEngine!
    var reportGenerator: ReportGenerator!
    var comparablesService: ComparablesService!
    var validationService: ValidationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize services
        validationService = ValidationService()
        scoringEngine = BDScoringEngine(validationService: validationService)
        reportGenerator = ReportGenerator()
        comparablesService = ComparablesService()
        
        // Clear any existing cache
        await MainActor.run {
            CachingService.shared.clearAll()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            CachingService.shared.clearAll()
        }
        try await super.tearDown()
    }
    
    // MARK: - Complete User Workflow Tests
    
    func testCompleteEvaluationWorkflow() async throws {
        // Test the complete workflow from company data input to final report
        
        // Step 1: Create company data
        let companyData = createComprehensiveCompanyData()
        
        // Step 2: Validate company data
        let validationResult = validationService.validateCompanyData(companyData)
        XCTAssertTrue(validationResult.isValid, "Company data should be valid")
        XCTAssertGreaterThan(validationResult.completeness, 0.8, "Data completeness should be high")
        
        // Step 3: Create scoring configuration
        let config = createCustomScoringConfig()
        
        // Step 4: Perform scoring evaluation
        let scoringResult = try await scoringEngine.evaluateCompany(companyData, config: config)
        
        // Verify scoring results
        XCTAssertGreaterThan(scoringResult.overallScore, 0)
        XCTAssertLessThanOrEqual(scoringResult.overallScore, 5.0)
        XCTAssertNotNil(scoringResult.investmentRecommendation)
        XCTAssertNotNil(scoringResult.riskLevel)
        XCTAssertFalse(scoringResult.recommendations.isEmpty)
        
        // Verify all pillar scores are present
        XCTAssertGreaterThan(scoringResult.pillarScores.assetQuality.rawScore, 0)
        XCTAssertGreaterThan(scoringResult.pillarScores.marketOutlook.rawScore, 0)
        XCTAssertGreaterThan(scoringResult.pillarScores.capitalIntensity.rawScore, 0)
        XCTAssertGreaterThan(scoringResult.pillarScores.strategicFit.rawScore, 0)
        XCTAssertGreaterThan(scoringResult.pillarScores.financialReadiness.rawScore, 0)
        XCTAssertGreaterThan(scoringResult.pillarScores.regulatoryRisk.rawScore, 0)
        
        // Step 5: Generate comprehensive report
        let report = try await reportGenerator.generateDetailedReport(scoringResult)
        
        // Verify report structure
        XCTAssertEqual(report.companyId, companyData.id)
        XCTAssertEqual(report.companyName, companyData.basicInfo.name)
        XCTAssertNotNil(report.executiveSummary)
        XCTAssertNotNil(report.detailedAnalysis)
        XCTAssertFalse(report.content.isEmpty)
        
        // Verify executive summary
        let execSummary = report.executiveSummary
        XCTAssertEqual(execSummary.overallScore, scoringResult.overallScore)
        XCTAssertEqual(execSummary.investmentRecommendation, scoringResult.investmentRecommendation)
        XCTAssertFalse(execSummary.keyFindings.isEmpty)
        XCTAssertFalse(execSummary.investmentThesis.isEmpty)
        
        // Step 6: Test comparables integration
        let criteria = ComparableCriteria(
            therapeuticArea: companyData.basicInfo.therapeuticAreas.first ?? "Oncology",
            stage: companyData.basicInfo.stage,
            marketSize: companyData.market.addressableMarket
        )
        
        let comparables = try await comparablesService.findComparables(criteria: criteria)
        XCTAssertNotNil(comparables)
        
        print("✅ Complete evaluation workflow test passed")
        print("   - Company: \(companyData.basicInfo.name)")
        print("   - Overall Score: \(String(format: "%.2f", scoringResult.overallScore))")
        print("   - Recommendation: \(scoringResult.investmentRecommendation.rawValue)")
        print("   - Risk Level: \(scoringResult.riskLevel.rawValue)")
        print("   - Report Length: \(report.content.count) characters")
    }
    
    func testMultiCompanyBatchWorkflow() async throws {
        // Test batch processing of multiple companies
        let companies = createMultipleCompanyDatasets()
        let config = createStandardScoringConfig()
        
        var results: [ScoringResult] = []
        var reports: [Report] = []
        
        // Process each company
        for company in companies {
            // Score the company
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            results.append(result)
            
            // Generate report
            let report = try await reportGenerator.generateDetailedReport(result)
            reports.append(report)
        }
        
        // Verify all companies were processed
        XCTAssertEqual(results.count, companies.count)
        XCTAssertEqual(reports.count, companies.count)
        
        // Verify score distribution is reasonable
        let scores = results.map { $0.overallScore }
        let averageScore = scores.reduce(0, +) / Double(scores.count)
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0
        
        XCTAssertGreaterThan(averageScore, 1.0)
        XCTAssertLessThan(averageScore, 5.0)
        XCTAssertGreaterThan(maxScore - minScore, 0.5, "Should have score variation")
        
        // Test batch statistics
        let statistics = scoringEngine.getScoringStatistics(results)
        XCTAssertEqual(statistics.totalCompanies, companies.count)
        XCTAssertEqual(statistics.averageScore, averageScore, accuracy: 0.01)
        XCTAssertFalse(statistics.scoreDistribution.isEmpty)
        
        print("✅ Multi-company batch workflow test passed")
        print("   - Companies processed: \(companies.count)")
        print("   - Average score: \(String(format: "%.2f", averageScore))")
        print("   - Score range: \(String(format: "%.2f", minScore)) - \(String(format: "%.2f", maxScore))")
    }
    
    func testUserJourneyWithDataValidation() async throws {
        // Test user journey with incomplete data and validation feedback
        
        // Step 1: Start with incomplete company data
        var incompleteData = createIncompleteCompanyData()
        
        // Step 2: Validate and get feedback
        let initialValidation = validationService.validateCompanyData(incompleteData)
        XCTAssertFalse(initialValidation.isValid)
        XCTAssertFalse(initialValidation.errors.isEmpty)
        XCTAssertLessThan(initialValidation.completeness, 0.7)
        
        // Step 3: User addresses validation issues
        incompleteData = improveCompanyDataBasedOnValidation(incompleteData, validation: initialValidation)
        
        // Step 4: Re-validate improved data
        let improvedValidation = validationService.validateCompanyData(incompleteData)
        XCTAssertTrue(improvedValidation.isValid || improvedValidation.errors.allSatisfy { $0.severity != .critical })
        XCTAssertGreaterThan(improvedValidation.completeness, initialValidation.completeness)
        
        // Step 5: Proceed with scoring
        let config = createStandardScoringConfig()
        let result = try await scoringEngine.evaluateCompany(incompleteData, config: config)
        
        // Verify scoring works with improved data
        XCTAssertGreaterThan(result.overallScore, 0)
        XCTAssertLessThan(result.confidence.overall, 1.0) // Should reflect data limitations
        
        // Step 6: Generate report with confidence indicators
        let report = try await reportGenerator.generateDetailedReport(result)
        XCTAssertTrue(report.content.contains("confidence") || report.content.contains("data"))
        
        print("✅ User journey with data validation test passed")
        print("   - Initial completeness: \(String(format: "%.1f", initialValidation.completeness * 100))%")
        print("   - Improved completeness: \(String(format: "%.1f", improvedValidation.completeness * 100))%")
        print("   - Final confidence: \(String(format: "%.1f", result.confidence.overall * 100))%")
    }
    
    func testConfigurationCustomizationWorkflow() async throws {
        // Test workflow with different scoring configurations
        let companyData = createStandardCompanyData()
        
        // Test different weight configurations
        let configurations = [
            ("Conservative", createConservativeConfig()),
            ("Aggressive", createAggressiveConfig()),
            ("Balanced", createBalancedConfig())
        ]
        
        var configResults: [(String, ScoringResult)] = []
        
        for (name, config) in configurations {
            let result = try await scoringEngine.evaluateCompany(companyData, config: config)
            configResults.append((name, result))
        }
        
        // Verify different configurations produce different results
        let scores = configResults.map { $0.1.overallScore }
        let scoreRange = (scores.max() ?? 0) - (scores.min() ?? 0)
        XCTAssertGreaterThan(scoreRange, 0.1, "Different configurations should produce different scores")
        
        // Verify all results are valid
        for (name, result) in configResults {
            XCTAssertGreaterThan(result.overallScore, 0, "\(name) config should produce valid score")
            XCTAssertLessThanOrEqual(result.overallScore, 5.0, "\(name) config should not exceed max score")
        }
        
        print("✅ Configuration customization workflow test passed")
        for (name, result) in configResults {
            print("   - \(name): \(String(format: "%.2f", result.overallScore))")
        }
    }
    
    func testErrorHandlingAndRecovery() async throws {
        // Test system behavior with various error conditions
        
        // Test 1: Invalid company data
        let invalidData = createInvalidCompanyData()
        
        do {
            _ = try await scoringEngine.evaluateCompany(invalidData, config: createStandardScoringConfig())
            XCTFail("Should have thrown error for invalid data")
        } catch {
            XCTAssertTrue(error is ScoringError, "Should throw ScoringError")
        }
        
        // Test 2: Invalid configuration
        let validData = createStandardCompanyData()
        let invalidConfig = createInvalidScoringConfig()
        
        do {
            _ = try await scoringEngine.evaluateCompany(validData, config: invalidConfig)
            XCTFail("Should have thrown error for invalid config")
        } catch {
            XCTAssertTrue(error is ScoringError, "Should throw ScoringError")
        }
        
        // Test 3: System recovery after errors
        let validConfig = createStandardScoringConfig()
        let validResult = try await scoringEngine.evaluateCompany(validData, config: validConfig)
        XCTAssertGreaterThan(validResult.overallScore, 0, "System should recover and work normally")
        
        print("✅ Error handling and recovery test passed")
    }
    
    // MARK: - Integration Tests
    
    func testServiceIntegration() async throws {
        // Test integration between all major services
        let companyData = createStandardCompanyData()
        let config = createStandardScoringConfig()
        
        // Test scoring engine integration
        let scoringResult = try await scoringEngine.evaluateCompany(companyData, config: config)
        
        // Test report generator integration
        let report = try await reportGenerator.generateDetailedReport(scoringResult)
        
        // Test comparables service integration
        let criteria = ComparableCriteria(
            therapeuticArea: "Oncology",
            stage: .phaseII,
            marketSize: 1000000000
        )
        let comparables = try await comparablesService.findComparables(criteria: criteria)
        
        // Verify all services work together
        XCTAssertNotNil(scoringResult)
        XCTAssertNotNil(report)
        XCTAssertNotNil(comparables)
        
        print("✅ Service integration test passed")
    }
    
    func testCachingIntegration() async throws {
        // Test caching integration across the workflow
        let companyData = createStandardCompanyData()
        let config = createStandardScoringConfig()
        
        // First evaluation (cache miss)
        let startTime1 = Date()
        let result1 = try await scoringEngine.evaluateCompany(companyData, config: config)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second evaluation (cache hit)
        let startTime2 = Date()
        let result2 = try await scoringEngine.evaluateCompany(companyData, config: config)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        // Verify results are identical
        XCTAssertEqual(result1.overallScore, result2.overallScore, accuracy: 0.001)
        XCTAssertEqual(result1.companyId, result2.companyId)
        
        // Verify caching improved performance
        XCTAssertLessThan(duration2, duration1 * 0.5, "Cached result should be significantly faster")
        
        print("✅ Caching integration test passed")
        print("   - First evaluation: \(String(format: "%.3f", duration1))s")
        print("   - Cached evaluation: \(String(format: "%.3f", duration2))s")
        print("   - Performance improvement: \(String(format: "%.1f", (duration1 - duration2) / duration1 * 100))%")
    }
    
    // MARK: - Helper Methods
    
    private func createComprehensiveCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Comprehensive Biotech Inc",
                ticker: "COMP",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phaseII,
                description: "Leading biotech company with innovative pipeline"
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "COMP-001",
                        indication: "Non-Small Cell Lung Cancer",
                        stage: .phaseII,
                        mechanism: "PD-L1 Inhibitor",
                        differentiators: ["Best-in-class efficacy", "Improved safety profile"],
                        risks: [Risk(type: "Clinical", description: "Efficacy risk", probability: 0.3)],
                        timeline: [
                            Milestone(name: "Phase II Results", date: Date().addingTimeInterval(180 * 24 * 3600)),
                            Milestone(name: "Phase III Start", date: Date().addingTimeInterval(365 * 24 * 3600))
                        ]
                    ),
                    Program(
                        name: "COMP-002",
                        indication: "Breast Cancer",
                        stage: .phase1,
                        mechanism: "ADC",
                        differentiators: ["Novel target"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 2
            ),
            financials: CompanyFinancials(
                cashPosition: 125000000,
                burnRate: 8000000,
                lastFunding: FundingRound(
                    amount: 150000000,
                    date: Date().addingTimeInterval(-90 * 24 * 3600),
                    type: "Series C"
                ),
                runway: 15
            ),
            market: CompanyMarket(
                addressableMarket: 12000000000,
                competitors: [
                    Competitor(name: "Big Pharma A", marketShare: 0.25, strengths: ["Established presence"]),
                    Competitor(name: "Biotech B", marketShare: 0.15, strengths: ["Similar mechanism"])
                ],
                marketDynamics: MarketDynamics(
                    growthRate: 0.18,
                    competitiveIntensity: "High"
                )
            ),
            regulatory: CompanyRegulatory(
                approvals: [
                    Approval(type: .fastTrack, date: Date().addingTimeInterval(-30 * 24 * 3600), indication: "NSCLC")
                ],
                clinicalTrials: [
                    ClinicalTrial(
                        phase: .phaseII,
                        status: "Active",
                        enrollment: 300,
                        primaryEndpoint: "Overall Response Rate"
                    )
                ],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: "Accelerated Approval",
                    timeline: 30,
                    risks: ["Regulatory delay"]
                )
            )
        )
    }
    
    private func createMultipleCompanyDatasets() -> [CompanyData] {
        return [
            createEarlyStageCompany(),
            createLateStageCompany(),
            createWellFundedCompany(),
            createCashConstrainedCompany(),
            createDiversifiedPipelineCompany()
        ]
    }
    
    private func createEarlyStageCompany() -> CompanyData {
        var data = createStandardCompanyData()
        data.basicInfo.name = "Early Stage Biotech"
        data.basicInfo.stage = .preclinical
        data.financials.cashPosition = 25000000
        data.financials.runway = 8
        return data
    }
    
    private func createLateStageCompany() -> CompanyData {
        var data = createStandardCompanyData()
        data.basicInfo.name = "Late Stage Biotech"
        data.basicInfo.stage = .phase3
        data.financials.cashPosition = 200000000
        data.financials.runway = 24
        return data
    }
    
    private func createWellFundedCompany() -> CompanyData {
        var data = createStandardCompanyData()
        data.basicInfo.name = "Well Funded Biotech"
        data.financials.cashPosition = 300000000
        data.financials.burnRate = 10000000
        data.financials.runway = 30
        return data
    }
    
    private func createCashConstrainedCompany() -> CompanyData {
        var data = createStandardCompanyData()
        data.basicInfo.name = "Cash Constrained Biotech"
        data.financials.cashPosition = 15000000
        data.financials.burnRate = 3000000
        data.financials.runway = 5
        return data
    }
    
    private func createDiversifiedPipelineCompany() -> CompanyData {
        var data = createStandardCompanyData()
        data.basicInfo.name = "Diversified Pipeline Biotech"
        data.pipeline.totalPrograms = 5
        data.basicInfo.therapeuticAreas = ["Oncology", "Immunology", "Neurology"]
        return data
    }
    
    private func createStandardCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Standard Biotech Co",
                ticker: "STND",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phaseII
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "Standard Program",
                        indication: "Cancer",
                        stage: .phaseII,
                        mechanism: "Small Molecule",
                        differentiators: ["Novel approach"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 1
            ),
            financials: CompanyFinancials(
                cashPosition: 75000000,
                burnRate: 6000000,
                lastFunding: FundingRound(amount: 100000000, date: Date(), type: "Series B"),
                runway: 12
            ),
            market: CompanyMarket(
                addressableMarket: 8000000000,
                competitors: [],
                marketDynamics: MarketDynamics(growthRate: 0.12, competitiveIntensity: "Medium")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Standard", timeline: 36, risks: [])
            )
        )
    }
    
    private func createIncompleteCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Incomplete Biotech",
                ticker: nil,
                sector: "",
                therapeuticAreas: [],
                stage: .phaseII
            ),
            pipeline: CompanyPipeline(programs: [], totalPrograms: 0),
            financials: CompanyFinancials(
                cashPosition: 0,
                burnRate: 0,
                lastFunding: nil,
                runway: 0
            ),
            market: CompanyMarket(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: MarketDynamics(growthRate: 0, competitiveIntensity: "")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(pathway: "", timeline: 0, risks: [])
            )
        )
    }
    
    private func createInvalidCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "",
                ticker: nil,
                sector: "",
                therapeuticAreas: [],
                stage: .phaseII
            ),
            pipeline: CompanyPipeline(programs: [], totalPrograms: 0),
            financials: CompanyFinancials(
                cashPosition: -1000000,
                burnRate: -500000,
                lastFunding: nil,
                runway: -5
            ),
            market: CompanyMarket(
                addressableMarket: -1000000000,
                competitors: [],
                marketDynamics: MarketDynamics(growthRate: -0.5, competitiveIntensity: "")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(pathway: "", timeline: -10, risks: [])
            )
        )
    }
    
    private func improveCompanyDataBasedOnValidation(_ data: CompanyData, validation: ValidationResult) -> CompanyData {
        var improved = data
        
        // Address common validation issues
        if improved.basicInfo.sector.isEmpty {
            improved.basicInfo.sector = "Biotechnology"
        }
        
        if improved.basicInfo.therapeuticAreas.isEmpty {
            improved.basicInfo.therapeuticAreas = ["Oncology"]
        }
        
        if improved.pipeline.programs.isEmpty {
            improved.pipeline.programs = [
                Program(
                    name: "Lead Program",
                    indication: "Cancer",
                    stage: .phaseII,
                    mechanism: "Small Molecule",
                    differentiators: [],
                    risks: [],
                    timeline: []
                )
            ]
            improved.pipeline.totalPrograms = 1
        }
        
        if improved.financials.cashPosition <= 0 {
            improved.financials.cashPosition = 50000000
            improved.financials.burnRate = 5000000
            improved.financials.runway = 10
        }
        
        if improved.market.addressableMarket <= 0 {
            improved.market.addressableMarket = 5000000000
        }
        
        return improved
    }
    
    private func createCustomScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.30,
                marketOutlook: 0.25,
                capitalIntensity: 0.10,
                strategicFit: 0.15,
                financialReadiness: 0.15,
                regulatoryRisk: 0.05
            ),
            customParameters: ["riskTolerance": "high"]
        )
    }
    
    private func createStandardScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(),
            customParameters: [:]
        )
    }
    
    private func createConservativeConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.20,
                marketOutlook: 0.15,
                capitalIntensity: 0.20,
                strategicFit: 0.10,
                financialReadiness: 0.25,
                regulatoryRisk: 0.10
            ),
            customParameters: ["approach": "conservative"]
        )
    }
    
    private func createAggressiveConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.35,
                marketOutlook: 0.30,
                capitalIntensity: 0.05,
                strategicFit: 0.20,
                financialReadiness: 0.05,
                regulatoryRisk: 0.05
            ),
            customParameters: ["approach": "aggressive"]
        )
    }
    
    private func createBalancedConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.25,
                marketOutlook: 0.20,
                capitalIntensity: 0.15,
                strategicFit: 0.15,
                financialReadiness: 0.15,
                regulatoryRisk: 0.10
            ),
            customParameters: ["approach": "balanced"]
        )
    }
    
    private func createInvalidScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.50,
                marketOutlook: 0.30,
                capitalIntensity: 0.20,
                strategicFit: 0.15,
                financialReadiness: 0.10,
                regulatoryRisk: 0.05
            ), // Weights sum to > 1.0
            customParameters: [:]
        )
    }
}