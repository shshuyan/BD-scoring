import XCTest
@testable import BDScoringModule

class BDScoringEngineTests: XCTestCase {
    
    var scoringEngine: BDScoringEngine!
    var sampleCompanyData: CompanyData!
    var sampleScoringConfig: ScoringConfig!
    
    override func setUp() {
        super.setUp()
        scoringEngine = BDScoringEngine()
        sampleCompanyData = createSampleCompanyData()
        sampleScoringConfig = createSampleScoringConfig()
    }
    
    override func tearDown() {
        scoringEngine = nil
        sampleCompanyData = nil
        sampleScoringConfig = nil
        super.tearDown()
    }
    
    // MARK: - Company Evaluation Tests
    
    func testEvaluateCompany_ValidData_ReturnsCompleteScoringResult() async throws {
        // When
        let result = try await scoringEngine.evaluateCompany(sampleCompanyData, config: sampleScoringConfig)
        
        // Then
        XCTAssertEqual(result.companyId, sampleCompanyData.id)
        XCTAssertGreaterThan(result.overallScore, 0)
        XCTAssertLessThanOrEqual(result.overallScore, 5.0)
        
        // Check that all pillar scores are present
        XCTAssertGreaterThan(result.pillarScores.assetQuality.rawScore, 0)
        XCTAssertGreaterThan(result.pillarScores.marketOutlook.rawScore, 0)
        XCTAssertGreaterThan(result.pillarScores.capitalIntensity.rawScore, 0)
        XCTAssertGreaterThan(result.pillarScores.strategicFit.rawScore, 0)
        XCTAssertGreaterThan(result.pillarScores.financialReadiness.rawScore, 0)
        XCTAssertGreaterThan(result.pillarScores.regulatoryRisk.rawScore, 0)
        
        // Check weighted scores
        XCTAssertGreaterThan(result.weightedScores.total, 0)
        XCTAssertLessThanOrEqual(result.weightedScores.total, 5.0)
        
        // Check confidence metrics
        XCTAssertGreaterThan(result.confidence.overall, 0)
        XCTAssertLessThanOrEqual(result.confidence.overall, 1.0)
        
        // Check recommendations are present
        XCTAssertFalse(result.recommendations.isEmpty)
        
        // Check timestamp is recent
        XCTAssertLessThan(Date().timeIntervalSince(result.timestamp), 5.0)
    }
    
    func testEvaluateCompany_DefaultConfig_UsesDefaultWeights() async throws {
        // When
        let result = try await scoringEngine.evaluateCompany(sampleCompanyData)
        
        // Then
        XCTAssertGreaterThan(result.overallScore, 0)
        XCTAssertNotNil(result.investmentRecommendation)
        XCTAssertNotNil(result.riskLevel)
    }
    
    func testEvaluateCompany_InvalidData_ThrowsError() async {
        // Given
        let invalidCompanyData = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "", // Empty name should cause validation error
                ticker: nil,
                sector: "",
                therapeuticAreas: [],
                stage: .preclinical
            ),
            pipeline: CompanyData.Pipeline(programs: []), // Empty pipeline
            financials: CompanyData.Financials(cashPosition: 0, burnRate: 0),
            market: CompanyData.Market(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 0,
                    barriers: [],
                    drivers: [],
                    reimbursement: .unknown
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 0,
                    risks: [],
                    mitigations: []
                )
            )
        )
        
        // When/Then
        do {
            _ = try await scoringEngine.evaluateCompany(invalidCompanyData, config: sampleScoringConfig)
            XCTFail("Expected error for invalid company data")
        } catch ScoringError.invalidData {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testEvaluateCompany_InvalidConfig_ThrowsError() async {
        // Given
        let invalidConfig = ScoringConfig(
            name: "Invalid",
            weights: WeightConfig(
                assetQuality: -1.0, // Invalid negative weight
                marketOutlook: 0.2,
                capitalIntensity: 0.2,
                strategicFit: 0.2,
                financialReadiness: 0.2,
                regulatoryRisk: 0.2
            ),
            parameters: ScoringParameters()
        )
        
        // When/Then
        do {
            _ = try await scoringEngine.evaluateCompany(sampleCompanyData, config: invalidConfig)
            XCTFail("Expected error for invalid configuration")
        } catch ScoringError.configurationError {
            // Expected error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testValidateInputData_ValidData_ReturnsValid() {
        // When
        let result = scoringEngine.validateInputData(sampleCompanyData)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.completeness, 0.5)
    }
    
    func testValidateInputData_MissingRequiredFields_ReturnsErrors() {
        // Given
        let incompleteData = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "", // Missing name
                ticker: nil,
                sector: "Biotech",
                therapeuticAreas: [],
                stage: .preclinical
            ),
            pipeline: CompanyData.Pipeline(programs: []), // Empty pipeline
            financials: CompanyData.Financials(cashPosition: 100, burnRate: 5),
            market: CompanyData.Market(
                addressableMarket: 1000,
                competitors: [],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 10,
                    barriers: [],
                    drivers: [],
                    reimbursement: .moderate
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 36,
                    risks: [],
                    mitigations: []
                )
            )
        )
        
        // When
        let result = scoringEngine.validateInputData(incompleteData)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.field == "basicInfo.name" })
        XCTAssertTrue(result.errors.contains { $0.field == "pipeline.programs" })
    }
    
    // MARK: - Weighted Score Calculation Tests
    
    func testCalculateWeightedScore_ValidInputs_ReturnsCorrectScore() {
        // Given
        let pillarScores = createSamplePillarScores()
        let weights = WeightConfig()
        
        // When
        let weightedScore = scoringEngine.calculateWeightedScore(pillarScores, weights: weights)
        
        // Then
        XCTAssertGreaterThan(weightedScore.score, 0)
        XCTAssertLessThanOrEqual(weightedScore.score, 5.0)
        XCTAssertEqual(weightedScore.breakdown.count, 6)
        XCTAssertGreaterThan(weightedScore.confidence, 0)
        XCTAssertLessThanOrEqual(weightedScore.confidence, 1.0)
    }
    
    func testCalculateWeightedScore_CustomWeights_ReflectsWeighting() {
        // Given
        let pillarScores = createSamplePillarScores()
        let customWeights = WeightConfig(
            assetQuality: 0.5, // High weight on asset quality
            marketOutlook: 0.2,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        
        // When
        let weightedScore = scoringEngine.calculateWeightedScore(pillarScores, weights: customWeights)
        
        // Then
        // Asset quality should have the highest contribution
        XCTAssertGreaterThan(weightedScore.breakdown["assetQuality"]!, weightedScore.breakdown["marketOutlook"]!)
        XCTAssertGreaterThan(weightedScore.breakdown["assetQuality"]!, weightedScore.breakdown["financialReadiness"]!)
    }
    
    // MARK: - Confidence Calculation Tests
    
    func testCalculateConfidence_ValidInputs_ReturnsReasonableConfidence() {
        // Given
        let pillarScores = createSamplePillarScores()
        
        // When
        let confidence = scoringEngine.calculateConfidence(pillarScores, data: sampleCompanyData)
        
        // Then
        XCTAssertGreaterThan(confidence.overall, 0)
        XCTAssertLessThanOrEqual(confidence.overall, 1.0)
        XCTAssertGreaterThan(confidence.dataCompleteness, 0)
        XCTAssertLessThanOrEqual(confidence.dataCompleteness, 1.0)
        XCTAssertGreaterThan(confidence.modelAccuracy, 0)
        XCTAssertLessThanOrEqual(confidence.modelAccuracy, 1.0)
        XCTAssertGreaterThan(confidence.comparableQuality, 0)
        XCTAssertLessThanOrEqual(confidence.comparableQuality, 1.0)
    }
    
    // MARK: - Batch Processing Tests
    
    func testEvaluateCompanies_MultipleCompanies_ReturnsAllResults() async throws {
        // Given
        let companies = [
            sampleCompanyData,
            createAlternativeCompanyData(),
            createThirdCompanyData()
        ]
        
        // When
        let results = try await scoringEngine.evaluateCompanies(companies, config: sampleScoringConfig)
        
        // Then
        XCTAssertEqual(results.count, 3)
        
        for result in results {
            XCTAssertGreaterThan(result.overallScore, 0)
            XCTAssertLessThanOrEqual(result.overallScore, 5.0)
            XCTAssertFalse(result.recommendations.isEmpty)
        }
    }
    
    func testEvaluateCompanies_WithInvalidCompany_ContinuesWithOthers() async throws {
        // Given
        let invalidCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(name: "", ticker: nil, sector: "", therapeuticAreas: [], stage: .preclinical),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(cashPosition: 0, burnRate: 0),
            market: CompanyData.Market(addressableMarket: 0, competitors: [], marketDynamics: CompanyData.MarketDynamics(growthRate: 0, barriers: [], drivers: [], reimbursement: .unknown)),
            regulatory: CompanyData.Regulatory(approvals: [], clinicalTrials: [], regulatoryStrategy: CompanyData.RegulatoryStrategy(pathway: .standard, timeline: 0, risks: [], mitigations: []))
        )
        
        let companies = [sampleCompanyData, invalidCompany, createAlternativeCompanyData()]
        
        // When
        let results = try await scoringEngine.evaluateCompanies(companies, config: sampleScoringConfig)
        
        // Then
        // Should have results for valid companies only
        XCTAssertEqual(results.count, 2)
    }
    
    // MARK: - Statistics Tests
    
    func testGetScoringStatistics_ValidResults_ReturnsCorrectStatistics() async throws {
        // Given
        let companies = [sampleCompanyData, createAlternativeCompanyData(), createThirdCompanyData()]
        let results = try await scoringEngine.evaluateCompanies(companies, config: sampleScoringConfig)
        
        // When
        let statistics = scoringEngine.getScoringStatistics(results)
        
        // Then
        XCTAssertEqual(statistics.totalCompanies, 3)
        XCTAssertGreaterThan(statistics.averageScore, 0)
        XCTAssertLessThanOrEqual(statistics.averageScore, 5.0)
        XCTAssertGreaterThan(statistics.averageConfidence, 0)
        XCTAssertLessThanOrEqual(statistics.averageConfidence, 1.0)
        
        // Check distributions
        XCTAssertFalse(statistics.scoreDistribution.isEmpty)
        XCTAssertFalse(statistics.recommendationDistribution.isEmpty)
        
        // Verify distribution counts sum to total
        let totalScoreDistribution = statistics.scoreDistribution.values.reduce(0, +)
        XCTAssertEqual(totalScoreDistribution, 3)
        
        let totalRecommendationDistribution = statistics.recommendationDistribution.values.reduce(0, +)
        XCTAssertEqual(totalRecommendationDistribution, 3)
    }
    
    func testGetScoringStatistics_EmptyResults_ReturnsZeroStatistics() {
        // Given
        let emptyResults: [ScoringResult] = []
        
        // When
        let statistics = scoringEngine.getScoringStatistics(emptyResults)
        
        // Then
        XCTAssertEqual(statistics.totalCompanies, 0)
        XCTAssertEqual(statistics.averageScore, 0)
        XCTAssertEqual(statistics.averageConfidence, 0)
        XCTAssertTrue(statistics.scoreDistribution.isEmpty)
        XCTAssertTrue(statistics.recommendationDistribution.isEmpty)
    }
    
    // MARK: - Market Context Tests
    
    func testUpdateMarketContext_NewContext_UpdatesSuccessfully() {
        // Given
        let newMarketContext = MarketContext(
            benchmarkData: [createSampleBenchmarkData()],
            marketConditions: MarketConditions(
                biotechIndex: 1200.0,
                ipoActivity: .hot,
                fundingEnvironment: .abundant,
                regulatoryClimate: .supportive
            ),
            comparableCompanies: [sampleCompanyData],
            industryMetrics: IndustryMetrics(
                averageValuation: 750.0,
                medianTimeline: 30,
                successRate: 0.20,
                averageRunway: 24
            )
        )
        
        // When
        scoringEngine.updateMarketContext(newMarketContext)
        let retrievedContext = scoringEngine.getCurrentMarketContext()
        
        // Then
        XCTAssertEqual(retrievedContext.marketConditions.biotechIndex, 1200.0)
        XCTAssertEqual(retrievedContext.marketConditions.ipoActivity, .hot)
        XCTAssertEqual(retrievedContext.marketConditions.fundingEnvironment, .abundant)
        XCTAssertEqual(retrievedContext.marketConditions.regulatoryClimate, .supportive)
    }
    
    // MARK: - Pillar Insights Tests
    
    func testGetPillarInsights_ValidCompany_ReturnsAllInsights() async throws {
        // When
        let insights = try await scoringEngine.getPillarInsights(sampleCompanyData)
        
        // Then
        XCTAssertEqual(insights.count, 6)
        XCTAssertNotNil(insights["Asset Quality"])
        XCTAssertNotNil(insights["Market Outlook"])
        XCTAssertNotNil(insights["Capital Intensity"])
        XCTAssertNotNil(insights["Strategic Fit"])
        XCTAssertNotNil(insights["Financial Readiness"])
        XCTAssertNotNil(insights["Regulatory Risk"])
        
        // Check that insights are not empty
        for (pillar, insight) in insights {
            XCTAssertFalse(insight.isEmpty, "Insight for \(pillar) should not be empty")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_EndToEnd_ProducesConsistentResults() async throws {
        // Given - Multiple evaluations of the same company
        let evaluations = 3
        var results: [ScoringResult] = []
        
        // When - Evaluate the same company multiple times
        for _ in 0..<evaluations {
            let result = try await scoringEngine.evaluateCompany(sampleCompanyData, config: sampleScoringConfig)
            results.append(result)
        }
        
        // Then - Results should be consistent (same inputs = same outputs)
        let firstResult = results[0]
        for i in 1..<results.count {
            let currentResult = results[i]
            XCTAssertEqual(currentResult.overallScore, firstResult.overallScore, accuracy: 0.001)
            XCTAssertEqual(currentResult.pillarScores.assetQuality.rawScore, firstResult.pillarScores.assetQuality.rawScore, accuracy: 0.001)
            XCTAssertEqual(currentResult.investmentRecommendation, firstResult.investmentRecommendation)
            XCTAssertEqual(currentResult.riskLevel, firstResult.riskLevel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "BioTech Innovations Inc.",
                ticker: "BTII",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "Leading biotech company focused on cancer immunotherapy"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "BTI-001",
                        indication: "Non-small cell lung cancer",
                        stage: .phase2,
                        mechanism: "PD-1 inhibitor",
                        differentiators: ["Novel binding site", "Reduced side effects"],
                        risks: [Risk(description: "Competitive landscape", probability: .medium, impact: .medium)],
                        timeline: [Milestone(name: "Phase 2 completion", expectedDate: Date().addingTimeInterval(365*24*60*60), status: .inProgress)]
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 150.0,
                burnRate: 8.0,
                lastFunding: FundingRound(type: .seriesB, amount: 75.0, date: Date().addingTimeInterval(-180*24*60*60), investors: ["Venture Capital Fund"])
            ),
            market: CompanyData.Market(
                addressableMarket: 25.0,
                competitors: [
                    Competitor(name: "Big Pharma Co", stage: .phase3, marketShare: 0.3, strengths: ["Resources"], weaknesses: ["Slow innovation"])
                ],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 15.0,
                    barriers: ["Regulatory approval"],
                    drivers: ["Aging population"],
                    reimbursement: .favorable
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [
                    ClinicalTrial(name: "BTI-001-P2", phase: .phase2, indication: "NSCLC", status: .active, startDate: Date().addingTimeInterval(-90*24*60*60), expectedCompletion: Date().addingTimeInterval(275*24*60*60), patientCount: 120)
                ],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .fastTrack,
                    timeline: 30,
                    risks: ["FDA feedback"],
                    mitigations: ["Regular FDA meetings"]
                )
            )
        )
    }
    
    private func createAlternativeCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "MedTech Solutions",
                ticker: "MTS",
                sector: "Medical Technology",
                therapeuticAreas: ["Cardiology"],
                stage: .phase1,
                description: "Cardiovascular device company"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "MTS-100",
                        indication: "Heart failure",
                        stage: .phase1,
                        mechanism: "Mechanical support",
                        differentiators: ["Minimally invasive"],
                        risks: [Risk(description: "Technical complexity", probability: .high, impact: .high)],
                        timeline: [Milestone(name: "Phase 1 start", expectedDate: Date().addingTimeInterval(90*24*60*60), status: .upcoming)]
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 50.0,
                burnRate: 3.0,
                lastFunding: FundingRound(type: .seriesA, amount: 25.0, date: Date().addingTimeInterval(-120*24*60*60), investors: ["Angel Investors"])
            ),
            market: CompanyData.Market(
                addressableMarket: 10.0,
                competitors: [
                    Competitor(name: "Device Corp", stage: .approved, marketShare: 0.5, strengths: ["Market presence"], weaknesses: ["Old technology"])
                ],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 8.0,
                    barriers: ["Device approval"],
                    drivers: ["Heart disease prevalence"],
                    reimbursement: .moderate
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 48,
                    risks: ["Device safety"],
                    mitigations: ["Extensive testing"]
                )
            )
        )
    }
    
    private func createThirdCompanyData() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Gene Therapy Corp",
                ticker: "GTC",
                sector: "Gene Therapy",
                therapeuticAreas: ["Rare Diseases"],
                stage: .phase3,
                description: "Gene therapy for rare genetic disorders"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "GTC-200",
                        indication: "Hemophilia A",
                        stage: .phase3,
                        mechanism: "Gene replacement",
                        differentiators: ["One-time treatment"],
                        risks: [Risk(description: "Manufacturing scale", probability: .medium, impact: .high)],
                        timeline: [Milestone(name: "Phase 3 completion", expectedDate: Date().addingTimeInterval(180*24*60*60), status: .inProgress)]
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 300.0,
                burnRate: 15.0,
                lastFunding: FundingRound(type: .seriesC, amount: 200.0, date: Date().addingTimeInterval(-60*24*60*60), investors: ["Strategic Partner"])
            ),
            market: CompanyData.Market(
                addressableMarket: 5.0,
                competitors: [],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 25.0,
                    barriers: ["High cost"],
                    drivers: ["Unmet medical need"],
                    reimbursement: .challenging
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [
                    Approval(indication: "Hemophilia A", region: "EU", date: Date().addingTimeInterval(-30*24*60*60), type: .conditional)
                ],
                clinicalTrials: [
                    ClinicalTrial(name: "GTC-200-P3", phase: .phase3, indication: "Hemophilia A", status: .active, startDate: Date().addingTimeInterval(-365*24*60*60), expectedCompletion: Date().addingTimeInterval(180*24*60*60), patientCount: 200)
                ],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .breakthrough,
                    timeline: 18,
                    risks: ["Long-term safety"],
                    mitigations: ["Extended follow-up"]
                )
            )
        )
    }
    
    private func createSampleScoringConfig() -> ScoringConfig {
        return ScoringConfig(
            name: "Test Configuration",
            weights: WeightConfig(
                assetQuality: 0.3,
                marketOutlook: 0.2,
                capitalIntensity: 0.15,
                strategicFit: 0.15,
                financialReadiness: 0.1,
                regulatoryRisk: 0.1
            ),
            parameters: ScoringParameters(
                riskAdjustment: 1.0,
                timeHorizon: 5,
                discountRate: 0.12,
                confidenceThreshold: 0.7
            )
        )
    }
    
    private func createSamplePillarScores() -> PillarScores {
        return PillarScores(
            assetQuality: PillarScore(rawScore: 4.0, confidence: 0.8, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 3.5, confidence: 0.7, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 2.8, confidence: 0.9, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 4.2, confidence: 0.85, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 3.2, confidence: 0.6, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 3.8, confidence: 0.75, factors: [], warnings: [])
        )
    }
    
    private func createSampleBenchmarkData() -> BenchmarkData {
        return BenchmarkData(
            therapeuticArea: "Oncology",
            stage: .phase2,
            averageScore: 3.5,
            standardDeviation: 0.8,
            sampleSize: 50
        )
    }
}