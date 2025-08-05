import Foundation

// MARK: - Base Scoring Pillar Implementation

/// Abstract base class providing common functionality for all scoring pillars
open class BaseScoringPillar: ScoringPillar {
    
    // MARK: - Properties
    
    /// Information about this pillar
    public let pillarInfo: PillarInfo
    
    /// Minimum confidence threshold for reliable scoring
    internal let minimumConfidenceThreshold: Double = 0.3
    
    /// Maximum score value (1-5 scale)
    internal let maxScore: Double = 5.0
    
    /// Minimum score value (1-5 scale)
    internal let minScore: Double = 1.0
    
    // MARK: - Initialization
    
    public init(pillarInfo: PillarInfo) {
        self.pillarInfo = pillarInfo
    }
    
    // MARK: - ScoringPillar Protocol Implementation
    
    /// Calculate score for this pillar - must be overridden by subclasses
    open func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        fatalError("calculateScore must be implemented by subclass")
    }
    
    /// Get required fields for this pillar
    public func getRequiredFields() -> [String] {
        return pillarInfo.requiredFields
    }
    
    /// Validate data for this pillar
    public func validateData(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check required fields
        let missingFields = checkMissingRequiredFields(data)
        for field in missingFields {
            errors.append(ValidationError(
                field: field,
                message: "Required field '\(field)' is missing",
                severity: .critical
            ))
        }
        
        // Perform pillar-specific validation
        let specificValidation = performSpecificValidation(data)
        errors.append(contentsOf: specificValidation.errors)
        warnings.append(contentsOf: specificValidation.warnings)
        
        // Calculate completeness
        let completeness = calculateDataCompleteness(data)
        
        // Add warning if completeness is low
        if completeness < 0.7 {
            warnings.append(ValidationWarning(
                field: "overall",
                message: "Data completeness is low (\(Int(completeness * 100))%)",
                suggestion: "Consider gathering additional data for more accurate scoring"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: completeness
        )
    }
    
    /// Explain how the score was calculated
    public func explainScore(_ score: PillarScore) -> ScoreExplanation {
        let factors = score.factors.map { factor in
            ExplanationFactor(
                name: factor.name,
                contribution: factor.weight * factor.score,
                explanation: factor.rationale
            )
        }
        
        return ScoreExplanation(
            summary: generateScoreSummary(score),
            factors: factors,
            methodology: getMethodologyDescription(),
            limitations: getKnownLimitations()
        )
    }
    
    // MARK: - Protected Helper Methods
    
    /// Check for missing required fields - can be overridden for custom logic
    internal func checkMissingRequiredFields(_ data: CompanyData) -> [String] {
        var missingFields: [String] = []
        
        for field in getRequiredFields() {
            if !isFieldPresent(field, in: data) {
                missingFields.append(field)
            }
        }
        
        return missingFields
    }
    
    /// Check if a specific field is present and valid in the data
    internal func isFieldPresent(_ fieldName: String, in data: CompanyData) -> Bool {
        // This is a simplified implementation - in practice, you'd use reflection
        // or a more sophisticated field checking mechanism
        switch fieldName {
        case "basicInfo.name":
            return !data.basicInfo.name.isEmpty
        case "basicInfo.sector":
            return !data.basicInfo.sector.isEmpty
        case "basicInfo.therapeuticAreas":
            return !data.basicInfo.therapeuticAreas.isEmpty
        case "pipeline.programs":
            return !data.pipeline.programs.isEmpty
        case "financials.cashPosition":
            return data.financials.cashPosition > 0
        case "financials.burnRate":
            return data.financials.burnRate > 0
        case "market.addressableMarket":
            return data.market.addressableMarket > 0
        default:
            return true // Assume present if not explicitly checked
        }
    }
    
    /// Calculate data completeness for this pillar (0-1 scale)
    internal func calculateDataCompleteness(_ data: CompanyData) -> Double {
        let requiredFields = getRequiredFields()
        let optionalFields = pillarInfo.optionalFields
        let totalFields = requiredFields.count + optionalFields.count
        
        guard totalFields > 0 else { return 1.0 }
        
        var presentFields = 0
        
        // Check required fields
        for field in requiredFields {
            if isFieldPresent(field, in: data) {
                presentFields += 1
            }
        }
        
        // Check optional fields
        for field in optionalFields {
            if isFieldPresent(field, in: data) {
                presentFields += 1
            }
        }
        
        return Double(presentFields) / Double(totalFields)
    }
    
    /// Perform pillar-specific validation - override in subclasses
    internal func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        return ValidationResult(
            isValid: true,
            errors: [],
            warnings: [],
            completeness: 1.0
        )
    }
    
    /// Normalize score to 1-5 scale
    internal func normalizeScore(_ rawScore: Double) -> Double {
        return max(minScore, min(maxScore, rawScore))
    }
    
    /// Calculate confidence based on data quality and completeness
    internal func calculateConfidence(
        dataCompleteness: Double,
        dataQuality: Double = 1.0,
        methodologyReliability: Double = 1.0
    ) -> Double {
        let baseConfidence = (dataCompleteness * 0.4) + 
                           (dataQuality * 0.3) + 
                           (methodologyReliability * 0.3)
        
        return max(0.0, min(1.0, baseConfidence))
    }
    
    /// Create a scoring factor with validation
    internal func createScoringFactor(
        name: String,
        weight: Double,
        score: Double,
        rationale: String
    ) -> ScoringFactor {
        let normalizedWeight = max(0.0, min(1.0, weight))
        let normalizedScore = normalizeScore(score)
        
        return ScoringFactor(
            name: name,
            weight: normalizedWeight,
            score: normalizedScore,
            rationale: rationale
        )
    }
    
    /// Generate warnings based on score and data quality
    internal func generateWarnings(
        score: Double,
        confidence: Double,
        dataCompleteness: Double
    ) -> [String] {
        var warnings: [String] = []
        
        if confidence < minimumConfidenceThreshold {
            warnings.append("Low confidence score due to insufficient data")
        }
        
        if dataCompleteness < 0.5 {
            warnings.append("Significant data gaps may affect scoring accuracy")
        }
        
        if score <= 2.0 {
            warnings.append("Low score indicates significant concerns")
        }
        
        return warnings
    }
    
    // MARK: - Abstract Methods (to be overridden)
    
    /// Generate a summary of the score - override in subclasses
    internal func generateScoreSummary(_ score: PillarScore) -> String {
        let scoreDescription = getScoreDescription(score.rawScore)
        return "\(pillarInfo.name) scored \(String(format: "%.1f", score.rawScore))/5.0 (\(scoreDescription))"
    }
    
    /// Get methodology description - override in subclasses
    internal func getMethodologyDescription() -> String {
        return "Standard \(pillarInfo.name) evaluation methodology"
    }
    
    /// Get known limitations - override in subclasses
    internal func getKnownLimitations() -> [String] {
        return [
            "Scoring is based on available data at time of evaluation",
            "Market conditions may change affecting relevance",
            "Subjective factors may influence interpretation"
        ]
    }
    
    // MARK: - Private Helper Methods
    
    private func getScoreDescription(_ score: Double) -> String {
        switch score {
        case 4.5...5.0:
            return "Excellent"
        case 3.5..<4.5:
            return "Good"
        case 2.5..<3.5:
            return "Average"
        case 1.5..<2.5:
            return "Below Average"
        default:
            return "Poor"
        }
    }
}

// MARK: - Pillar Creation Helper

/// Factory for creating pillar info objects
public struct PillarInfoFactory {
    
    public static func createAssetQualityInfo() -> PillarInfo {
        return PillarInfo(
            name: "Asset Quality",
            description: "Evaluates pipeline strength, development stage, and competitive positioning",
            defaultWeight: 0.25,
            requiredFields: [
                "pipeline.programs",
                "basicInfo.therapeuticAreas",
                "basicInfo.stage"
            ],
            optionalFields: [
                "pipeline.leadProgram.differentiators",
                "pipeline.leadProgram.risks",
                "market.competitors"
            ]
        )
    }
    
    public static func createMarketOutlookInfo() -> PillarInfo {
        return PillarInfo(
            name: "Market Outlook",
            description: "Analyzes addressable market size and growth potential",
            defaultWeight: 0.20,
            requiredFields: [
                "market.addressableMarket",
                "basicInfo.therapeuticAreas"
            ],
            optionalFields: [
                "market.competitors",
                "market.marketDynamics"
            ]
        )
    }
    
    public static func createCapitalIntensityInfo() -> PillarInfo {
        return PillarInfo(
            name: "Capital Intensity",
            description: "Assesses development costs and capital requirements",
            defaultWeight: 0.15,
            requiredFields: [
                "financials.burnRate",
                "basicInfo.stage"
            ],
            optionalFields: [
                "pipeline.programs",
                "regulatory.clinicalTrials"
            ]
        )
    }
    
    public static func createStrategicFitInfo() -> PillarInfo {
        return PillarInfo(
            name: "Strategic Fit",
            description: "Analyzes alignment with acquirer capabilities and strategy",
            defaultWeight: 0.20,
            requiredFields: [
                "basicInfo.therapeuticAreas",
                "pipeline.programs"
            ],
            optionalFields: [
                "market.competitors",
                "regulatory.approvals"
            ]
        )
    }
    
    public static func createFinancialReadinessInfo() -> PillarInfo {
        return PillarInfo(
            name: "Financial Readiness",
            description: "Analyzes current cash position and burn rate",
            defaultWeight: 0.10,
            requiredFields: [
                "financials.cashPosition",
                "financials.burnRate",
                "financials.runway"
            ],
            optionalFields: [
                "financials.lastFunding"
            ]
        )
    }
    
    public static func createRegulatoryRiskInfo() -> PillarInfo {
        return PillarInfo(
            name: "Regulatory Risk",
            description: "Assesses regulatory pathway complexity and timeline",
            defaultWeight: 0.10,
            requiredFields: [
                "basicInfo.stage",
                "basicInfo.therapeuticAreas"
            ],
            optionalFields: [
                "regulatory.approvals",
                "regulatory.clinicalTrials",
                "regulatory.regulatoryStrategy"
            ]
        )
    }
}