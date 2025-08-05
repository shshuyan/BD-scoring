import Foundation
import Vapor

// MARK: - Request Models

/// Request to evaluate a single company
struct CompanyEvaluationRequest: Content {
    var companyData: CompanyData
    var config: ScoringConfig?
    
    /// Validation for the request
    func validate() throws {
        guard !companyData.basicInfo.name.isEmpty else {
            throw Abort(.badRequest, reason: "Company name is required")
        }
        
        guard !companyData.pipeline.programs.isEmpty else {
            throw Abort(.badRequest, reason: "At least one pipeline program is required")
        }
        
        // Validate scoring config if provided
        if let config = config {
            guard config.weights.isValid else {
                throw Abort(.badRequest, reason: "Invalid weight configuration - weights must sum to 1.0")
            }
        }
    }
}

/// Request to evaluate multiple companies in batch
struct BatchEvaluationRequest: Content {
    var companies: [CompanyData]
    var config: ScoringConfig?
    var options: BatchOptions?
    
    func validate() throws {
        guard !companies.isEmpty else {
            throw Abort(.badRequest, reason: "At least one company is required for batch evaluation")
        }
        
        guard companies.count <= 100 else {
            throw Abort(.badRequest, reason: "Maximum 100 companies allowed per batch")
        }
        
        // Validate each company
        for (index, company) in companies.enumerated() {
            guard !company.basicInfo.name.isEmpty else {
                throw Abort(.badRequest, reason: "Company name is required for company at index \(index)")
            }
        }
        
        // Validate scoring config if provided
        if let config = config {
            guard config.weights.isValid else {
                throw Abort(.badRequest, reason: "Invalid weight configuration - weights must sum to 1.0")
            }
        }
    }
}

struct BatchOptions: Content {
    var continueOnError: Bool = true
    var maxConcurrency: Int = 5
    var notifyOnCompletion: Bool = false
    var webhookUrl: String?
}

/// Request to create or update scoring configuration
struct ScoringConfigRequest: Content {
    var name: String
    var weights: WeightConfig
    var parameters: ScoringParameters?
    var isDefault: Bool = false
    
    func validate() throws {
        guard !name.isEmpty else {
            throw Abort(.badRequest, reason: "Configuration name is required")
        }
        
        guard weights.isValid else {
            throw Abort(.badRequest, reason: "Invalid weight configuration - weights must sum to 1.0")
        }
    }
}

/// Request to generate a report
struct ReportGenerationRequest: Content {
    var scoringResultId: UUID
    var template: ReportTemplate?
    var format: ExportFormat = .pdf
    var includeCharts: Bool = true
    var includeRawData: Bool = false
    
    func validate() throws {
        // Basic validation - more complex validation would happen in the service layer
    }
}

/// Request to update actual outcome for historical tracking
struct OutcomeUpdateRequest: Content {
    var companyId: UUID
    var outcome: ActualOutcome
    
    func validate() throws {
        guard outcome.valuation == nil || outcome.valuation! > 0 else {
            throw Abort(.badRequest, reason: "Valuation must be positive if provided")
        }
    }
}

// MARK: - Response Models

/// Standard API response wrapper
struct APIResponse<T: Content>: Content {
    var success: Bool
    var data: T?
    var error: APIError?
    var metadata: ResponseMetadata?
    
    init(data: T, metadata: ResponseMetadata? = nil) {
        self.success = true
        self.data = data
        self.error = nil
        self.metadata = metadata
    }
    
    init(error: APIError) {
        self.success = false
        self.data = nil
        self.error = error
        self.metadata = nil
    }
}

/// Error response model
struct APIError: Content {
    var code: String
    var message: String
    var details: [String]?
    var timestamp: Date = Date()
    
    init(code: String, message: String, details: [String]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

/// Response metadata for pagination and additional info
struct ResponseMetadata: Content {
    var requestId: String = UUID().uuidString
    var timestamp: Date = Date()
    var processingTime: Double?
    var pagination: PaginationInfo?
    var warnings: [String]?
}

struct PaginationInfo: Content {
    var page: Int
    var pageSize: Int
    var totalItems: Int
    var totalPages: Int
    var hasNext: Bool
    var hasPrevious: Bool
}

/// Company evaluation response
struct CompanyEvaluationResponse: Content {
    var result: ScoringResult
    var insights: [String: String]?
    var recommendations: [String]
    var confidence: ConfidenceMetrics
    var processingTime: Double
}

/// Batch evaluation response
struct BatchEvaluationResponse: Content {
    var jobId: UUID
    var status: BatchStatus
    var results: [ScoringResult]
    var errors: [BatchError]
    var summary: BatchSummary
    var processingTime: Double
}

struct BatchError: Content, Identifiable {
    let id = UUID()
    var companyId: UUID?
    var companyName: String?
    var error: String
    var index: Int
}

struct BatchSummary: Content {
    var totalCompanies: Int
    var successfulEvaluations: Int
    var failedEvaluations: Int
    var averageScore: Double?
    var averageConfidence: Double?
    var processingTime: Double
}

enum BatchStatus: String, Content {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case partiallyCompleted = "partially_completed"
}

/// Configuration management response
struct ConfigurationResponse: Content {
    var configurations: [ScoringConfig]
    var defaultConfiguration: ScoringConfig?
}

/// Report generation response
struct ReportResponse: Content {
    var reportId: UUID
    var downloadUrl: String?
    var format: ExportFormat
    var size: Int?
    var generatedAt: Date
    var expiresAt: Date?
}

/// Historical data response
struct HistoricalDataResponse: Content {
    var companyId: UUID
    var scoringHistory: [ScoringResult]
    var actualOutcomes: [ActualOutcome]
    var accuracyMetrics: AccuracyMetrics?
}

struct AccuracyMetrics: Content {
    var overallAccuracy: Double
    var pillarAccuracies: [String: Double]
    var predictionCount: Int
    var averageError: Double
    var confidenceCalibration: Double
}

/// System health response
struct HealthResponse: Content {
    var status: String
    var version: String
    var uptime: TimeInterval
    var dependencies: [DependencyStatus]
    var metrics: SystemMetrics
}

struct DependencyStatus: Content {
    var name: String
    var status: String
    var responseTime: Double?
    var lastChecked: Date
}

struct SystemMetrics: Content {
    var totalEvaluations: Int
    var averageResponseTime: Double
    var errorRate: Double
    var activeConnections: Int
    var memoryUsage: Double
    var cpuUsage: Double
}

// MARK: - Query Parameters

/// Query parameters for listing companies
struct CompanyListQuery: Content {
    var page: Int = 1
    var pageSize: Int = 20
    var search: String?
    var therapeuticArea: String?
    var stage: DevelopmentStage?
    var minScore: Double?
    var maxScore: Double?
    var sortBy: String = "name"
    var sortOrder: String = "asc"
    
    func validate() throws {
        guard page > 0 else {
            throw Abort(.badRequest, reason: "Page must be greater than 0")
        }
        
        guard pageSize > 0 && pageSize <= 100 else {
            throw Abort(.badRequest, reason: "Page size must be between 1 and 100")
        }
        
        if let minScore = minScore {
            guard minScore >= 1.0 && minScore <= 5.0 else {
                throw Abort(.badRequest, reason: "Minimum score must be between 1.0 and 5.0")
            }
        }
        
        if let maxScore = maxScore {
            guard maxScore >= 1.0 && maxScore <= 5.0 else {
                throw Abort(.badRequest, reason: "Maximum score must be between 1.0 and 5.0")
            }
        }
        
        if let minScore = minScore, let maxScore = maxScore {
            guard minScore <= maxScore else {
                throw Abort(.badRequest, reason: "Minimum score must be less than or equal to maximum score")
            }
        }
        
        let validSortFields = ["name", "score", "stage", "therapeuticArea", "lastUpdated"]
        guard validSortFields.contains(sortBy) else {
            throw Abort(.badRequest, reason: "Invalid sort field. Valid options: \(validSortFields.joined(separator: ", "))")
        }
        
        let validSortOrders = ["asc", "desc"]
        guard validSortOrders.contains(sortOrder.lowercased()) else {
            throw Abort(.badRequest, reason: "Invalid sort order. Valid options: asc, desc")
        }
    }
}

/// Query parameters for historical data
struct HistoricalDataQuery: Content {
    var companyId: UUID?
    var startDate: Date?
    var endDate: Date?
    var includeOutcomes: Bool = true
    var includeAccuracy: Bool = false
    
    func validate() throws {
        if let startDate = startDate, let endDate = endDate {
            guard startDate <= endDate else {
                throw Abort(.badRequest, reason: "Start date must be before or equal to end date")
            }
        }
    }
}

// MARK: - Validation Extensions

extension CompanyData: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("basicInfo.name", as: String.self, is: !.empty)
        validations.add("pipeline.programs", as: [Program].self, is: !.empty)
    }
}

extension WeightConfig: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("assetQuality", as: Double.self, is: .range(0...1))
        validations.add("marketOutlook", as: Double.self, is: .range(0...1))
        validations.add("capitalIntensity", as: Double.self, is: .range(0...1))
        validations.add("strategicFit", as: Double.self, is: .range(0...1))
        validations.add("financialReadiness", as: Double.self, is: .range(0...1))
        validations.add("regulatoryRisk", as: Double.self, is: .range(0...1))
    }
}

// MARK: - Helper Extensions

extension APIResponse {
    /// Create success response with processing time
    static func success<T: Content>(_ data: T, processingTime: Double? = nil) -> APIResponse<T> {
        var metadata = ResponseMetadata()
        metadata.processingTime = processingTime
        return APIResponse(data: data, metadata: metadata)
    }
    
    /// Create error response from Abort
    static func error<T: Content>(_ abort: Abort) -> APIResponse<T> {
        let apiError = APIError(
            code: abort.status.code.description,
            message: abort.reason,
            details: nil
        )
        return APIResponse<T>(error: apiError)
    }
    
    /// Create error response from Error
    static func error<T: Content>(_ error: Error) -> APIResponse<T> {
        let apiError = APIError(
            code: "INTERNAL_ERROR",
            message: error.localizedDescription,
            details: nil
        )
        return APIResponse<T>(error: apiError)
    }
}

extension Date {
    /// Create date from ISO string for API requests
    static func fromISO(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: string) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use ISO 8601 format (e.g., 2023-12-01T10:00:00Z)")
        }
        return date
    }
}