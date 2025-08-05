import Foundation

// MARK: - WeightConfig Validation Extension

extension WeightConfig {
    
    /// Validates the weight configuration
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check individual weight ranges (0.0 to 1.0)
        let weights = [
            ("assetQuality", assetQuality),
            ("marketOutlook", marketOutlook),
            ("capitalIntensity", capitalIntensity),
            ("strategicFit", strategicFit),
            ("financialReadiness", financialReadiness),
            ("regulatoryRisk", regulatoryRisk)
        ]
        
        for (name, weight) in weights {
            if weight < 0.0 {
                errors.append(ValidationError(
                    field: name,
                    message: "Weight cannot be negative",
                    severity: .error
                ))
            }
            
            if weight > 1.0 {
                errors.append(ValidationError(
                    field: name,
                    message: "Weight cannot exceed 1.0 (100%)",
                    severity: .error
                ))
            }
            
            if weight == 0.0 {
                warnings.append(ValidationWarning(
                    field: name,
                    message: "Zero weight means this pillar will not contribute to scoring",
                    suggestion: "Consider if this pillar should be completely excluded from evaluation"
                ))
            }
        }
        
        // Check total weight sum
        let totalWeight = assetQuality + marketOutlook + capitalIntensity + 
                         strategicFit + financialReadiness + regulatoryRisk
        
        let tolerance = 0.001
        if abs(totalWeight - 1.0) > tolerance {
            if totalWeight < 1.0 - tolerance {
                errors.append(ValidationError(
                    field: "totalWeight",
                    message: "Total weights sum to \(String(format: "%.3f", totalWeight)), which is less than 1.0",
                    severity: .error
                ))
            } else if totalWeight > 1.0 + tolerance {
                errors.append(ValidationError(
                    field: "totalWeight",
                    message: "Total weights sum to \(String(format: "%.3f", totalWeight)), which exceeds 1.0",
                    severity: .error
                ))
            }
        }
        
        // Check for balanced weighting
        let maxWeight = weights.map { $0.1 }.max() ?? 0.0
        let minWeight = weights.map { $0.1 }.min() ?? 0.0
        
        if maxWeight > 0.5 {
            warnings.append(ValidationWarning(
                field: "weightBalance",
                message: "One pillar has weight > 50%, which may create scoring bias",
                suggestion: "Consider more balanced weight distribution across pillars"
            ))
        }
        
        if maxWeight - minWeight > 0.4 && minWeight > 0.0 {
            warnings.append(ValidationWarning(
                field: "weightBalance",
                message: "Large weight disparity detected between pillars",
                suggestion: "Review if weight distribution reflects evaluation priorities"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateWeightCompleteness()
        )
    }
    
    /// Validates and normalizes weights to sum to 1.0
    mutating func validateAndNormalize() -> ValidationResult {
        let validation = validate()
        
        // Only normalize if there are no critical errors and total > 0
        let totalWeight = assetQuality + marketOutlook + capitalIntensity + 
                         strategicFit + financialReadiness + regulatoryRisk
        
        if validation.errors.isEmpty && totalWeight > 0 {
            normalize()
        }
        
        return validation
    }
    
    /// Creates a default weight configuration
    static func defaultConfiguration() -> WeightConfig {
        return WeightConfig(
            assetQuality: 0.25,      // 25% - Pipeline quality is critical
            marketOutlook: 0.20,     // 20% - Market opportunity assessment
            capitalIntensity: 0.15,  // 15% - Development cost considerations
            strategicFit: 0.20,      // 20% - Alignment with acquirer strategy
            financialReadiness: 0.10, // 10% - Current financial position
            regulatoryRisk: 0.10     // 10% - Regulatory pathway risks
        )
    }
    
    /// Creates a conservative weight configuration (emphasizes risk factors)
    static func conservativeConfiguration() -> WeightConfig {
        return WeightConfig(
            assetQuality: 0.20,
            marketOutlook: 0.15,
            capitalIntensity: 0.20,  // Higher weight on cost considerations
            strategicFit: 0.15,
            financialReadiness: 0.15, // Higher weight on financial stability
            regulatoryRisk: 0.15     // Higher weight on regulatory risks
        )
    }
    
    /// Creates an aggressive weight configuration (emphasizes upside potential)
    static func aggressiveConfiguration() -> WeightConfig {
        return WeightConfig(
            assetQuality: 0.35,      // Higher weight on pipeline quality
            marketOutlook: 0.30,     // Higher weight on market opportunity
            capitalIntensity: 0.10,  // Lower weight on cost concerns
            strategicFit: 0.15,
            financialReadiness: 0.05, // Lower weight on current financials
            regulatoryRisk: 0.05     // Lower weight on regulatory risks
        )
    }
    
    private func calculateWeightCompleteness() -> Double {
        let weights = [assetQuality, marketOutlook, capitalIntensity, 
                      strategicFit, financialReadiness, regulatoryRisk]
        let nonZeroWeights = weights.filter { $0 > 0.0 }.count
        return Double(nonZeroWeights) / Double(weights.count)
    }
}

// MARK: - ScoringConfig Validation Extension

extension ScoringConfig {
    
    /// Validates the complete scoring configuration
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Validate name
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Configuration name is required",
                severity: .critical
            ))
        }
        
        // Validate weights
        let weightValidation = weights.validate()
        errors.append(contentsOf: weightValidation.errors.map { error in
            ValidationError(
                field: "weights.\(error.field)",
                message: error.message,
                severity: error.severity
            )
        })
        
        warnings.append(contentsOf: weightValidation.warnings.map { warning in
            ValidationWarning(
                field: "weights.\(warning.field)",
                message: warning.message,
                suggestion: warning.suggestion
            )
        })
        
        // Validate parameters
        let parametersValidation = parameters.validate()
        errors.append(contentsOf: parametersValidation.errors.map { error in
            ValidationError(
                field: "parameters.\(error.field)",
                message: error.message,
                severity: error.severity
            )
        })
        
        warnings.append(contentsOf: parametersValidation.warnings.map { warning in
            ValidationWarning(
                field: "parameters.\(warning.field)",
                message: warning.message,
                suggestion: warning.suggestion
            )
        })
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateConfigCompleteness()
        )
    }
    
    /// Creates a default scoring configuration
    static func defaultConfiguration() -> ScoringConfig {
        return ScoringConfig(
            name: "Default Configuration",
            weights: WeightConfig.defaultConfiguration(),
            parameters: ScoringParameters.defaultParameters(),
            isDefault: true
        )
    }
    
    /// Creates a conservative scoring configuration
    static func conservativeConfiguration() -> ScoringConfig {
        return ScoringConfig(
            name: "Conservative Configuration",
            weights: WeightConfig.conservativeConfiguration(),
            parameters: ScoringParameters.conservativeParameters(),
            isDefault: false
        )
    }
    
    /// Creates an aggressive scoring configuration
    static func aggressiveConfiguration() -> ScoringConfig {
        return ScoringConfig(
            name: "Aggressive Configuration",
            weights: WeightConfig.aggressiveConfiguration(),
            parameters: ScoringParameters.aggressiveParameters(),
            isDefault: false
        )
    }
    
    private func calculateConfigCompleteness() -> Double {
        var score = 0.0
        let totalFields = 3.0
        
        if !name.isEmpty { score += 1.0 }
        if weights.isValid { score += 1.0 }
        // Parameters are always present, so add 1.0
        score += 1.0
        
        return score / totalFields
    }
}

// MARK: - ScoringParameters Validation Extension

extension ScoringParameters {
    
    /// Validates scoring parameters
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Risk adjustment validation
        if riskAdjustment < 0.1 {
            errors.append(ValidationError(
                field: "riskAdjustment",
                message: "Risk adjustment factor cannot be less than 0.1",
                severity: .error
            ))
        }
        
        if riskAdjustment > 3.0 {
            errors.append(ValidationError(
                field: "riskAdjustment",
                message: "Risk adjustment factor cannot exceed 3.0",
                severity: .error
            ))
        }
        
        if riskAdjustment < 0.5 || riskAdjustment > 2.0 {
            warnings.append(ValidationWarning(
                field: "riskAdjustment",
                message: "Risk adjustment factor outside typical range (0.5-2.0)",
                suggestion: "Consider if extreme risk adjustment is appropriate for your use case"
            ))
        }
        
        // Time horizon validation
        if timeHorizon <= 0 {
            errors.append(ValidationError(
                field: "timeHorizon",
                message: "Time horizon must be positive",
                severity: .error
            ))
        }
        
        if timeHorizon > 20 {
            errors.append(ValidationError(
                field: "timeHorizon",
                message: "Time horizon cannot exceed 20 years",
                severity: .error
            ))
        }
        
        if timeHorizon < 3 {
            warnings.append(ValidationWarning(
                field: "timeHorizon",
                message: "Short time horizon may not capture long-term biotech value",
                suggestion: "Consider extending time horizon for biotech investments (typically 5-10 years)"
            ))
        }
        
        if timeHorizon > 10 {
            warnings.append(ValidationWarning(
                field: "timeHorizon",
                message: "Long time horizon increases uncertainty in biotech predictions",
                suggestion: "Consider shorter time horizon for more reliable forecasts"
            ))
        }
        
        // Discount rate validation
        if discountRate < 0.0 {
            errors.append(ValidationError(
                field: "discountRate",
                message: "Discount rate cannot be negative",
                severity: .error
            ))
        }
        
        if discountRate > 1.0 {
            errors.append(ValidationError(
                field: "discountRate",
                message: "Discount rate cannot exceed 100%",
                severity: .error
            ))
        }
        
        if discountRate < 0.05 || discountRate > 0.25 {
            warnings.append(ValidationWarning(
                field: "discountRate",
                message: "Discount rate outside typical range for biotech (5%-25%)",
                suggestion: "Consider industry-standard discount rates for biotech investments"
            ))
        }
        
        // Confidence threshold validation
        if confidenceThreshold < 0.0 || confidenceThreshold > 1.0 {
            errors.append(ValidationError(
                field: "confidenceThreshold",
                message: "Confidence threshold must be between 0.0 and 1.0",
                severity: .error
            ))
        }
        
        if confidenceThreshold < 0.5 {
            warnings.append(ValidationWarning(
                field: "confidenceThreshold",
                message: "Low confidence threshold may accept unreliable predictions",
                suggestion: "Consider raising threshold to 0.6-0.8 for better prediction quality"
            ))
        }
        
        if confidenceThreshold > 0.9 {
            warnings.append(ValidationWarning(
                field: "confidenceThreshold",
                message: "Very high confidence threshold may reject valid predictions",
                suggestion: "Consider lowering threshold to allow more predictions through"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: 1.0 // All parameters are always present
        )
    }
    
    /// Creates default scoring parameters
    static func defaultParameters() -> ScoringParameters {
        return ScoringParameters(
            riskAdjustment: 1.0,      // Neutral risk adjustment
            timeHorizon: 5,           // 5-year investment horizon
            discountRate: 0.12,       // 12% discount rate (typical for biotech)
            confidenceThreshold: 0.7  // 70% confidence threshold
        )
    }
    
    /// Creates conservative scoring parameters
    static func conservativeParameters() -> ScoringParameters {
        return ScoringParameters(
            riskAdjustment: 1.3,      // Higher risk adjustment
            timeHorizon: 3,           // Shorter time horizon
            discountRate: 0.15,       // Higher discount rate
            confidenceThreshold: 0.8  // Higher confidence threshold
        )
    }
    
    /// Creates aggressive scoring parameters
    static func aggressiveParameters() -> ScoringParameters {
        return ScoringParameters(
            riskAdjustment: 0.8,      // Lower risk adjustment
            timeHorizon: 7,           // Longer time horizon
            discountRate: 0.10,       // Lower discount rate
            confidenceThreshold: 0.6  // Lower confidence threshold
        )
    }
}

// MARK: - Configuration Management

/// Manages multiple scoring configurations
class ScoringConfigurationManager {
    private var configurations: [ScoringConfig] = []
    
    init() {
        // Load default configurations
        configurations = [
            ScoringConfig.defaultConfiguration(),
            ScoringConfig.conservativeConfiguration(),
            ScoringConfig.aggressiveConfiguration()
        ]
    }
    
    /// Adds a new configuration after validation
    func addConfiguration(_ config: ScoringConfig) -> ValidationResult {
        let validation = config.validate()
        
        if validation.isValid {
            // Check for duplicate names
            if configurations.contains(where: { $0.name == config.name }) {
                return ValidationResult(
                    isValid: false,
                    errors: [ValidationError(
                        field: "name",
                        message: "Configuration name already exists",
                        severity: .error
                    )],
                    warnings: [],
                    completeness: validation.completeness
                )
            }
            
            configurations.append(config)
        }
        
        return validation
    }
    
    /// Updates an existing configuration
    func updateConfiguration(_ config: ScoringConfig) -> ValidationResult {
        let validation = config.validate()
        
        if validation.isValid {
            if let index = configurations.firstIndex(where: { $0.id == config.id }) {
                configurations[index] = config
            } else {
                return ValidationResult(
                    isValid: false,
                    errors: [ValidationError(
                        field: "id",
                        message: "Configuration not found",
                        severity: .error
                    )],
                    warnings: [],
                    completeness: validation.completeness
                )
            }
        }
        
        return validation
    }
    
    /// Removes a configuration
    func removeConfiguration(id: UUID) -> Bool {
        if let index = configurations.firstIndex(where: { $0.id == id }) {
            // Don't allow removal of default configuration
            if configurations[index].isDefault {
                return false
            }
            configurations.remove(at: index)
            return true
        }
        return false
    }
    
    /// Gets all configurations
    func getAllConfigurations() -> [ScoringConfig] {
        return configurations
    }
    
    /// Gets the default configuration
    func getDefaultConfiguration() -> ScoringConfig? {
        return configurations.first { $0.isDefault }
    }
    
    /// Gets a configuration by ID
    func getConfiguration(id: UUID) -> ScoringConfig? {
        return configurations.first { $0.id == id }
    }
    
    /// Validates all configurations
    func validateAllConfigurations() -> [UUID: ValidationResult] {
        var results: [UUID: ValidationResult] = [:]
        
        for config in configurations {
            results[config.id] = config.validate()
        }
        
        return results
    }
}