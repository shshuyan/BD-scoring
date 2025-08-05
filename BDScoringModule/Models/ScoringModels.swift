import Foundation

// MARK: - Scoring Result Models

/// Complete scoring result for a company evaluation
struct ScoringResult: Codable, Identifiable {
    let id = UUID()
    var companyId: UUID
    var overallScore: Double
    var pillarScores: PillarScores
    var weightedScores: WeightedScores
    var confidence: ConfidenceMetrics
    var recommendations: [String]
    var timestamp: Date
    var investmentRecommendation: InvestmentRecommendation
    var riskLevel: RiskLevel
}

/// Individual pillar scores (1-5 scale)
struct PillarScores: Codable {
    var assetQuality: PillarScore
    var marketOutlook: PillarScore
    var capitalIntensity: PillarScore
    var strategicFit: PillarScore
    var financialReadiness: PillarScore
    var regulatoryRisk: PillarScore
}

/// Weighted scores after applying configuration weights
struct WeightedScores: Codable {
    var assetQuality: Double
    var marketOutlook: Double
    var capitalIntensity: Double
    var strategicFit: Double
    var financialReadiness: Double
    var regulatoryRisk: Double
    
    var total: Double {
        assetQuality + marketOutlook + capitalIntensity + 
        strategicFit + financialReadiness + regulatoryRisk
    }
}

/// Individual pillar score with supporting data
struct PillarScore: Codable {
    var rawScore: Double // 1-5 scale
    var confidence: Double // 0-1 scale
    var factors: [ScoringFactor]
    var warnings: [String]
    var explanation: String?
}

/// Factors contributing to a pillar score
struct ScoringFactor: Codable, Identifiable {
    let id = UUID()
    var name: String
    var weight: Double
    var score: Double
    var rationale: String
}

/// Overall confidence metrics for the scoring
struct ConfidenceMetrics: Codable {
    var overall: Double // 0-1 scale
    var dataCompleteness: Double // 0-1 scale
    var modelAccuracy: Double // 0-1 scale
    var comparableQuality: Double // 0-1 scale
}

// MARK: - Configuration Models

/// Configurable weights for scoring pillars
struct WeightConfig: Codable {
    var assetQuality: Double = 0.25      // 25%
    var marketOutlook: Double = 0.20     // 20%
    var capitalIntensity: Double = 0.15  // 15%
    var strategicFit: Double = 0.20      // 20%
    var financialReadiness: Double = 0.10 // 10%
    var regulatoryRisk: Double = 0.10    // 10%
    
    /// Validates that weights sum to 1.0
    var isValid: Bool {
        let total = assetQuality + marketOutlook + capitalIntensity + 
                   strategicFit + financialReadiness + regulatoryRisk
        return abs(total - 1.0) < 0.001
    }
    
    /// Normalizes weights to sum to 1.0
    mutating func normalize() {
        let total = assetQuality + marketOutlook + capitalIntensity + 
                   strategicFit + financialReadiness + regulatoryRisk
        guard total > 0 else { return }
        
        assetQuality /= total
        marketOutlook /= total
        capitalIntensity /= total
        strategicFit /= total
        financialReadiness /= total
        regulatoryRisk /= total
    }
}

/// Complete scoring configuration
struct ScoringConfig: Codable, Identifiable {
    let id = UUID()
    var name: String
    var weights: WeightConfig
    var parameters: ScoringParameters
    var isDefault: Bool = false
}

/// Additional scoring parameters
struct ScoringParameters: Codable {
    var riskAdjustment: Double = 1.0
    var timeHorizon: Int = 5 // years
    var discountRate: Double = 0.12 // 12%
    var confidenceThreshold: Double = 0.7
}

// MARK: - Recommendation Types

enum InvestmentRecommendation: String, CaseIterable, Codable {
    case strongBuy = "Strong Buy"
    case buy = "Buy"
    case hold = "Hold"
    case sell = "Sell"
    case strongSell = "Strong Sell"
    
    var color: String {
        switch self {
        case .strongBuy: return "green"
        case .buy: return "lightGreen"
        case .hold: return "yellow"
        case .sell: return "orange"
        case .strongSell: return "red"
        }
    }
}

enum RiskLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        }
    }
}

// MARK: - Validation Models

/// Result of data validation
struct ValidationResult: Codable {
    var isValid: Bool
    var errors: [ValidationError]
    var warnings: [ValidationWarning]
    var completeness: Double // 0-1 scale
}

struct ValidationError: Codable, Identifiable {
    let id = UUID()
    var field: String
    var message: String
    var severity: ValidationSeverity
}

struct ValidationWarning: Codable, Identifiable {
    let id = UUID()
    var field: String
    var message: String
    var suggestion: String?
}

enum ValidationSeverity: String, CaseIterable, Codable {
    case critical = "Critical"
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
}

// MARK: - Historical Data Models

/// Historical scoring data for tracking accuracy
struct HistoricalScore: Codable, Identifiable {
    let id = UUID()
    var companyId: UUID
    var scoringResult: ScoringResult
    var actualOutcome: ActualOutcome?
    var predictionAccuracy: Double?
}

struct ActualOutcome: Codable {
    var eventType: OutcomeType
    var date: Date
    var valuation: Double?
    var details: String?
}

enum OutcomeType: String, CaseIterable, Codable {
    case acquisition = "Acquisition"
    case ipo = "IPO"
    case partnership = "Partnership"
    case licensing = "Licensing"
    case bankruptcy = "Bankruptcy"
    case ongoing = "Ongoing"
}