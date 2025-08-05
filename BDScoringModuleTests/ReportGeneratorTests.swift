import XCTest
@testable import BDScoringModule

class ReportGeneratorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var reportGenerator: ReportGenerator!
    private var exportService: ReportExportService!
    private var sampleScoringResult: ScoringResult!
    private var sampleCompanyData: CompanyData!
    private var sampleValuationAnalysis: ValuationAnalysis!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        reportGenerator = ReportGenerator()
        exportService = ReportExportService()
        sampleScoringResult = createSampleScoringResult()
        sampleCompanyData = createSampleCompanyData()
        sampleValuationAnalysis = createSampleValuationAnalysis()
    }
    
    override func tearDown() {
        reportGenerator = nil
        exportService = nil
        sampleScoringResult = nil
        sampleCompanyData = nil
        sampleValuationAnalysis = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Creation
    
    private func createSampleScoringResult() -> ScoringResult {
        let pillarScores = PillarScores(
            assetQuality: PillarScore(
                rawScore: 4.2,
                confidence: 0.85,
                factors: [
                    ScoringFactor(name: "Pipeline Diversity", weight: 0.3, score: 4.5, rationale: "Strong pipeline with multiple assets"),
                    ScoringFactor(name: "Development Stage", weight: 0.4, score: 4.0, rationale: "Advanced stage programs")
                ],
                warnings: [],
                explanation: "Strong asset quality with diversified pipeline"
            ),
            marketOutlook: PillarScore(
                rawScore: 3.8,
                confidence: 0.75,
                factors: [
                    ScoringFactor(name: "Market Size", weight: 0.5, score: 4.0, rationale: "Large addressable market"),
                    ScoringFactor(name: "Competition", weight: 0.3, score: 3.5, rationale: "Moderate competitive pressure")
                ],
                warnings: ["Increasing competition expected"],
                explanation: "Positive market outlook with growth potential"
            ),
            capitalIntensity: PillarScore(
                rawScore: 3.2,
                confidence: 0.70,
                factors: [],
                warnings: ["High development costs anticipated"],
                explanation: "Moderate capital requirements"
            ),
            strategicFit: PillarScore(
                rawScore: 4.0,
                confidence: 0.80,
                factors: [],
                warnings: [],
                explanation: "Strong strategic fit for partnerships"
            ),
            financialReadiness: PillarScore(
                rawScore: 3.5,
                confidence: 0.90,
                factors: [],
                warnings: ["Limited runway"],
                explanation: "Adequate financial position with funding needs"
            ),
            regulatoryRisk: PillarScore(
                rawScore: 3.3,
                confidence: 0.65,
                factors: [],
                warnings: ["Regulatory pathway uncertainty"],
                explanation: "Moderate regulatory risk"
            )
        )
        
        let weightedScores = WeightedScores(
            assetQuality: 1.05,
            marketOutlook: 0.76,
            capitalIntensity: 0.48,
            strategicFit: 0.80,
            financialReadiness: 0.35,
            regulatoryRisk: 0.33
        )
        
        let confidence = ConfidenceMetrics(
            overall: 0.78,
            dataCompleteness: 0.82,
            modelAccuracy: 0.75,
            comparableQuality: 0.77
        )
        
        return ScoringResult(
            companyId: UUID(),
            overallScore: 3.77,
            pillarScores: pillarScores,
            weightedScores: weightedScores,
            confidence: confidence,
            recommendations: ["Monitor Phase II results", "Explore partnerships"],
            timestamp: Date(),
            investmentRecommendation: .buy,
            riskLevel: .medium
        )
    }
    
    private func createSampleCompanyData() -> CompanyData {
        let basicInfo = CompanyData.BasicInfo(
            name: "BioTech Innovations Inc.",
            ticker: "BTII",
            sector: "Biotechnology",
            therapeuticAreas: ["Oncology", "Immunology"],
            stage: .phase2,
            description: "Leading biotech company focused on innovative cancer treatments"
        )
        
        let programs = [
            Program(
                name: "BTI-001",
                indication: "Non-small cell lung cancer",
                stage: .phase2,
                mechanism: "PD-L1 inhibitor",
                differentiators: ["Novel binding site", "Improved safety profile"],
                risks: [
                    Risk(description: "Efficacy uncertainty", probability: .medium, impact: .high, mitigation: "Interim analysis")
                ],
                timeline: [
                    Milestone(name: "Phase II completion", expectedDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())!, status: .inProgress)
                ]
            ),
            Program(
                name: "BTI-002",
                indication: "Breast cancer",
                stage: .phase1,
                mechanism: "ADC",
                differentiators: ["Targeted delivery"],
                risks: [],
                timeline: []
            )
        ]
        
        let pipeline = CompanyData.Pipeline(programs: programs)
        
        let financials = CompanyData.Financials(
            cashPosition: 85.5,
            burnRate: 4.2,
            lastFunding: FundingRound(
                type: .seriesB,
                amount: 75.0,
                date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                investors: ["Venture Capital A", "Strategic Investor B"]
            )
        )
        
        let market = CompanyData.Market(
            addressableMarket: 12.5,
            competitors: [
                Competitor(
                    name: "Big Pharma Corp",
                    stage: .phase3,
                    marketShare: 0.25,
                    strengths: ["Established presence", "Large resources"],
                    weaknesses: ["Slow innovation"]
                )
            ],
            marketDynamics: MarketDynamics(
                growthRate: 0.15,
                barriers: ["High development costs", "Regulatory complexity"],
                drivers: ["Aging population", "Unmet medical need"],
                reimbursement: .favorable
            )
        )
        
        let regulatory = CompanyData.Regulatory(
            approvals: [
                Approval(
                    indication: "NSCLC",
                    region: "US",
                    date: Date(),
                    type: .breakthrough
                )
            ],
            clinicalTrials: [
                ClinicalTrial(
                    name: "BTI-001-201",
                    phase: .phase2,
                    indication: "NSCLC",
                    status: .active,
                    startDate: Calendar.current.date(byAdding: .month, value: -12, to: Date()),
                    expectedCompletion: Calendar.current.date(byAdding: .month, value: 8, to: Date()),
                    patientCount: 150
                )
            ],
            regulatoryStrategy: RegulatoryStrategy(
                pathway: .breakthrough,
                timeline: 36,
                risks: ["FDA feedback uncertainty"],
                mitigations: ["Regular FDA meetings"]
            )
        )
        
        return CompanyData(
            basicInfo: basicInfo,
            pipeline: pipeline,
            financials: financials,
            market: market,
            regulatory: regulatory
        )
    }
    
    private func createSampleValuationAnalysis() -> ValuationAnalysis {
        return ValuationAnalysis(
            baseValuation: 850.0,
            valuationRange: ValuationRange(
                low: 600.0,
                base: 850.0,
                high: 1200.0,
                confidence: 0.75
            ),
            methodology: .comparables,
            scenarios: [
                ValuationScenario(
                    name: "Base Case",
                    probability: 0.6,
                    valuation: 850.0,
                    keyAssumptions: ["Phase II success", "Partnership by 2025"],
                    description: "Most likely scenario"
                ),
                ValuationScenario(
                    name: "Bull Case",
                    probability: 0.2,
                    valuation: 1200.0,
                    keyAssumptions: ["Accelerated approval", "Premium partnership"],
                    description: "Optimistic scenario"
                )
            ],
            comparables: [
                ValuationComparable(
                    companyName: "Similar Oncology Co",
                    transactionType: "Acquisition",
                    valuation: 900.0,
                    multiple: 4.5,
                    relevanceScore: 0.85,
                    keyMetrics: ["Stage": "Phase II", "Indication": "Oncology"]
                )
            ],
            sensitivityAnalysis: SensitivityAnalysis(
                baseCase: 850.0,
                sensitivities: [
                    SensitivityFactor(
                        factor: "Market Size",
                        baseValue: 12.5,
                        lowCase: 8.0,
                        highCase: 18.0,
                        impact: 0.25
                    )
                ],
                scenarios: [
                    SensitivityScenario(
                        name: "Market Expansion",
                        changes: ["Market Size": 18.0],
                        resultingValuation: 1050.0,
                        variance: 0.24
                    )
                ]
            )
        )
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateFullReport() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template,
            includeValuation: true,
            valuationAnalysis: sampleValuationAnalysis
        )
        
        XCTAssertEqual(report.companyName, "BioTech Innovations Inc.")
        XCTAssertEqual(report.reportType, .full)
        XCTAssertEqual(report.executiveSummary.overallScore, 3.77)
        XCTAssertEqual(report.executiveSummary.investmentRecommendation, .buy)
        XCTAssertEqual(report.executiveSummary.riskLevel, .medium)
        
        // Verify executive summary content
        XCTAssertFalse(report.executiveSummary.keyFindings.isEmpty)
        XCTAssertFalse(report.executiveSummary.keyRisks.isEmpty)
        XCTAssertFalse(report.executiveSummary.keyOpportunities.isEmpty)
        XCTAssertFalse(report.executiveSummary.investmentThesis.isEmpty)
        
        // Verify detailed analysis
        XCTAssertEqual(report.detailedAnalysis.pillarAnalyses.count, 6)
        XCTAssertNotNil(report.detailedAnalysis.valuationAnalysis)
        XCTAssertFalse(report.detailedAnalysis.riskAssessment.riskCategories.isEmpty)
        
        // Verify metadata
        XCTAssertEqual(report.metadata.confidentialityLevel, .confidential)
        XCTAssertFalse(report.metadata.disclaimers.isEmpty)
    }
    
    func testGenerateExecutiveSummaryReport() {
        let report = reportGenerator.generateExecutiveSummaryReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            includeValuation: true,
            valuationAnalysis: sampleValuationAnalysis
        )
        
        XCTAssertEqual(report.reportType, .executiveSummary)
        XCTAssertEqual(report.template.sections.count, 2) // Executive summary + recommendations
        XCTAssertTrue(report.template.sections.allSatisfy { $0.isRequired })
        
        // Verify executive summary content is comprehensive
        XCTAssertGreaterThan(report.executiveSummary.keyFindings.count, 0)
        XCTAssertGreaterThan(report.executiveSummary.keyRisks.count, 0)
        XCTAssertGreaterThan(report.executiveSummary.keyOpportunities.count, 0)
        XCTAssertGreaterThan(report.executiveSummary.recommendedActions.count, 0)
        
        // Verify summary statistics
        XCTAssertGreaterThan(report.executiveSummary.summaryStats.totalCompaniesEvaluated, 0)
        XCTAssertGreaterThan(report.executiveSummary.summaryStats.percentileRanking, 0)
        XCTAssertNotNil(report.executiveSummary.summaryStats.estimatedValuation)
    }
    
    func testGeneratePillarAnalysisReport() {
        let report = reportGenerator.generatePillarAnalysisReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData
        )
        
        XCTAssertEqual(report.reportType, .pillarAnalysis)
        XCTAssertNil(report.detailedAnalysis.valuationAnalysis) // Should not include valuation
        
        // Verify all pillars are analyzed
        let pillarAnalyses = report.detailedAnalysis.pillarAnalyses
        XCTAssertEqual(pillarAnalyses.count, 6)
        
        let pillarNames = pillarAnalyses.map { $0.pillarName }
        XCTAssertTrue(pillarNames.contains("Asset Quality"))
        XCTAssertTrue(pillarNames.contains("Market Outlook"))
        XCTAssertTrue(pillarNames.contains("Financial Readiness"))
        XCTAssertTrue(pillarNames.contains("Strategic Fit"))
        XCTAssertTrue(pillarNames.contains("Capital Intensity"))
        XCTAssertTrue(pillarNames.contains("Regulatory Risk"))
        
        // Verify pillar analysis content
        for analysis in pillarAnalyses {
            XCTAssertFalse(analysis.analysis.isEmpty)
            XCTAssertGreaterThan(analysis.score.rawScore, 0)
            XCTAssertLessThanOrEqual(analysis.score.rawScore, 5)
            XCTAssertGreaterThan(analysis.score.confidence, 0)
            XCTAssertLessThanOrEqual(analysis.score.confidence, 1)
        }
    }
    
    func testGenerateValuationReport() {
        let report = reportGenerator.generateValuationReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            valuationAnalysis: sampleValuationAnalysis
        )
        
        XCTAssertEqual(report.reportType, .valuation)
        XCTAssertNotNil(report.detailedAnalysis.valuationAnalysis)
        
        // Verify valuation analysis is included
        let valuation = report.detailedAnalysis.valuationAnalysis!
        XCTAssertEqual(valuation.baseValuation, 850.0)
        XCTAssertEqual(valuation.methodology, .comparables)
        XCTAssertFalse(valuation.scenarios.isEmpty)
        XCTAssertFalse(valuation.comparables.isEmpty)
        
        // Verify executive summary includes valuation context
        XCTAssertNotNil(report.executiveSummary.summaryStats.estimatedValuation)
        XCTAssertEqual(report.executiveSummary.summaryStats.estimatedValuation, 850.0)
    }
    
    // MARK: - Executive Summary Generation Tests
    
    func testKeyFindingsGeneration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let keyFindings = report.executiveSummary.keyFindings
        XCTAssertFalse(keyFindings.isEmpty)
        XCTAssertLessThanOrEqual(keyFindings.count, 5) // Should limit to top 5
        
        // Check for strength findings (Asset Quality score is 4.2)
        let strengthFindings = keyFindings.filter { $0.category == .strength }
        XCTAssertFalse(strengthFindings.isEmpty)
        
        // Check for threat findings (limited runway)
        let threatFindings = keyFindings.filter { $0.category == .threat }
        XCTAssertFalse(threatFindings.isEmpty)
        
        // Verify finding structure
        for finding in keyFindings {
            XCTAssertFalse(finding.title.isEmpty)
            XCTAssertFalse(finding.description.isEmpty)
            XCTAssertFalse(finding.supportingData.isEmpty)
        }
    }
    
    func testInvestmentThesisGeneration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let thesis = report.executiveSummary.investmentThesis
        XCTAssertFalse(thesis.isEmpty)
        
        // Should include company name
        XCTAssertTrue(thesis.contains("BioTech Innovations Inc."))
        
        // Should include score
        XCTAssertTrue(thesis.contains("3.8") || thesis.contains("3.77"))
        
        // Should include recommendation
        XCTAssertTrue(thesis.contains("Buy"))
        
        // Should include therapeutic areas
        XCTAssertTrue(thesis.contains("Oncology") || thesis.contains("Immunology"))
        
        // Should include market size context
        XCTAssertTrue(thesis.contains("12.5") || thesis.contains("market"))
    }
    
    func testRiskAndOpportunityExtraction() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let risks = report.executiveSummary.keyRisks
        let opportunities = report.executiveSummary.keyOpportunities
        
        XCTAssertFalse(risks.isEmpty)
        XCTAssertFalse(opportunities.isEmpty)
        XCTAssertLessThanOrEqual(risks.count, 5)
        XCTAssertLessThanOrEqual(opportunities.count, 4)
        
        // Should include financial risk due to limited runway
        XCTAssertTrue(risks.contains { $0.contains("runway") || $0.contains("financing") })
        
        // Should include partnership opportunity due to high strategic fit
        XCTAssertTrue(opportunities.contains { $0.contains("partnership") || $0.contains("strategic") })
    }
    
    // MARK: - Detailed Analysis Tests
    
    func testPillarAnalysisGeneration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let pillarAnalyses = report.detailedAnalysis.pillarAnalyses
        XCTAssertEqual(pillarAnalyses.count, 6)
        
        // Test Asset Quality analysis
        let assetQualityAnalysis = pillarAnalyses.first { $0.pillarName == "Asset Quality" }
        XCTAssertNotNil(assetQualityAnalysis)
        XCTAssertEqual(assetQualityAnalysis?.score.rawScore, 4.2)
        XCTAssertTrue(assetQualityAnalysis?.analysis.contains("4.2") ?? false)
        XCTAssertTrue(assetQualityAnalysis?.analysis.contains("strong") ?? false)
        XCTAssertFalse(assetQualityAnalysis?.keyMetrics.isEmpty ?? true)
        XCTAssertFalse(assetQualityAnalysis?.benchmarks.isEmpty ?? true)
        
        // Test Financial Readiness analysis
        let financialAnalysis = pillarAnalyses.first { $0.pillarName == "Financial Readiness" }
        XCTAssertNotNil(financialAnalysis)
        XCTAssertTrue(financialAnalysis?.analysis.contains("85.5") ?? false) // Cash position
        XCTAssertTrue(financialAnalysis?.analysis.contains("20") ?? false) // Runway months
    }
    
    func testRiskAssessmentGeneration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let riskAssessment = report.detailedAnalysis.riskAssessment
        XCTAssertEqual(riskAssessment.overallRiskLevel, .medium)
        XCTAssertFalse(riskAssessment.riskCategories.isEmpty)
        XCTAssertFalse(riskAssessment.mitigationStrategies.isEmpty)
        
        // Should include regulatory, financial, and market risk categories
        let categoryNames = riskAssessment.riskCategories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("Regulatory Risk"))
        XCTAssertTrue(categoryNames.contains("Financial Risk"))
        XCTAssertTrue(categoryNames.contains("Market Risk"))
        
        // Each category should have risks and mitigation strategies
        for category in riskAssessment.riskCategories {
            XCTAssertFalse(category.risks.isEmpty)
            XCTAssertFalse(category.impact.isEmpty)
            XCTAssertFalse(category.likelihood.isEmpty)
        }
    }
    
    func testComparativeAnalysisGeneration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let comparativeAnalysis = report.detailedAnalysis.comparativeAnalysis
        XCTAssertFalse(comparativeAnalysis.peerComparison.isEmpty)
        XCTAssertFalse(comparativeAnalysis.industryBenchmarks.isEmpty)
        
        // Market position should be appropriate for score
        XCTAssertTrue([.leader, .challenger].contains(comparativeAnalysis.marketPosition))
        
        // Should have competitive advantages and disadvantages
        XCTAssertFalse(comparativeAnalysis.competitiveAdvantages.isEmpty)
    }
    
    // MARK: - Export Service Tests
    
    func testPDFExport() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let exportConfig = ExportConfiguration(
            format: .pdf,
            quality: .standard,
            includeCharts: true,
            includeAppendices: true,
            passwordProtected: false,
            watermark: nil
        )
        
        let result = exportService.exportReport(report, configuration: exportConfig)
        
        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)
            
            // Verify content contains key elements
            if let content = String(data: data, encoding: .utf8) {
                XCTAssertTrue(content.contains("BioTech Innovations Inc."))
                XCTAssertTrue(content.contains("3.8") || content.contains("3.77"))
                XCTAssertTrue(content.contains("Buy"))
            }
        case .failure(let error):
            XCTFail("PDF export failed: \(error)")
        }
    }
    
    func testExcelExport() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        let exportConfig = ExportConfiguration(
            format: .excel,
            quality: .standard,
            includeCharts: false,
            includeAppendices: false,
            passwordProtected: false,
            watermark: nil
        )
        
        let result = exportService.exportReport(report, configuration: exportConfig)
        
        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)
            
            // Verify CSV-like content
            if let content = String(data: data, encoding: .utf8) {
                XCTAssertTrue(content.contains("BioTech Innovations Inc."))
                XCTAssertTrue(content.contains("3.77") || content.contains("3.8"))
                XCTAssertTrue(content.contains("4.2")) // Asset Quality score
            }
        case .failure(let error):
            XCTFail("Excel export failed: \(error)")
        }
    }
    
    func testHTMLExport() {
        let template = ReportTemplateService.createDefaultTemplate(for: .executiveSummary)
        let report = reportGenerator.generateExecutiveSummaryReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData
        )
        
        let exportConfig = ExportConfiguration(
            format: .html,
            quality: .high,
            includeCharts: true,
            includeAppendices: false,
            passwordProtected: false,
            watermark: nil
        )
        
        let result = exportService.exportReport(report, configuration: exportConfig)
        
        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)
            
            // Verify HTML structure
            if let content = String(data: data, encoding: .utf8) {
                XCTAssertTrue(content.contains("<!DOCTYPE html>"))
                XCTAssertTrue(content.contains("<html>"))
                XCTAssertTrue(content.contains("BioTech Innovations Inc."))
                XCTAssertTrue(content.contains("3.8") || content.contains("3.77"))
                XCTAssertTrue(content.contains("Buy"))
                XCTAssertTrue(content.contains("</html>"))
            }
        case .failure(let error):
            XCTFail("HTML export failed: \(error)")
        }
    }
    
    func testPowerPointExport() {
        let template = ReportTemplateService.createDefaultTemplate(for: .executiveSummary)
        let report = reportGenerator.generateExecutiveSummaryReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData
        )
        
        let exportConfig = ExportConfiguration(
            format: .powerpoint,
            quality: .high,
            includeCharts: true,
            includeAppendices: false,
            passwordProtected: false,
            watermark: nil
        )
        
        let result = exportService.exportReport(report, configuration: exportConfig)
        
        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)
            
            // Verify PowerPoint-like content
            if let content = String(data: data, encoding: .utf8) {
                XCTAssertTrue(content.contains("Slide 1"))
                XCTAssertTrue(content.contains("Executive Summary"))
                XCTAssertTrue(content.contains("BioTech Innovations Inc."))
            }
        case .failure(let error):
            XCTFail("PowerPoint export failed: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteReportGenerationWorkflow() {
        // Test the complete workflow from scoring result to exported report
        
        // 1. Generate full report
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template,
            includeValuation: true,
            valuationAnalysis: sampleValuationAnalysis
        )
        
        // 2. Verify report completeness
        XCTAssertEqual(report.companyName, "BioTech Innovations Inc.")
        XCTAssertEqual(report.reportType, .full)
        XCTAssertNotNil(report.detailedAnalysis.valuationAnalysis)
        
        // 3. Export to multiple formats
        let formats: [ExportFormat] = [.pdf, .excel, .html, .powerpoint, .word]
        
        for format in formats {
            let exportConfig = ExportConfiguration(
                format: format,
                quality: .standard,
                includeCharts: true,
                includeAppendices: true,
                passwordProtected: false,
                watermark: nil
            )
            
            let result = exportService.exportReport(report, configuration: exportConfig)
            
            switch result {
            case .success(let data):
                XCTAssertFalse(data.isEmpty, "Export data should not be empty for format: \(format)")
            case .failure(let error):
                XCTFail("Export failed for format \(format): \(error)")
            }
        }
    }
    
    func testReportGenerationWithVariousScenarios() {
        // Test report generation with different scoring scenarios
        
        let scenarios = [
            (score: 4.5, recommendation: InvestmentRecommendation.strongBuy, risk: RiskLevel.low),
            (score: 2.0, recommendation: InvestmentRecommendation.sell, risk: RiskLevel.high),
            (score: 3.0, recommendation: InvestmentRecommendation.hold, risk: RiskLevel.medium)
        ]
        
        for scenario in scenarios {
            var modifiedResult = sampleScoringResult!
            modifiedResult.overallScore = scenario.score
            modifiedResult.investmentRecommendation = scenario.recommendation
            modifiedResult.riskLevel = scenario.risk
            
            let template = ReportTemplateService.createDefaultTemplate(for: .executiveSummary)
            let report = reportGenerator.generateReport(
                from: modifiedResult,
                companyData: sampleCompanyData,
                template: template
            )
            
            XCTAssertEqual(report.executiveSummary.overallScore, scenario.score)
            XCTAssertEqual(report.executiveSummary.investmentRecommendation, scenario.recommendation)
            XCTAssertEqual(report.executiveSummary.riskLevel, scenario.risk)
            
            // Verify thesis adapts to scenario
            let thesis = report.executiveSummary.investmentThesis
            XCTAssertTrue(thesis.contains(scenario.recommendation.rawValue))
            XCTAssertTrue(thesis.contains(scenario.risk.rawValue.lowercased()))
        }
    }
    
    func testReportGenerationPerformance() {
        // Test that report generation completes within reasonable time
        let startTime = Date()
        
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template,
            includeValuation: true,
            valuationAnalysis: sampleValuationAnalysis
        )
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 1.0, "Report generation should complete within 1 second")
        XCTAssertNotNil(report)
        XCTAssertFalse(report.executiveSummary.investmentThesis.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testReportGenerationWithMissingData() {
        // Test report generation with incomplete company data
        var incompleteCompanyData = sampleCompanyData!
        incompleteCompanyData.pipeline.programs = []
        incompleteCompanyData.financials.cashPosition = 0
        
        let template = ReportTemplateService.createDefaultTemplate(for: .executiveSummary)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: incompleteCompanyData,
            template: template
        )
        
        // Should still generate report but with appropriate warnings/limitations
        XCTAssertNotNil(report)
        XCTAssertFalse(report.executiveSummary.investmentThesis.isEmpty)
        
        // Should handle missing pipeline gracefully
        XCTAssertNotNil(report.executiveSummary.summaryStats.timeToNextMilestone)
    }
    
    func testExportWithUnsupportedConfiguration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let report = reportGenerator.generateReport(
            from: sampleScoringResult,
            companyData: sampleCompanyData,
            template: template
        )
        
        // All formats are currently supported, so this test verifies the export service handles all formats
        for format in ExportFormat.allCases {
            let exportConfig = ExportConfiguration(
                format: format,
                quality: .standard,
                includeCharts: true,
                includeAppendices: true,
                passwordProtected: false,
                watermark: nil
            )
            
            let result = exportService.exportReport(report, configuration: exportConfig)
            
            switch result {
            case .success:
                // All formats should succeed with basic implementation
                break
            case .failure(let error):
                XCTFail("Unexpected export failure for format \(format): \(error)")
            }
        }
    }
}