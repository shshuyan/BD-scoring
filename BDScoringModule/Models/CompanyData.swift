import Foundation

// MARK: - Core Data Models

/// Represents a biotech company with all relevant data for scoring
struct CompanyData: Codable, Identifiable {
    let id = UUID()
    var basicInfo: BasicInfo
    var pipeline: Pipeline
    var financials: Financials
    var market: Market
    var regulatory: Regulatory
    
    struct BasicInfo: Codable {
        var name: String
        var ticker: String?
        var sector: String
        var therapeuticAreas: [String]
        var stage: DevelopmentStage
        var description: String?
    }
    
    struct Pipeline: Codable {
        var programs: [Program]
        var totalPrograms: Int { programs.count }
        var leadProgram: Program? { programs.first }
    }
    
    struct Financials: Codable {
        var cashPosition: Double // in millions
        var burnRate: Double // monthly burn in millions
        var lastFunding: FundingRound?
        var runway: Int { // calculated runway in months
            guard burnRate > 0 else { return Int.max }
            return Int(cashPosition / burnRate)
        }
    }
    
    struct Market: Codable {
        var addressableMarket: Double // in billions
        var competitors: [Competitor]
        var marketDynamics: MarketDynamics
    }
    
    struct Regulatory: Codable {
        var approvals: [Approval]
        var clinicalTrials: [ClinicalTrial]
        var regulatoryStrategy: RegulatoryStrategy
    }
}

// MARK: - Supporting Types

enum DevelopmentStage: String, CaseIterable, Codable {
    case preclinical = "Preclinical"
    case phase1 = "Phase I"
    case phase2 = "Phase II"
    case phase3 = "Phase III"
    case approved = "Approved"
    case marketed = "Marketed"
}

struct Program: Codable, Identifiable {
    let id = UUID()
    var name: String
    var indication: String
    var stage: DevelopmentStage
    var mechanism: String
    var differentiators: [String]
    var risks: [Risk]
    var timeline: [Milestone]
}

struct FundingRound: Codable {
    var type: FundingType
    var amount: Double // in millions
    var date: Date
    var investors: [String]
}

enum FundingType: String, CaseIterable, Codable {
    case seed = "Seed"
    case seriesA = "Series A"
    case seriesB = "Series B"
    case seriesC = "Series C"
    case ipo = "IPO"
    case debt = "Debt"
}

struct Competitor: Codable, Identifiable {
    let id = UUID()
    var name: String
    var stage: DevelopmentStage
    var marketShare: Double?
    var strengths: [String]
    var weaknesses: [String]
}

struct MarketDynamics: Codable {
    var growthRate: Double // annual percentage
    var barriers: [String]
    var drivers: [String]
    var reimbursement: ReimbursementEnvironment
}

enum ReimbursementEnvironment: String, CaseIterable, Codable {
    case favorable = "Favorable"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case unknown = "Unknown"
}

struct Approval: Codable, Identifiable {
    let id = UUID()
    var indication: String
    var region: String
    var date: Date
    var type: ApprovalType
}

enum ApprovalType: String, CaseIterable, Codable {
    case full = "Full Approval"
    case conditional = "Conditional Approval"
    case breakthrough = "Breakthrough Designation"
    case fastTrack = "Fast Track"
    case orphan = "Orphan Drug"
}

struct ClinicalTrial: Codable, Identifiable {
    let id = UUID()
    var name: String
    var phase: DevelopmentStage
    var indication: String
    var status: TrialStatus
    var startDate: Date?
    var expectedCompletion: Date?
    var patientCount: Int?
}

enum TrialStatus: String, CaseIterable, Codable {
    case planned = "Planned"
    case recruiting = "Recruiting"
    case active = "Active"
    case completed = "Completed"
    case suspended = "Suspended"
    case terminated = "Terminated"
}

struct RegulatoryStrategy: Codable {
    var pathway: RegulatoryPathway
    var timeline: Int // months to approval
    var risks: [String]
    var mitigations: [String]
}

enum RegulatoryPathway: String, CaseIterable, Codable {
    case standard = "Standard"
    case accelerated = "Accelerated"
    case breakthrough = "Breakthrough"
    case fastTrack = "Fast Track"
    case orphan = "Orphan"
}

struct Risk: Codable, Identifiable {
    let id = UUID()
    var description: String
    var probability: RiskProbability
    var impact: RiskImpact
    var mitigation: String?
}

enum RiskProbability: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum RiskImpact: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct Milestone: Codable, Identifiable {
    let id = UUID()
    var name: String
    var expectedDate: Date
    var status: MilestoneStatus
    var description: String?
}

enum MilestoneStatus: String, CaseIterable, Codable {
    case upcoming = "Upcoming"
    case inProgress = "In Progress"
    case completed = "Completed"
    case delayed = "Delayed"
    case cancelled = "Cancelled"
}