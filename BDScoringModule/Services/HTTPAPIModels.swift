import Foundation

// MARK: - HTTP Request/Response Models (Foundation-based)

/// Base protocol for API request models
protocol APIRequest: Codable {
    func validate() throws
}

/// Base protocol for API response models
protocol APIResponse: Codable {
    var success: Bool { get }
    var timestamp: Date { get }
}

// MARK: - Request Models

/// Request to evaluate a single company
struct CompanyEvaluationRequest: APIRequest {
    var companyData: CompanyData
    var config: ScoringConfig?
    
    func validate() throws {
        guard !companyData.basicInfo.name.isEmpty else {
            throw APIError.validationError("Company name is required")
        }
        
        guard !companyData.pipeline.programs.isEmpty else {
            throw APIError.validationError("At least one pipeline program is required")
        }
        
        // Validate scoring config if provided
        if let config = config {
            guard config.weights.isValid else {
                throw APIError.validationError("Invalid weight configuration - weights must sum to 1.0")
            }
        }
    }
}

/// Request to evaluate multiple companies in batch
struct BatchEvaluationRequest: APIRequest {
    var companies: [CompanyData]
    var config: ScoringConfig?
    var options: BatchOptions?
    
    func validate() throws {
        guard !companies.isEmpty else {
            throw APIError.validationError("At least one company is required for batch evaluation")
        }
        
        guard companies.count <= 100 else {
            throw APIError.validationError("Maximum 100 companies allowed per batch")
        }
        
        // Validate each company
        for (index, company) in companies.enumerated() {
            guard !company.basicInfo.name.isEmpty else {
                throw APIError.validationError("Company name is required for company at index \(index)")
            }
        }
        
        // Validate scoring config if provided
        if let config = config {
            guard config.weights.isValid else {
                throw APIError.validationError("Invalid weight configuration - weights must sum to 1.0")
            }
        }
    }
}

struct BatchOptions: Codable {
    var continueOnError: Bool = true
    var maxConcurrency: Int = 5
    var notifyOnCompletion: Bool = false
    var webhookUrl: String?
}

/// Request to create or update scoring configuration
struct ScoringConfigRequest: APIRequest {
    var name: String
    var weights: WeightConfig
    var parameters: ScoringParameters?
    var isDefault: Bool = false
    
    func validate() throws {
        guard !name.isEmpty else {
            throw APIError.validationError("Configuration name is required")
        }
        
        guard weights.isValid else {
            throw APIError.validationError("Invalid weight configuration - weights must sum to 1.0")
        }
    }
}

/// Request to generate a report
struct ReportGenerationRequest: APIRequest {
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
struct OutcomeUpdateRequest: APIRequest {
    var companyId: UUID
    var outcome: ActualOutcome
    
    func validate() throws {
        guard outcome.valuation == nil || outcome.valuation! > 0 else {
            throw APIError.validationError("Valuation must be positive if provided")
        }
    }
}

// MARK: - Response Models

/// Standard API response wrapper
struct StandardAPIResponse<T: Codable>: APIResponse {
    var success: Bool
    var data: T?
    var error: APIErrorInfo?
    var metadata: ResponseMetadata?
    var timestamp: Date = Date()
    
    init(data: T, metadata: ResponseMetadata? = nil) {
        self.success = true
        self.data = data
        self.error = nil
        self.metadata = metadata
    }
    
    init(error: APIErrorInfo) {
        self.success = false
        self.data = nil
        self.error = error
        self.metadata = nil
    }
}

/// Error information for API responses
struct APIErrorInfo: Codable {
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
struct ResponseMetadata: Codable {
    var requestId: String = UUID().uuidString
    var timestamp: Date = Date()
    var processingTime: Double?
    var pagination: PaginationInfo?
    var warnings: [String]?
}

struct PaginationInfo: Codable {
    var page: Int
    var pageSize: Int
    var totalItems: Int
    var totalPages: Int
    var hasNext: Bool
    var hasPrevious: Bool
}

/// Company evaluation response
struct CompanyEvaluationResponse: Codable {
    var result: ScoringResult
    var insights: [String: String]?
    var recommendations: [String]
    var confidence: ConfidenceMetrics
    var processingTime: Double
}

/// Batch evaluation response
struct BatchEvaluationResponse: Codable {
    var jobId: UUID
    var status: BatchStatus
    var results: [ScoringResult]
    var errors: [BatchError]
    var summary: BatchSummary
    var processingTime: Double
}

struct BatchError: Codable, Identifiable {
    let id = UUID()
    var companyId: UUID?
    var companyName: String?
    var error: String
    var index: Int
}

struct BatchSummary: Codable {
    var totalCompanies: Int
    var successfulEvaluations: Int
    var failedEvaluations: Int
    var averageScore: Double?
    var averageConfidence: Double?
    var processingTime: Double
}

enum BatchStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case partiallyCompleted = "partially_completed"
}

/// Status of a batch processing job (enhanced version)
enum BatchJobStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case partiallyCompleted = "partially_completed"
    case cancelled = "cancelled"
}

/// Configuration management response
struct ConfigurationResponse: Codable {
    var configurations: [ScoringConfig]
    var defaultConfiguration: ScoringConfig?
}

/// Report generation response
struct ReportResponse: Codable {
    var reportId: UUID
    var downloadUrl: String?
    var format: ExportFormat
    var size: Int?
    var generatedAt: Date
    var expiresAt: Date?
}

/// Historical data response
struct HistoricalDataResponse: Codable {
    var companyId: UUID
    var scoringHistory: [ScoringResult]
    var actualOutcomes: [ActualOutcome]
    var accuracyMetrics: AccuracyMetrics?
}

struct AccuracyMetrics: Codable {
    var overallAccuracy: Double
    var pillarAccuracies: [String: Double]
    var predictionCount: Int
    var averageError: Double
    var confidenceCalibration: Double
}

/// Response for batch job results with pagination
struct BatchJobResultsResponse: Codable {
    var jobId: UUID
    var results: [ScoringResult]
    var pagination: PaginationInfo
    var jobStatus: BatchJobStatus
    var totalResults: Int
}

/// Response for batch job errors with pagination
struct BatchJobErrorsResponse: Codable {
    var jobId: UUID
    var errors: [BatchError]
    var pagination: PaginationInfo
    var jobStatus: BatchJobStatus
    var totalErrors: Int
}

/// System health response
struct HealthResponse: Codable {
    var status: String
    var version: String
    var uptime: TimeInterval
    var dependencies: [DependencyStatus]
    var metrics: SystemMetrics
}

struct DependencyStatus: Codable {
    var name: String
    var status: String
    var responseTime: Double?
    var lastChecked: Date
}

struct SystemMetrics: Codable {
    var totalEvaluations: Int
    var averageResponseTime: Double
    var errorRate: Double
    var activeConnections: Int
    var memoryUsage: Double
    var cpuUsage: Double
}

// MARK: - Query Parameters

/// Query parameters for listing companies
struct CompanyListQuery: Codable {
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
            throw APIError.validationError("Page must be greater than 0")
        }
        
        guard pageSize > 0 && pageSize <= 100 else {
            throw APIError.validationError("Page size must be between 1 and 100")
        }
        
        if let minScore = minScore {
            guard minScore >= 1.0 && minScore <= 5.0 else {
                throw APIError.validationError("Minimum score must be between 1.0 and 5.0")
            }
        }
        
        if let maxScore = maxScore {
            guard maxScore >= 1.0 && maxScore <= 5.0 else {
                throw APIError.validationError("Maximum score must be between 1.0 and 5.0")
            }
        }
        
        if let minScore = minScore, let maxScore = maxScore {
            guard minScore <= maxScore else {
                throw APIError.validationError("Minimum score must be less than or equal to maximum score")
            }
        }
        
        let validSortFields = ["name", "score", "stage", "therapeuticArea", "lastUpdated"]
        guard validSortFields.contains(sortBy) else {
            throw APIError.validationError("Invalid sort field. Valid options: \(validSortFields.joined(separator: ", "))")
        }
        
        let validSortOrders = ["asc", "desc"]
        guard validSortOrders.contains(sortOrder.lowercased()) else {
            throw APIError.validationError("Invalid sort order. Valid options: asc, desc")
        }
    }
}

/// Query parameters for historical data
struct HistoricalDataQuery: Codable {
    var companyId: UUID?
    var startDate: Date?
    var endDate: Date?
    var includeOutcomes: Bool = true
    var includeAccuracy: Bool = false
    
    func validate() throws {
        if let startDate = startDate, let endDate = endDate {
            guard startDate <= endDate else {
                throw APIError.validationError("Start date must be before or equal to end date")
            }
        }
    }
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case validationError(String)
    case notFound(String)
    case internalError(String)
    case serviceUnavailable(String)
    case badRequest(String)
    case unauthorized(String)
    
    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return "Validation error: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .internalError(let message):
            return "Internal error: \(message)"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        }
    }
    
    var httpStatusCode: Int {
        switch self {
        case .validationError, .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .notFound:
            return 404
        case .internalError:
            return 500
        case .serviceUnavailable:
            return 503
        }
    }
}

// MARK: - Helper Extensions

extension StandardAPIResponse {
    /// Create success response with processing time
    static func success<T: Codable>(_ data: T, processingTime: Double? = nil) -> StandardAPIResponse<T> {
        var metadata = ResponseMetadata()
        metadata.processingTime = processingTime
        return StandardAPIResponse(data: data, metadata: metadata)
    }
    
    /// Create error response from APIError
    static func error<T: Codable>(_ error: APIError) -> StandardAPIResponse<T> {
        let apiError = APIErrorInfo(
            code: String(error.httpStatusCode),
            message: error.localizedDescription,
            details: nil
        )
        return StandardAPIResponse<T>(error: apiError)
    }
    
    /// Create error response from generic Error
    static func error<T: Codable>(_ error: Error) -> StandardAPIResponse<T> {
        let apiError = APIErrorInfo(
            code: "500",
            message: error.localizedDescription,
            details: nil
        )
        return StandardAPIResponse<T>(error: apiError)
    }
}

extension Date {
    /// Create date from ISO string for API requests
    static func fromISO(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: string) else {
            throw APIError.validationError("Invalid date format. Use ISO 8601 format (e.g., 2023-12-01T10:00:00Z)")
        }
        return date
    }
}