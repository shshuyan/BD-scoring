import XCTest
@testable import BDScoringModule

class ReportModelsTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    private func createSampleReport() -> Report {
        let executiveSummary = ExecutiveSummary(
            overallScore: 3.8,
            investmentRecommendation: .buy,
            riskLevel: .medium,
            keyFindings: [
                KeyFinding(
                    category: .strength,
                    title: "Strong Pipeline",
                    description: "Diversified pipeline with multiple Phase II assets",
                    impact: .high,
                    supportingData: ["3 Phase II programs", "2 breakthrough designations"]
                )
            ],
            investmentThesis: "Strong biotech company with promising pipeline and solid financials",
            keyRisks: ["Regulatory approval risk", "Competition from big pharma"],
            keyOpportunities: ["Large addressable market", "Partnership potential"],
            recommendedActions: ["Monitor Phase II results", "Evaluate partnership opportunities"],
            confidenceLevel: 0.85,
            summaryStats: SummaryStatistics(
                totalCompaniesEvaluated: 150,
                averageScore: 3.2,
                percentileRanking: 75.0,
                industryBenchmark: 3.1,
                timeToNextMilestone: 8,
                estimatedValuation: 2500.0
            )
        )
        
        let detailedAnalysis = DetailedAnalysis(
            scoringBreakdown: createSampleScoringBreakdown(),
            pillarAnalyses: createSamplePillarAnalyses(),
            comparativeAnalysis: createSampleComparativeAnalysis(),
            riskAssessment: createSampleRiskAssessment(),
            valuationAnalysis: createSampleValuationAnalysis(),
            recommendations: createSampleDetailedRecommendations()
        )
        
        let metadata = ReportMetadata(
            generatedDate: Date(),
            generatedBy: "Test User",
            version: "1.0",
            dataAsOfDate: Date(),
            confidentialityLevel: .confidential,
            distributionList: ["analyst@company.com"],
            expirationDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            disclaimers: ["This analysis is for internal use only"]
        )
        
        return Report(
            companyId: UUID(),
            companyName: "Test Biotech Inc.",
            reportType: .full,
            executiveSummary: executiveSummary,
            detailedAnalysis: detailedAnalysis,
            metadata: metadata,
            template: ReportTemplateService.createDefaultTemplate(for: .full)
        )
    }
    
    private func createSampleScoringBreakdown() -> ScoringBreakdown {
        let pillarScores = PillarScores(
            assetQuality: PillarScore(rawScore: 4.0, confidence: 0.9, factors: [], warnings: []),
            marketOutlook: PillarScore(rawScore: 3.5, confidence: 0.8, factors: [], warnings: []),
            capitalIntensity: PillarScore(rawScore: 3.0, confidence: 0.7, factors: [], warnings: []),
            strategicFit: PillarScore(rawScore: 4.2, confidence: 0.85, factors: [], warnings: []),
            financialReadiness: PillarScore(rawScore: 3.8, confidence: 0.9, factors: [], warnings: []),
            regulatoryRisk: PillarScore(rawScore: 3.2, confidence: 0.75, factors: [], warnings: [])
        )
        
        let weightedScores = WeightedScores(
            assetQuality: 1.0,
            marketOutlook: 0.7,
            capitalIntensity: 0.45,
            strategicFit: 0.84,
            financialReadiness: 0.38,
            regulatoryRisk: 0.32
        )
        
        return ScoringBreakdown(
            pillarScores: pillarScores,
            weightedScores: weightedScores,
            weightConfiguration: WeightConfig(),
            confidenceMetrics: ConfidenceMetrics(
                overall: 0.82,
                dataCompleteness: 0.85,
                modelAccuracy: 0.78,
                comparableQuality: 0.83
            ),
            scoringMethodology: "Six-pillar weighted scoring framework"
        )
    }
    
    private func createSamplePillarAnalyses() -> [PillarAnalysis] {
        return [
            PillarAnalysis(
                pillarName: "Asset Quality",
                score: PillarScore(rawScore: 4.0, confidence: 0.9, factors: [], warnings: []),
                weightedScore: 1.0,
                analysis: "Strong pipeline with multiple differentiated assets",
                keyMetrics: [
                    KeyMetric(
                        name: "Pipeline Diversity",
                        value: "5 programs",
                        benchmark: "3.2 average",
                        trend: .improving,
                        importance: .high
                    )
                ],
                benchmarks: [
                    Benchmark(
                        category: "Pipeline Size",
                        companyValue: 5.0,
                        benchmarkValue: 3.2,
                        percentile: 78.0,
                        interpretation: "Above average pipeline size"
                    )
                ],
                recommendations: ["Continue investing in lead programs"]
            )
        ]
    }
    
    private func createSampleComparativeAnalysis() -> ComparativeAnalysis {
        return ComparativeAnalysis(
            peerComparison: [
                PeerComparison(
                    peerName: "Competitor A",
                    companyScore: 3.8,
                    peerScore: 3.2,
                    keyDifferences: ["Stronger pipeline", "Better financials"]
                )
            ],
            industryBenchmarks: [
                IndustryBenchmark(
                    metric: "Overall Score",
                    companyValue: 3.8,
                    industryAverage: 3.1,
                    industryMedian: 3.0,
                    topQuartile: 4.2
                )
            ],
            marketPosition: .challenger,
            competitiveAdvantages: ["Innovative platform", "Strong IP portfolio"],
            competitiveDisadvantages: ["Limited commercial experience"]
        )
    }
    
    private func createSampleRiskAssessment() -> RiskAssessment {
        return RiskAssessment(
            overallRiskLevel: .medium,
            riskCategories: [
                RiskCategory(
                    name: "Regulatory Risk",
                    level: .medium,
                    risks: [
                        RiskItem(
                            description: "FDA approval uncertainty",
                            probability: .medium,
                            impact: .high,
                            timeframe: .mediumTerm,
                            mitigation: "Engage with FDA early"
                        )
                    ],
                    impact: "Could delay market entry",
                    likelihood: "Moderate based on precedent"
                )
            ],
            mitigationStrategies: [
                MitigationStrategy(
                    riskId: UUID(),
                    strategy: "Diversify pipeline",
                    cost: .medium,
                    effectiveness: .high,
                    timeline: "12-18 months"
                )
            ],
            riskMatrix: [[]]
        )
    }
    
    private func createSampleValuationAnalysis() -> ValuationAnalysis {
        return ValuationAnalysis(
            baseValuation: 2500.0,
            valuationRange: ValuationRange(
                low: 1800.0,
                base: 2500.0,
                high: 3200.0,
                confidence: 0.75
            ),
            methodology: .comparables,
            scenarios: [
                ValuationScenario(
                    name: "Base Case",
                    probability: 0.6,
                    valuation: 2500.0,
                    keyAssumptions: ["Successful Phase II", "Partnership by 2025"],
                    description: "Most likely scenario based on current trajectory"
                )
            ],
            comparables: [
                ValuationComparable(
                    companyName: "Similar Biotech",
                    transactionType: "Acquisition",
                    valuation: 2800.0,
                    multiple: 4.2,
                    relevanceScore: 0.85,
                    keyMetrics: ["Stage": "Phase II", "Indication": "Oncology"]
                )
            ],
            sensitivityAnalysis: SensitivityAnalysis(
                baseCase: 2500.0,
                sensitivities: [
                    SensitivityFactor(
                        factor: "Market Size",
                        baseValue: 10.0,
                        lowCase: 7.0,
                        highCase: 15.0,
                        impact: 0.3
                    )
                ],
                scenarios: [
                    SensitivityScenario(
                        name: "Bull Case",
                        changes: ["Market Size": 15.0],
                        resultingValuation: 3200.0,
                        variance: 0.28
                    )
                ]
            )
        )
    }
    
    private func createSampleDetailedRecommendations() -> DetailedRecommendations {
        return DetailedRecommendations(
            investmentRecommendation: .buy,
            rationale: "Strong fundamentals with upside potential",
            actionItems: [
                ActionItem(
                    action: "Monitor Phase II results",
                    priority: .high,
                    owner: "Research Team",
                    deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                    expectedOutcome: "Updated risk assessment"
                )
            ],
            timeline: RecommendationTimeline(
                immediate: ["Review latest data"],
                nearTerm: ["Evaluate partnership options"],
                longTerm: ["Monitor competitive landscape"]
            ),
            successMetrics: [
                SuccessMetric(
                    metric: "Phase II Success Rate",
                    currentValue: "60%",
                    targetValue: "70%",
                    timeframe: "12 months",
                    measurement: "Clinical trial outcomes"
                )
            ],
            alternativeScenarios: [
                AlternativeScenario(
                    name: "Partnership Scenario",
                    description: "Early partnership with big pharma",
                    probability: 0.3,
                    implications: ["Reduced risk", "Lower upside"],
                    recommendedActions: ["Negotiate favorable terms"]
                )
            ]
        )
    }
    
    // MARK: - Report Model Tests
    
    func testReportCreation() {
        let report = createSampleReport()
        
        XCTAssertEqual(report.companyName, "Test Biotech Inc.")
        XCTAssertEqual(report.reportType, .full)
        XCTAssertEqual(report.executiveSummary.overallScore, 3.8)
        XCTAssertEqual(report.executiveSummary.investmentRecommendation, .buy)
        XCTAssertEqual(report.metadata.confidentialityLevel, .confidential)
    }
    
    func testReportTitle() {
        let report = createSampleReport()
        XCTAssertEqual(report.title, "BD & IPO Scoring Analysis: Test Biotech Inc.")
        
        var executiveReport = report
        executiveReport.reportType = .executiveSummary
        XCTAssertEqual(executiveReport.title, "Executive Summary: Test Biotech Inc.")
    }
    
    func testExecutiveSummaryValidation() {
        let summary = createSampleReport().executiveSummary
        
        XCTAssertGreaterThan(summary.overallScore, 0)
        XCTAssertLessThanOrEqual(summary.overallScore, 5)
        XCTAssertGreaterThan(summary.confidenceLevel, 0)
        XCTAssertLessThanOrEqual(summary.confidenceLevel, 1)
        XCTAssertFalse(summary.keyFindings.isEmpty)
        XCTAssertFalse(summary.keyRisks.isEmpty)
        XCTAssertFalse(summary.keyOpportunities.isEmpty)
    }
    
    func testKeyFindingCategories() {
        let finding = KeyFinding(
            category: .strength,
            title: "Test Finding",
            description: "Test description",
            impact: .high,
            supportingData: ["Data point 1"]
        )
        
        XCTAssertEqual(finding.category.color, "green")
        XCTAssertEqual(finding.impact, .high)
        XCTAssertFalse(finding.supportingData.isEmpty)
    }
    
    func testSummaryStatistics() {
        let stats = createSampleReport().executiveSummary.summaryStats
        
        XCTAssertGreaterThan(stats.totalCompaniesEvaluated, 0)
        XCTAssertGreaterThan(stats.averageScore, 0)
        XCTAssertGreaterThan(stats.percentileRanking, 0)
        XCTAssertLessThanOrEqual(stats.percentileRanking, 100)
        XCTAssertNotNil(stats.timeToNextMilestone)
        XCTAssertNotNil(stats.estimatedValuation)
    }
    
    // MARK: - Detailed Analysis Tests
    
    func testScoringBreakdown() {
        let breakdown = createSampleReport().detailedAnalysis.scoringBreakdown
        
        XCTAssertGreaterThan(breakdown.pillarScores.assetQuality.rawScore, 0)
        XCTAssertLessThanOrEqual(breakdown.pillarScores.assetQuality.rawScore, 5)
        XCTAssertGreaterThan(breakdown.confidenceMetrics.overall, 0)
        XCTAssertLessThanOrEqual(breakdown.confidenceMetrics.overall, 1)
        XCTAssertTrue(breakdown.weightConfiguration.isValid)
    }
    
    func testPillarAnalysis() {
        let analyses = createSampleReport().detailedAnalysis.pillarAnalyses
        
        XCTAssertFalse(analyses.isEmpty)
        
        let firstAnalysis = analyses[0]
        XCTAssertEqual(firstAnalysis.pillarName, "Asset Quality")
        XCTAssertFalse(firstAnalysis.keyMetrics.isEmpty)
        XCTAssertFalse(firstAnalysis.benchmarks.isEmpty)
        XCTAssertFalse(firstAnalysis.recommendations.isEmpty)
    }
    
    func testKeyMetrics() {
        let metric = KeyMetric(
            name: "Test Metric",
            value: "100",
            benchmark: "80",
            trend: .improving,
            importance: .high
        )
        
        XCTAssertEqual(metric.name, "Test Metric")
        XCTAssertEqual(metric.trend, .improving)
        XCTAssertEqual(metric.importance, .high)
    }
    
    func testBenchmarkComparison() {
        let benchmark = Benchmark(
            category: "Test Category",
            companyValue: 4.0,
            benchmarkValue: 3.0,
            percentile: 75.0,
            interpretation: "Above average"
        )
        
        XCTAssertGreaterThan(benchmark.companyValue, benchmark.benchmarkValue)
        XCTAssertGreaterThan(benchmark.percentile, 50.0)
    }
    
    // MARK: - Risk Assessment Tests
    
    func testRiskAssessment() {
        let riskAssessment = createSampleReport().detailedAnalysis.riskAssessment
        
        XCTAssertEqual(riskAssessment.overallRiskLevel, .medium)
        XCTAssertFalse(riskAssessment.riskCategories.isEmpty)
        XCTAssertFalse(riskAssessment.mitigationStrategies.isEmpty)
    }
    
    func testRiskItem() {
        let risk = RiskItem(
            description: "Test risk",
            probability: .medium,
            impact: .high,
            timeframe: .nearTerm,
            mitigation: "Test mitigation"
        )
        
        XCTAssertEqual(risk.probability, .medium)
        XCTAssertEqual(risk.impact, .high)
        XCTAssertEqual(risk.timeframe, .nearTerm)
        XCTAssertNotNil(risk.mitigation)
    }
    
    func testMitigationStrategy() {
        let strategy = MitigationStrategy(
            riskId: UUID(),
            strategy: "Test strategy",
            cost: .medium,
            effectiveness: .high,
            timeline: "6 months"
        )
        
        XCTAssertEqual(strategy.cost, .medium)
        XCTAssertEqual(strategy.effectiveness, .high)
        XCTAssertFalse(strategy.timeline.isEmpty)
    }
    
    // MARK: - Valuation Analysis Tests
    
    func testValuationAnalysis() {
        let valuation = createSampleReport().detailedAnalysis.valuationAnalysis!
        
        XCTAssertGreaterThan(valuation.baseValuation, 0)
        XCTAssertLessThanOrEqual(valuation.valuationRange.low, valuation.valuationRange.base)
        XCTAssertLessThanOrEqual(valuation.valuationRange.base, valuation.valuationRange.high)
        XCTAssertFalse(valuation.scenarios.isEmpty)
        XCTAssertFalse(valuation.comparables.isEmpty)
    }
    
    func testValuationScenario() {
        let scenario = ValuationScenario(
            name: "Test Scenario",
            probability: 0.4,
            valuation: 2000.0,
            keyAssumptions: ["Assumption 1", "Assumption 2"],
            description: "Test scenario description"
        )
        
        XCTAssertGreaterThan(scenario.probability, 0)
        XCTAssertLessThanOrEqual(scenario.probability, 1)
        XCTAssertGreaterThan(scenario.valuation, 0)
        XCTAssertFalse(scenario.keyAssumptions.isEmpty)
    }
    
    func testSensitivityAnalysis() {
        let sensitivity = createSampleReport().detailedAnalysis.valuationAnalysis!.sensitivityAnalysis
        
        XCTAssertGreaterThan(sensitivity.baseCase, 0)
        XCTAssertFalse(sensitivity.sensitivities.isEmpty)
        XCTAssertFalse(sensitivity.scenarios.isEmpty)
    }
    
    // MARK: - Recommendations Tests
    
    func testDetailedRecommendations() {
        let recommendations = createSampleReport().detailedAnalysis.recommendations
        
        XCTAssertEqual(recommendations.investmentRecommendation, .buy)
        XCTAssertFalse(recommendations.rationale.isEmpty)
        XCTAssertFalse(recommendations.actionItems.isEmpty)
        XCTAssertFalse(recommendations.successMetrics.isEmpty)
    }
    
    func testActionItem() {
        let action = ActionItem(
            action: "Test action",
            priority: .high,
            owner: "Test owner",
            deadline: Date(),
            expectedOutcome: "Test outcome"
        )
        
        XCTAssertEqual(action.priority, .high)
        XCTAssertNotNil(action.owner)
        XCTAssertNotNil(action.deadline)
        XCTAssertFalse(action.expectedOutcome.isEmpty)
    }
    
    func testSuccessMetric() {
        let metric = SuccessMetric(
            metric: "Test Metric",
            currentValue: "50%",
            targetValue: "75%",
            timeframe: "12 months",
            measurement: "Test measurement"
        )
        
        XCTAssertFalse(metric.metric.isEmpty)
        XCTAssertFalse(metric.targetValue.isEmpty)
        XCTAssertFalse(metric.timeframe.isEmpty)
    }
    
    // MARK: - Metadata Tests
    
    func testReportMetadata() {
        let metadata = createSampleReport().metadata
        
        XCTAssertEqual(metadata.confidentialityLevel, .confidential)
        XCTAssertFalse(metadata.distributionList.isEmpty)
        XCTAssertNotNil(metadata.expirationDate)
        XCTAssertFalse(metadata.disclaimers.isEmpty)
    }
    
    // MARK: - Export Configuration Tests
    
    func testExportConfiguration() {
        let config = ExportConfiguration(
            format: .pdf,
            quality: .high,
            includeCharts: true,
            includeAppendices: true,
            passwordProtected: false,
            watermark: nil
        )
        
        XCTAssertEqual(config.format, .pdf)
        XCTAssertEqual(config.quality, .high)
        XCTAssertTrue(config.includeCharts)
        XCTAssertTrue(config.includeAppendices)
        XCTAssertFalse(config.passwordProtected)
    }
    
    // MARK: - Codable Tests
    
    func testReportCodable() throws {
        let originalReport = createSampleReport()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalReport)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedReport = try decoder.decode(Report.self, from: data)
        
        XCTAssertEqual(originalReport.companyName, decodedReport.companyName)
        XCTAssertEqual(originalReport.reportType, decodedReport.reportType)
        XCTAssertEqual(originalReport.executiveSummary.overallScore, decodedReport.executiveSummary.overallScore)
    }
    
    func testExecutiveSummaryCodable() throws {
        let summary = createSampleReport().executiveSummary
        
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(ExecutiveSummary.self, from: data)
        
        XCTAssertEqual(summary.overallScore, decoded.overallScore)
        XCTAssertEqual(summary.investmentRecommendation, decoded.investmentRecommendation)
        XCTAssertEqual(summary.keyFindings.count, decoded.keyFindings.count)
    }
}