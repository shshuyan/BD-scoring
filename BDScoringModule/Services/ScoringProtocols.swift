import Foundation

// MARK: - Core Scoring Protocols

/// Protocol for individual scoring pillars
protocol ScoringPillar {
    /// Calculate score for this pillar based on company data
    func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore
    
    /// Get required fields for this pillar
    func getRequiredFields() -> [String]
    
    /// Validate data for this pillar
    func validateData(_ data: CompanyData) -> ValidationResult
    
    /// Explain how the score was calculated
    func explainScore(_ score: PillarScore) -> ScoreExplanation
    
    /// Get pillar name and description
    var pillarInfo: PillarInfo { get }
}

/// Main scoring engine protocol
protocol ScoringEngine {
    /// Evaluate a company across all pillars
    func evaluateCompany(_ companyData: CompanyData, config: ScoringConfig) async throws -> ScoringResult
    
    /// Validate input data completeness
    func validateInputData(_ data: CompanyData) -> ValidationResult
    
    /// Calculate weighted score from pillar scores
    func calculateWeightedScore(_ pillarScores: PillarScores, weights: WeightConfig) -> WeightedScore
    
    /// Get confidence metrics for the scoring
    func calculateConfidence(_ pillarScores: PillarScores, data: CompanyData) -> ConfidenceMetrics
}

/// Protocol for weighting engine
protocol WeightingEngine {
    /// Apply weights to pillar scores
    func applyWeights(_ pillarScores: PillarScores, weights: WeightConfig) -> WeightedScores
    
    /// Validate weight configuration
    func validateWeights(_ weights: WeightConfig) -> ValidationResult
    
    /// Normalize weights to sum to 1.0
    func normalizeWeights(_ weights: inout WeightConfig)
}

/// Protocol for data validation service
protocol ValidationService {
    /// Validate complete company data
    func validateCompanyData(_ data: CompanyData) -> ValidationResult
    
    /// Check data completeness
    func checkDataCompleteness(_ data: CompanyData) -> Double
    
    /// Get missing required fields
    func getMissingFields(_ data: CompanyData) -> [String]
    
    /// Validate specific field
    func validateField(_ fieldName: String, value: Any?) -> ValidationResult
}

// MARK: - Supporting Types

/// Market context for scoring calculations
struct MarketContext {
    var benchmarkData: [BenchmarkData]
    var marketConditions: MarketConditions
    var comparableCompanies: [CompanyData]
    var industryMetrics: IndustryMetrics
}

struct BenchmarkData: Codable {
    var therapeuticArea: String
    var stage: DevelopmentStage
    var averageScore: Double
    var standardDeviation: Double
    var sampleSize: Int
}

struct MarketConditions: Codable {
    var biotechIndex: Double
    var ipoActivity: IPOActivity
    var fundingEnvironment: FundingEnvironment
    var regulatoryClimate: RegulatoryClimate
}

enum IPOActivity: String, CaseIterable, Codable {
    case hot = "Hot"
    case moderate = "Moderate"
    case cold = "Cold"
}

enum FundingEnvironment: String, CaseIterable, Codable {
    case abundant = "Abundant"
    case moderate = "Moderate"
    case constrained = "Constrained"
}

enum RegulatoryClimate: String, CaseIterable, Codable {
    case supportive = "Supportive"
    case neutral = "Neutral"
    case restrictive = "Restrictive"
}

struct IndustryMetrics: Codable {
    var averageValuation: Double
    var medianTimeline: Int
    var successRate: Double
    var averageRunway: Int
}

/// Information about a scoring pillar
struct PillarInfo: Codable {
    var name: String
    var description: String
    var defaultWeight: Double
    var requiredFields: [String]
    var optionalFields: [String]
}

/// Detailed explanation of a score
struct ScoreExplanation: Codable {
    var summary: String
    var factors: [ExplanationFactor]
    var methodology: String
    var limitations: [String]
}

struct ExplanationFactor: Codable, Identifiable {
    let id = UUID()
    var name: String
    var contribution: Double
    var explanation: String
}

/// Weighted score result
struct WeightedScore: Codable {
    var score: Double
    var breakdown: [String: Double]
    var confidence: Double
}

// MARK: - Error Types

enum ScoringError: Error, LocalizedError {
    case invalidData(String)
    case missingRequiredField(String)
    case calculationError(String)
    case configurationError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .calculationError(let message):
            return "Calculation error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Service Protocols

/// Protocol for data persistence
protocol DataService {
    /// Save company data
    func saveCompany(_ company: CompanyData) async throws
    
    /// Load company data
    func loadCompany(id: UUID) async throws -> CompanyData
    
    /// Get all companies
    func getAllCompanies() async throws -> [CompanyData]
    
    /// Delete company
    func deleteCompany(id: UUID) async throws
    
    /// Save scoring result
    func saveScoringResult(_ result: ScoringResult) async throws
    
    /// Load scoring results for company
    func getScoringResults(companyId: UUID) async throws -> [ScoringResult]
}

/// Protocol for report generation
protocol ReportService {
    /// Generate executive summary
    func generateExecutiveSummary(_ result: ScoringResult) async throws -> ExecutiveSummary
    
    /// Generate detailed report
    func generateDetailedReport(_ result: ScoringResult, template: ReportTemplate) async throws -> DetailedReport
    
    /// Export report in specified format
    func exportReport(_ report: DetailedReport, format: ExportFormat) async throws -> Data
}

// MARK: - Report Types

struct ExecutiveSummary: Codable {
    var companyName: String
    var overallScore: Double
    var recommendation: InvestmentRecommendation
    var keyStrengths: [String]
    var keyRisks: [String]
    var valuation: ValuationSummary?
    var nextSteps: [String]
}

struct DetailedReport: Codable {
    var executiveSummary: ExecutiveSummary
    var pillarAnalysis: [PillarAnalysis]
    var financialAnalysis: FinancialAnalysis
    var riskAssessment: RiskAssessment
    var comparableAnalysis: ComparableAnalysis
    var appendices: [ReportAppendix]
}

struct PillarAnalysis: Codable {
    var pillarName: String
    var score: Double
    var weight: Double
    var analysis: String
    var supportingData: [String: Any]
}

struct FinancialAnalysis: Codable {
    var currentPosition: String
    var projections: [FinancialProjection]
    var keyMetrics: [String: Double]
    var risks: [String]
}

struct FinancialProjection: Codable {
    var year: Int
    var revenue: Double?
    var expenses: Double?
    var cashFlow: Double?
    var assumptions: [String]
}

struct RiskAssessment: Codable {
    var overallRisk: RiskLevel
    var riskFactors: [RiskFactor]
    var mitigationStrategies: [String]
}

struct RiskFactor: Codable, Identifiable {
    let id = UUID()
    var category: String
    var description: String
    var probability: RiskProbability
    var impact: RiskImpact
    var mitigation: String?
}

struct ComparableAnalysis: Codable {
    var comparableCompanies: [ComparableCompany]
    var benchmarkMetrics: [String: Double]
    var positioningAnalysis: String
}

struct ComparableCompany: Codable, Identifiable {
    let id = UUID()
    var name: String
    var stage: DevelopmentStage
    var valuation: Double?
    var keyMetrics: [String: Double]
    var similarity: Double // 0-1 scale
}

struct ValuationSummary: Codable {
    var baseCase: Double
    var bearCase: Double
    var bullCase: Double
    var methodology: String
    var confidence: Double
}

struct ReportTemplate: Codable {
    var name: String
    var sections: [ReportSection]
    var formatting: ReportFormatting
}

struct ReportSection: Codable {
    var title: String
    var content: String
    var includeCharts: Bool
    var includeData: Bool
}

struct ReportFormatting: Codable {
    var fontSize: Int
    var fontFamily: String
    var includeLogos: Bool
    var colorScheme: String
}

struct ReportAppendix: Codable {
    var title: String
    var content: String
    var dataTable: [[String]]?
}

enum ExportFormat: String, CaseIterable, Codable {
    case pdf = "PDF"
    case excel = "Excel"
    case powerpoint = "PowerPoint"
    case word = "Word"
}