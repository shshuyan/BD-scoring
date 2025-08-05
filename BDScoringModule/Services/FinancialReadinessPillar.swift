import Foundation

// MARK: - Financial Readiness Scoring Pillar

/// Evaluates cash position, burn rate, funding runway, and capital intensity requirements
public class FinancialReadinessPillar: BaseScoringPillar {
    
    // MARK: - Constants
    
    private let optimalRunwayMonths: Double = 24.0 // 2 years considered optimal
    private let minimumRunwayMonths: Double = 12.0 // 1 year minimum
    private let dataFreshnessThresholdDays: Double = 90.0 // 3 months
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createFinancialReadinessInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Financial Readiness scoring requires valid financial data")
        }
        
        // Calculate individual scoring factors
        let cashPositionFactor = calculateCashPositionScore(data)
        let burnRateFactor = calculateBurnRateScore(data)
        let fundingRunwayFactor = calculateFundingRunwayScore(data)
        let capitalIntensityFactor = calculateCapitalIntensityScore(data)
        let financingNeedFactor = calculateFinancingNeedScore(data)
        let dataFreshnessFactor = calculateDataFreshnessScore(data)
        
        let factors = [
            cashPositionFactor,
            burnRateFactor,
            fundingRunwayFactor,
            capitalIntensityFactor,
            financingNeedFactor,
            dataFreshnessFactor
        ]
        
        // Calculate weighted score
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let dataQuality = assessFinancialDataQuality(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: dataQuality,
            methodologyReliability: 0.90 // Financial analysis methodology is highly reliable
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateFinancialSpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Financial readiness evaluation based on cash position, burn rate, funding runway, capital intensity, and financing needs"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check cash position
        if data.financials.cashPosition <= 0 {
            errors.append(ValidationError(
                field: "financials.cashPosition",
                message: "Cash position must be greater than zero",
                severity: .critical
            ))
        }
        
        // Check burn rate
        if data.financials.burnRate <= 0 {
            errors.append(ValidationError(
                field: "financials.burnRate",
                message: "Burn rate must be greater than zero",
                severity: .critical
            ))
        }
        
        // Check for unrealistic values
        if data.financials.cashPosition > 10000 { // > $10B seems unrealistic for biotech
            warnings.append(ValidationWarning(
                field: "financials.cashPosition",
                message: "Cash position seems unusually high (\(data.financials.cashPosition)M)",
                suggestion: "Verify cash position data accuracy"
            ))
        }
        
        if data.financials.burnRate > 100 { // > $100M monthly burn seems high
            warnings.append(ValidationWarning(
                field: "financials.burnRate",
                message: "Monthly burn rate seems unusually high (\(data.financials.burnRate)M)",
                suggestion: "Verify burn rate calculation and data accuracy"
            ))
        }
        
        // Check data freshness
        if let lastFunding = data.financials.lastFunding {
            let daysSinceLastFunding = Date().timeIntervalSince(lastFunding.date) / (24 * 60 * 60)
            if daysSinceLastFunding > dataFreshnessThresholdDays {
                warnings.append(ValidationWarning(
                    field: "financials.lastFunding.date",
                    message: "Financial data may be outdated (last funding \(Int(daysSinceLastFunding)) days ago)",
                    suggestion: "Consider updating financial data for more accurate assessment"
                ))
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateDataCompleteness(data)
        )
    }
    
    // MARK: - Scoring Factor Calculations
    
    private func calculateCashPositionScore(_ data: CompanyData) -> ScoringFactor {
        let cashPosition = data.financials.cashPosition
        
        // Score based on absolute cash position and relative to development stage
        var score: Double = 1.0
        let stageMultiplier = getStageMultiplier(data.basicInfo.stage)
        
        // Base scoring thresholds (adjusted by stage)
        let excellentThreshold = 500.0 * stageMultiplier
        let goodThreshold = 200.0 * stageMultiplier
        let averageThreshold = 100.0 * stageMultiplier
        let poorThreshold = 50.0 * stageMultiplier
        
        switch cashPosition {
        case excellentThreshold...:
            score = 5.0
        case goodThreshold..<excellentThreshold:
            score = 4.0
        case averageThreshold..<goodThreshold:
            score = 3.0
        case poorThreshold..<averageThreshold:
            score = 2.0
        default:
            score = 1.0
        }
        
        let rationale = "Cash position of $\(String(format: "%.1f", cashPosition))M " +
                       "is \(getCashPositionDescription(score)) for a \(data.basicInfo.stage.rawValue) company"
        
        return createScoringFactor(
            name: "Cash Position",
            weight: 0.25,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateBurnRateScore(_ data: CompanyData) -> ScoringFactor {
        let burnRate = data.financials.burnRate
        let stage = data.basicInfo.stage
        
        // Score based on burn rate efficiency relative to stage
        var score: Double = 3.0 // Default average
        
        // Expected burn rate ranges by stage (monthly, in millions)
        let expectedBurnRanges: [DevelopmentStage: (low: Double, high: Double)] = [
            .preclinical: (low: 1.0, high: 5.0),
            .phase1: (low: 3.0, high: 10.0),
            .phase2: (low: 5.0, high: 20.0),
            .phase3: (low: 10.0, high: 50.0),
            .approved: (low: 5.0, high: 30.0),
            .marketed: (low: 10.0, high: 100.0)
        ]
        
        if let range = expectedBurnRanges[stage] {
            if burnRate <= range.low {
                score = 5.0 // Very efficient
            } else if burnRate <= range.low * 1.5 {
                score = 4.0 // Efficient
            } else if burnRate <= range.high {
                score = 3.0 // Average
            } else if burnRate <= range.high * 1.5 {
                score = 2.0 // High
            } else {
                score = 1.0 // Very high
            }
        }
        
        let rationale = "Monthly burn rate of $\(String(format: "%.1f", burnRate))M " +
                       "is \(getBurnRateDescription(score)) for \(stage.rawValue) stage"
        
        return createScoringFactor(
            name: "Burn Rate Efficiency",
            weight: 0.20,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateFundingRunwayScore(_ data: CompanyData) -> ScoringFactor {
        let runway = Double(data.financials.runway)
        
        // Score based on runway length
        var score: Double = 1.0
        
        switch runway {
        case optimalRunwayMonths...:
            score = 5.0
        case (optimalRunwayMonths * 0.75)..<optimalRunwayMonths:
            score = 4.0
        case minimumRunwayMonths..<(optimalRunwayMonths * 0.75):
            score = 3.0
        case (minimumRunwayMonths * 0.5)..<minimumRunwayMonths:
            score = 2.0
        default:
            score = 1.0
        }
        
        let rationale = "Funding runway of \(Int(runway)) months " +
                       "provides \(getRunwayDescription(score)) financial cushion"
        
        return createScoringFactor(
            name: "Funding Runway",
            weight: 0.30,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateCapitalIntensityScore(_ data: CompanyData) -> ScoringFactor {
        let stage = data.basicInfo.stage
        let programCount = data.pipeline.programs.count
        
        // Assess capital intensity based on stage and pipeline complexity
        var score: Double = 3.0
        
        // Capital intensity factors
        let stageIntensity = getStageCapitalIntensity(stage)
        let pipelineComplexity = getPipelineComplexity(data.pipeline)
        
        // Combined intensity score (lower intensity = higher score)
        let combinedIntensity = (stageIntensity + pipelineComplexity) / 2.0
        
        switch combinedIntensity {
        case 0.0..<0.3:
            score = 5.0 // Low intensity
        case 0.3..<0.5:
            score = 4.0 // Moderate-low intensity
        case 0.5..<0.7:
            score = 3.0 // Moderate intensity
        case 0.7..<0.9:
            score = 2.0 // High intensity
        default:
            score = 1.0 // Very high intensity
        }
        
        let rationale = "Capital intensity is \(getCapitalIntensityDescription(score)) " +
                       "based on \(stage.rawValue) stage and \(programCount) programs"
        
        return createScoringFactor(
            name: "Capital Intensity",
            weight: 0.15,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateFinancingNeedScore(_ data: CompanyData) -> ScoringFactor {
        let runway = Double(data.financials.runway)
        let burnRate = data.financials.burnRate
        let stage = data.basicInfo.stage
        
        // Predict financing need timing and urgency
        var score: Double = 3.0
        
        // Calculate months until financing need (typically start fundraising 6-12 months before runway ends)
        let monthsUntilFinancingNeed = max(0, runway - 9) // Start fundraising 9 months before runway ends
        
        // Score based on financing urgency and market conditions
        switch monthsUntilFinancingNeed {
        case 18...:
            score = 5.0 // No immediate pressure
        case 12..<18:
            score = 4.0 // Comfortable timeline
        case 6..<12:
            score = 3.0 // Moderate pressure
        case 3..<6:
            score = 2.0 // High pressure
        default:
            score = 1.0 // Immediate need
        }
        
        // Adjust for stage (later stages have more financing options)
        let stageAdjustment = getStageFinancingAdvantage(stage)
        score = min(5.0, score * stageAdjustment)
        
        let rationale = "Financing need expected in \(Int(monthsUntilFinancingNeed)) months " +
                       "creates \(getFinancingPressureDescription(score)) pressure"
        
        return createScoringFactor(
            name: "Financing Need Timing",
            weight: 0.08,
            score: score,
            rationale: rationale
        )
    }
    
    private func calculateDataFreshnessScore(_ data: CompanyData) -> ScoringFactor {
        var score: Double = 5.0 // Assume fresh data by default
        var daysSinceUpdate: Double = 0
        
        // Check data freshness based on last funding date
        if let lastFunding = data.financials.lastFunding {
            daysSinceUpdate = Date().timeIntervalSince(lastFunding.date) / (24 * 60 * 60)
            
            switch daysSinceUpdate {
            case 0..<30:
                score = 5.0 // Very fresh
            case 30..<60:
                score = 4.0 // Fresh
            case 60..<90:
                score = 3.0 // Acceptable
            case 90..<180:
                score = 2.0 // Stale
            default:
                score = 1.0 // Very stale
            }
        }
        
        let rationale = daysSinceUpdate > 0 ? 
            "Financial data is \(Int(daysSinceUpdate)) days old - \(getDataFreshnessDescription(score))" :
            "Financial data appears current"
        
        return createScoringFactor(
            name: "Data Freshness",
            weight: 0.02,
            score: score,
            rationale: rationale
        )
    }
    
    // MARK: - Helper Methods
    
    private func getStageMultiplier(_ stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.5
        case .phase1: return 0.7
        case .phase2: return 1.0
        case .phase3: return 1.5
        case .approved: return 1.2
        case .marketed: return 2.0
        }
    }
    
    private func getStageCapitalIntensity(_ stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.2
        case .phase1: return 0.4
        case .phase2: return 0.6
        case .phase3: return 0.9
        case .approved: return 0.5
        case .marketed: return 0.3
        }
    }
    
    private func getPipelineComplexity(_ pipeline: CompanyData.Pipeline) -> Double {
        let programCount = pipeline.programs.count
        let uniqueIndications = Set(pipeline.programs.map { $0.indication }).count
        
        // More programs and indications = higher complexity
        let programComplexity = min(1.0, Double(programCount) / 10.0)
        let indicationComplexity = min(1.0, Double(uniqueIndications) / 5.0)
        
        return (programComplexity + indicationComplexity) / 2.0
    }
    
    private func getStageFinancingAdvantage(_ stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.8
        case .phase1: return 0.9
        case .phase2: return 1.0
        case .phase3: return 1.2
        case .approved: return 1.3
        case .marketed: return 1.1
        }
    }
    
    private func assessFinancialDataQuality(_ data: CompanyData) -> Double {
        var qualityScore: Double = 1.0
        
        // Check for reasonable values
        if data.financials.cashPosition > 0 && data.financials.burnRate > 0 {
            qualityScore *= 1.0
        } else {
            qualityScore *= 0.5
        }
        
        // Check for funding history
        if data.financials.lastFunding != nil {
            qualityScore *= 1.0
        } else {
            qualityScore *= 0.8
        }
        
        // Check for realistic runway
        let runway = data.financials.runway
        if runway > 0 && runway < 120 { // 0-10 years seems reasonable
            qualityScore *= 1.0
        } else {
            qualityScore *= 0.7
        }
        
        return min(1.0, qualityScore)
    }
    
    private func generateFinancialSpecificWarnings(_ data: CompanyData) -> [String] {
        var warnings: [String] = []
        
        let runway = data.financials.runway
        
        // Critical runway warnings
        if runway < 6 {
            warnings.append("Critical: Less than 6 months runway remaining")
        } else if runway < 12 {
            warnings.append("Warning: Less than 12 months runway remaining")
        }
        
        // High burn rate warning
        let burnRate = data.financials.burnRate
        let cashPosition = data.financials.cashPosition
        if burnRate > cashPosition * 0.1 { // Burning >10% of cash per month
            warnings.append("High burn rate relative to cash position")
        }
        
        // Funding gap warning
        if let lastFunding = data.financials.lastFunding {
            let monthsSinceLastFunding = Date().timeIntervalSince(lastFunding.date) / (30 * 24 * 60 * 60)
            if monthsSinceLastFunding > 18 {
                warnings.append("No recent funding activity (>18 months)")
            }
        }
        
        return warnings
    }
    
    // MARK: - Description Methods
    
    private func getCashPositionDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "excellent"
        case 3.5..<4.5: return "strong"
        case 2.5..<3.5: return "adequate"
        case 1.5..<2.5: return "concerning"
        default: return "critical"
        }
    }
    
    private func getBurnRateDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "very efficient"
        case 3.5..<4.5: return "efficient"
        case 2.5..<3.5: return "reasonable"
        case 1.5..<2.5: return "high"
        default: return "excessive"
        }
    }
    
    private func getRunwayDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "excellent"
        case 3.5..<4.5: return "good"
        case 2.5..<3.5: return "adequate"
        case 1.5..<2.5: return "limited"
        default: return "critical"
        }
    }
    
    private func getCapitalIntensityDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "low"
        case 3.5..<4.5: return "moderate"
        case 2.5..<3.5: return "average"
        case 1.5..<2.5: return "high"
        default: return "very high"
        }
    }
    
    private func getFinancingPressureDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "minimal"
        case 3.5..<4.5: return "low"
        case 2.5..<3.5: return "moderate"
        case 1.5..<2.5: return "high"
        default: return "critical"
        }
    }
    
    private func getDataFreshnessDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "very current"
        case 3.5..<4.5: return "current"
        case 2.5..<3.5: return "acceptable"
        case 1.5..<2.5: return "outdated"
        default: return "very outdated"
        }
    }
    
    // MARK: - Override Methods
    
    internal override func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        let runway = "N/A" // Would need access to original data
        return "Financial Readiness scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription))"
    }
    
    internal override func getMethodologyDescription() -> String {
        return "Financial readiness evaluation based on cash position analysis, burn rate efficiency, funding runway calculation, capital intensity assessment, financing need prediction, and data freshness validation"
    }
    
    internal override func getKnownLimitations() -> [String] {
        return [
            "Analysis based on reported financial data which may not reflect real-time position",
            "Market conditions and funding environment changes can affect financing availability",
            "Burn rate projections assume current spending patterns continue",
            "Capital intensity estimates are based on typical development costs",
            "Data freshness affects accuracy of runway calculations"
        ]
    }
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0: return "Excellent"
        case 3.5..<4.5: return "Good"
        case 2.5..<3.5: return "Average"
        case 1.5..<2.5: return "Below Average"
        default: return "Poor"
        }
    }
}