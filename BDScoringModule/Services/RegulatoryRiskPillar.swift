import Foundation

// MARK: - Regulatory Risk Scoring Pillar

/// Assesses regulatory pathway complexity and timeline
public class RegulatoryRiskPillar: BaseScoringPillar {
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createRegulatoryRiskInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Regulatory Risk scoring requires valid development stage and therapeutic area data")
        }
        
        // Calculate individual scoring factors
        let pathwayComplexityFactor = calculatePathwayComplexity(data)
        let clinicalRiskFactor = calculateClinicalRisk(data)
        let regulatoryPrecedentFactor = calculateRegulatoryPrecedent(data, context: context)
        let safetyProfileFactor = calculateSafetyProfile(data)
        let manufacturingRiskFactor = calculateManufacturingRisk(data)
        let timelineRiskFactor = calculateTimelineRisk(data)
        
        let factors = [
            pathwayComplexityFactor,
            clinicalRiskFactor,
            regulatoryPrecedentFactor,
            safetyProfileFactor,
            manufacturingRiskFactor,
            timelineRiskFactor
        ]
        
        // Calculate weighted score (note: higher score = lower risk)
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: assessDataQuality(data),
            methodologyReliability: 0.85 // Regulatory risk assessment is well-established
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateRegulatorySpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Regulatory risk evaluation based on pathway complexity, clinical risk, regulatory precedent, safety profile, manufacturing risk, and timeline risk (higher score indicates lower risk)"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check development stage
        if data.basicInfo.stage == .marketed {
            warnings.append(ValidationWarning(
                field: "basicInfo.stage",
                message: "Regulatory risk assessment is less relevant for marketed products",
                suggestion: "Consider post-market regulatory risks and lifecycle management"
            ))
        }
        
        // Check therapeutic areas
        if data.basicInfo.therapeuticAreas.isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.therapeuticAreas",
                message: "Therapeutic areas are required for regulatory risk assessment",
                severity: .critical
            ))
        }
        
        // Check clinical trial data for development-stage companies
        if (data.basicInfo.stage == .phase1 || data.basicInfo.stage == .phase2 || data.basicInfo.stage == .phase3) &&
           data.regulatory.clinicalTrials.isEmpty {
            warnings.append(ValidationWarning(
                field: "regulatory.clinicalTrials",
                message: "No clinical trial data for development-stage company",
                suggestion: "Add clinical trial information for more accurate regulatory risk assessment"
            ))
        }
        
        // Check regulatory strategy completeness
        if data.regulatory.regulatoryStrategy.risks.isEmpty {
            warnings.append(ValidationWarning(
                field: "regulatory.regulatoryStrategy.risks",
                message: "No regulatory risks identified in strategy",
                suggestion: "Consider adding known regulatory risks and challenges"
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
    
    private func calculatePathwayComplexity(_ data: CompanyData) -> ScoringFactor {
        let pathway = data.regulatory.regulatoryStrategy.pathway
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let stage = data.basicInfo.stage
        
        var score: Double = 3.0
        
        // Base score by regulatory pathway (higher score = lower complexity/risk)
        switch pathway {
        case .orphan:
            score = 4.5 // Orphan designation simplifies pathway
        case .breakthrough:
            score = 4.2 // Breakthrough designation reduces complexity
        case .fastTrack:
            score = 4.0 // Fast track provides advantages
        case .accelerated:
            score = 3.8 // Accelerated approval has benefits but requirements
        case .standard:
            score = 3.0 // Standard pathway baseline
        }
        
        // Adjust for therapeutic area complexity
        let complexAreas = [
            "gene therapy": -0.8,
            "cell therapy": -0.7,
            "neurology": -0.5,
            "psychiatry": -0.5,
            "cardiovascular": -0.3,
            "oncology": -0.2,
            "rare diseases": 0.3, // Often have clearer pathways
            "infectious diseases": 0.2,
            "dermatology": 0.3
        ]
        
        for area in therapeuticAreas {
            let lowerArea = area.lowercased()
            for (complexArea, adjustment) in complexAreas {
                if lowerArea.contains(complexArea) {
                    score += adjustment
                    break
                }
            }
        }
        
        // Adjust for development stage
        switch stage {
        case .preclinical:
            score -= 0.2 // More uncertainty in early stages
        case .phase1:
            score += 0.1 // Some regulatory clarity
        case .phase2:
            score += 0.2 // Better regulatory understanding
        case .phase3:
            score += 0.3 // Clear regulatory path
        case .approved, .marketed:
            score = 4.5 // Regulatory approval achieved
        }
        
        let rationale = "Pathway complexity assessment based on regulatory pathway (\(pathway.rawValue)), therapeutic area complexity, and development stage"
        
        return createScoringFactor(
            name: "Pathway Complexity",
            weight: 0.25,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateClinicalRisk(_ data: CompanyData) -> ScoringFactor {
        let clinicalTrials = data.regulatory.clinicalTrials
        let stage = data.basicInfo.stage
        let programs = data.pipeline.programs
        
        var score: Double = 3.0
        
        // Base score by development stage
        switch stage {
        case .preclinical:
            score = 3.5 // Clinical risk not yet realized
        case .phase1:
            score = 3.0 // Safety risk primary concern
        case .phase2:
            score = 2.5 // Efficacy risk increases
        case .phase3:
            score = 2.0 // High stakes confirmatory trials
        case .approved, .marketed:
            score = 4.5 // Clinical risk largely resolved
        }
        
        // Assess clinical trial complexity
        let phase3Trials = clinicalTrials.filter { $0.phase == .phase3 }
        let phase2Trials = clinicalTrials.filter { $0.phase == .phase2 }
        
        // Adjust for trial complexity
        if phase3Trials.count > 1 {
            score -= 0.5 // Multiple Phase 3 trials increase risk
        }
        
        if phase2Trials.count > 2 {
            score -= 0.3 // Multiple Phase 2 trials indicate complexity
        }
        
        // Assess patient population challenges
        let totalPatients = clinicalTrials.compactMap { $0.patientCount }.reduce(0, +)
        switch totalPatients {
        case 0...100:
            score += 0.2 // Small studies easier to execute
        case 100...500:
            score += 0.1 // Moderate size manageable
        case 500...1500:
            score -= 0.1 // Large studies more complex
        default:
            score -= 0.3 // Very large studies high risk
        }
        
        // Check for trial status issues
        let problematicTrials = clinicalTrials.filter { $0.status == .suspended || $0.status == .terminated }
        if !problematicTrials.isEmpty {
            score -= 0.4 // History of trial problems
        }
        
        // Assess endpoint complexity (simplified based on therapeutic area)
        let hardEndpointAreas = ["neurology", "psychiatry", "alzheimer", "depression"]
        let hasHardEndpoints = data.basicInfo.therapeuticAreas.contains { area in
            hardEndpointAreas.contains { hard in
                area.lowercased().contains(hard)
            }
        }
        
        if hasHardEndpoints {
            score -= 0.3 // Difficult endpoints increase clinical risk
        }
        
        let rationale = "Clinical risk based on development stage, trial complexity (\(clinicalTrials.count) trials), patient population size, and endpoint difficulty"
        
        return createScoringFactor(
            name: "Clinical Risk",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateRegulatoryPrecedent(_ data: CompanyData, context: MarketContext) -> ScoringFactor {
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let programs = data.pipeline.programs
        let approvals = data.regulatory.approvals
        
        var score: Double = 3.0
        
        // Assess therapeutic area precedent
        let wellEstablishedAreas = ["oncology", "cardiovascular", "diabetes", "infectious diseases", "dermatology"]
        let emergingAreas = ["gene therapy", "cell therapy", "digital therapeutics", "microbiome"]
        let challengingAreas = ["neurology", "psychiatry", "alzheimer", "pain"]
        
        for area in therapeuticAreas {
            let lowerArea = area.lowercased()
            if wellEstablishedAreas.contains(where: { lowerArea.contains($0) }) {
                score += 0.3 // Well-established regulatory precedent
            } else if emergingAreas.contains(where: { lowerArea.contains($0) }) {
                score -= 0.4 // Limited regulatory precedent
            } else if challengingAreas.contains(where: { lowerArea.contains($0) }) {
                score -= 0.2 // Challenging regulatory history
            }
        }
        
        // Assess mechanism precedent
        let establishedMechanisms = ["small molecule", "monoclonal antibody", "vaccine"]
        let novelMechanisms = ["gene therapy", "cell therapy", "RNA therapy", "CRISPR"]
        
        for program in programs {
            let mechanism = program.mechanism.lowercased()
            if establishedMechanisms.contains(where: { mechanism.contains($0) }) {
                score += 0.2 // Established mechanism
            } else if novelMechanisms.contains(where: { mechanism.contains($0) }) {
                score -= 0.3 // Novel mechanism with limited precedent
            }
        }
        
        // Consider existing approvals as positive precedent
        if !approvals.isEmpty {
            score += 0.4 // Company has regulatory approval experience
            
            // Bonus for breakthrough or accelerated approvals
            let specialApprovals = approvals.filter { 
                $0.type == .breakthrough || $0.type == .fastTrack || $0.type == .conditional 
            }
            if !specialApprovals.isEmpty {
                score += 0.2 // Experience with special regulatory pathways
            }
        }
        
        // Consider competitive approvals (from context if available)
        // Simplified assessment based on therapeutic area maturity
        let matureAreas = ["oncology", "cardiovascular", "diabetes"]
        let hasMatureArea = therapeuticAreas.contains { area in
            matureAreas.contains { mature in
                area.lowercased().contains(mature)
            }
        }
        
        if hasMatureArea {
            score += 0.2 // Mature therapeutic areas have more precedent
        }
        
        let rationale = "Regulatory precedent assessment based on therapeutic area maturity, mechanism precedent, company approval history, and competitive landscape"
        
        return createScoringFactor(
            name: "Regulatory Precedent",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateSafetyProfile(_ data: CompanyData) -> ScoringFactor {
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        let programs = data.pipeline.programs
        let clinicalTrials = data.regulatory.clinicalTrials
        let stage = data.basicInfo.stage
        
        var score: Double = 3.5 // Default moderate safety profile
        
        // Assess inherent safety risks by therapeutic area
        let highSafetyRiskAreas = ["gene therapy", "cell therapy", "immunotherapy", "neurology"]
        let moderateSafetyRiskAreas = ["oncology", "cardiovascular", "respiratory"]
        let lowSafetyRiskAreas = ["dermatology", "ophthalmology", "infectious diseases"]
        
        for area in therapeuticAreas {
            let lowerArea = area.lowercased()
            if highSafetyRiskAreas.contains(where: { lowerArea.contains($0) }) {
                score -= 0.4 // High inherent safety risk
            } else if moderateSafetyRiskAreas.contains(where: { lowerArea.contains($0) }) {
                score -= 0.1 // Moderate safety considerations
            } else if lowSafetyRiskAreas.contains(where: { lowerArea.contains($0) }) {
                score += 0.2 // Generally favorable safety profile
            }
        }
        
        // Assess mechanism-related safety risks
        let highRiskMechanisms = ["immunosuppressive", "cytotoxic", "gene editing", "viral vector"]
        let moderateRiskMechanisms = ["monoclonal antibody", "protein therapy", "hormone therapy"]
        let lowRiskMechanisms = ["topical", "oral small molecule", "vaccine"]
        
        for program in programs {
            let mechanism = program.mechanism.lowercased()
            if highRiskMechanisms.contains(where: { mechanism.contains($0) }) {
                score -= 0.3 // High-risk mechanism
            } else if moderateRiskMechanisms.contains(where: { mechanism.contains($0) }) {
                score -= 0.1 // Moderate risk mechanism
            } else if lowRiskMechanisms.contains(where: { mechanism.contains($0) }) {
                score += 0.2 // Lower risk mechanism
            }
        }
        
        // Consider clinical trial safety data
        if stage != .preclinical {
            let completedTrials = clinicalTrials.filter { $0.status == .completed }
            if completedTrials.count > 0 {
                score += 0.3 // Completed trials suggest manageable safety
            }
            
            // Check for trial suspensions (safety concerns)
            let suspendedTrials = clinicalTrials.filter { $0.status == .suspended }
            if !suspendedTrials.isEmpty {
                score -= 0.5 // Trial suspensions indicate safety concerns
            }
        }
        
        // Consider patient population vulnerability
        let vulnerablePopulations = ["pediatric", "elderly", "immunocompromised", "pregnant"]
        let hasVulnerablePopulation = programs.contains { program in
            vulnerablePopulations.contains { vulnerable in
                program.indication.lowercased().contains(vulnerable)
            }
        }
        
        if hasVulnerablePopulation {
            score -= 0.2 // Vulnerable populations increase safety scrutiny
        }
        
        // Consider combination therapy risks
        let hasCombinationTherapy = programs.contains { 
            $0.mechanism.lowercased().contains("combination") || 
            $0.mechanism.lowercased().contains("plus")
        }
        
        if hasCombinationTherapy {
            score -= 0.2 // Combination therapies have additional safety complexity
        }
        
        let rationale = "Safety profile assessment based on therapeutic area risks, mechanism safety, clinical experience, and patient population considerations"
        
        return createScoringFactor(
            name: "Safety Profile",
            weight: 0.15,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateManufacturingRisk(_ data: CompanyData) -> ScoringFactor {
        let programs = data.pipeline.programs
        let therapeuticAreas = data.basicInfo.therapeuticAreas
        
        var score: Double = 3.5 // Default moderate manufacturing risk
        
        // Assess manufacturing complexity by mechanism
        let highComplexityManufacturing = ["gene therapy", "cell therapy", "viral vector", "personalized medicine"]
        let moderateComplexityManufacturing = ["monoclonal antibody", "protein therapy", "biologics"]
        let lowComplexityManufacturing = ["small molecule", "oral", "topical"]
        
        for program in programs {
            let mechanism = program.mechanism.lowercased()
            if highComplexityManufacturing.contains(where: { mechanism.contains($0) }) {
                score -= 0.4 // High manufacturing complexity increases regulatory risk
            } else if moderateComplexityManufacturing.contains(where: { mechanism.contains($0) }) {
                score -= 0.1 // Moderate complexity
            } else if lowComplexityManufacturing.contains(where: { mechanism.contains($0) }) {
                score += 0.2 // Lower manufacturing complexity
            }
        }
        
        // Consider therapeutic area manufacturing requirements
        let complexManufacturingAreas = ["gene therapy", "cell therapy", "regenerative medicine"]
        let hasComplexManufacturing = therapeuticAreas.contains { area in
            complexManufacturingAreas.contains { complex in
                area.lowercased().contains(complex)
            }
        }
        
        if hasComplexManufacturing {
            score -= 0.3 // Complex manufacturing areas have higher regulatory risk
        }
        
        // Consider scale-up challenges
        let scaleUpChallenges = ["autologous", "personalized", "fresh", "living"]
        let hasScaleUpChallenges = programs.contains { program in
            scaleUpChallenges.contains { challenge in
                program.mechanism.lowercased().contains(challenge) ||
                program.indication.lowercased().contains(challenge)
            }
        }
        
        if hasScaleUpChallenges {
            score -= 0.3 // Scale-up challenges increase regulatory complexity
        }
        
        // Consider supply chain complexity
        let complexSupplyChain = ["cold chain", "cryopreservation", "short shelf life"]
        let hasComplexSupplyChain = programs.contains { program in
            complexSupplyChain.contains { complex in
                program.mechanism.lowercased().contains(complex)
            }
        }
        
        if hasComplexSupplyChain {
            score -= 0.2 // Complex supply chain increases regulatory oversight
        }
        
        let rationale = "Manufacturing risk assessment based on production complexity, scale-up challenges, and supply chain requirements"
        
        return createScoringFactor(
            name: "Manufacturing Risk",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateTimelineRisk(_ data: CompanyData) -> ScoringFactor {
        let timeline = data.regulatory.regulatoryStrategy.timeline
        let stage = data.basicInfo.stage
        let clinicalTrials = data.regulatory.clinicalTrials
        let programs = data.pipeline.programs
        
        var score: Double = 3.0
        
        // Base score by regulatory timeline (higher score = lower timeline risk)
        switch timeline {
        case 0...24:
            score = 4.5 // Short timeline, low risk
        case 24...48:
            score = 4.0 // Moderate timeline
        case 48...72:
            score = 3.0 // Standard timeline
        case 72...96:
            score = 2.5 // Long timeline increases risk
        default:
            score = 2.0 // Very long timeline, high risk
        }
        
        // Adjust for development stage consistency
        let expectedTimelines: [DevelopmentStage: ClosedRange<Int>] = [
            .preclinical: 60...120,
            .phase1: 48...84,
            .phase2: 36...60,
            .phase3: 24...48,
            .approved: 0...12,
            .marketed: 0...6
        ]
        
        if let expectedRange = expectedTimelines[stage] {
            if expectedRange.contains(timeline) {
                score += 0.2 // Timeline consistent with stage
            } else if timeline > expectedRange.upperBound {
                score -= 0.3 // Timeline longer than expected
            } else {
                score -= 0.1 // Timeline shorter than expected (may be optimistic)
            }
        }
        
        // Consider clinical trial timeline risks
        let activeTrials = clinicalTrials.filter { $0.status == .active || $0.status == .recruiting }
        let trialsWithDelays = clinicalTrials.filter { trial in
            guard let expected = trial.expectedCompletion else { return false }
            return expected < Date() && trial.status != .completed
        }
        
        if !trialsWithDelays.isEmpty {
            score -= 0.4 // History of delays increases timeline risk
        }
        
        // Assess recruitment challenges
        let largeTrials = clinicalTrials.filter { ($0.patientCount ?? 0) > 500 }
        if !largeTrials.isEmpty {
            score -= 0.2 // Large trials have recruitment timeline risks
        }
        
        // Consider rare disease recruitment advantages
        let rareDisease = data.basicInfo.therapeuticAreas.contains { 
            $0.lowercased().contains("rare") || $0.lowercased().contains("orphan")
        }
        
        if rareDisease {
            score -= 0.1 // Rare diseases may have recruitment challenges
        }
        
        // Consider regulatory pathway timeline benefits
        let pathway = data.regulatory.regulatoryStrategy.pathway
        switch pathway {
        case .breakthrough, .fastTrack:
            score += 0.3 // Accelerated pathways reduce timeline risk
        case .accelerated:
            score += 0.2 // Some timeline benefits
        case .orphan:
            score += 0.1 // Minor timeline advantages
        case .standard:
            break // No adjustment
        }
        
        let rationale = "Timeline risk assessment based on regulatory timeline (\(timeline) months), development stage consistency, trial execution history, and pathway advantages"
        
        return createScoringFactor(
            name: "Timeline Risk",
            weight: 0.10,
            score: score,
            rationale: rationale
        )
    }
    
    // MARK: - Helper Methods
    
    private func assessDataQuality(_ data: CompanyData) -> Double {
        var qualityScore = 1.0
        
        // Check regulatory strategy completeness
        if data.regulatory.regulatoryStrategy.risks.isEmpty {
            qualityScore -= 0.2 // Missing risk assessment
        }
        
        if data.regulatory.regulatoryStrategy.mitigations.isEmpty {
            qualityScore -= 0.1 // Missing mitigation strategies
        }
        
        // Check clinical trial data completeness
        let trialsWithDates = data.regulatory.clinicalTrials.filter { 
            $0.startDate != nil && $0.expectedCompletion != nil 
        }
        if !data.regulatory.clinicalTrials.isEmpty {
            let dateCompleteness = Double(trialsWithDates.count) / Double(data.regulatory.clinicalTrials.count)
            qualityScore *= (0.7 + 0.3 * dateCompleteness)
        }
        
        // Check for realistic timeline
        if data.regulatory.regulatoryStrategy.timeline <= 0 || data.regulatory.regulatoryStrategy.timeline > 200 {
            qualityScore -= 0.3 // Unrealistic timeline
        }
        
        return max(0.0, min(1.0, qualityScore))
    }
    
    private func generateRegulatorySpecificWarnings(_ data: CompanyData) -> [String] {
        var warnings: [String] = []
        
        // Check for high-risk therapeutic areas
        let highRiskAreas = ["gene therapy", "cell therapy", "neurology", "psychiatry"]
        let hasHighRiskArea = data.basicInfo.therapeuticAreas.contains { area in
            highRiskAreas.contains { risk in
                area.lowercased().contains(risk)
            }
        }
        
        if hasHighRiskArea {
            warnings.append("High-risk therapeutic area may face additional regulatory scrutiny")
        }
        
        // Check for novel mechanisms
        let novelMechanisms = ["CRISPR", "gene editing", "RNA therapy", "viral vector"]
        let hasNovelMechanism = data.pipeline.programs.contains { program in
            novelMechanisms.contains { novel in
                program.mechanism.lowercased().contains(novel)
            }
        }
        
        if hasNovelMechanism {
            warnings.append("Novel mechanism may require additional regulatory guidance and longer review times")
        }
        
        // Check for suspended trials
        let suspendedTrials = data.regulatory.clinicalTrials.filter { $0.status == .suspended }
        if !suspendedTrials.isEmpty {
            warnings.append("Suspended clinical trials may indicate safety or efficacy concerns")
        }
        
        // Check for aggressive timeline
        let stage = data.basicInfo.stage
        let timeline = data.regulatory.regulatoryStrategy.timeline
        
        if (stage == .preclinical && timeline < 48) || 
           (stage == .phase1 && timeline < 36) ||
           (stage == .phase2 && timeline < 24) {
            warnings.append("Regulatory timeline may be optimistic for current development stage")
        }
        
        // Check for complex manufacturing
        let complexManufacturing = data.pipeline.programs.contains { program in
            program.mechanism.lowercased().contains("gene therapy") ||
            program.mechanism.lowercased().contains("cell therapy") ||
            program.mechanism.lowercased().contains("personalized")
        }
        
        if complexManufacturing {
            warnings.append("Complex manufacturing may require extensive regulatory oversight and validation")
        }
        
        // Check for multiple indications
        let indications = Set(data.pipeline.programs.map { $0.indication })
        if indications.count > 3 {
            warnings.append("Multiple indications may require separate regulatory submissions and increase complexity")
        }
        
        return warnings
    }
    
    // MARK: - Overridden Methods
    
    internal override func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        let riskLevel = score.rawScore >= 4.0 ? "Low" : score.rawScore >= 3.0 ? "Moderate" : "High"
        return "Regulatory Risk scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription)) - \(riskLevel) regulatory risk"
    }
    
    internal override func getMethodologyDescription() -> String {
        return "Regulatory risk evaluation using pathway complexity analysis, clinical risk assessment, regulatory precedent evaluation, safety profile analysis, manufacturing risk assessment, and timeline risk evaluation"
    }
    
    internal override func getKnownLimitations() -> [String] {
        return [
            "Regulatory landscape can change rapidly with new guidance and policies",
            "Safety profile assessment is based on limited early-stage data",
            "Manufacturing risk evaluation may not capture all technical complexities",
            "Timeline estimates are subject to regulatory agency workload and priorities",
            "Precedent analysis may not account for evolving regulatory standards",
            "Clinical risk assessment is simplified and may not capture all trial complexities"
        ]
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0:
            return "Very Low Risk"
        case 3.5..<4.5:
            return "Low Risk"
        case 2.5..<3.5:
            return "Moderate Risk"
        case 1.5..<2.5:
            return "High Risk"
        default:
            return "Very High Risk"
        }
    }
}