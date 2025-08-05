import Foundation

// MARK: - Comparable Transaction Models

/// Represents a comparable transaction (BD deal or IPO) for valuation analysis
struct Comparable: Codable, Identifiable {
    let id = UUID()
    var companyName: String
    var transactionType: TransactionType
    var date: Date
    var valuation: Double // in millions USD
    var stage: DevelopmentStage
    var therapeuticAreas: [String]
    var leadProgram: ComparableProgram
    var marketSize: Double // addressable market in billions
    var financials: ComparableFinancials
    var dealStructure: DealStructure?
    var similarity: Double? // calculated similarity score (0-1)
    var confidence: Double // confidence in data quality (0-1)
    
    /// Calculate age of transaction in years
    var ageInYears: Double {
        Date().timeIntervalSince(date) / (365.25 * 24 * 3600)
    }
    
    /// Check if transaction is recent (within specified years)
    func isRecent(withinYears years: Double = 3.0) -> Bool {
        ageInYears <= years
    }
}

enum TransactionType: String, CaseIterable, Codable {
    case acquisition = "Acquisition"
    case licensing = "Licensing"
    case partnership = "Partnership"
    case ipo = "IPO"
    case merger = "Merger"
    
    var displayName: String {
        switch self {
        case .acquisition: return "Acquisition"
        case .licensing: return "Licensing Deal"
        case .partnership: return "Strategic Partnership"
        case .ipo: return "IPO"
        case .merger: return "Merger"
        }
    }
}

struct ComparableProgram: Codable {
    var name: String
    var indication: String
    var mechanism: String
    var stage: DevelopmentStage
    var differentiators: [String]
    var competitivePosition: CompetitivePosition
}

enum CompetitivePosition: String, CaseIterable, Codable {
    case firstInClass = "First-in-Class"
    case bestInClass = "Best-in-Class"
    case fastFollower = "Fast Follower"
    case meToo = "Me-Too"
    case unknown = "Unknown"
}

struct ComparableFinancials: Codable {
    var cashAtTransaction: Double? // in millions
    var burnRate: Double? // monthly burn in millions
    var runway: Int? // months
    var lastFundingAmount: Double? // in millions
    var revenue: Double? // annual revenue in millions
    var employees: Int?
}

struct DealStructure: Codable {
    var upfront: Double // upfront payment in millions
    var milestones: Double // potential milestone payments in millions
    var royalties: Double? // royalty percentage
    var equity: Double? // equity percentage acquired
    var terms: [String] // key deal terms
}

// MARK: - Search and Matching Models

/// Criteria for finding comparable transactions
struct ComparableCriteria: Codable {
    var therapeuticAreas: [String]?
    var stages: [DevelopmentStage]?
    var transactionTypes: [TransactionType]?
    var minMarketSize: Double?
    var maxMarketSize: Double?
    var minValuation: Double?
    var maxValuation: Double?
    var maxAge: Double? // maximum age in years
    var minConfidence: Double? // minimum data confidence
    var competitivePositions: [CompetitivePosition]?
    var mechanisms: [String]?
    var indications: [String]?
    
    /// Default criteria for broad search
    static var `default`: ComparableCriteria {
        ComparableCriteria(
            maxAge: 5.0,
            minConfidence: 0.6
        )
    }
}

/// Result of comparable search with matching details
struct ComparableSearchResult: Codable {
    var comparables: [ComparableMatch]
    var totalFound: Int
    var searchCriteria: ComparableCriteria
    var averageConfidence: Double
    var searchTimestamp: Date
    
    /// Get comparables sorted by similarity score
    var sortedBySimilarity: [ComparableMatch] {
        comparables.sorted { $0.similarity > $1.similarity }
    }
    
    /// Get top N most similar comparables
    func topMatches(_ count: Int) -> [ComparableMatch] {
        Array(sortedBySimilarity.prefix(count))
    }
}

/// Comparable with calculated similarity and matching details
struct ComparableMatch: Codable, Identifiable {
    let id = UUID()
    var comparable: Comparable
    var similarity: Double // overall similarity score (0-1)
    var matchingFactors: MatchingFactors
    var confidence: Double // confidence in the match
    
    /// Weighted score combining similarity and confidence
    var weightedScore: Double {
        (similarity * 0.7) + (confidence * 0.3)
    }
}

/// Detailed breakdown of matching factors
struct MatchingFactors: Codable {
    var therapeuticAreaMatch: Double // 0-1
    var stageMatch: Double // 0-1
    var marketSizeMatch: Double // 0-1
    var mechanismMatch: Double // 0-1
    var competitivePositionMatch: Double // 0-1
    var timeRelevance: Double // 0-1 (newer = higher)
    var financialSimilarity: Double // 0-1
    
    /// Calculate overall similarity from individual factors
    var overallSimilarity: Double {
        let weights: [Double] = [0.25, 0.20, 0.15, 0.15, 0.10, 0.10, 0.05]
        let scores = [therapeuticAreaMatch, stageMatch, marketSizeMatch, 
                     mechanismMatch, competitivePositionMatch, timeRelevance, financialSimilarity]
        
        return zip(weights, scores).reduce(0.0) { $0 + ($1.0 * $1.1) }
    }
}

// MARK: - Database Schema Models

/// Database configuration for comparables storage
struct ComparablesDatabase: Codable {
    var version: String
    var lastUpdated: Date
    var totalRecords: Int
    var dataQualityMetrics: DataQualityMetrics
    var sources: [DataSource]
}

struct DataQualityMetrics: Codable {
    var averageConfidence: Double
    var completenessScore: Double // percentage of fields populated
    var recentnessScore: Double // percentage of recent transactions
    var diversityScore: Double // diversity across therapeutic areas and stages
}

struct DataSource: Codable, Identifiable {
    let id = UUID()
    var name: String
    var type: DataSourceType
    var reliability: Double // 0-1 scale
    var lastUpdate: Date
    var recordCount: Int
}

enum DataSourceType: String, CaseIterable, Codable {
    case publicFiling = "Public Filing"
    case pressRelease = "Press Release"
    case industryReport = "Industry Report"
    case proprietary = "Proprietary Database"
    case manual = "Manual Entry"
}

// MARK: - Validation Models

/// Validation result for comparable data
struct ComparableValidation: Codable {
    var isValid: Bool
    var completeness: Double // 0-1 scale
    var confidence: Double // 0-1 scale
    var issues: [ValidationIssue]
    var recommendations: [String]
}

struct ValidationIssue: Codable, Identifiable {
    let id = UUID()
    var field: String
    var severity: ValidationSeverity
    var message: String
    var suggestion: String?
}

// MARK: - Analytics Models

/// Analytics for comparable database performance
struct ComparablesAnalytics: Codable {
    var totalComparables: Int
    var byTransactionType: [TransactionType: Int]
    var byTherapeuticArea: [String: Int]
    var byStage: [DevelopmentStage: Int]
    var averageValuation: Double
    var medianValuation: Double
    var valuationRange: ClosedRange<Double>
    var dataFreshness: DataFreshness
    var qualityMetrics: QualityMetrics
}

struct DataFreshness: Codable {
    var averageAge: Double // in years
    var recentTransactions: Int // within last 2 years
    var oldestTransaction: Date
    var newestTransaction: Date
}

struct QualityMetrics: Codable {
    var averageConfidence: Double
    var highConfidenceCount: Int // confidence > 0.8
    var completeRecords: Int // all required fields populated
    var verifiedTransactions: Int // manually verified
}