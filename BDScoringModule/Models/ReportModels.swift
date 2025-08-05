import Foundation

// MARK: - Report Data Models

/// Complete report containing all sections and data
struct Report: Codable, Identifiable {
    let id = UUID()
    var companyId: UUID
    var companyName: String
    var reportType: ReportType
    var executiveSummary: ExecutiveSummary
    var detailedAnalysis: DetailedAnalysis
    var metadata: ReportMetadata
    var template: ReportTemplate
    
    /// Generate report title based on company and type
    var title: String {
        switch reportType {
        case .full:
            return "BD & IPO Scoring Analysis: \(companyName)"
        case .executiveSummary:
            return "Executive Summary: \(companyName)"
        case .pillarAnalysis:
            return "Pillar Analysis: \(companyName)"
        case .valuation:
            return "Valuation Report: \(companyName)"
        }
    }
}

/// Types of reports that can be generated
enum ReportType: String, CaseIterable, Codable {
    case full = "Full Analysis"
    case executiveSummary = "Executive Summary"
    case pillarAnalysis = "Pillar Analysis"
    case valuation = "Valuation Report"
}

/// Executive summary section of the report
struct ExecutiveSummary: Codable {
    var overallScore: Double
    var investmentRecommendation: InvestmentRecommendation
    var riskLevel: RiskLevel
    var keyFindings: [KeyFinding]
    var investmentThesis: String
    var keyRisks: [String]
    var keyOpportunities: [String]
    var recommendedActions: [String]
    var confidenceLevel: Double
    
    /// Summary statistics for quick reference
    var summaryStats: SummaryStatistics
}

/// Key finding with supporting rationale
struct KeyFinding: Codable, Identifiable {
    let id = UUID()
    var category: FindingCategory
    var title: String
    var description: String
    var impact: FindingImpact
    var supportingData: [String]
}

enum FindingCategory: String, CaseIterable, Codable {
    case strength = "Strength"
    case weakness = "Weakness"
    case opportunity = "Opportunity"
    case threat = "Threat"
    case neutral = "Neutral"
    
    var color: String {
        switch self {
        case .strength: return "green"
        case .weakness: return "red"
        case .opportunity: return "blue"
        case .threat: return "orange"
        case .neutral: return "gray"
        }
    }
}

enum FindingImpact: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

/// Summary statistics for executive overview
struct SummaryStatistics: Codable {
    var totalCompaniesEvaluated: Int
    var averageScore: Double
    var percentileRanking: Double
    var industryBenchmark: Double
    var timeToNextMilestone: Int? // months
    var estimatedValuation: Double? // millions
}

/// Detailed analysis section with all pillar breakdowns
struct DetailedAnalysis: Codable {
    var scoringBreakdown: ScoringBreakdown
    var pillarAnalyses: [PillarAnalysis]
    var comparativeAnalysis: ComparativeAnalysis
    var riskAssessment: RiskAssessment
    var valuationAnalysis: ValuationAnalysis?
    var recommendations: DetailedRecommendations
}

/// Comprehensive scoring breakdown
struct ScoringBreakdown: Codable {
    var pillarScores: PillarScores
    var weightedScores: WeightedScores
    var weightConfiguration: WeightConfig
    var confidenceMetrics: ConfidenceMetrics
    var scoringMethodology: String
}

/// Individual pillar analysis with detailed insights
struct PillarAnalysis: Codable, Identifiable {
    let id = UUID()
    var pillarName: String
    var score: PillarScore
    var weightedScore: Double
    var analysis: String
    var keyMetrics: [KeyMetric]
    var benchmarks: [Benchmark]
    var recommendations: [String]
}

/// Key metric within a pillar analysis
struct KeyMetric: Codable, Identifiable {
    let id = UUID()
    var name: String
    var value: String
    var benchmark: String?
    var trend: MetricTrend?
    var importance: MetricImportance
}

enum MetricTrend: String, CaseIterable, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
    case unknown = "Unknown"
}

enum MetricImportance: String, CaseIterable, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

/// Benchmark comparison data
struct Benchmark: Codable, Identifiable {
    let id = UUID()
    var category: String
    var companyValue: Double
    var benchmarkValue: Double
    var percentile: Double
    var interpretation: String
}

/// Comparative analysis against peers and market
struct ComparativeAnalysis: Codable {
    var peerComparison: [PeerComparison]
    var industryBenchmarks: [IndustryBenchmark]
    var marketPosition: MarketPosition
    var competitiveAdvantages: [String]
    var competitiveDisadvantages: [String]
}

struct PeerComparison: Codable, Identifiable {
    let id = UUID()
    var peerName: String
    var companyScore: Double
    var peerScore: Double
    var keyDifferences: [String]
}

struct IndustryBenchmark: Codable, Identifiable {
    let id = UUID()
    var metric: String
    var companyValue: Double
    var industryAverage: Double
    var industryMedian: Double
    var topQuartile: Double
}

enum MarketPosition: String, CaseIterable, Codable {
    case leader = "Market Leader"
    case challenger = "Challenger"
    case follower = "Follower"
    case niche = "Niche Player"
}

/// Comprehensive risk assessment
struct RiskAssessment: Codable {
    var overallRiskLevel: RiskLevel
    var riskCategories: [RiskCategory]
    var mitigationStrategies: [MitigationStrategy]
    var riskMatrix: [[RiskItem]]
}

struct RiskCategory: Codable, Identifiable {
    let id = UUID()
    var name: String
    var level: RiskLevel
    var risks: [RiskItem]
    var impact: String
    var likelihood: String
}

struct RiskItem: Codable, Identifiable {
    let id = UUID()
    var description: String
    var probability: RiskProbability
    var impact: RiskImpact
    var timeframe: RiskTimeframe
    var mitigation: String?
}

enum RiskTimeframe: String, CaseIterable, Codable {
    case immediate = "Immediate (0-6 months)"
    case nearTerm = "Near-term (6-18 months)"
    case mediumTerm = "Medium-term (1-3 years)"
    case longTerm = "Long-term (3+ years)"
}

struct MitigationStrategy: Codable, Identifiable {
    let id = UUID()
    var riskId: UUID
    var strategy: String
    var cost: MitigationCost
    var effectiveness: MitigationEffectiveness
    var timeline: String
}

enum MitigationCost: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}

enum MitigationEffectiveness: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}

/// Valuation analysis section
struct ValuationAnalysis: Codable {
    var baseValuation: Double
    var valuationRange: ValuationRange
    var methodology: ValuationMethodology
    var scenarios: [ValuationScenario]
    var comparables: [ValuationComparable]
    var sensitivityAnalysis: SensitivityAnalysis
}

struct ValuationRange: Codable {
    var low: Double
    var base: Double
    var high: Double
    var confidence: Double
}

enum ValuationMethodology: String, CaseIterable, Codable {
    case comparables = "Comparable Transactions"
    case dcf = "Discounted Cash Flow"
    case riskAdjustedNPV = "Risk-Adjusted NPV"
    case realOptions = "Real Options"
    case hybrid = "Hybrid Approach"
}

struct ValuationScenario: Codable, Identifiable {
    let id = UUID()
    var name: String
    var probability: Double
    var valuation: Double
    var keyAssumptions: [String]
    var description: String
}

struct ValuationComparable: Codable, Identifiable {
    let id = UUID()
    var companyName: String
    var transactionType: String
    var valuation: Double
    var multiple: Double
    var relevanceScore: Double
    var keyMetrics: [String: String]
}

struct SensitivityAnalysis: Codable {
    var baseCase: Double
    var sensitivities: [SensitivityFactor]
    var scenarios: [SensitivityScenario]
}

struct SensitivityFactor: Codable, Identifiable {
    let id = UUID()
    var factor: String
    var baseValue: Double
    var lowCase: Double
    var highCase: Double
    var impact: Double
}

struct SensitivityScenario: Codable, Identifiable {
    let id = UUID()
    var name: String
    var changes: [String: Double]
    var resultingValuation: Double
    var variance: Double
}

/// Detailed recommendations section
struct DetailedRecommendations: Codable {
    var investmentRecommendation: InvestmentRecommendation
    var rationale: String
    var actionItems: [ActionItem]
    var timeline: RecommendationTimeline
    var successMetrics: [SuccessMetric]
    var alternativeScenarios: [AlternativeScenario]
}

struct ActionItem: Codable, Identifiable {
    let id = UUID()
    var action: String
    var priority: ActionPriority
    var owner: String?
    var deadline: Date?
    var expectedOutcome: String
}

enum ActionPriority: String, CaseIterable, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct RecommendationTimeline: Codable {
    var immediate: [String] // 0-3 months
    var nearTerm: [String] // 3-12 months
    var longTerm: [String] // 12+ months
}

struct SuccessMetric: Codable, Identifiable {
    let id = UUID()
    var metric: String
    var currentValue: String?
    var targetValue: String
    var timeframe: String
    var measurement: String
}

struct AlternativeScenario: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var probability: Double
    var implications: [String]
    var recommendedActions: [String]
}

/// Report metadata and generation information
struct ReportMetadata: Codable {
    var generatedDate: Date
    var generatedBy: String?
    var version: String
    var dataAsOfDate: Date
    var confidentialityLevel: ConfidentialityLevel
    var distributionList: [String]
    var expirationDate: Date?
    var disclaimers: [String]
}

enum ConfidentialityLevel: String, CaseIterable, Codable {
    case `public` = "Public"
    case `internal` = "Internal"
    case confidential = "Confidential"
    case restricted = "Restricted"
}

// MARK: - Report Templates

/// Template configuration for report generation
struct ReportTemplate: Codable, Identifiable {
    let id = UUID()
    var name: String
    var type: ReportType
    var sections: [ReportSection]
    var formatting: ReportFormatting
    var branding: ReportBranding
}

/// Individual section within a report template
struct ReportSection: Codable, Identifiable {
    let id = UUID()
    var name: String
    var type: SectionType
    var order: Int
    var isRequired: Bool
    var configuration: SectionConfiguration
}

enum SectionType: String, CaseIterable, Codable {
    case executiveSummary = "Executive Summary"
    case scoringOverview = "Scoring Overview"
    case pillarAnalysis = "Pillar Analysis"
    case riskAssessment = "Risk Assessment"
    case valuation = "Valuation"
    case recommendations = "Recommendations"
    case appendix = "Appendix"
    case methodology = "Methodology"
}

struct SectionConfiguration: Codable {
    var includeCharts: Bool
    var includeDetailedMetrics: Bool
    var includeBenchmarks: Bool
    var pageBreakAfter: Bool
    var customContent: [String: String]
}

/// Formatting configuration for reports
struct ReportFormatting: Codable {
    var pageSize: PageSize
    var margins: PageMargins
    var fonts: FontConfiguration
    var colors: ColorScheme
    var chartStyle: ChartStyle
}

enum PageSize: String, CaseIterable, Codable {
    case letter = "Letter"
    case a4 = "A4"
    case legal = "Legal"
}

struct PageMargins: Codable {
    var top: Double
    var bottom: Double
    var left: Double
    var right: Double
}

struct FontConfiguration: Codable {
    var headingFont: String
    var bodyFont: String
    var headingSize: Double
    var bodySize: Double
}

struct ColorScheme: Codable {
    var primary: String
    var secondary: String
    var accent: String
    var background: String
    var text: String
}

enum ChartStyle: String, CaseIterable, Codable {
    case professional = "Professional"
    case modern = "Modern"
    case minimal = "Minimal"
    case colorful = "Colorful"
}

/// Branding configuration for reports
struct ReportBranding: Codable {
    var companyName: String
    var logoUrl: String?
    var headerText: String?
    var footerText: String?
    var watermark: String?
    var contactInfo: ContactInfo?
}

struct ContactInfo: Codable {
    var email: String?
    var phone: String?
    var website: String?
    var address: String?
}

// MARK: - Export Configuration

/// Configuration for report export formats
struct ExportConfiguration: Codable {
    var format: ExportFormat
    var quality: ExportQuality
    var includeCharts: Bool
    var includeAppendices: Bool
    var passwordProtected: Bool
    var watermark: String?
}

enum ExportFormat: String, CaseIterable, Codable {
    case pdf = "PDF"
    case excel = "Excel"
    case powerpoint = "PowerPoint"
    case word = "Word"
    case html = "HTML"
}

enum ExportQuality: String, CaseIterable, Codable {
    case draft = "Draft"
    case standard = "Standard"
    case high = "High"
    case print = "Print"
}