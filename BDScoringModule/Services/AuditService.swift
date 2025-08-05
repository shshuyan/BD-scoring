import Foundation

// MARK: - Audit Service

actor AuditService {
    static let shared = AuditService()
    
    private var auditLogs: [AuditLogEntry] = []
    private let maxLogEntries = 10000
    private let storageService: AuditStorageService
    
    private init(storageService: AuditStorageService = AuditStorageService.shared) {
        self.storageService = storageService
        Task {
            await loadStoredLogs()
        }
    }
    
    // MARK: - Logging Methods
    
    func logAction(_ action: AuditAction, 
                   resource: String, 
                   resourceId: String? = nil, 
                   details: [String: String] = [:], 
                   userId: UUID? = nil, 
                   username: String? = nil, 
                   ipAddress: String? = nil, 
                   userAgent: String? = nil, 
                   success: Bool = true) {
        
        let entry = AuditLogEntry(
            userId: userId,
            username: username,
            action: action,
            resource: resource,
            resourceId: resourceId,
            details: details,
            ipAddress: ipAddress,
            userAgent: userAgent,
            success: success
        )
        
        auditLogs.append(entry)
        
        // Maintain log size limit
        if auditLogs.count > maxLogEntries {
            auditLogs.removeFirst(auditLogs.count - maxLogEntries)
        }
        
        // Persist to storage
        Task {
            await storageService.storeAuditEntry(entry)
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("AUDIT: [\(entry.timestamp)] \(entry.username ?? "Unknown") - \(entry.action.displayName) on \(entry.resource) - Success: \(entry.success)")
        #endif
    }
    
    // MARK: - Query Methods
    
    func getAuditLogs(limit: Int = 100, offset: Int = 0) -> [AuditLogEntry] {
        let startIndex = max(0, auditLogs.count - offset - limit)
        let endIndex = max(0, auditLogs.count - offset)
        
        if startIndex >= endIndex {
            return []
        }
        
        return Array(auditLogs[startIndex..<endIndex].reversed())
    }
    
    func getAuditLogs(for userId: UUID, limit: Int = 100) -> [AuditLogEntry] {
        return auditLogs
            .filter { $0.userId == userId }
            .suffix(limit)
            .reversed()
    }
    
    func getAuditLogs(for action: AuditAction, limit: Int = 100) -> [AuditLogEntry] {
        return auditLogs
            .filter { $0.action == action }
            .suffix(limit)
            .reversed()
    }
    
    func getAuditLogs(for resource: String, limit: Int = 100) -> [AuditLogEntry] {
        return auditLogs
            .filter { $0.resource == resource }
            .suffix(limit)
            .reversed()
    }
    
    func getAuditLogs(from startDate: Date, to endDate: Date) -> [AuditLogEntry] {
        return auditLogs.filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }
    
    func getFailedActions(limit: Int = 100) -> [AuditLogEntry] {
        return auditLogs
            .filter { !$0.success }
            .suffix(limit)
            .reversed()
    }
    
    // MARK: - Analytics Methods
    
    func getActionCounts(from startDate: Date, to endDate: Date) -> [AuditAction: Int] {
        let filteredLogs = getAuditLogs(from: startDate, to: endDate)
        var counts: [AuditAction: Int] = [:]
        
        for log in filteredLogs {
            counts[log.action, default: 0] += 1
        }
        
        return counts
    }
    
    func getUserActivityCounts(from startDate: Date, to endDate: Date) -> [String: Int] {
        let filteredLogs = getAuditLogs(from: startDate, to: endDate)
        var counts: [String: Int] = [:]
        
        for log in filteredLogs {
            let username = log.username ?? "Unknown"
            counts[username, default: 0] += 1
        }
        
        return counts
    }
    
    func getSecurityEvents(from startDate: Date, to endDate: Date) -> [AuditLogEntry] {
        let securityActions: Set<AuditAction> = [.loginFailed, .login, .logout]
        
        return getAuditLogs(from: startDate, to: endDate)
            .filter { securityActions.contains($0.action) }
    }
    
    // MARK: - Private Methods
    
    private func loadStoredLogs() async {
        let storedLogs = await storageService.getAuditEntries(limit: maxLogEntries)
        auditLogs = storedLogs
    }
}

// MARK: - Audit Storage Service

actor AuditStorageService {
    static let shared = AuditStorageService()
    
    private var storage: [AuditLogEntry] = []
    
    private init() {}
    
    func storeAuditEntry(_ entry: AuditLogEntry) {
        storage.append(entry)
        
        // In production, this would write to a persistent database
        // For demo purposes, we'll keep it in memory
    }
    
    func getAuditEntries(limit: Int = 1000, offset: Int = 0) -> [AuditLogEntry] {
        let startIndex = max(0, offset)
        let endIndex = min(storage.count, offset + limit)
        
        if startIndex >= endIndex {
            return []
        }
        
        return Array(storage[startIndex..<endIndex])
    }
    
    func getAuditEntry(id: UUID) -> AuditLogEntry? {
        return storage.first { $0.id == id }
    }
    
    func deleteOldEntries(olderThan date: Date) {
        storage.removeAll { $0.timestamp < date }
    }
}

// MARK: - Audit Middleware

struct AuditMiddleware {
    private let auditService: AuditService
    
    init(auditService: AuditService = AuditService.shared) {
        self.auditService = auditService
    }
    
    func logCompanyAccess(companyId: String, action: AuditAction, userId: UUID?, username: String?) async {
        await auditService.logAction(
            action,
            resource: "company",
            resourceId: companyId,
            userId: userId,
            username: username
        )
    }
    
    func logReportGeneration(reportType: String, companyId: String?, userId: UUID?, username: String?) async {
        await auditService.logAction(
            .generateReport,
            resource: "report",
            resourceId: companyId,
            details: ["report_type": reportType],
            userId: userId,
            username: username
        )
    }
    
    func logConfigurationChange(configType: String, details: [String: String], userId: UUID?, username: String?) async {
        await auditService.logAction(
            .configureWeights,
            resource: "configuration",
            details: details.merging(["config_type": configType]) { _, new in new },
            userId: userId,
            username: username
        )
    }
    
    func logUserManagement(action: AuditAction, targetUserId: UUID?, details: [String: String], userId: UUID?, username: String?) async {
        await auditService.logAction(
            action,
            resource: "user",
            resourceId: targetUserId?.uuidString,
            details: details,
            userId: userId,
            username: username
        )
    }
}