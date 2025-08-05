import Foundation
import SwiftUI

// MARK: - User and Authentication Models

struct User: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let role: UserRole
    let permissions: Set<Permission>
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?
    
    init(id: UUID = UUID(), username: String, email: String, role: UserRole, isActive: Bool = true) {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.permissions = role.defaultPermissions
        self.isActive = isActive
        self.createdAt = Date()
        self.lastLoginAt = nil
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case analyst = "analyst"
    case viewer = "viewer"
    case bdProfessional = "bd_professional"
    case financialAnalyst = "financial_analyst"
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .analyst: return "Investment Analyst"
        case .viewer: return "Viewer"
        case .bdProfessional: return "BD Professional"
        case .financialAnalyst: return "Financial Analyst"
        }
    }
    
    var defaultPermissions: Set<Permission> {
        switch self {
        case .admin:
            return Set(Permission.allCases)
        case .analyst:
            return [.viewCompanies, .scoreCompanies, .generateReports, .viewReports, .configureWeights, .viewComparables]
        case .viewer:
            return [.viewCompanies, .viewReports]
        case .bdProfessional:
            return [.viewCompanies, .scoreCompanies, .generateReports, .viewReports, .viewComparables]
        case .financialAnalyst:
            return [.viewCompanies, .scoreCompanies, .generateReports, .viewReports, .configureWeights, .viewComparables, .viewFinancials]
        }
    }
}

enum Permission: String, Codable, CaseIterable {
    case viewCompanies = "view_companies"
    case scoreCompanies = "score_companies"
    case editCompanies = "edit_companies"
    case deleteCompanies = "delete_companies"
    case generateReports = "generate_reports"
    case viewReports = "view_reports"
    case exportReports = "export_reports"
    case configureWeights = "configure_weights"
    case viewComparables = "view_comparables"
    case editComparables = "edit_comparables"
    case viewFinancials = "view_financials"
    case manageUsers = "manage_users"
    case viewAuditLogs = "view_audit_logs"
    case systemConfiguration = "system_configuration"
    
    var displayName: String {
        switch self {
        case .viewCompanies: return "View Companies"
        case .scoreCompanies: return "Score Companies"
        case .editCompanies: return "Edit Companies"
        case .deleteCompanies: return "Delete Companies"
        case .generateReports: return "Generate Reports"
        case .viewReports: return "View Reports"
        case .exportReports: return "Export Reports"
        case .configureWeights: return "Configure Weights"
        case .viewComparables: return "View Comparables"
        case .editComparables: return "Edit Comparables"
        case .viewFinancials: return "View Financials"
        case .manageUsers: return "Manage Users"
        case .viewAuditLogs: return "View Audit Logs"
        case .systemConfiguration: return "System Configuration"
        }
    }
}

// MARK: - Authentication Models

struct AuthenticationRequest: Codable {
    let username: String
    let password: String
}

struct AuthenticationResponse: Codable {
    let success: Bool
    let token: String?
    let user: User?
    let expiresAt: Date?
    let message: String?
}

struct AuthToken: Codable {
    let token: String
    let userId: UUID
    let expiresAt: Date
    let createdAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Audit Log Models

struct AuditLogEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let username: String?
    let action: AuditAction
    let resource: String
    let resourceId: String?
    let details: [String: String]
    let ipAddress: String?
    let userAgent: String?
    let timestamp: Date
    let success: Bool
    
    init(userId: UUID?, username: String?, action: AuditAction, resource: String, resourceId: String? = nil, details: [String: String] = [:], ipAddress: String? = nil, userAgent: String? = nil, success: Bool = true) {
        self.id = UUID()
        self.userId = userId
        self.username = username
        self.action = action
        self.resource = resource
        self.resourceId = resourceId
        self.details = details
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.timestamp = Date()
        self.success = success
    }
}

enum AuditAction: String, Codable, CaseIterable {
    case login = "login"
    case logout = "logout"
    case loginFailed = "login_failed"
    case viewCompany = "view_company"
    case scoreCompany = "score_company"
    case editCompany = "edit_company"
    case deleteCompany = "delete_company"
    case generateReport = "generate_report"
    case exportReport = "export_report"
    case configureWeights = "configure_weights"
    case viewComparables = "view_comparables"
    case editComparables = "edit_comparables"
    case createUser = "create_user"
    case editUser = "edit_user"
    case deleteUser = "delete_user"
    case systemConfiguration = "system_configuration"
    
    var displayName: String {
        switch self {
        case .login: return "User Login"
        case .logout: return "User Logout"
        case .loginFailed: return "Failed Login Attempt"
        case .viewCompany: return "View Company"
        case .scoreCompany: return "Score Company"
        case .editCompany: return "Edit Company"
        case .deleteCompany: return "Delete Company"
        case .generateReport: return "Generate Report"
        case .exportReport: return "Export Report"
        case .configureWeights: return "Configure Weights"
        case .viewComparables: return "View Comparables"
        case .editComparables: return "Edit Comparables"
        case .createUser: return "Create User"
        case .editUser: return "Edit User"
        case .deleteUser: return "Delete User"
        case .systemConfiguration: return "System Configuration"
        }
    }
}