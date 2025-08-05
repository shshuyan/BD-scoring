import Foundation

/// Concrete implementation of the WeightingEngine protocol
/// Handles application of configurable weights to pillar scores with real-time recalculation
class BDWeightingEngine: WeightingEngine {
    
    // MARK: - Properties
    
    /// Current weight configuration
    private var currentWeights: WeightConfig
    
    /// Stored weight profiles for reuse
    private var weightProfiles: [String: WeightConfig] = [:]
    
    /// Validation thresholds
    private let minWeight: Double = 0.0
    private let maxWeight: Double = 1.0
    private let weightSumTolerance: Double = 0.001
    
    // MARK: - Initialization
    
    init(defaultWeights: WeightConfig = WeightConfig()) {
        self.currentWeights = defaultWeights
        setupDefaultProfiles()
    }
    
    // MARK: - WeightingEngine Protocol Implementation
    
    /// Apply weights to pillar scores and return weighted scores
    func applyWeights(_ pillarScores: PillarScores, weights: WeightConfig) -> WeightedScores {
        // Validate weights before applying
        let validationResult = validateWeights(weights)
        guard validationResult.isValid else {
            // Use normalized weights if validation fails
            var normalizedWeights = weights
            normalizeWeights(&normalizedWeights)
            return calculateWeightedScores(pillarScores, weights: normalizedWeights)
        }
        
        return calculateWeightedScores(pillarScores, weights: weights)
    }
    
    /// Validate weight configuration
    func validateWeights(_ weights: WeightConfig) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check individual weight bounds
        let weightValues = [
            ("assetQuality", weights.assetQuality),
            ("marketOutlook", weights.marketOutlook),
            ("capitalIntensity", weights.capitalIntensity),
            ("strategicFit", weights.strategicFit),
            ("financialReadiness", weights.financialReadiness),
            ("regulatoryRisk", weights.regulatoryRisk)
        ]
        
        for (name, value) in weightValues {
            if value < minWeight {
                errors.append(ValidationError(
                    field: name,
                    message: "Weight cannot be negative",
                    severity: .error
                ))
            }
            
            if value > maxWeight {
                errors.append(ValidationError(
                    field: name,
                    message: "Weight cannot exceed 1.0",
                    severity: .error
                ))
            }
            
            if value == 0.0 {
                warnings.append(ValidationWarning(
                    field: name,
                    message: "Zero weight will exclude this pillar from scoring",
                    suggestion: "Consider using a small positive weight instead"
                ))
            }
        }
        
        // Check weight sum
        let totalWeight = weights.assetQuality + weights.marketOutlook + 
                         weights.capitalIntensity + weights.strategicFit + 
                         weights.financialReadiness + weights.regulatoryRisk
        
        if abs(totalWeight - 1.0) > weightSumTolerance {
            if totalWeight == 0.0 {
                errors.append(ValidationError(
                    field: "total",
                    message: "All weights cannot be zero",
                    severity: .critical
                ))
            } else {
                warnings.append(ValidationWarning(
                    field: "total",
                    message: "Weights sum to \(String(format: "%.3f", totalWeight)) instead of 1.0",
                    suggestion: "Weights will be automatically normalized"
                ))
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: 1.0
        )
    }
    
    /// Normalize weights to sum to 1.0
    func normalizeWeights(_ weights: inout WeightConfig) {
        let total = weights.assetQuality + weights.marketOutlook + 
                   weights.capitalIntensity + weights.strategicFit + 
                   weights.financialReadiness + weights.regulatoryRisk
        
        guard total > 0 else {
            // If all weights are zero, set to equal weights
            weights = WeightConfig(
                assetQuality: 1.0/6.0,
                marketOutlook: 1.0/6.0,
                capitalIntensity: 1.0/6.0,
                strategicFit: 1.0/6.0,
                financialReadiness: 1.0/6.0,
                regulatoryRisk: 1.0/6.0
            )
            return
        }
        
        weights.assetQuality /= total
        weights.marketOutlook /= total
        weights.capitalIntensity /= total
        weights.strategicFit /= total
        weights.financialReadiness /= total
        weights.regulatoryRisk /= total
    }
    
    // MARK: - Public Methods
    
    /// Apply weights with real-time recalculation
    func applyWeightsWithRecalculation(_ pillarScores: PillarScores, weights: WeightConfig) -> (WeightedScores, ValidationResult) {
        let validationResult = validateWeights(weights)
        let weightedScores = applyWeights(pillarScores, weights: weights)
        return (weightedScores, validationResult)
    }
    
    /// Save a weight profile for reuse
    func saveWeightProfile(name: String, weights: WeightConfig) throws {
        let validationResult = validateWeights(weights)
        guard validationResult.isValid || validationResult.errors.allSatisfy({ $0.severity != .critical }) else {
            throw ScoringError.configurationError("Cannot save invalid weight profile: \(validationResult.errors.first?.message ?? "Unknown error")")
        }
        
        var normalizedWeights = weights
        normalizeWeights(&normalizedWeights)
        weightProfiles[name] = normalizedWeights
    }
    
    /// Load a saved weight profile
    func loadWeightProfile(name: String) -> WeightConfig? {
        return weightProfiles[name]
    }
    
    /// Get all available weight profiles
    func getAvailableProfiles() -> [String] {
        return Array(weightProfiles.keys).sorted()
    }
    
    /// Delete a weight profile
    func deleteWeightProfile(name: String) -> Bool {
        return weightProfiles.removeValue(forKey: name) != nil
    }
    
    /// Calculate impact of weight changes on overall score
    func calculateWeightImpact(pillarScores: PillarScores, originalWeights: WeightConfig, newWeights: WeightConfig) -> WeightImpactAnalysis {
        let originalWeighted = applyWeights(pillarScores, weights: originalWeights)
        let newWeighted = applyWeights(pillarScores, weights: newWeights)
        
        let scoreDifference = newWeighted.total - originalWeighted.total
        let percentageChange = originalWeighted.total > 0 ? (scoreDifference / originalWeighted.total) * 100 : 0
        
        let pillarImpacts = [
            "assetQuality": newWeighted.assetQuality - originalWeighted.assetQuality,
            "marketOutlook": newWeighted.marketOutlook - originalWeighted.marketOutlook,
            "capitalIntensity": newWeighted.capitalIntensity - originalWeighted.capitalIntensity,
            "strategicFit": newWeighted.strategicFit - originalWeighted.strategicFit,
            "financialReadiness": newWeighted.financialReadiness - originalWeighted.financialReadiness,
            "regulatoryRisk": newWeighted.regulatoryRisk - originalWeighted.regulatoryRisk
        ]
        
        return WeightImpactAnalysis(
            totalScoreDifference: scoreDifference,
            percentageChange: percentageChange,
            pillarImpacts: pillarImpacts,
            significantChanges: pillarImpacts.filter { abs($0.value) > 0.1 }
        )
    }
    
    // MARK: - Private Methods
    
    /// Calculate weighted scores from pillar scores and weights
    private func calculateWeightedScores(_ pillarScores: PillarScores, weights: WeightConfig) -> WeightedScores {
        return WeightedScores(
            assetQuality: pillarScores.assetQuality.rawScore * weights.assetQuality,
            marketOutlook: pillarScores.marketOutlook.rawScore * weights.marketOutlook,
            capitalIntensity: pillarScores.capitalIntensity.rawScore * weights.capitalIntensity,
            strategicFit: pillarScores.strategicFit.rawScore * weights.strategicFit,
            financialReadiness: pillarScores.financialReadiness.rawScore * weights.financialReadiness,
            regulatoryRisk: pillarScores.regulatoryRisk.rawScore * weights.regulatoryRisk
        )
    }
    
    /// Setup default weight profiles
    private func setupDefaultProfiles() {
        // Conservative profile - emphasizes financial readiness and regulatory risk
        weightProfiles["Conservative"] = WeightConfig(
            assetQuality: 0.20,
            marketOutlook: 0.15,
            capitalIntensity: 0.15,
            strategicFit: 0.15,
            financialReadiness: 0.20,
            regulatoryRisk: 0.15
        )
        
        // Aggressive profile - emphasizes asset quality and market outlook
        weightProfiles["Aggressive"] = WeightConfig(
            assetQuality: 0.35,
            marketOutlook: 0.30,
            capitalIntensity: 0.10,
            strategicFit: 0.15,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        
        // Balanced profile - equal weighting
        weightProfiles["Balanced"] = WeightConfig(
            assetQuality: 1.0/6.0,
            marketOutlook: 1.0/6.0,
            capitalIntensity: 1.0/6.0,
            strategicFit: 1.0/6.0,
            financialReadiness: 1.0/6.0,
            regulatoryRisk: 1.0/6.0
        )
        
        // Strategic profile - emphasizes strategic fit and asset quality
        weightProfiles["Strategic"] = WeightConfig(
            assetQuality: 0.30,
            marketOutlook: 0.20,
            capitalIntensity: 0.10,
            strategicFit: 0.30,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
    }
}

// MARK: - Supporting Types

/// Analysis of weight change impact on scoring
struct WeightImpactAnalysis {
    let totalScoreDifference: Double
    let percentageChange: Double
    let pillarImpacts: [String: Double]
    let significantChanges: [String: Double]
}

// MARK: - Extensions

extension WeightConfig {
    /// Create a weight config from a dictionary
    static func from(dictionary: [String: Double]) -> WeightConfig? {
        guard let assetQuality = dictionary["assetQuality"],
              let marketOutlook = dictionary["marketOutlook"],
              let capitalIntensity = dictionary["capitalIntensity"],
              let strategicFit = dictionary["strategicFit"],
              let financialReadiness = dictionary["financialReadiness"],
              let regulatoryRisk = dictionary["regulatoryRisk"] else {
            return nil
        }
        
        return WeightConfig(
            assetQuality: assetQuality,
            marketOutlook: marketOutlook,
            capitalIntensity: capitalIntensity,
            strategicFit: strategicFit,
            financialReadiness: financialReadiness,
            regulatoryRisk: regulatoryRisk
        )
    }
    
    /// Convert to dictionary
    func toDictionary() -> [String: Double] {
        return [
            "assetQuality": assetQuality,
            "marketOutlook": marketOutlook,
            "capitalIntensity": capitalIntensity,
            "strategicFit": strategicFit,
            "financialReadiness": financialReadiness,
            "regulatoryRisk": regulatoryRisk
        ]
    }
}