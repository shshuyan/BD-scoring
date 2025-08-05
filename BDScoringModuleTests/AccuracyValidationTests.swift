import XCTest
@testable import BDScoringModule

class AccuracyValidationTests: XCTestCase {
    var scoringEngine: BDScoringEngine!
    var validationService: ValidationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        validationService = ValidationService()
        scoringEngine = BDScoringEngine(validationService: validationService)
        
        // Clear cache for clean testing
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
    
    // MARK: - Reference Company Validation Tests
    
    func testHighQualityCompanyAccuracy() async throws {
        // Test scoring accuracy for a high-quality reference company
        let referenceCompany = createHighQualityReferenceCompany()
        let expectedScoreRange = 4.0...5.0
        let expectedRecommendation: InvestmentRecommendation = .buy
        let expectedRiskLevel: RiskLevel = .low
        
        let config = createStandardScoringConfig()
        let result = try await scoringEngine.evaluateCompany(referenceCompany, config: config)
        
        // Validate overall score
        XCTAssertTrue(expectedScoreRange.contains(result.overallScore),
                     "High-quality company score \(result.overallScore) should be in range \(expectedScoreRange)")
        
        // Validate investment recommendation
        XCTAssertTrue([.buy, .strongBuy].contains(result.investmentRecommendation),
                     "High-quality company should have positive recommendation, got \(result.investmentRecommendation)")
        
        // Validate risk level
        XCTAssertTrue([.low, .medium].contains(result.riskLevel),
                     "High-quality company should have low-medium risk, got \(result.riskLevel)")
        
        // Validate pillar scores
        XCTAssertGreaterThan(result.pillarScores.assetQuality.rawScore, 3.5,
                           "Asset quality should be high for reference company")
        XCTAssertGreaterThan(result.pillarScores.financialReadiness.rawScore, 3.5,
                           "Financial readiness should be high for well-funded company")
        
        // Validate confidence
        XCTAssertGreaterThan(result.confidence.overall, 0.7,
                           "Confidence should be high for complete data")
        
        print("✅ High-quality company accuracy test passed")
        print("   - Score: \(String(format: "%.2f", result.overallScore))")
        print("   - Recommendation: \(result.investmentRecommendation.rawValue)")
        print("   - Risk: \(result.riskLevel.rawValue)")
        print("   - Confidence: \(String(format: "%.1f", result.confidence.overall * 100))%")
    }
    
    func testLowQualityCompanyAccuracy() async throws {
        // Test scoring accuracy for a low-quality reference company
        let referenceCompany = createLowQualityReferenceCompany()
        let expectedScoreRange = 1.0...2.5
        let expectedRecommendation: InvestmentRecommendation = .sell
        let expectedRiskLevel: RiskLevel = .high
        
        let config = createStandardScoringConfig()
        let result = try await scoringEngine.evaluateCompany(referenceCompany, config: config)
        
        // Validate overall score
        XCTAssertTrue(expectedScoreRange.contains(result.overallScore),
                     "Low-quality company score \(result.overallScore) should be in range \(expectedScoreRange)")
        
        // Validate investment recommendation
        XCTAssertTrue([.sell, .strongSell].contains(result.investmentRecommendation),
                     "Low-quality company should have negative recommendation, got \(result.investmentRecommendation)")
        
        // Validate risk level
        XCTAssertTrue([.high, .veryHigh].contains(result.riskLevel),
                     "Low-quality company should have high risk, got \(result.riskLevel)")
        
        // Validate pillar scores reflect issues
        XCTAssertLessThan(result.pillarScores.financialReadiness.rawScore, 3.0,
                         "Financial readiness should be low for cash-constrained company")
        XCTAssertLessThan(result.pillarScores.regulatoryRisk.rawScore, 3.0,
                         "Regulatory risk should be high for early-stage company")
        
        print("✅ Low-quality company accuracy test passed")
        print("   - Score: \(String(format: "%.2f", result.overallScore))")
        print("   - Recommendation: \(result.investmentRecommendation.rawValue)")
        print("   - Risk: \(result.riskLevel.rawValue)")
    }
    
    func testMediumQualityCompanyAccuracy() async throws {
        // Test scoring accuracy for a medium-quality reference company
        let referenceCompany = createMediumQualityReferenceCompany()
        let expectedScoreRange = 2.5...3.5
        let expectedRecommendation: InvestmentRecommendation = .hold
        let expectedRiskLevel: RiskLevel = .medium
        
        let config = createStandardScoringConfig()
        let result = try await scoringEngine.evaluateCompany(referenceCompany, config: config)
        
        // Validate overall score
        XCTAssertTrue(expectedScoreRange.contains(result.overallScore),
                     "Medium-quality company score \(result.overallScore) should be in range \(expectedScoreRange)")
        
        // Validate investment recommendation
        XCTAssertTrue([.hold, .buy, .sell].contains(result.investmentRecommendation),
                     "Medium-quality company should have moderate recommendation, got \(result.investmentRecommendation)")
        
        // Validate risk level
        XCTAssertEqual(result.riskLevel, .medium,
                      "Medium-quality company should have medium risk, got \(result.riskLevel)")
        
        // Validate balanced pillar scores
        let pillarScores = [
            result.pillarScores.assetQuality.rawScore,
            result.pillarScores.marketOutlook.rawScore,
            result.pillarScores.capitalIntensity.rawScore,
            result.pillarScores.strategicFit.rawScore,
            result.pillarScores.financialReadiness.rawScore,
            result.pillarScores.regulatoryRisk.rawScore
        ]
        
        let averagePillarScore = pillarScores.reduce(0, +) / Double(pillarScores.count)
        XCTAssertTrue((2.5...3.5).contains(averagePillarScore),
                     "Average pillar score should be moderate")
        
        print("✅ Medium-quality company accuracy test passed")
        print("   - Score: \(String(format: "%.2f", result.overallScore))")
        print("   - Recommendation: \(result.investmentRecommendation.rawValue)")
        print("   - Risk: \(result.riskLevel.rawValue)")
        print("   - Average pillar score: \(String(format: "%.2f", averagePillarScore))")
    }
    
    // MARK: - Pillar-Specific Accuracy Tests
    
    func testAssetQualityPillarAccuracy() async throws {
        // Test asset quality pillar with known characteristics
        let companies = [
            ("Strong Pipeline", createStrongPipelineCompany(), 4.0...5.0),
            ("Weak Pipeline", createWeakPipelineCompany(), 1.0...2.5),
            ("Diversified Pipeline", createDiversifiedPipelineCompany(), 3.5...4.5)
        ]
        
        let config = createStandardScoringConfig()
        
        for (name, company, expectedRange) in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            let assetQualityScore = result.pillarScores.assetQuality.rawScore
            
            XCTAssertTrue(expectedRange.contains(assetQualityScore),
                         "\(name) asset quality score \(assetQualityScore) should be in range \(expectedRange)")
            
            print("   - \(name): \(String(format: "%.2f", assetQualityScore))")
        }
        
        print("✅ Asset quality pillar accuracy test passed")
    }
    
    func testFinancialReadinessPillarAccuracy() async throws {
        // Test financial readiness pillar with known financial situations
        let companies = [
            ("Well Funded", createWellFundedCompany(), 4.0...5.0),
            ("Cash Constrained", createCashConstrainedCompany(), 1.0...2.5),
            ("Moderate Funding", createModerateFundingCompany(), 2.5...3.5)
        ]
        
        let config = createStandardScoringConfig()
        
        for (name, company, expectedRange) in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            let financialScore = result.pillarScores.financialReadiness.rawScore
            
            XCTAssertTrue(expectedRange.contains(financialScore),
                         "\(name) financial readiness score \(financialScore) should be in range \(expectedRange)")
            
            print("   - \(name): \(String(format: "%.2f", financialScore))")
        }
        
        print("✅ Financial readiness pillar accuracy test passed")
    }
    
    func testMarketOutlookPillarAccuracy() async throws {
        // Test market outlook pillar with different market conditions
        let companies = [
            ("Large Market", createLargeMarketCompany(), 3.5...5.0),
            ("Small Market", createSmallMarketCompany(), 1.0...3.0),
            ("Competitive Market", createCompetitiveMarketCompany(), 2.0...3.5)
        ]
        
        let config = createStandardScoringConfig()
        
        for (name, company, expectedRange) in companies {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            let marketScore = result.pillarScores.marketOutlook.rawScore
            
            XCTAssertTrue(expectedRange.contains(marketScore),
                         "\(name) market outlook score \(marketScore) should be in range \(expectedRange)")
            
            print("   - \(name): \(String(format: "%.2f", marketScore))")
        }
        
        print("✅ Market outlook pillar accuracy test passed")
    }
    
    // MARK: - Configuration Sensitivity Tests
    
    func testWeightConfigurationAccuracy() async throws {
        // Test that different weight configurations produce expected relative changes
        let company = createStandardReferenceCompany()
        
        // Create configurations emphasizing different pillars
        let assetFocusedConfig = createAssetFocusedConfig()
        let financialFocusedConfig = createFinancialFocusedConfig()
        let marketFocusedConfig = createMarketFocusedConfig()
        
        let assetResult = try await scoringEngine.evaluateCompany(company, config: assetFocusedConfig)
        let financialResult = try await scoringEngine.evaluateCompany(company, config: financialFocusedConfig)
        let marketResult = try await scoringEngine.evaluateCompany(company, config: marketFocusedConfig)
        
        // Verify that emphasized pillars have greater impact on overall score
        let assetPillarScore = assetResult.pillarScores.assetQuality.rawScore
        let financialPillarScore = financialResult.pillarScores.financialReadiness.rawScore
        let marketPillarScore = marketResult.pillarScores.marketOutlook.rawScore
        
        // The configuration that emphasizes the strongest pillar should have the highest overall score
        if assetPillarScore >= financialPillarScore && assetPillarScore >= marketPillarScore {
            XCTAssertGreaterThanOrEqual(assetResult.overallScore, financialResult.overallScore,
                                       "Asset-focused config should score higher when asset quality is strongest")
            XCTAssertGreaterThanOrEqual(assetResult.overallScore, marketResult.overallScore,
                                       "Asset-focused config should score higher when asset quality is strongest")
        }
        
        print("✅ Weight configuration accuracy test passed")
        print("   - Asset-focused score: \(String(format: "%.2f", assetResult.overallScore))")
        print("   - Financial-focused score: \(String(format: "%.2f", financialResult.overallScore))")
        print("   - Market-focused score: \(String(format: "%.2f", marketResult.overallScore))")
    }
    
    // MARK: - Consistency and Reliability Tests
    
    func testScoringConsistency() async throws {
        // Test that the same company produces consistent scores across multiple evaluations
        let company = createStandardReferenceCompany()
        let config = createStandardScoringConfig()
        let numberOfEvaluations = 10
        
        var scores: [Double] = []
        
        for _ in 0..<numberOfEvaluations {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            scores.append(result.overallScore)
        }
        
        // Calculate score statistics
        let averageScore = scores.reduce(0, +) / Double(scores.count)
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0
        let scoreRange = maxScore - minScore
        
        // Scores should be highly consistent (within 0.1 points)
        XCTAssertLessThan(scoreRange, 0.1, "Score range should be minimal for consistent scoring")
        XCTAssertGreaterThan(averageScore, 0, "Average score should be positive")
        
        // All scores should be identical for deterministic scoring
        let uniqueScores = Set(scores.map { String(format: "%.3f", $0) })
        XCTAssertEqual(uniqueScores.count, 1, "All scores should be identical for same input")
        
        print("✅ Scoring consistency test passed")
        print("   - Evaluations: \(numberOfEvaluations)")
        print("   - Average score: \(String(format: "%.3f", averageScore))")
        print("   - Score range: \(String(format: "%.3f", scoreRange))")
        print("   - Unique scores: \(uniqueScores.count)")
    }
    
    func testDataCompletenessImpact() async throws {
        // Test that data completeness appropriately affects confidence and scoring
        let completeCompany = createCompleteReferenceCompany()
        let incompleteCompany = createIncompleteReferenceCompany()
        let config = createStandardScoringConfig()
        
        let completeResult = try await scoringEngine.evaluateCompany(completeCompany, config: config)
        let incompleteResult = try await scoringEngine.evaluateCompany(incompleteCompany, config: config)
        
        // Complete data should have higher confidence
        XCTAssertGreaterThan(completeResult.confidence.overall, incompleteResult.confidence.overall,
                           "Complete data should have higher confidence")
        
        // Data completeness should be reflected in confidence metrics
        XCTAssertGreaterThan(completeResult.confidence.dataCompleteness, 0.8,
                           "Complete data should have high completeness score")
        XCTAssertLessThan(incompleteResult.confidence.dataCompleteness, 0.7,
                         "Incomplete data should have lower completeness score")
        
        print("✅ Data completeness impact test passed")
        print("   - Complete data confidence: \(String(format: "%.1f", completeResult.confidence.overall * 100))%")
        print("   - Incomplete data confidence: \(String(format: "%.1f", incompleteResult.confidence.overall * 100))%")
        print("   - Complete data completeness: \(String(format: "%.1f", completeResult.confidence.dataCompleteness * 100))%")
        print("   - Incomplete data completeness: \(String(format: "%.1f", incompleteResult.confidence.dataCompleteness * 100))%")
    }
    
    // MARK: - Edge Case Accuracy Tests
    
    func testEdgeCaseAccuracy() async throws {
        // Test scoring accuracy for edge cases
        let edgeCases = [
            ("Pre-revenue company", createPreRevenueCompany()),
            ("Single asset company", createSingleAssetCompany()),
            ("Late-stage company", createLateStageCompany()),
            ("Orphan drug company", createOrphanDrugCompany())
        ]
        
        let config = createStandardScoringConfig()
        
        for (name, company) in edgeCases {
            let result = try await scoringEngine.evaluateCompany(company, config: config)
            
            // All edge cases should produce valid scores
            XCTAssertGreaterThan(result.overallScore, 0, "\(name) should have positive score")
            XCTAssertLessThanOrEqual(result.overallScore, 5.0, "\(name) should not exceed maximum score")
            XCTAssertNotNil(result.investmentRecommendation, "\(name) should have recommendation")
            XCTAssertNotNil(result.riskLevel, "\(name) should have risk level")
            XCTAssertFalse(result.recommendations.isEmpty, "\(name) should have recommendations")
            
            print("   - \(name): \(String(format: "%.2f", result.overallScore)) (\(result.investmentRecommendation.rawValue))")
        }
        
        print("✅ Edge case accuracy test passed")
    }
    
    // MARK: - Helper Methods - Reference Companies
    
    private func createHighQualityReferenceCompany() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "High Quality Biotech",
                ticker: "HQB",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phase3,
                description: "Leading biotech with breakthrough therapy"
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "HQB-001",
                        indication: "Non-Small Cell Lung Cancer",
                        stage: .phase3,
                        mechanism: "PD-L1 Inhibitor",
                        differentiators: ["Best-in-class efficacy", "Superior safety profile", "Breakthrough therapy designation"],
                        risks: [Risk(type: "Clinical", description: "Low efficacy risk", probability: 0.1)],
                        timeline: [
                            Milestone(name: "Phase III Completion", date: Date().addingTimeInterval(180 * 24 * 3600)),
                            Milestone(name: "BLA Submission", date: Date().addingTimeInterval(270 * 24 * 3600))
                        ]
                    )
                ],
                totalPrograms: 3
            ),
            financials: CompanyFinancials(
                cashPosition: 500000000,
                burnRate: 15000000,
                lastFunding: FundingRound(amount: 300000000, date: Date().addingTimeInterval(-60 * 24 * 3600), type: "IPO"),
                runway: 33
            ),
            market: CompanyMarket(
                addressableMarket: 25000000000,
                competitors: [
                    Competitor(name: "Established Player", marketShare: 0.3, strengths: ["Market presence"])
                ],
                marketDynamics: MarketDynamics(growthRate: 0.20, competitiveIntensity: "Medium")
            ),
            regulatory: CompanyRegulatory(
                approvals: [
                    Approval(type: .breakthrough, date: Date().addingTimeInterval(-365 * 24 * 3600), indication: "NSCLC"),
                    Approval(type: .fastTrack, date: Date().addingTimeInterval(-300 * 24 * 3600), indication: "NSCLC")
                ],
                clinicalTrials: [
                    ClinicalTrial(phase: .phase3, status: "Active", enrollment: 800, primaryEndpoint: "Overall Survival")
                ],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Accelerated Approval", timeline: 18, risks: [])
            )
        )
    }
    
    private func createLowQualityReferenceCompany() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Low Quality Biotech",
                ticker: "LQB",
                sector: "Biotechnology",
                therapeuticAreas: ["Rare Disease"],
                stage: .preclinical
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "LQB-001",
                        indication: "Rare Genetic Disorder",
                        stage: .preclinical,
                        mechanism: "Unknown",
                        differentiators: [],
                        risks: [
                            Risk(type: "Clinical", description: "High efficacy risk", probability: 0.7),
                            Risk(type: "Regulatory", description: "Unclear pathway", probability: 0.6)
                        ],
                        timeline: []
                    )
                ],
                totalPrograms: 1
            ),
            financials: CompanyFinancials(
                cashPosition: 5000000,
                burnRate: 2000000,
                lastFunding: FundingRound(amount: 8000000, date: Date().addingTimeInterval(-300 * 24 * 3600), type: "Seed"),
                runway: 2
            ),
            market: CompanyMarket(
                addressableMarket: 100000000,
                competitors: [
                    Competitor(name: "Big Pharma Incumbent", marketShare: 0.8, strengths: ["Established treatment", "Market dominance"])
                ],
                marketDynamics: MarketDynamics(growthRate: 0.02, competitiveIntensity: "Very High")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Uncertain", timeline: 84, risks: ["Regulatory rejection", "Safety concerns"])
            )
        )
    }
    
    private func createMediumQualityReferenceCompany() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Medium Quality Biotech",
                ticker: "MQB",
                sector: "Biotechnology",
                therapeuticAreas: ["Immunology"],
                stage: .phase2
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "MQB-001",
                        indication: "Rheumatoid Arthritis",
                        stage: .phase2,
                        mechanism: "JAK Inhibitor",
                        differentiators: ["Improved selectivity"],
                        risks: [Risk(type: "Clinical", description: "Moderate efficacy risk", probability: 0.4)],
                        timeline: [
                            Milestone(name: "Phase II Results", date: Date().addingTimeInterval(270 * 24 * 3600))
                        ]
                    )
                ],
                totalPrograms: 2
            ),
            financials: CompanyFinancials(
                cashPosition: 75000000,
                burnRate: 8000000,
                lastFunding: FundingRound(amount: 100000000, date: Date().addingTimeInterval(-120 * 24 * 3600), type: "Series B"),
                runway: 9
            ),
            market: CompanyMarket(
                addressableMarket: 8000000000,
                competitors: [
                    Competitor(name: "Moderate Competitor", marketShare: 0.4, strengths: ["Similar mechanism"])
                ],
                marketDynamics: MarketDynamics(growthRate: 0.12, competitiveIntensity: "High")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [
                    ClinicalTrial(phase: .phase2, status: "Active", enrollment: 200, primaryEndpoint: "ACR20 Response")
                ],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Standard", timeline: 42, risks: ["Competitive landscape"])
            )
        )
    }
    
    // Additional helper methods for specific test scenarios...
    
    private func createStrongPipelineCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Strong Pipeline Co"
        company.pipeline.totalPrograms = 5
        company.basicInfo.stage = .phase3
        return company
    }
    
    private func createWeakPipelineCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Weak Pipeline Co"
        company.pipeline.totalPrograms = 1
        company.basicInfo.stage = .preclinical
        return company
    }
    
    private func createDiversifiedPipelineCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Diversified Pipeline Co"
        company.pipeline.totalPrograms = 4
        company.basicInfo.therapeuticAreas = ["Oncology", "Immunology", "Neurology"]
        return company
    }
    
    private func createWellFundedCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Well Funded Co"
        company.financials.cashPosition = 300000000
        company.financials.burnRate = 10000000
        company.financials.runway = 30
        return company
    }
    
    private func createCashConstrainedCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Cash Constrained Co"
        company.financials.cashPosition = 8000000
        company.financials.burnRate = 4000000
        company.financials.runway = 2
        return company
    }
    
    private func createModerateFundingCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Moderate Funding Co"
        company.financials.cashPosition = 60000000
        company.financials.burnRate = 6000000
        company.financials.runway = 10
        return company
    }
    
    private func createLargeMarketCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Large Market Co"
        company.market.addressableMarket = 50000000000
        return company
    }
    
    private func createSmallMarketCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Small Market Co"
        company.market.addressableMarket = 500000000
        return company
    }
    
    private func createCompetitiveMarketCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Competitive Market Co"
        company.market.competitors = [
            Competitor(name: "Competitor 1", marketShare: 0.3, strengths: ["Established"]),
            Competitor(name: "Competitor 2", marketShare: 0.25, strengths: ["Similar product"]),
            Competitor(name: "Competitor 3", marketShare: 0.2, strengths: ["Lower cost"])
        ]
        company.market.marketDynamics.competitiveIntensity = "Very High"
        return company
    }
    
    private func createStandardReferenceCompany() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: "Standard Reference Co",
                ticker: "SRC",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phase2
            ),
            pipeline: CompanyPipeline(
                programs: [
                    Program(
                        name: "SRC-001",
                        indication: "Cancer",
                        stage: .phase2,
                        mechanism: "Small Molecule",
                        differentiators: ["Novel target"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 2
            ),
            financials: CompanyFinancials(
                cashPosition: 100000000,
                burnRate: 8000000,
                lastFunding: FundingRound(amount: 150000000, date: Date(), type: "Series B"),
                runway: 12
            ),
            market: CompanyMarket(
                addressableMarket: 10000000000,
                competitors: [],
                marketDynamics: MarketDynamics(growthRate: 0.15, competitiveIntensity: "Medium")
            ),
            regulatory: CompanyRegulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(pathway: "Standard", timeline: 36, risks: [])
            )
        )
    }
    
    private func createCompleteReferenceCompany() -> CompanyData {
        return createHighQualityReferenceCompany() // Already has complete data
    }
    
    private func createIncompleteReferenceCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.ticker = nil
        company.basicInfo.description = nil
        company.financials.lastFunding = nil
        company.market.competitors = []
        company.regulatory.approvals = []
        company.regulatory.clinicalTrials = []
        return company
    }
    
    private func createPreRevenueCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Pre-Revenue Co"
        company.basicInfo.stage = .phase1
        return company
    }
    
    private func createSingleAssetCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Single Asset Co"
        company.pipeline.totalPrograms = 1
        return company
    }
    
    private func createLateStageCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Late Stage Co"
        company.basicInfo.stage = .phase3
        return company
    }
    
    private func createOrphanDrugCompany() -> CompanyData {
        var company = createStandardReferenceCompany()
        company.basicInfo.name = "Orphan Drug Co"
        company.basicInfo.therapeuticAreas = ["Rare Disease"]
        company.market.addressableMarket = 2000000000
        company.regulatory.approvals = [
            Approval(type: .orphanDrug, date: Date(), indication: "Rare Disease")
        ]
        return company
    }
    
    // Configuration helpers
    
    private func createStandardScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(),
            customParameters: [:]
        )
    }
    
    private func createAssetFocusedConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.50,
                marketOutlook: 0.15,
                capitalIntensity: 0.10,
                strategicFit: 0.10,
                financialReadiness: 0.10,
                regulatoryRisk: 0.05
            ),
            customParameters: ["focus": "asset"]
        )
    }
    
    private func createFinancialFocusedConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.15,
                marketOutlook: 0.15,
                capitalIntensity: 0.15,
                strategicFit: 0.10,
                financialReadiness: 0.40,
                regulatoryRisk: 0.05
            ),
            customParameters: ["focus": "financial"]
        )
    }
    
    private func createMarketFocusedConfig() -> ScoringConfig {
        return ScoringConfig(
            weights: WeightConfig(
                assetQuality: 0.15,
                marketOutlook: 0.45,
                capitalIntensity: 0.10,
                strategicFit: 0.15,
                financialReadiness: 0.10,
                regulatoryRisk: 0.05
            ),
            customParameters: ["focus": "market"]
        )
    }
}