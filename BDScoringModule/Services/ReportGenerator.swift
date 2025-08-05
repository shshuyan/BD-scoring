import Foundation

/// Service for generating comprehensive reports from scoring results
class ReportGenerator {
    
    // MARK: - Properties
    
    private let templateService: ReportTemplateService.Type
    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter
    private let performanceMonitor: PerformanceMonitoringService
    private let cachingService: CachingService
    
    // MARK: - Initialization
    
    init(templateService: ReportTemplateService.Type = ReportTemplateService.self) {
        self.templateService = templateService
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
        
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.maximumFractionDigits = 2
        
        self.performanceMonitor = PerformanceMonitoringService.shared
        self.cachingService = CachingService.shared
    }
    
    // MARK: - Report Generation
    
    /// Generates a complete report from scoring results
    func generateReport(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        template: ReportTemplate,
        includeValuation: Bool = false,
        valuationAnalysis: ValuationAnalysis? = nil
    ) -> Report {
        
        let executiveSummary = generateExecutiveSummary(
            from: scoringResult,
            companyData: companyData,
            includeValuation: includeValuation,
            valuationAnalysis: valuationAnalysis
        )
        
        let detailedAnalysis = generateDetailedAnalysis(
            from: scoringResult,
            companyData: companyData,
            includeValuation: includeValuation,
            valuationAnalysis: valuationAnalysis
        )
        
        let metadata = generateReportMetadata(
            companyData: companyData,
            template: template
        )
        
        return Report(
            companyId: companyData.id,
            companyName: companyData.basicInfo.name,
            reportType: template.type,
            executiveSummary: executiveSummary,
            detailedAnalysis: detailedAnalysis,
            metadata: metadata,
            template: template
        )
    }
    
    /// Generates an executive summary report
    func generateExecutiveSummaryReport(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        includeValuation: Bool = false,
        valuationAnalysis: ValuationAnalysis? = nil
    ) -> Report {
        
        return performanceMonitor.measureOperation("reportGeneration") {
            let template = templateService.createDefaultTemplate(for: .executiveSummary)
            return generateReport(
                from: scoringResult,
                companyData: companyData,
                template: template,
                includeValuation: includeValuation,
                valuationAnalysis: valuationAnalysis
            )
        }
    }
    
    /// Generates a detailed pillar analysis report
    func generatePillarAnalysisReport(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> Report {
        
        let template = templateService.createDefaultTemplate(for: .pillarAnalysis)
        return generateReport(
            from: scoringResult,
            companyData: companyData,
            template: template,
            includeValuation: false,
            valuationAnalysis: nil
        )
    }
    
    /// Generates a valuation-focused report
    func generateValuationReport(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        valuationAnalysis: ValuationAnalysis
    ) -> Report {
        
        let template = templateService.createDefaultTemplate(for: .valuation)
        return generateReport(
            from: scoringResult,
            companyData: companyData,
            template: template,
            includeValuation: true,
            valuationAnalysis: valuationAnalysis
        )
    }
    
    /// Generates a detailed report asynchronously with performance monitoring
    func generateDetailedReport(_ scoringResult: ScoringResult) async throws -> Report {
        return try await performanceMonitor.measureAsyncOperation("reportGeneration") {
            // Check cache first
            let reportId = "detailed_\(scoringResult.companyId)_\(scoringResult.timestamp.timeIntervalSince1970)"
            
            if let cachedReport: Report = await MainActor.run(body: {
                cachingService.getCachedReport(for: reportId)
            }) {
                return cachedReport
            }
            
            // Generate new report
            let template = templateService.createDefaultTemplate(for: .detailed)
            
            // This would normally fetch company data from database
            // For now, creating a mock company data structure
            let companyData = try await fetchCompanyData(for: scoringResult.companyId)
            
            let report = generateReport(
                from: scoringResult,
                companyData: companyData,
                template: template,
                includeValuation: false,
                valuationAnalysis: nil
            )
            
            // Cache the result
            await MainActor.run {
                cachingService.cacheReport(report, for: reportId)
            }
            
            return report
        }
    }
    
    /// Mock method to fetch company data - would be replaced with actual database call
    private func fetchCompanyData(for companyId: String) async throws -> CompanyData {
        // This is a placeholder - in real implementation would fetch from database
        throw ScoringError.dataNotFound("Company data not found for ID: \(companyId)")
    }
    
    // MARK: - Executive Summary Generation
    
    private func generateExecutiveSummary(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        includeValuation: Bool,
        valuationAnalysis: ValuationAnalysis?
    ) -> ExecutiveSummary {
        
        let keyFindings = generateKeyFindings(from: scoringResult, companyData: companyData)
        let investmentThesis = generateInvestmentThesis(from: scoringResult, companyData: companyData)
        let keyRisks = extractKeyRisks(from: scoringResult, companyData: companyData)
        let keyOpportunities = extractKeyOpportunities(from: scoringResult, companyData: companyData)
        let recommendedActions = generateRecommendedActions(from: scoringResult, companyData: companyData)
        let summaryStats = generateSummaryStatistics(
            from: scoringResult,
            companyData: companyData,
            valuationAnalysis: valuationAnalysis
        )
        
        return ExecutiveSummary(
            overallScore: scoringResult.overallScore,
            investmentRecommendation: scoringResult.investmentRecommendation,
            riskLevel: scoringResult.riskLevel,
            keyFindings: keyFindings,
            investmentThesis: investmentThesis,
            keyRisks: keyRisks,
            keyOpportunities: keyOpportunities,
            recommendedActions: recommendedActions,
            confidenceLevel: scoringResult.confidence.overall,
            summaryStats: summaryStats
        )
    }
    
    private func generateKeyFindings(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [KeyFinding] {
        
        var findings: [KeyFinding] = []
        
        // Analyze each pillar for key findings
        let pillars = [
            ("Asset Quality", scoringResult.pillarScores.assetQuality),
            ("Market Outlook", scoringResult.pillarScores.marketOutlook),
            ("Capital Intensity", scoringResult.pillarScores.capitalIntensity),
            ("Strategic Fit", scoringResult.pillarScores.strategicFit),
            ("Financial Readiness", scoringResult.pillarScores.financialReadiness),
            ("Regulatory Risk", scoringResult.pillarScores.regulatoryRisk)
        ]
        
        for (pillarName, pillarScore) in pillars {
            if pillarScore.rawScore >= 4.0 {
                findings.append(KeyFinding(
                    category: .strength,
                    title: "Strong \(pillarName)",
                    description: pillarScore.explanation ?? "Excellent performance in \(pillarName.lowercased())",
                    impact: .high,
                    supportingData: pillarScore.factors.map { $0.rationale }
                ))
            } else if pillarScore.rawScore <= 2.0 {
                findings.append(KeyFinding(
                    category: .weakness,
                    title: "Weak \(pillarName)",
                    description: pillarScore.explanation ?? "Concerns identified in \(pillarName.lowercased())",
                    impact: .high,
                    supportingData: pillarScore.warnings
                ))
            }
        }
        
        // Add pipeline-specific findings
        if let leadProgram = companyData.pipeline.leadProgram {
            if leadProgram.stage == .phase3 || leadProgram.stage == .approved {
                findings.append(KeyFinding(
                    category: .opportunity,
                    title: "Advanced Pipeline Asset",
                    description: "Lead program \(leadProgram.name) in \(leadProgram.stage.rawValue)",
                    impact: .high,
                    supportingData: ["Stage: \(leadProgram.stage.rawValue)", "Indication: \(leadProgram.indication)"]
                ))
            }
        }
        
        // Add financial findings
        if companyData.financials.runway < 12 {
            findings.append(KeyFinding(
                category: .threat,
                title: "Limited Financial Runway",
                description: "Company has approximately \(companyData.financials.runway) months of cash remaining",
                impact: .high,
                supportingData: [
                    "Cash Position: $\(numberFormatter.string(from: NSNumber(value: companyData.financials.cashPosition)) ?? "0")M",
                    "Monthly Burn: $\(numberFormatter.string(from: NSNumber(value: companyData.financials.burnRate)) ?? "0")M"
                ]
            ))
        }
        
        return findings.prefix(5).map { $0 } // Limit to top 5 findings
    }
    
    private func generateInvestmentThesis(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> String {
        
        let companyName = companyData.basicInfo.name
        let overallScore = scoringResult.overallScore
        let recommendation = scoringResult.investmentRecommendation.rawValue
        let stage = companyData.basicInfo.stage.rawValue
        let therapeuticAreas = companyData.basicInfo.therapeuticAreas.joined(separator: ", ")
        
        var thesis = "\(companyName) is a \(stage) biotech company focused on \(therapeuticAreas) with an overall score of \(String(format: "%.1f", overallScore))/5.0, resulting in a \(recommendation) recommendation. "
        
        // Add strengths
        let strongPillars = getStrongPillars(from: scoringResult)
        if !strongPillars.isEmpty {
            thesis += "Key strengths include \(strongPillars.joined(separator: ", ").lowercased()). "
        }
        
        // Add pipeline context
        if companyData.pipeline.totalPrograms > 1 {
            thesis += "The company has a diversified pipeline with \(companyData.pipeline.totalPrograms) programs. "
        }
        
        // Add market context
        if companyData.market.addressableMarket > 5.0 {
            thesis += "The addressable market opportunity exceeds $\(String(format: "%.1f", companyData.market.addressableMarket))B. "
        }
        
        // Add risk context
        let riskLevel = scoringResult.riskLevel.rawValue.lowercased()
        thesis += "The investment carries \(riskLevel) risk based on our comprehensive analysis."
        
        return thesis
    }
    
    private func getStrongPillars(from scoringResult: ScoringResult) -> [String] {
        let pillars = [
            ("asset quality", scoringResult.pillarScores.assetQuality.rawScore),
            ("market outlook", scoringResult.pillarScores.marketOutlook.rawScore),
            ("strategic fit", scoringResult.pillarScores.strategicFit.rawScore),
            ("financial readiness", scoringResult.pillarScores.financialReadiness.rawScore)
        ]
        
        return pillars.compactMap { name, score in
            score >= 4.0 ? name : nil
        }
    }
    
    private func extractKeyRisks(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [String] {
        
        var risks: [String] = []
        
        // Regulatory risks
        if scoringResult.pillarScores.regulatoryRisk.rawScore <= 3.0 {
            risks.append("Regulatory approval uncertainty")
        }
        
        // Financial risks
        if companyData.financials.runway < 18 {
            risks.append("Limited funding runway requiring near-term financing")
        }
        
        // Market risks
        if scoringResult.pillarScores.marketOutlook.rawScore <= 3.0 {
            risks.append("Competitive market dynamics and pricing pressure")
        }
        
        // Development risks
        if let leadProgram = companyData.pipeline.leadProgram {
            if leadProgram.stage == .phase1 || leadProgram.stage == .phase2 {
                risks.append("Clinical development and efficacy risks")
            }
        }
        
        // Add specific warnings from pillar scores
        let allWarnings = [
            scoringResult.pillarScores.assetQuality.warnings,
            scoringResult.pillarScores.marketOutlook.warnings,
            scoringResult.pillarScores.financialReadiness.warnings,
            scoringResult.pillarScores.regulatoryRisk.warnings
        ].flatMap { $0 }
        
        risks.append(contentsOf: allWarnings.prefix(2))
        
        return Array(risks.prefix(5))
    }
    
    private func extractKeyOpportunities(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [String] {
        
        var opportunities: [String] = []
        
        // Partnership opportunities
        if scoringResult.pillarScores.strategicFit.rawScore >= 4.0 {
            opportunities.append("Strong potential for strategic partnerships")
        }
        
        // Market opportunities
        if companyData.market.addressableMarket > 10.0 {
            opportunities.append("Large addressable market with significant upside potential")
        }
        
        // Pipeline opportunities
        if companyData.pipeline.totalPrograms >= 3 {
            opportunities.append("Diversified pipeline reducing single-asset risk")
        }
        
        // Regulatory opportunities
        let hasBreakthrough = companyData.regulatory.approvals.contains { approval in
            approval.type == .breakthrough || approval.type == .fastTrack
        }
        if hasBreakthrough {
            opportunities.append("Accelerated regulatory pathways available")
        }
        
        // IP opportunities
        if scoringResult.pillarScores.assetQuality.rawScore >= 4.0 {
            opportunities.append("Strong intellectual property position")
        }
        
        return Array(opportunities.prefix(4))
    }
    
    private func generateRecommendedActions(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [String] {
        
        var actions: [String] = []
        
        // Financial actions
        if companyData.financials.runway < 18 {
            actions.append("Initiate fundraising process within next 6 months")
        }
        
        // Partnership actions
        if scoringResult.pillarScores.strategicFit.rawScore >= 3.5 {
            actions.append("Explore strategic partnership opportunities")
        }
        
        // Development actions
        if let leadProgram = companyData.pipeline.leadProgram {
            if leadProgram.stage == .phase2 {
                actions.append("Monitor Phase II results and prepare for Phase III planning")
            }
        }
        
        // Market actions
        if scoringResult.pillarScores.marketOutlook.rawScore <= 3.0 {
            actions.append("Conduct deeper market analysis and competitive intelligence")
        }
        
        // Risk mitigation actions
        if scoringResult.riskLevel == .high || scoringResult.riskLevel == .veryHigh {
            actions.append("Implement risk mitigation strategies for identified concerns")
        }
        
        return Array(actions.prefix(4))
    }
    
    private func generateSummaryStatistics(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        valuationAnalysis: ValuationAnalysis?
    ) -> SummaryStatistics {
        
        // These would typically come from a database of historical evaluations
        // For now, using representative values
        return SummaryStatistics(
            totalCompaniesEvaluated: 247,
            averageScore: 3.2,
            percentileRanking: calculatePercentileRanking(score: scoringResult.overallScore),
            industryBenchmark: 3.1,
            timeToNextMilestone: calculateTimeToNextMilestone(companyData: companyData),
            estimatedValuation: valuationAnalysis?.baseValuation
        )
    }
    
    private func calculatePercentileRanking(score: Double) -> Double {
        // Simple percentile calculation based on score
        // In practice, this would use historical data
        switch score {
        case 4.5...:
            return 95.0
        case 4.0..<4.5:
            return 85.0
        case 3.5..<4.0:
            return 70.0
        case 3.0..<3.5:
            return 50.0
        case 2.5..<3.0:
            return 30.0
        default:
            return 15.0
        }
    }
    
    private func calculateTimeToNextMilestone(companyData: CompanyData) -> Int? {
        guard let leadProgram = companyData.pipeline.leadProgram else { return nil }
        
        let upcomingMilestones = leadProgram.timeline.filter { milestone in
            milestone.status == .upcoming && milestone.expectedDate > Date()
        }.sorted { $0.expectedDate < $1.expectedDate }
        
        guard let nextMilestone = upcomingMilestones.first else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: nextMilestone.expectedDate)
        return components.month
    }
    
    // MARK: - Detailed Analysis Generation
    
    private func generateDetailedAnalysis(
        from scoringResult: ScoringResult,
        companyData: CompanyData,
        includeValuation: Bool,
        valuationAnalysis: ValuationAnalysis?
    ) -> DetailedAnalysis {
        
        let scoringBreakdown = generateScoringBreakdown(from: scoringResult)
        let pillarAnalyses = generatePillarAnalyses(from: scoringResult, companyData: companyData)
        let comparativeAnalysis = generateComparativeAnalysis(from: scoringResult, companyData: companyData)
        let riskAssessment = generateRiskAssessment(from: scoringResult, companyData: companyData)
        let recommendations = generateDetailedRecommendations(from: scoringResult, companyData: companyData)
        
        return DetailedAnalysis(
            scoringBreakdown: scoringBreakdown,
            pillarAnalyses: pillarAnalyses,
            comparativeAnalysis: comparativeAnalysis,
            riskAssessment: riskAssessment,
            valuationAnalysis: includeValuation ? valuationAnalysis : nil,
            recommendations: recommendations
        )
    }
    
    private func generateScoringBreakdown(from scoringResult: ScoringResult) -> ScoringBreakdown {
        return ScoringBreakdown(
            pillarScores: scoringResult.pillarScores,
            weightedScores: scoringResult.weightedScores,
            weightConfiguration: WeightConfig(), // Would come from scoring configuration
            confidenceMetrics: scoringResult.confidence,
            scoringMethodology: "Six-pillar weighted scoring framework with configurable weights and confidence adjustments"
        )
    }
    
    private func generatePillarAnalyses(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [PillarAnalysis] {
        
        let pillars = [
            ("Asset Quality", scoringResult.pillarScores.assetQuality, scoringResult.weightedScores.assetQuality),
            ("Market Outlook", scoringResult.pillarScores.marketOutlook, scoringResult.weightedScores.marketOutlook),
            ("Capital Intensity", scoringResult.pillarScores.capitalIntensity, scoringResult.weightedScores.capitalIntensity),
            ("Strategic Fit", scoringResult.pillarScores.strategicFit, scoringResult.weightedScores.strategicFit),
            ("Financial Readiness", scoringResult.pillarScores.financialReadiness, scoringResult.weightedScores.financialReadiness),
            ("Regulatory Risk", scoringResult.pillarScores.regulatoryRisk, scoringResult.weightedScores.regulatoryRisk)
        ]
        
        return pillars.map { name, pillarScore, weightedScore in
            generatePillarAnalysis(
                pillarName: name,
                pillarScore: pillarScore,
                weightedScore: weightedScore,
                companyData: companyData
            )
        }
    }
    
    private func generatePillarAnalysis(
        pillarName: String,
        pillarScore: PillarScore,
        weightedScore: Double,
        companyData: CompanyData
    ) -> PillarAnalysis {
        
        let analysis = generatePillarAnalysisText(pillarName: pillarName, pillarScore: pillarScore, companyData: companyData)
        let keyMetrics = generatePillarKeyMetrics(pillarName: pillarName, companyData: companyData)
        let benchmarks = generatePillarBenchmarks(pillarName: pillarName, pillarScore: pillarScore)
        let recommendations = generatePillarRecommendations(pillarName: pillarName, pillarScore: pillarScore)
        
        return PillarAnalysis(
            pillarName: pillarName,
            score: pillarScore,
            weightedScore: weightedScore,
            analysis: analysis,
            keyMetrics: keyMetrics,
            benchmarks: benchmarks,
            recommendations: recommendations
        )
    }
    
    private func generatePillarAnalysisText(
        pillarName: String,
        pillarScore: PillarScore,
        companyData: CompanyData
    ) -> String {
        
        let scoreDescription = getScoreDescription(pillarScore.rawScore)
        var analysis = "\(pillarName) scored \(String(format: "%.1f", pillarScore.rawScore))/5.0, indicating \(scoreDescription) performance. "
        
        // Add pillar-specific context
        switch pillarName {
        case "Asset Quality":
            analysis += "The assessment considered pipeline diversity (\(companyData.pipeline.totalPrograms) programs), development stage, and competitive positioning. "
        case "Market Outlook":
            analysis += "Market analysis evaluated the $\(String(format: "%.1f", companyData.market.addressableMarket))B addressable market and competitive dynamics. "
        case "Financial Readiness":
            analysis += "Financial evaluation considered current cash position ($\(String(format: "%.1f", companyData.financials.cashPosition))M) and \(companyData.financials.runway)-month runway. "
        case "Strategic Fit":
            analysis += "Strategic assessment evaluated partnership potential and synergy opportunities in \(companyData.basicInfo.therapeuticAreas.joined(separator: ", ")). "
        default:
            break
        }
        
        // Add confidence context
        let confidenceDescription = getConfidenceDescription(pillarScore.confidence)
        analysis += "Confidence in this assessment is \(confidenceDescription) (\(String(format: "%.0f", pillarScore.confidence * 100))%)."
        
        return analysis
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...:
            return "exceptional"
        case 4.0..<4.5:
            return "strong"
        case 3.5..<4.0:
            return "good"
        case 3.0..<3.5:
            return "adequate"
        case 2.5..<3.0:
            return "below average"
        default:
            return "weak"
        }
    }
    
    private func getConfidenceDescription(_ confidence: Double) -> String {
        switch confidence {
        case 0.9...:
            return "very high"
        case 0.8..<0.9:
            return "high"
        case 0.7..<0.8:
            return "moderate"
        case 0.6..<0.7:
            return "fair"
        default:
            return "low"
        }
    }
    
    private func generatePillarKeyMetrics(pillarName: String, companyData: CompanyData) -> [KeyMetric] {
        switch pillarName {
        case "Asset Quality":
            return [
                KeyMetric(name: "Pipeline Programs", value: "\(companyData.pipeline.totalPrograms)", benchmark: "3.2", trend: .stable, importance: .high),
                KeyMetric(name: "Lead Program Stage", value: companyData.pipeline.leadProgram?.stage.rawValue ?? "N/A", benchmark: "Phase II", trend: .improving, importance: .critical)
            ]
        case "Financial Readiness":
            return [
                KeyMetric(name: "Cash Position", value: "$\(String(format: "%.1f", companyData.financials.cashPosition))M", benchmark: "$45M", trend: .stable, importance: .critical),
                KeyMetric(name: "Runway", value: "\(companyData.financials.runway) months", benchmark: "18 months", trend: .declining, importance: .high)
            ]
        case "Market Outlook":
            return [
                KeyMetric(name: "Addressable Market", value: "$\(String(format: "%.1f", companyData.market.addressableMarket))B", benchmark: "$8.5B", trend: .improving, importance: .high)
            ]
        default:
            return []
        }
    }
    
    private func generatePillarBenchmarks(pillarName: String, pillarScore: PillarScore) -> [Benchmark] {
        let industryAverage = 3.1
        let percentile = calculatePercentileRanking(score: pillarScore.rawScore)
        
        return [
            Benchmark(
                category: "\(pillarName) Score",
                companyValue: pillarScore.rawScore,
                benchmarkValue: industryAverage,
                percentile: percentile,
                interpretation: pillarScore.rawScore > industryAverage ? "Above industry average" : "Below industry average"
            )
        ]
    }
    
    private func generatePillarRecommendations(pillarName: String, pillarScore: PillarScore) -> [String] {
        var recommendations: [String] = []
        
        if pillarScore.rawScore < 3.0 {
            recommendations.append("Address identified weaknesses in \(pillarName.lowercased())")
        }
        
        if pillarScore.confidence < 0.7 {
            recommendations.append("Gather additional data to improve assessment confidence")
        }
        
        // Add specific recommendations based on warnings
        recommendations.append(contentsOf: pillarScore.warnings.prefix(2))
        
        return recommendations
    }
    
    // MARK: - Additional Analysis Components
    
    private func generateComparativeAnalysis(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> ComparativeAnalysis {
        
        // In practice, this would query a database of peer companies
        let peerComparisons = [
            PeerComparison(
                peerName: "Similar Biotech A",
                companyScore: scoringResult.overallScore,
                peerScore: 3.4,
                keyDifferences: ["Stronger pipeline", "Better financials"]
            )
        ]
        
        let industryBenchmarks = [
            IndustryBenchmark(
                metric: "Overall Score",
                companyValue: scoringResult.overallScore,
                industryAverage: 3.1,
                industryMedian: 3.0,
                topQuartile: 4.2
            )
        ]
        
        let marketPosition: MarketPosition = scoringResult.overallScore >= 4.0 ? .leader : 
                                           scoringResult.overallScore >= 3.5 ? .challenger : .follower
        
        return ComparativeAnalysis(
            peerComparison: peerComparisons,
            industryBenchmarks: industryBenchmarks,
            marketPosition: marketPosition,
            competitiveAdvantages: getStrongPillars(from: scoringResult),
            competitiveDisadvantages: getWeakPillars(from: scoringResult)
        )
    }
    
    private func getWeakPillars(from scoringResult: ScoringResult) -> [String] {
        let pillars = [
            ("Limited asset quality", scoringResult.pillarScores.assetQuality.rawScore),
            ("Challenging market outlook", scoringResult.pillarScores.marketOutlook.rawScore),
            ("High capital intensity", scoringResult.pillarScores.capitalIntensity.rawScore),
            ("Poor strategic fit", scoringResult.pillarScores.strategicFit.rawScore),
            ("Weak financial position", scoringResult.pillarScores.financialReadiness.rawScore),
            ("High regulatory risk", scoringResult.pillarScores.regulatoryRisk.rawScore)
        ]
        
        return pillars.compactMap { name, score in
            score <= 2.5 ? name : nil
        }
    }
    
    private func generateRiskAssessment(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> RiskAssessment {
        
        let riskCategories = [
            generateRegulatoryRiskCategory(from: scoringResult, companyData: companyData),
            generateFinancialRiskCategory(from: scoringResult, companyData: companyData),
            generateMarketRiskCategory(from: scoringResult, companyData: companyData)
        ]
        
        let mitigationStrategies = generateMitigationStrategies(riskCategories: riskCategories)
        
        return RiskAssessment(
            overallRiskLevel: scoringResult.riskLevel,
            riskCategories: riskCategories,
            mitigationStrategies: mitigationStrategies,
            riskMatrix: [[]] // Would be populated with detailed risk matrix
        )
    }
    
    private func generateRegulatoryRiskCategory(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> RiskCategory {
        
        let riskLevel: RiskLevel = scoringResult.pillarScores.regulatoryRisk.rawScore <= 2.5 ? .high : .medium
        
        let risks = [
            RiskItem(
                description: "FDA approval uncertainty for lead program",
                probability: .medium,
                impact: .high,
                timeframe: .mediumTerm,
                mitigation: "Engage with FDA early and frequently"
            )
        ]
        
        return RiskCategory(
            name: "Regulatory Risk",
            level: riskLevel,
            risks: risks,
            impact: "Could delay market entry by 12-24 months",
            likelihood: "Moderate based on development stage and precedent"
        )
    }
    
    private func generateFinancialRiskCategory(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> RiskCategory {
        
        let riskLevel: RiskLevel = companyData.financials.runway < 12 ? .high : .medium
        
        let risks = [
            RiskItem(
                description: "Funding shortfall requiring dilutive financing",
                probability: companyData.financials.runway < 18 ? .high : .medium,
                impact: .high,
                timeframe: .nearTerm,
                mitigation: "Initiate fundraising process early"
            )
        ]
        
        return RiskCategory(
            name: "Financial Risk",
            level: riskLevel,
            risks: risks,
            impact: "Could force unfavorable financing terms or asset sales",
            likelihood: "High if runway falls below 12 months"
        )
    }
    
    private func generateMarketRiskCategory(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> RiskCategory {
        
        let riskLevel: RiskLevel = scoringResult.pillarScores.marketOutlook.rawScore <= 2.5 ? .high : .medium
        
        let risks = [
            RiskItem(
                description: "Competitive pressure from larger players",
                probability: .medium,
                impact: .medium,
                timeframe: .longTerm,
                mitigation: "Focus on differentiation and niche positioning"
            )
        ]
        
        return RiskCategory(
            name: "Market Risk",
            level: riskLevel,
            risks: risks,
            impact: "Could limit pricing power and market share",
            likelihood: "Moderate in competitive therapeutic areas"
        )
    }
    
    private func generateMitigationStrategies(riskCategories: [RiskCategory]) -> [MitigationStrategy] {
        return riskCategories.flatMap { category in
            category.risks.map { risk in
                MitigationStrategy(
                    riskId: risk.id,
                    strategy: risk.mitigation ?? "Monitor and reassess regularly",
                    cost: .medium,
                    effectiveness: .medium,
                    timeline: "6-12 months"
                )
            }
        }
    }
    
    private func generateDetailedRecommendations(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> DetailedRecommendations {
        
        let actionItems = generateActionItems(from: scoringResult, companyData: companyData)
        let timeline = generateRecommendationTimeline(from: scoringResult, companyData: companyData)
        let successMetrics = generateSuccessMetrics(from: scoringResult, companyData: companyData)
        let alternativeScenarios = generateAlternativeScenarios(from: scoringResult, companyData: companyData)
        
        return DetailedRecommendations(
            investmentRecommendation: scoringResult.investmentRecommendation,
            rationale: generateInvestmentThesis(from: scoringResult, companyData: companyData),
            actionItems: actionItems,
            timeline: timeline,
            successMetrics: successMetrics,
            alternativeScenarios: alternativeScenarios
        )
    }
    
    private func generateActionItems(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [ActionItem] {
        
        var actions: [ActionItem] = []
        
        if companyData.financials.runway < 18 {
            actions.append(ActionItem(
                action: "Initiate Series B fundraising process",
                priority: .critical,
                owner: "CFO",
                deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                expectedOutcome: "Secure 24+ months additional runway"
            ))
        }
        
        if scoringResult.pillarScores.strategicFit.rawScore >= 3.5 {
            actions.append(ActionItem(
                action: "Explore strategic partnership opportunities",
                priority: .high,
                owner: "Business Development",
                deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                expectedOutcome: "Identify 2-3 potential partners"
            ))
        }
        
        return actions
    }
    
    private func generateRecommendationTimeline(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> RecommendationTimeline {
        
        return RecommendationTimeline(
            immediate: ["Review latest clinical data", "Update financial projections"],
            nearTerm: ["Execute fundraising strategy", "Advance partnership discussions"],
            longTerm: ["Monitor competitive landscape", "Prepare for next development phase"]
        )
    }
    
    private func generateSuccessMetrics(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [SuccessMetric] {
        
        return [
            SuccessMetric(
                metric: "Clinical Trial Success Rate",
                currentValue: "65%",
                targetValue: "75%",
                timeframe: "12 months",
                measurement: "Phase completion rates"
            ),
            SuccessMetric(
                metric: "Cash Runway",
                currentValue: "\(companyData.financials.runway) months",
                targetValue: "24+ months",
                timeframe: "6 months",
                measurement: "Monthly burn rate analysis"
            )
        ]
    }
    
    private func generateAlternativeScenarios(
        from scoringResult: ScoringResult,
        companyData: CompanyData
    ) -> [AlternativeScenario] {
        
        return [
            AlternativeScenario(
                name: "Partnership Scenario",
                description: "Early strategic partnership with pharmaceutical company",
                probability: 0.3,
                implications: ["Reduced financial risk", "Accelerated development", "Lower upside potential"],
                recommendedActions: ["Negotiate favorable milestone payments", "Retain co-commercialization rights"]
            ),
            AlternativeScenario(
                name: "IPO Scenario",
                description: "Public offering within 18-24 months",
                probability: 0.4,
                implications: ["Access to public markets", "Increased regulatory scrutiny", "Quarterly reporting requirements"],
                recommendedActions: ["Strengthen management team", "Improve financial reporting", "Build investor relations capability"]
            )
        ]
    }
    
    // MARK: - Report Metadata
    
    private func generateReportMetadata(
        companyData: CompanyData,
        template: ReportTemplate
    ) -> ReportMetadata {
        
        return ReportMetadata(
            generatedDate: Date(),
            generatedBy: "BD & IPO Scoring Module",
            version: "1.0",
            dataAsOfDate: Date(),
            confidentialityLevel: .confidential,
            distributionList: [],
            expirationDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            disclaimers: [
                "This analysis is for internal use only and should not be distributed without authorization.",
                "Projections and valuations are estimates based on available data and may not reflect actual outcomes.",
                "Investment decisions should consider additional factors beyond this analysis."
            ]
        )
    }
}

// MARK: - Export Service

/// Service for exporting reports to various formats
class ReportExportService {
    
    /// Exports a report to the specified format
    func exportReport(
        _ report: Report,
        configuration: ExportConfiguration
    ) -> Result<Data, ReportExportError> {
        
        switch configuration.format {
        case .pdf:
            return exportToPDF(report, configuration: configuration)
        case .excel:
            return exportToExcel(report, configuration: configuration)
        case .powerpoint:
            return exportToPowerPoint(report, configuration: configuration)
        case .word:
            return exportToWord(report, configuration: configuration)
        case .html:
            return exportToHTML(report, configuration: configuration)
        }
    }
    
    private func exportToPDF(_ report: Report, configuration: ExportConfiguration) -> Result<Data, ReportExportError> {
        // PDF export implementation would go here
        // For now, return a placeholder
        let pdfContent = generatePDFContent(report)
        return .success(pdfContent.data(using: .utf8) ?? Data())
    }
    
    private func exportToExcel(_ report: Report, configuration: ExportConfiguration) -> Result<Data, ReportExportError> {
        // Excel export implementation would go here
        let excelContent = generateExcelContent(report)
        return .success(excelContent.data(using: .utf8) ?? Data())
    }
    
    private func exportToPowerPoint(_ report: Report, configuration: ExportConfiguration) -> Result<Data, ReportExportError> {
        // PowerPoint export implementation would go here
        let pptContent = generatePowerPointContent(report)
        return .success(pptContent.data(using: .utf8) ?? Data())
    }
    
    private func exportToWord(_ report: Report, configuration: ExportConfiguration) -> Result<Data, ReportExportError> {
        // Word export implementation would go here
        let wordContent = generateWordContent(report)
        return .success(wordContent.data(using: .utf8) ?? Data())
    }
    
    private func exportToHTML(_ report: Report, configuration: ExportConfiguration) -> Result<Data, ReportExportError> {
        let htmlContent = generateHTMLContent(report)
        return .success(htmlContent.data(using: .utf8) ?? Data())
    }
    
    // MARK: - Content Generation
    
    private func generatePDFContent(_ report: Report) -> String {
        return """
        PDF Report: \(report.title)
        Company: \(report.companyName)
        Overall Score: \(String(format: "%.1f", report.executiveSummary.overallScore))
        Recommendation: \(report.executiveSummary.investmentRecommendation.rawValue)
        
        Executive Summary:
        \(report.executiveSummary.investmentThesis)
        
        Key Findings:
        \(report.executiveSummary.keyFindings.map { "• \($0.title): \($0.description)" }.joined(separator: "\n"))
        """
    }
    
    private func generateExcelContent(_ report: Report) -> String {
        return """
        Excel Report Data for \(report.companyName)
        Overall Score,\(report.executiveSummary.overallScore)
        Asset Quality,\(report.detailedAnalysis.scoringBreakdown.pillarScores.assetQuality.rawScore)
        Market Outlook,\(report.detailedAnalysis.scoringBreakdown.pillarScores.marketOutlook.rawScore)
        Financial Readiness,\(report.detailedAnalysis.scoringBreakdown.pillarScores.financialReadiness.rawScore)
        """
    }
    
    private func generatePowerPointContent(_ report: Report) -> String {
        return """
        PowerPoint Presentation: \(report.title)
        
        Slide 1: Executive Summary
        - Company: \(report.companyName)
        - Score: \(String(format: "%.1f", report.executiveSummary.overallScore))/5.0
        - Recommendation: \(report.executiveSummary.investmentRecommendation.rawValue)
        
        Slide 2: Key Findings
        \(report.executiveSummary.keyFindings.map { "• \($0.title)" }.joined(separator: "\n"))
        """
    }
    
    private func generateWordContent(_ report: Report) -> String {
        return """
        \(report.title)
        
        Executive Summary
        \(report.executiveSummary.investmentThesis)
        
        Overall Score: \(String(format: "%.1f", report.executiveSummary.overallScore))/5.0
        Investment Recommendation: \(report.executiveSummary.investmentRecommendation.rawValue)
        Risk Level: \(report.executiveSummary.riskLevel.rawValue)
        
        Key Findings:
        \(report.executiveSummary.keyFindings.map { "• \($0.title): \($0.description)" }.joined(separator: "\n"))
        """
    }
    
    private func generateHTMLContent(_ report: Report) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>\(report.title)</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .header { color: #1f4e79; border-bottom: 2px solid #1f4e79; padding-bottom: 10px; }
                .score { font-size: 24px; font-weight: bold; color: #4472c4; }
                .finding { margin: 10px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>\(report.title)</h1>
                <h2>\(report.companyName)</h2>
            </div>
            
            <div class="score">
                Overall Score: \(String(format: "%.1f", report.executiveSummary.overallScore))/5.0
            </div>
            
            <h3>Investment Recommendation: \(report.executiveSummary.investmentRecommendation.rawValue)</h3>
            
            <h3>Executive Summary</h3>
            <p>\(report.executiveSummary.investmentThesis)</p>
            
            <h3>Key Findings</h3>
            \(report.executiveSummary.keyFindings.map { "<div class=\"finding\"><strong>\($0.title)</strong>: \($0.description)</div>" }.joined(separator: "\n"))
        </body>
        </html>
        """
    }
}

// MARK: - Export Error Types

enum ReportExportError: Error, LocalizedError {
    case unsupportedFormat
    case generationFailed(String)
    case insufficientData
    case templateError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "The requested export format is not supported"
        case .generationFailed(let reason):
            return "Report generation failed: \(reason)"
        case .insufficientData:
            return "Insufficient data to generate the requested report"
        case .templateError:
            return "Template configuration error"
        }
    }
}