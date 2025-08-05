import Foundation

// MARK: - Capital Intensity Scoring Pillar

/// Assesses development costs and capital requirements
public class CapitalIntensityPillar: BaseScoringPillar {
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createCapitalIntensityInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Capital Intensity scoring requires valid financial and development stage data")
        }
        
        // Calculate individual scoring factors
        let developmentCostFactor = calculateDevelopmentCost(data)
        let capitalEfficiencyFactor = calculateCapitalEfficiency(data)
        let manufacturingComplexityFactor = calculateManufacturingComplexity(data)
        let regulatoryCostFactor = calculateRegulatoryCost(data)
        let timeToMarketFactor = calculateTimeToMarket(data)
        let scalabilityFactor = calculateScalability(data)
        
        let factors = [
            developmentCostFactor,
            capitalEfficiencyFactor,
            manufacturingComplexityFactor,
            regulatoryCostFactor,
            timeToMarketFactor,
            scalabilityFactor
        ]
        
        // Calculate weighted score
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: assessDataQuality(data),
            methodologyReliability: 0.80 // Capital intensity methodology has moderate reliability
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateCapitalSpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Capital intensity evaluation based on development costs, capital efficiency, manufacturing complexity, regulatory costs, time to market, and scalability"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check financial data
        if data.financials.burnRate <= 0 {
            errors.append(ValidationError(
                field: "financials.burnRate",
                message: "Valid burn rate is required for capital intensity assessment",
                severity: .critical
            ))
        }
        
        // Check development stage
        if data.basicInfo.stage == .approved || data.basicInfo.stage == .marketed {
            warnings.append(ValidationWarning(
                field: "basicInfo.stage",
                message: "Capital intensity assessment is most relevant for companies in development stages",
                suggestion: "Consider focusing on post-market capital requirements for approved products"
            ))
        }
        
        // Check pipeline data for cost estimation
        if data.pipeline.programs.isEmpty {
            warnings.append(ValidationWarning(
                field: "pipeline.programs",
                message: "No pipeline programs specified",
                suggestion: "Add pipeline programs for more accurate capital intensity assessment"
            ))
        }
        
        // Check clinical trial data
        if data.regulatory.clinicalTrials.isEmpty && data.basicInfo.stage != .preclinical {
            warnings.append(ValidationWarning(
                field: "regulatory.clinicalTrials",
                message: "No clinical trial data available for development-stage company",
                suggestion: "Add clinical trial information for better cost estimation"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateDataCompleteness(data)
        )
    }
    
    // MARK: - Scoring Factor Calculations
    
    private func calculateDevelopmentCost(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let programCount = data.pipeline.programs.count
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        
        // Base cost estimation by stage (higher score = lower cost/better)
        var score: Double = 3.0
        
        // Adjust based on development stage
        switch stage {
        case .preclinical:
            score = 4.5 // Lower costs in preclinical
        case .phase1:
            score = 4.0 // Moderate costs
        case .phase2:
            score = 3.0 // Higher costs
        case .phase3:
            score = 2.0 // Very high costs
        case .approved, .marketed:
            score = 4.0 // Post-approval costs are different
        }
        
        // Adjust for therapeutic area complexity
        let complexAreas = ["oncology", "neurology", "rare diseases", "gene therapy"]
        let hasComplexArea = therapeuticAreas.contains { area in
            complexAreas.contains { complex in
                area.lowercased().contains(complex)
            }
        }
        
        if hasComplexArea {
            score -= 0.5 // Complex therapeutic areas increase costs
        }
        
        // Adjust for multiple programs (economies of scale vs. resource dilution)
        if programCount > 3 {
            score -= 0.3 // Multiple programs increase capital intensity
        } else if programCount == 1 {
            score += 0.2 // Single program focus can be more efficient
        }
        
        let rationale = "Development cost assessment based on stage (\(stage.rawValue)), therapeutic complexity, and program portfolio size"
        
        return createScoringFactor(
            name: "Development Cost",
            weight: 0.25,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateCapitalEfficiency(_ data: CompanyData) -> ScoringFactor {
        let burnRate = data.financials.burnRate
        let cashPosition = data.financials.cashPosition
        let programCount = max(1, data.pipeline.programs.count)
        
        // Calculate efficiency metrics
        let burnPerProgram = burnRate / Double(programCount)
        let cashPerProgram = cashPosition / Double(programCount)
        
        var score: Double = 3.0
        
        // Score based on burn rate efficiency
        switch burnPerProgram {
        case 0...2.0:
            score = 4.5 // Very efficient
        case 2.0...5.0:
            score = 4.0 // Efficient
        case 5.0...10.0:
            score = 3.0 // Average
        case 10.0...20.0:
            score = 2.0 // Inefficient
        default:
            score = 1.5 // Very inefficient
        }
        
        // Adjust for cash management
        if cashPerProgram > 50.0 {
            score += 0.3 // Well-capitalized per program
        } else if cashPerProgram < 10.0 {
            score -= 0.3 // Under-capitalized per program
        }
        
        let rationale = "Capital efficiency based on burn rate per program ($\(String(format: "%.1f", burnPerProgram))M/month) and cash allocation"
        
        return createScoringFactor(
            name: "Capital Efficiency",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateManufacturingComplexity(_ data: CompanyData) -> ScoringFactor {
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let programs = data.pipeline.programs
        
        var score: Double = 3.5 // Default moderate complexity
        
        // Assess manufacturing complexity by therapeutic area and mechanism
        let highComplexityAreas = ["gene therapy", "cell therapy", "biologics", "personalized medicine"]
        let moderateComplexityAreas = ["monoclonal antibodies", "vaccines", "protein therapeutics"]
        let lowComplexityAreas = ["small molecules", "generics"]
        
        var complexityLevel = 0
        
        for area in therapeuticAreas {
            let lowerArea = area.lowercased()
            if highComplexityAreas.contains(where: { lowerArea.contains($0) }) {
                complexityLevel = max(complexityLevel, 3)
            } else if moderateComplexityAreas.contains(where: { lowerArea.contains($0) }) {
                complexityLevel = max(complexityLevel, 2)
            } else if lowComplexityAreas.contains(where: { lowerArea.contains($0) }) {
                complexityLevel = max(complexityLevel, 1)
            }
        }
        
        // Check program mechanisms for additional complexity indicators
        for program in programs {
            let mechanism = program.mechanism.lowercased()
            if mechanism.contains("gene") || mechanism.contains("cell") || mechanism.contains("viral") {
                complexityLevel = max(complexityLevel, 3)
            } else if mechanism.contains("antibody") || mechanism.contains("protein") {
                complexityLevel = max(complexityLevel, 2)
            }
        }
        
        // Score based on complexity (higher score = lower complexity/better)
        switch complexityLevel {
        case 0, 1:
            score = 4.5 // Low complexity
        case 2:
            score = 3.5 // Moderate complexity
        case 3:
            score = 2.0 // High complexity
        default:
            score = 3.0
        }
        
        let complexityDescription = complexityLevel == 3 ? "High" : complexityLevel == 2 ? "Moderate" : "Low"
        let rationale = "Manufacturing complexity assessment: \(complexityDescription) based on therapeutic areas and mechanisms"
        
        return createScoringFactor(
            name: "Manufacturing Complexity",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateRegulatoryCost(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let clinicalTrials = data.regulatory.clinicalTrials
        let pathway = data.regulatory.regulatoryStrategy.pathway
        
        var score: Double = 3.0
        
        // Base score by regulatory pathway (higher score = lower cost)
        switch pathway {
        case .orphan:
            score = 4.5 // Orphan designation reduces costs
        case .breakthrough, .fastTrack:
            score = 4.0 // Accelerated pathways reduce costs
        case .accelerated:
            score = 3.5 // Some cost savings
        case .standard:
            score = 3.0 // Standard costs
        }
        
        // Adjust for clinical trial complexity
        let activeTrials = clinicalTrials.filter { $0.status == .active || $0.status == .recruiting }
        let phase3Trials = clinicalTrials.filter { $0.phase == .phase3 }
        
        if phase3Trials.count > 1 {
            score -= 0.5 // Multiple Phase 3 trials are expensive
        }
        
        if activeTrials.count > 3 {
            score -= 0.3 // Many concurrent trials increase costs
        }
        
        // Adjust for patient count requirements
        let totalPatients = clinicalTrials.compactMap { $0.patientCount }.reduce(0, +)
        if totalPatients > 1000 {
            score -= 0.4 // Large patient populations increase costs
        } else if totalPatients < 100 {
            score += 0.2 // Small studies are more cost-effective
        }
        
        let rationale = "Regulatory cost assessment based on pathway (\(pathway.rawValue)), trial complexity, and patient requirements"
        
        return createScoringFactor(
            name: "Regulatory Cost",
            weight: 0.15,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateTimeToMarket(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let timeline = data.regulatory.regulatoryStrategy.timeline
        let programs = data.pipeline.programs
        
        var score: Double = 3.0
        
        // Base score by development stage (higher score = shorter time/better)
        switch stage {
        case .preclinical:
            score = 2.0 // Long time to market
        case .phase1:
            score = 2.5 // Moderate time
        case .phase2:
            score = 3.5 // Getting closer
        case .phase3:
            score = 4.0 // Near-term potential
        case .approved:
            score = 5.0 // Already approved
        case .marketed:
            score = 5.0 // Already marketed
        }
        
        // Adjust for regulatory timeline
        if timeline <= 24 {
            score += 0.5 // Fast timeline
        } else if timeline > 60 {
            score -= 0.5 // Slow timeline
        }
        
        // Consider lead program milestones
        if let leadProgram = programs.first {
            let upcomingMilestones = leadProgram.timeline.filter { $0.status == .upcoming }
            let nearTermMilestones = upcomingMilestones.filter { 
                Calendar.current.dateInterval(of: .year, for: Date())?.contains($0.expectedDate) ?? false
            }
            
            if nearTermMilestones.count > 0 {
                score += 0.3 // Near-term catalysts
            }
        }
        
        let rationale = "Time to market assessment based on development stage, regulatory timeline (\(timeline) months), and upcoming milestones"
        
        return createScoringFactor(
            name: "Time to Market",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateScalability(_ data: CompanyData) -> ScoringFactor {
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let programs = data.pipeline.programs
        let marketSize = data.market.addressableMarket
        
        var score: Double = 3.0
        
        // Score based on market size potential
        switch marketSize {
        case 0...1.0:
            score = 2.0 // Small market, limited scalability
        case 1.0...5.0:
            score = 3.0 // Moderate market
        case 5.0...20.0:
            score = 4.0 // Large market
        default:
            score = 4.5 // Very large market
        }
        
        // Adjust for platform potential
        let platformAreas = ["gene therapy", "cell therapy", "platform technology"]
        let hasPlatformPotential = therapeuticAreas.contains { area in
            platformAreas.contains { platform in
                area.lowercased().contains(platform)
            }
        }
        
        if hasPlatformPotential {
            score += 0.5 // Platform technologies have better scalability
        }
        
        // Consider program diversity for scalability
        let uniqueIndications = Set(programs.map { $0.indication })
        if uniqueIndications.count > 2 {
            score += 0.2 // Multiple indications improve scalability
        }
        
        // Check for manufacturing scalability indicators
        let scalableManufacturing = programs.contains { program in
            program.mechanism.lowercased().contains("small molecule") ||
            program.mechanism.lowercased().contains("oral")
        }
        
        if scalableManufacturing {
            score += 0.3 // Scalable manufacturing approaches
        }
        
        let rationale = "Scalability assessment based on market size ($\(String(format: "%.1f", marketSize))B), platform potential, and manufacturing approach"
        
        return createScoringFactor(
            name: "Scalability",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    // MARK: - Helper Methods
    
    private func assessDataQuality(_ data: CompanyData) -> Double {
        var qualityScore = 1.0
        
        // Check financial data recency
        if let lastFunding = data.financials.lastFunding {
            let monthsSinceLastFunding = Calendar.current.dateComponents([.month], from: lastFunding.date, to: Date()).month ?? 0
            if monthsSinceLastFunding > 12 {
                qualityScore -= 0.2 // Outdated financial data
            }
        }
        
        // Check burn rate reasonableness
        if data.financials.burnRate > data.financials.cashPosition {
            qualityScore -= 0.1 // Unrealistic burn rate
        }
        
        // Check clinical trial data completeness
        let trialsWithPatientCount = data.regulatory.clinicalTrials.filter { $0.patientCount != nil }
        let trialCompleteness = Double(trialsWithPatientCount.count) / max(1.0, Double(data.regulatory.clinicalTrials.count))
        qualityScore *= trialCompleteness
        
        return max(0.0, min(1.0, qualityScore))
    }
    
    private func generateCapitalSpecificWarnings(_ data: CompanyData) -> [String] {
        var warnings: [String] = []
        
        // Check for high burn rate
        if data.financials.burnRate > 10.0 {
            warnings.append("High monthly burn rate may indicate capital inefficiency")
        }
        
        // Check for short runway
        if data.financials.runway < 12 {
            warnings.append("Short funding runway may require immediate capital raising")
        }
        
        // Check for complex manufacturing
        let complexAreas = ["gene therapy", "cell therapy"]
        let hasComplexManufacturing = data.basicInfo.therapeuticAreas.contains { area in
            complexAreas.contains { complex in
                area.lowercased().contains(complex)
            }
        }
        
        if hasComplexManufacturing {
            warnings.append("Complex manufacturing may require significant capital investment")
        }
        
        // Check for multiple Phase 3 trials
        let phase3Trials = data.regulatory.clinicalTrials.filter { $0.phase == .phase3 }
        if phase3Trials.count > 1 {
            warnings.append("Multiple Phase 3 trials significantly increase capital requirements")
        }
        
        return warnings
    }
    
    // MARK: - Overridden Methods
    
    internal override func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        let capitalIntensity = score.rawScore >= 3.5 ? "Low" : score.rawScore >= 2.5 ? "Moderate" : "High"
        return "Capital Intensity scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription)) - \(capitalIntensity) capital intensity"
    }
    
    internal override func getMethodologyDescription() -> String {
        return "Capital intensity evaluation using development cost analysis, capital efficiency metrics, manufacturing complexity assessment, regulatory cost estimation, time-to-market analysis, and scalability potential"
    }
    
    internal override func getKnownLimitations() -> [String] {
        return [
            "Cost estimates are based on industry averages and may vary significantly",
            "Manufacturing complexity assessment is simplified and may not capture all factors",
            "Regulatory costs can change based on agency feedback and requirements",
            "Market conditions and competitive landscape can affect capital requirements",
            "Platform technology potential may be difficult to assess in early stages"
        ]
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0:
            return "Very Low Capital Intensity"
        case 3.5..<4.5:
            return "Low Capital Intensity"
        case 2.5..<3.5:
            return "Moderate Capital Intensity"
        case 1.5..<2.5:
            return "High Capital Intensity"
        default:
            return "Very High Capital Intensity"
        }
    }
}