import Foundation
import CryptoKit
import SwiftUI

// MARK: - Authentication Service

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var authToken: AuthToken?
    
    private let auditService: AuditService
    private let userStorage: UserStorageService
    private let tokenStorage: TokenStorageService
    
    init(auditService: AuditService = AuditService.shared, 
         userStorage: UserStorageService = UserStorageService.shared,
         tokenStorage: TokenStorageService = TokenStorageService.shared) {
        self.auditService = auditService
        self.userStorage = userStorage
        self.tokenStorage = tokenStorage
        
        // Check for existing valid token on initialization
        loadStoredAuthentication()
    }
    
    // MARK: - Authentication Methods
    
    func authenticate(username: String, password: String) async -> AuthenticationResponse {
        do {
            // Validate credentials
            guard let user = await userStorage.getUser(username: username) else {
                await auditService.logAction(.loginFailed, resource: "authentication", 
                                           details: ["username": username, "reason": "user_not_found"])
                return AuthenticationResponse(success: false, token: nil, user: nil, expiresAt: nil, 
                                            message: "Invalid username or password")
            }
            
            guard user.isActive else {
                await auditService.logAction(.loginFailed, resource: "authentication", 
                                           details: ["username": username, "reason": "user_inactive"])
                return AuthenticationResponse(success: false, token: nil, user: nil, expiresAt: nil, 
                                            message: "Account is inactive")
            }
            
            // Verify password (in production, this would check against hashed password)
            guard await verifyPassword(password, for: user) else {
                await auditService.logAction(.loginFailed, resource: "authentication", 
                                           details: ["username": username, "reason": "invalid_password"])
                return AuthenticationResponse(success: false, token: nil, user: nil, expiresAt: nil, 
                                            message: "Invalid username or password")
            }
            
            // Generate authentication token
            let token = generateAuthToken(for: user)
            await tokenStorage.storeToken(token)
            
            // Update user's last login
            var updatedUser = user
            updatedUser = User(id: user.id, username: user.username, email: user.email, role: user.role, isActive: user.isActive)
            await userStorage.updateUser(updatedUser)
            
            // Update current state
            self.currentUser = updatedUser
            self.authToken = token
            self.isAuthenticated = true
            
            // Log successful authentication
            await auditService.logAction(.login, resource: "authentication", 
                                       details: ["username": username], userId: user.id, username: username)
            
            return AuthenticationResponse(success: true, token: token.token, user: updatedUser, 
                                        expiresAt: token.expiresAt, message: "Authentication successful")
            
        } catch {
            await auditService.logAction(.loginFailed, resource: "authentication", 
                                       details: ["username": username, "error": error.localizedDescription])
            return AuthenticationResponse(success: false, token: nil, user: nil, expiresAt: nil, 
                                        message: "Authentication failed: \(error.localizedDescription)")
        }
    }
    
    func logout() async {
        if let user = currentUser {
            await auditService.logAction(.logout, resource: "authentication", 
                                       userId: user.id, username: user.username)
        }
        
        // Clear stored token
        if let token = authToken {
            await tokenStorage.removeToken(token.token)
        }
        
        // Clear current state
        currentUser = nil
        authToken = nil
        isAuthenticated = false
    }
    
    func validateToken(_ tokenString: String) async -> Bool {
        guard let token = await tokenStorage.getToken(tokenString) else {
            return false
        }
        
        guard !token.isExpired else {
            await tokenStorage.removeToken(tokenString)
            return false
        }
        
        guard let user = await userStorage.getUser(id: token.userId) else {
            await tokenStorage.removeToken(tokenString)
            return false
        }
        
        guard user.isActive else {
            await tokenStorage.removeToken(tokenString)
            return false
        }
        
        // Update current state if token is valid
        currentUser = user
        authToken = token
        isAuthenticated = true
        
        return true
    }
    
    // MARK: - Authorization Methods
    
    func hasPermission(_ permission: Permission) -> Bool {
        guard let user = currentUser else { return false }
        return user.permissions.contains(permission)
    }
    
    func hasRole(_ role: UserRole) -> Bool {
        guard let user = currentUser else { return false }
        return user.role == role
    }
    
    func hasAnyRole(_ roles: [UserRole]) -> Bool {
        guard let user = currentUser else { return false }
        return roles.contains(user.role)
    }
    
    func requirePermission(_ permission: Permission) throws {
        guard hasPermission(permission) else {
            throw AuthorizationError.insufficientPermissions(required: permission)
        }
    }
    
    func requireRole(_ role: UserRole) throws {
        guard hasRole(role) else {
            throw AuthorizationError.insufficientRole(required: role)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadStoredAuthentication() {
        Task {
            if let storedToken = await tokenStorage.getCurrentToken() {
                await validateToken(storedToken.token)
            }
        }
    }
    
    private func verifyPassword(_ password: String, for user: User) async -> Bool {
        // In production, this would verify against a properly hashed password
        // For demo purposes, we'll use a simple check
        let hashedPassword = hashPassword(password, salt: user.id.uuidString)
        let storedHash = await userStorage.getPasswordHash(for: user.id)
        return hashedPassword == storedHash
    }
    
    private func hashPassword(_ password: String, salt: String) -> String {
        let data = Data((password + salt).utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func generateAuthToken(for user: User) -> AuthToken {
        let tokenString = UUID().uuidString + "-" + Date().timeIntervalSince1970.description
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        return AuthToken(token: tokenString, userId: user.id, expiresAt: expiresAt, createdAt: Date())
    }
}

// MARK: - Authorization Errors

enum AuthorizationError: LocalizedError {
    case insufficientPermissions(required: Permission)
    case insufficientRole(required: UserRole)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions(let permission):
            return "Insufficient permissions. Required: \(permission.displayName)"
        case .insufficientRole(let role):
            return "Insufficient role. Required: \(role.displayName)"
        case .notAuthenticated:
            return "User not authenticated"
        }
    }
}

// MARK: - Authorization Decorator

@propertyWrapper
struct RequiresPermission {
    let permission: Permission
    
    init(_ permission: Permission) {
        self.permission = permission
    }
    
    var wrappedValue: Bool {
        get {
            AuthenticationService().hasPermission(permission)
        }
    }
}

@propertyWrapper
struct RequiresRole {
    let role: UserRole
    
    init(_ role: UserRole) {
        self.role = role
    }
    
    var wrappedValue: Bool {
        get {
            AuthenticationService().hasRole(role)
        }
    }
}