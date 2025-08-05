import Foundation

// MARK: - Market Outlook Scoring Pillar

/// Analyzes addressable market size and growth potential, competitive landscape, and regulatory pathway assessment
public class MarketOutlookPillar: BaseScoringPillar {
    
    // MARK: - Constants
    
    private let excellentMarketSize: Double = 10.0 // $10B+ addressable market
    private let goodMarketSize: Double = 5.0      // $5B+ addressable market
    private let averageMarketSize: Double = 1.0   // $1B+ addressable market
    private let minimumMarketSize: Double = 0.1   // $100M+ addressable market
    
    private let highGrowthRate: Double = 0.15     // 15%+ annual growth
    private let moderateGrowthRate: Double = 0.08 // 8%+ annual growth
    private let lowGrowthRate: Double = 0.03      // 3%+ annual growth
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createMarketOutlookInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Market Outlook scoring requires valid market and therapeutic area data")
        }
        
        // Calculate individual scoring factors
        let marketSizeFactor = calculateMarketSize(data)
        let growthPotentialFactor = calculateGrowthPotential(data)
        let competitiveLandscapeFactor = calculateCompetitiveLandscape(data, context: context)
        let regulatoryPathwayFactor = calculateRegulatoryPathway(data)
        let reimbursementFactor = calculateReimbursementEnvironment(data)
        let marketDynamicsFactor = calculateMarketDynamics(data)
        
        let factors = [
            marketSizeFactor,
            growthPotentialFactor,
            competitiveLandscapeFactor,
            regulatoryPathwayFactor,
            reimbursementFactor,
            marketDynamicsFactor
        ]
        
        // Calculate weighted score
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: assessMarketDataQuality(data),
            methodologyReliability: 0.80 // Market analysis has inherent uncertainty
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateMarketSpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Market outlook evaluation based on addressable market size, growth potential, competitive landscape, regulatory pathway, reimbursement environment, and market dynamics"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check addressable market data
        if data.market.addressableMarket <= 0 {
            errors.append(ValidationError(
                field: "market.addressableMarket",
                message: "Addressable market size must be greater than zero",
                severity: .critical
            ))
        }
        
        // Check therapeutic areas
        if data.basicInfo.therapeuticAreas.isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.therapeuticAreas",
                message: "Therapeutic areas are required for market analysis",
                severity: .critical
            ))
        }
        
        // Check market dynamics data
        if data.market.marketDynamics.growthRate < 0 {
            warnings.append(ValidationWarning(
                field: "market.marketDynamics.growthRate",
                message: "Negative growth rate indicates declining market",
                suggestion: "Verify market growth data and consider market contraction risks"
            ))
        }
        
        // Check competitor data
        if data.market.competitors.isEmpty {
            warnings.append(ValidationWarning(
                field: "market.competitors",
                message: "No competitor data provided",
                suggestion: "Add competitor information for more accurate competitive landscape assessment"
            ))
        }
        
        // Check reimbursement environment
        if data.market.marketDynamics.reimbursement == .unknown {
            warnings.append(ValidationWarning(
                field: "market.marketDynamics.reimbursement",
                message: "Reimbursement environment is unknown",
                suggestion: "Research reimbursement landscape for target indications"
            ))
        }
        
        // Check for very small markets
        if data.market.addressableMarket < minimumMarketSize {
            warnings.append(ValidationWarning(
                field: "market.addressableMarket",
                message: "Very small addressable market (< $100M)",
                suggestion: "Consider market expansion opportunities or niche market strategies"
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
    
    private func calculateMarketSize(_ data: CompanyData) -> ScoringFactor {
        let marketSize = data.market.addressableMarket
        
        var score: Double
        var rationale: String
        
        switch marketSize {
        case excellentMarketSize...:
            score = 5.0
            rationale = "Excellent addressable market size (≥$10B) provides significant commercial opportunity"
        case goodMarketSize..<excellentMarketSize:
            score = 4.0
            rationale = "Good addressable market size ($5-10B) offers substantial commercial potential"
        case averageMarketSize..<goodMarketSize:
            score = 3.0
            rationale = "Average addressable market size ($1-5B) provides moderate commercial opportunity"
        case minimumMarketSize..<averageMarketSize:
            score = 2.0
            rationale = "Small addressable market size ($100M-1B) limits commercial potential"
        default:
            score = 1.0
            rationale = "Very small addressable market size (<$100M) significantly constrains commercial opportunity"
        }
        
        return createScoringFactor(
            name: "Market Size",
            weight: 0.30,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateGrowthPotential(_ data: CompanyData) -> ScoringFactor {
        let growthRate = data.market.marketDynamics.growthRate
        
        var score: Double
        var rationale: String
        
        switch growthRate {
        case highGrowthRate...:
            score = 5.0
            rationale = "High market growth rate (≥15%) indicates strong expansion potential"
        case moderateGrowthRate..<highGrowthRate:
            score = 4.0
            rationale = "Moderate market growth rate (8-15%) shows good expansion opportunity"
        case lowGrowthRate..<moderateGrowthRate:
            score = 3.0
            rationale = "Low market growth rate (3-8%) suggests limited expansion potential"
        case 0..<lowGrowthRate:
            score = 2.0
            rationale = "Very low market growth rate (0-3%) indicates mature market with minimal expansion"
        default:
            score = 1.0
            rationale = "Negative market growth rate indicates declining market conditions"
        }
        
        // Adjust for market drivers and barriers
        let drivers = data.market.marketDynamics.drivers
        let barriers = data.market.marketDynamics.barriers
        
        if drivers.count > barriers.count {
            score = min(5.0, score + 0.5)
            rationale += ". Strong market drivers support growth potential"
        } else if barriers.count > drivers.count {
            score = max(1.0, score - 0.5)
            rationale += ". Market barriers may limit growth potential"
        }
        
        return createScoringFactor(
            name: "Growth Potential",
            weight: 0.25,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateCompetitiveLandscape(_ data: CompanyData, context: MarketContext) -> ScoringFactor {
        let competitors = data.market.competitors
        let competitorCount = competitors.count
        
        var score: Double
        var rationale: String
        
        // Base score on competitive intensity
        switch competitorCount {
        case 0:
            score = 5.0
            rationale = "No direct competitors identified - potential first-mover advantage"
        case 1...2:
            score = 4.0
            rationale = "Limited competition (1-2 competitors) provides favorable competitive position"
        case 3...5:
            score = 3.0
            rationale = "Moderate competition (3-5 competitors) requires differentiation strategy"
        case 6...10:
            score = 2.0
            rationale = "High competition (6-10 competitors) creates challenging market dynamics"
        default:
            score = 1.0
            rationale = "Very high competition (>10 competitors) indicates saturated market"
        }
        
        // Adjust based on competitor stages and strengths
        if !competitors.isEmpty {
            let advancedCompetitors = competitors.filter { 
                $0.stage == .phase3 || $0.stage == .approved || $0.stage == .marketed 
            }
            
            if advancedCompetitors.count > competitorCount / 2 {
                score = max(1.0, score - 1.0)
                rationale += ". Many competitors in advanced stages increase competitive pressure"
            }
            
            // Check for competitor weaknesses that could be exploited
            let competitorsWithWeaknesses = competitors.filter { !$0.weaknesses.isEmpty }
            if competitorsWithWeaknesses.count > competitorCount / 2 {
                score = min(5.0, score + 0.5)
                rationale += ". Competitor weaknesses present market opportunities"
            }
        }
        
        return createScoringFactor(
            name: "Competitive Landscape",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateRegulatoryPathway(_ data: CompanyData) -> ScoringFactor {
        let regulatoryStrategy = data.regulatory.regulatoryStrategy
        let pathway = regulatoryStrategy.pathway
        let timeline = regulatoryStrategy.timeline
        
        var score: Double
        var rationale: String
        
        // Score based on regulatory pathway
        switch pathway {
        case .breakthrough:
            score = 5.0
            rationale = "Breakthrough designation provides accelerated regulatory pathway"
        case .fastTrack:
            score = 4.5
            rationale = "Fast track designation offers expedited regulatory review"
        case .accelerated:
            score = 4.0
            rationale = "Accelerated approval pathway reduces time to market"
        case .orphan:
            score = 4.0
            rationale = "Orphan drug designation provides regulatory advantages"
        case .standard:
            score = 3.0
            rationale = "Standard regulatory pathway with typical timelines"
        }
        
        // Adjust based on timeline
        if timeline <= 24 {
            score = min(5.0, score + 0.5)
            rationale += " with short timeline to approval"
        } else if timeline >= 60 {
            score = max(1.0, score - 0.5)
            rationale += " but extended timeline increases risk"
        }
        
        // Consider regulatory risks
        let riskCount = regulatoryStrategy.risks.count
        if riskCount > 3 {
            score = max(1.0, score - 0.5)
            rationale += ". Multiple regulatory risks identified"
        }
        
        return createScoringFactor(
            name: "Regulatory Pathway",
            weight: 0.15,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateReimbursementEnvironment(_ data: CompanyData) -> ScoringFactor {
        let reimbursement = data.market.marketDynamics.reimbursement
        
        var score: Double
        var rationale: String
        
        switch reimbursement {
        case .favorable:
            score = 5.0
            rationale = "Favorable reimbursement environment supports market access"
        case .moderate:
            score = 3.0
            rationale = "Moderate reimbursement environment requires value demonstration"
        case .challenging:
            score = 2.0
            rationale = "Challenging reimbursement environment may limit market access"
        case .unknown:
            score = 2.5
            rationale = "Unknown reimbursement environment creates uncertainty"
        }
        
        return createScoringFactor(
            name: "Reimbursement Environment",
            weight: 0.05,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateMarketDynamics(_ data: CompanyData) -> ScoringFactor {
        let dynamics = data.market.marketDynamics
        let drivers = dynamics.drivers
        let barriers = dynamics.barriers
        
        var score: Double = 3.0 // Base score
        var rationale: String
        
        // Analyze market drivers vs barriers
        let netDrivers = drivers.count - barriers.count
        
        switch netDrivers {
        case 3...:
            score = 5.0
            rationale = "Strong positive market dynamics with multiple drivers"
        case 1...2:
            score = 4.0
            rationale = "Positive market dynamics favor growth"
        case 0:
            score = 3.0
            rationale = "Balanced market dynamics with equal drivers and barriers"
        case -1...(-2):
            score = 2.0
            rationale = "Challenging market dynamics with more barriers than drivers"
        default:
            score = 1.0
            rationale = "Negative market dynamics with significant barriers"
        }
        
        // Consider specific high-impact drivers
        let highImpactDrivers = drivers.filter { driver in
            driver.lowercased().contains("unmet need") ||
            driver.lowercased().contains("aging population") ||
            driver.lowercased().contains("breakthrough") ||
            driver.lowercased().contains("innovation")
        }
        
        if !highImpactDrivers.isEmpty {
            score = min(5.0, score + 0.5)
            rationale += " with high-impact market drivers"
        }
        
        return createScoringFactor(
            name: "Market Dynamics",
            weight: 0.05,
            score: score,
            rationale: rationale
        )
    }
    
    // MARK: - Helper Methods
    
    private func assessMarketDataQuality(_ data: CompanyData) -> Double {
        var qualityScore: Double = 0.0
        var factors: Int = 0
        
        // Market size data quality
        if data.market.addressableMarket > 0 {
            qualityScore += 1.0
        }
        factors += 1
        
        // Growth rate data quality
        if data.market.marketDynamics.growthRate >= 0 {
            qualityScore += 1.0
        }
        factors += 1
        
        // Competitor data quality
        if !data.market.competitors.isEmpty {
            qualityScore += 1.0
        }
        factors += 1
        
        // Market dynamics data quality
        if !data.market.marketDynamics.drivers.isEmpty || !data.market.marketDynamics.barriers.isEmpty {
            qualityScore += 1.0
        }
        factors += 1
        
        // Reimbursement data quality
        if data.market.marketDynamics.reimbursement != .unknown {
            qualityScore += 1.0
        }
        factors += 1
        
        return factors > 0 ? qualityScore / Double(factors) : 0.0
    }
    
    private func generateMarketSpecificWarnings(_ data: CompanyData) -> [String] {
        var warnings: [String] = []
        
        // Market size warnings
        if data.market.addressableMarket < minimumMarketSize {
            warnings.append("Very small addressable market may limit commercial viability")
        }
        
        // Growth rate warnings
        if data.market.marketDynamics.growthRate < 0 {
            warnings.append("Declining market conditions pose significant risk")
        }
        
        // Competition warnings
        let advancedCompetitors = data.market.competitors.filter { 
            $0.stage == .approved || $0.stage == .marketed 
        }
        if advancedCompetitors.count > 2 {
            warnings.append("Multiple approved competitors create challenging market entry")
        }
        
        // Regulatory warnings
        if data.regulatory.regulatoryStrategy.timeline > 60 {
            warnings.append("Extended regulatory timeline increases market entry risk")
        }
        
        // Reimbursement warnings
        if data.market.marketDynamics.reimbursement == .challenging {
            warnings.append("Challenging reimbursement environment may limit market access")
        }
        
        return warnings
    }
    
    // MARK: - Override Methods
    
    internal override func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        return "Market Outlook scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription)) based on market size, growth potential, and competitive dynamics"
    }
    
    internal override func getMethodologyDescription() -> String {
        return "Market outlook evaluation methodology analyzing addressable market size, growth potential, competitive landscape intensity, regulatory pathway assessment, reimbursement environment, and overall market dynamics"
    }
    
    internal override func getKnownLimitations() -> [String] {
        return [
            "Market size estimates may vary significantly based on methodology and assumptions",
            "Competitive landscape is dynamic and may change rapidly",
            "Regulatory pathways can be unpredictable and subject to policy changes",
            "Reimbursement decisions are influenced by health economics and policy factors",
            "Market growth projections are subject to economic and healthcare trends"
        ]
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0:
            return "Excellent Market Opportunity"
        case 3.5..<4.5:
            return "Good Market Potential"
        case 2.5..<3.5:
            return "Average Market Conditions"
        case 1.5..<2.5:
            return "Challenging Market Environment"
        default:
            return "Poor Market Outlook"
        }
    }
}