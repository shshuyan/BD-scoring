import Foundation

// MARK: - Strategic Fit Scoring Pillar

/// Analyzes alignment with acquirer capabilities and strategy
public class StrategicFitPillar: BaseScoringPillar {
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createStrategicFitInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Strategic Fit scoring requires valid therapeutic area and pipeline data")
        }
        
        // Calculate individual scoring factors
        let therapeuticAlignmentFactor = calculateTherapeuticAlignment(data, context: context)
        let capabilityComplementFactor = calculateCapabilityComplement(data)
        let synergyPotentialFactor = calculateSynergyPotential(data, context: context)
        let integrationComplexityFactor = calculateIntegrationComplexity(data)
        let geographicFitFactor = calculateGeographicFit(data)
        let culturalFitFactor = calculateCulturalFit(data)
        
        let factors = [
            therapeuticAlignmentFactor,
            capabilityComplementFactor,
            synergyPotentialFactor,
            integrationComplexityFactor,
            geographicFitFactor,
            culturalFitFactor
        ]
        
        // Calculate weighted score
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: assessDataQuality(data),
            methodologyReliability: 0.75 // Strategic fit assessment has moderate reliability due to subjective factors
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateStrategicSpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Strategic fit evaluation based on therapeutic alignment, capability complement, synergy potential, integration complexity, geographic fit, and cultural alignment"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check therapeutic areas
        if data.basicInfo.therapeuticAreas.isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.therapeuticAreas",
                message: "Therapeutic areas are required for strategic fit assessment",
                severity: .critical
            ))
        }
        
        // Check pipeline programs
        if data.pipeline.programs.isEmpty {
            errors.append(ValidationError(
                field: "pipeline.programs",
                message: "Pipeline programs are required for strategic fit evaluation",
                severity: .critical
            ))
        }
        
        // Check for competitive data
        if data.market.competitors.isEmpty {
            warnings.append(ValidationWarning(
                field: "market.competitors",
                message: "No competitor data available",
                suggestion: "Add competitor information for better strategic positioning analysis"
            ))
        }
        
        // Check for regulatory approvals data
        if data.regulatory.approvals.isEmpty && data.basicInfo.stage != .preclinical {
            warnings.append(ValidationWarning(
                field: "regulatory.approvals",
                message: "No regulatory approvals data for advanced-stage company",
                suggestion: "Add regulatory milestone information for better strategic assessment"
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
    
    private func calculateTherapeuticAlignment(_ data: CompanyData, context: MarketContext) -> ScoringFactor {
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let programs = data.pipeline.programs
        
        var score: Double = 3.0
        
        // Define strategic therapeutic areas (high value for acquirers)
        let strategicAreas = [
            "oncology", "immunology", "neurology", "rare diseases", "ophthalmology",
            "dermatology", "respiratory", "cardiovascular", "metabolic", "infectious diseases"
        ]
        
        // Calculate alignment score
        var alignmentCount = 0
        for area in therapeuticAreas {
            let lowerArea = area.lowercased()
            if strategicAreas.contains(where: { lowerArea.contains($0) }) {
                alignmentCount += 1
            }
        }
        
        // Score based on strategic area alignment
        let alignmentRatio = Double(alignmentCount) / Double(therapeuticAreas.count)
        switch alignmentRatio {
        case 0.8...1.0:
            score = 4.5 // Excellent alignment
        case 0.6..<0.8:
            score = 4.0 // Good alignment
        case 0.4..<0.6:
            score = 3.5 // Moderate alignment
        case 0.2..<0.4:
            score = 2.5 // Limited alignment
        default:
            score = 2.0 // Poor alignment
        }
        
        // Bonus for high-value areas
        let highValueAreas = ["oncology", "rare diseases", "gene therapy", "immunology"]
        let hasHighValueArea = therapeuticAreas.contains { area in
            highValueAreas.contains { highValue in
                area.lowercased().contains(highValue)
            }
        }
        
        if hasHighValueArea {
            score += 0.3 // Bonus for high-value therapeutic areas
        }
        
        // Consider program focus vs. diversification
        let uniqueAreas = Set(programs.map { $0.indication })
        if uniqueAreas.count == 1 {
            score += 0.2 // Focused approach can be more strategic
        } else if uniqueAreas.count > 5 {
            score -= 0.2 // Too much diversification may reduce strategic value
        }
        
        let rationale = "Therapeutic alignment based on strategic area coverage (\(alignmentCount)/\(therapeuticAreas.count)) and focus on high-value indications"
        
        return createScoringFactor(
            name: "Therapeutic Alignment",
            weight: 0.25,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateCapabilityComplement(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let programs = data.pipeline.programs
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        
        var score: Double = 3.0
        
        // Score based on development stage (what capabilities acquirer gains)
        switch stage {
        case .preclinical:
            score = 3.5 // Early research capabilities
        case .phase1:
            score = 4.0 // Clinical development capabilities
        case .phase2:
            score = 4.5 // Proven clinical capabilities
        case .phase3:
            score = 4.0 // Late-stage development
        case .approved:
            score = 3.5 // Commercial capabilities
        case .marketed:
            score = 3.0 // Established commercial presence
        }
        
        // Assess technology platform potential
        let platformTechnologies = ["gene therapy", "cell therapy", "antibody platform", "delivery platform"]
        let hasPlatformTech = programs.contains { program in
            platformTechnologies.contains { platform in
                program.mechanism.lowercased().contains(platform.lowercased())
            }
        }
        
        if hasPlatformTech {
            score += 0.4 // Platform technologies provide broader capabilities
        }
        
        // Consider unique mechanisms or approaches
        let uniqueMechanisms = Set(programs.map { $0.mechanism })
        if uniqueMechanisms.count > 2 {
            score += 0.2 // Diverse mechanisms add capability breadth
        }
        
        // Assess specialized expertise areas
        let specializedAreas = ["rare diseases", "pediatric", "precision medicine", "biomarkers"]
        let hasSpecialization = therapeuticAreas.contains { area in
            specializedAreas.contains { specialized in
                area.lowercased().contains(specialized)
            }
        }
        
        if hasSpecialization {
            score += 0.3 // Specialized expertise is valuable
        }
        
        let rationale = "Capability complement assessment based on development stage, platform potential, mechanism diversity, and specialized expertise"
        
        return createScoringFactor(
            name: "Capability Complement",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateSynergyPotential(_ data: CompanyData, context: MarketContext) -> ScoringFactor {
        let programs = data.pipeline.programs
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let competitors = data.market.competitors
        
        var score: Double = 3.0
        
        // Assess R&D synergies
        let rdSynergies = calculateRDSynergies(programs, therapeuticAreas)
        score += rdSynergies * 0.4
        
        // Assess commercial synergies
        let commercialSynergies = calculateCommercialSynergies(therapeuticAreas, competitors)
        score += commercialSynergies * 0.3
        
        // Assess manufacturing synergies
        let manufacturingSynergies = calculateManufacturingSynergies(programs)
        score += manufacturingSynergies * 0.2
        
        // Assess regulatory synergies
        let regulatorySynergies = calculateRegulatorySynergies(data)
        score += regulatorySynergies * 0.1
        
        let rationale = "Synergy potential based on R&D, commercial, manufacturing, and regulatory alignment opportunities"
        
        return createScoringFactor(
            name: "Synergy Potential",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateIntegrationComplexity(_ data: CompanyData) -> ScoringFactor {
        let programs = data.pipeline.programs
        let stage = data.basicInfo.stage
        let clinicalTrials = data.regulatory.clinicalTrials
        
        var score: Double = 3.0 // Start with moderate complexity
        
        // Score based on development stage (higher score = easier integration)
        switch stage {
        case .preclinical:
            score = 4.0 // Easier to integrate early-stage
        case .phase1:
            score = 3.5 // Moderate complexity
        case .phase2:
            score = 3.0 // More complex due to ongoing trials
        case .phase3:
            score = 2.5 // Complex due to critical trials
        case .approved:
            score = 2.0 // Complex commercial integration
        case .marketed:
            score = 1.5 // Most complex due to established operations
        }
        
        // Adjust for number of active clinical trials
        let activeTrials = clinicalTrials.filter { $0.status == .active || $0.status == .recruiting }
        if activeTrials.count > 3 {
            score -= 0.5 // Many active trials increase complexity
        } else if activeTrials.count == 0 {
            score += 0.3 // No active trials simplify integration
        }
        
        // Consider program portfolio complexity
        if programs.count > 5 {
            score -= 0.3 // Large portfolio increases integration complexity
        } else if programs.count == 1 {
            score += 0.2 // Single program is easier to integrate
        }
        
        // Assess geographic complexity
        let internationalTrials = clinicalTrials.filter { trial in
            // Simplified check - in practice would check trial locations
            trial.patientCount ?? 0 > 500 // Large trials often international
        }
        
        if internationalTrials.count > 0 {
            score -= 0.2 // International operations increase complexity
        }
        
        let rationale = "Integration complexity based on development stage, active trials (\(activeTrials.count)), portfolio size, and operational scope"
        
        return createScoringFactor(
            name: "Integration Complexity",
            weight: 0.15,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateGeographicFit(_ data: CompanyData) -> ScoringFactor {
        let approvals = data.regulatory.approvals
        let clinicalTrials = data.regulatory.clinicalTrials
        
        var score: Double = 3.5 // Default moderate fit
        
        // Assess regulatory presence
        let regions = Set(approvals.map { $0.region })
        let majorRegions = ["US", "EU", "Japan", "China"]
        let majorRegionCoverage = regions.intersection(Set(majorRegions)).count
        
        switch majorRegionCoverage {
        case 0:
            score = 3.0 // Limited geographic presence
        case 1:
            score = 3.5 // Single major market
        case 2:
            score = 4.0 // Good geographic coverage
        case 3...4:
            score = 4.5 // Excellent global presence
        default:
            score = 3.5
        }
        
        // Consider clinical trial geography
        let hasGlobalTrials = clinicalTrials.contains { ($0.patientCount ?? 0) > 300 }
        if hasGlobalTrials {
            score += 0.2 // Global clinical experience
        }
        
        // Bonus for US presence (often strategic for acquirers)
        if regions.contains("US") || regions.contains("United States") {
            score += 0.2
        }
        
        let rationale = "Geographic fit based on regulatory presence in \(majorRegionCoverage) major regions and global clinical experience"
        
        return createScoringFactor(
            name: "Geographic Fit",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateCulturalFit(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let programs = data.pipeline.programs
        
        var score: Double = 3.5 // Default moderate cultural fit
        
        // Assess innovation culture (based on pipeline diversity and stage)
        let uniqueMechanisms = Set(programs.map { $0.mechanism })
        let innovationScore = min(4.5, 3.0 + (Double(uniqueMechanisms.count) * 0.2))
        score = (score + innovationScore) / 2
        
        // Consider risk tolerance alignment
        switch stage {
        case .preclinical, .phase1:
            score += 0.2 // High-risk, high-reward culture
        case .phase2:
            score += 0.1 // Balanced risk culture
        case .phase3, .approved, .marketed:
            score -= 0.1 // More conservative culture
        }
        
        // Assess scientific rigor (simplified based on available data)
        let hasDetailedPrograms = programs.contains { !$0.differentiators.isEmpty }
        if hasDetailedPrograms {
            score += 0.2 // Evidence of scientific rigor
        }
        
        // Consider therapeutic area culture alignment
        let cuttingEdgeAreas = ["gene therapy", "cell therapy", "precision medicine", "AI/ML"]
        let hasCuttingEdge = data.basicInfo.therapeuticAreas.contains { area in
            cuttingEdgeAreas.contains { cutting in
                area.lowercased().contains(cutting.lowercased())
            }
        }
        
        if hasCuttingEdge {
            score += 0.3 // Cutting-edge focus indicates innovation culture
        }
        
        let rationale = "Cultural fit assessment based on innovation profile, risk tolerance, scientific rigor, and therapeutic focus"
        
        return createScoringFactor(
            name: "Cultural Fit",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateRDSynergies(_ programs: [Program], _ therapeuticAreas: [String]) -> Double {
        var synergies: Double = 0.0
        
        // Check for complementary mechanisms
        let mechanisms = Set(programs.map { $0.mechanism })
        if mechanisms.count > 1 {
            synergies += 0.3 // Diverse mechanisms create R&D synergies
        }
        
        // Check for platform potential
        let platformKeywords = ["platform", "technology", "delivery system"]
        let hasPlatform = programs.contains { program in
            platformKeywords.contains { keyword in
                program.mechanism.lowercased().contains(keyword)
            }
        }
        
        if hasPlatform {
            synergies += 0.4 // Platform technologies create broad synergies
        }
        
        // Check for therapeutic area synergies
        let synergyAreas = ["oncology", "immunology", "neurology"]
        let hasSynergyArea = therapeuticAreas.contains { area in
            synergyAreas.contains { synergy in
                area.lowercased().contains(synergy)
            }
        }
        
        if hasSynergyArea {
            synergies += 0.3 // Strategic therapeutic areas
        }
        
        return min(1.0, synergies)
    }
    
    private func calculateCommercialSynergies(_ therapeuticAreas: [String], _ competitors: [Competitor]) -> Double {
        var synergies: Double = 0.0
        
        // Check for established commercial areas
        let commercialAreas = ["oncology", "immunology", "dermatology", "ophthalmology"]
        let hasCommercialArea = therapeuticAreas.contains { area in
            commercialAreas.contains { commercial in
                area.lowercased().contains(commercial)
            }
        }
        
        if hasCommercialArea {
            synergies += 0.4 // Established commercial infrastructure
        }
        
        // Check competitive landscape
        if competitors.count > 2 {
            synergies += 0.3 // Competitive markets indicate commercial opportunity
        }
        
        // Check for specialty vs. primary care
        let specialtyAreas = ["rare diseases", "oncology", "neurology"]
        let isSpecialty = therapeuticAreas.contains { area in
            specialtyAreas.contains { specialty in
                area.lowercased().contains(specialty)
            }
        }
        
        if isSpecialty {
            synergies += 0.3 // Specialty focus aligns with many acquirer strategies
        }
        
        return min(1.0, synergies)
    }
    
    private func calculateManufacturingSynergies(_ programs: [Program]) -> Double {
        var synergies: Double = 0.0
        
        // Check for similar manufacturing requirements
        let mechanisms = programs.map { $0.mechanism.lowercased() }
        let biologics = mechanisms.filter { $0.contains("antibody") || $0.contains("protein") }
        let smallMolecules = mechanisms.filter { $0.contains("small molecule") || $0.contains("oral") }
        
        if biologics.count > 1 {
            synergies += 0.4 // Biologics manufacturing synergies
        }
        
        if smallMolecules.count > 1 {
            synergies += 0.3 // Small molecule manufacturing synergies
        }
        
        // Check for scalable manufacturing
        let scalable = mechanisms.contains { $0.contains("oral") || $0.contains("small molecule") }
        if scalable {
            synergies += 0.3 // Scalable manufacturing approaches
        }
        
        return min(1.0, synergies)
    }
    
    private func calculateRegulatorySynergies(_ data: CompanyData) -> Double {
        var synergies: Double = 0.0
        
        // Check for regulatory pathway alignment
        let pathway = data.regulatory.regulatoryStrategy.pathway
        switch pathway {
        case .breakthrough, .fastTrack, .orphan:
            synergies += 0.5 // Special regulatory pathways
        case .accelerated:
            synergies += 0.3 // Accelerated approval
        case .standard:
            synergies += 0.1 // Standard pathway
        }
        
        // Check for existing approvals
        if !data.regulatory.approvals.isEmpty {
            synergies += 0.3 // Regulatory experience
        }
        
        return min(1.0, synergies)
    }
    
    private func assessDataQuality(_ data: CompanyData) -> Double {
        var qualityScore = 1.0
        
        // Check therapeutic area specificity
        let vagueTAs = data.basicInfo.therapeuticAreas.filter { $0.lowercased().contains("other") || $0.lowercased().contains("general") }
        if !vagueTAs.isEmpty {
            qualityScore -= 0.2 // Vague therapeutic areas reduce quality
        }
        
        // Check program detail completeness
        let programsWithDetails = data.pipeline.programs.filter { !$0.differentiators.isEmpty }
        let detailCompleteness = Double(programsWithDetails.count) / max(1.0, Double(data.pipeline.programs.count))
        qualityScore *= detailCompleteness
        
        // Check competitor data quality
        let competitorsWithDetails = data.market.competitors.filter { !$0.strengths.isEmpty }
        if !data.market.competitors.isEmpty {
            let competitorQuality = Double(competitorsWithDetails.count) / Double(data.market.competitors.count)
            qualityScore *= (0.8 + 0.2 * competitorQuality) // Weight competitor quality at 20%
        }
        
        return max(0.0, min(1.0, qualityScore))
    }
    
    private func generateStrategicSpecificWarnings(_ data: CompanyData) -> [String] {
        var warnings: [String] = []
        
        // Check for niche therapeutic areas
        let nicheAreas = ["ultra-rare", "orphan", "pediatric only"]
        let hasNicheArea = data.basicInfo.therapeuticAreas.contains { area in
            nicheAreas.contains { niche in
                area.lowercased().contains(niche)
            }
        }
        
        if hasNicheArea {
            warnings.append("Niche therapeutic focus may limit strategic appeal to some acquirers")
        }
        
        // Check for single program dependency
        if data.pipeline.programs.count == 1 {
            warnings.append("Single program dependency increases strategic risk")
        }
        
        // Check for early stage with no platform
        if data.basicInfo.stage == .preclinical && data.pipeline.programs.count < 2 {
            warnings.append("Early-stage single asset may have limited strategic value")
        }
        
        // Check for complex integration scenarios
        let activeTrials = data.regulatory.clinicalTrials.filter { $0.status == .active }
        if activeTrials.count > 5 {
            warnings.append("Multiple active trials may complicate integration planning")
        }
        
        // Check for geographic limitations
        let regions = Set(data.regulatory.approvals.map { $0.region })
        if regions.isEmpty {
            warnings.append("No regulatory approvals may limit immediate strategic value")
        }
        
        return warnings
    }
    
    // MARK: - Overridden Methods
    
    internal override func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        let strategicFit = score.rawScore >= 4.0 ? "Excellent" : score.rawScore >= 3.0 ? "Good" : "Limited"
        return "Strategic Fit scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription)) - \(strategicFit) strategic alignment"
    }
    
    internal override func getMethodologyDescription() -> String {
        return "Strategic fit evaluation using therapeutic alignment analysis, capability complement assessment, synergy potential evaluation, integration complexity analysis, geographic fit assessment, and cultural alignment evaluation"
    }
    
    internal override func getKnownLimitations() -> [String] {
        return [
            "Strategic fit assessment is highly dependent on specific acquirer strategy and priorities",
            "Cultural fit evaluation is simplified and may not capture organizational nuances",
            "Synergy potential estimates are based on general industry patterns",
            "Integration complexity assessment may not account for specific operational factors",
            "Geographic fit analysis is limited by available regulatory data",
            "Market dynamics and competitive landscape can change rapidly"
        ]
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0:
            return "Excellent Strategic Fit"
        case 3.5..<4.5:
            return "Good Strategic Fit"
        case 2.5..<3.5:
            return "Moderate Strategic Fit"
        case 1.5..<2.5:
            return "Limited Strategic Fit"
        default:
            return "Poor Strategic Fit"
        }
    }
}