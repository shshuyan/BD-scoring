import Foundation
import CryptoKit

// MARK: - User Storage Service

actor UserStorageService {
    static let shared = UserStorageService()
    
    private var users: [UUID: User] = [:]
    private var usersByUsername: [String: UUID] = [:]
    private var passwordHashes: [UUID: String] = [:]
    
    private init() {
        // Initialize with default admin user
        Task {
            await createDefaultUsers()
        }
    }
    
    // MARK: - User Management
    
    func createUser(_ user: User, password: String) async throws -> User {
        // Check if username already exists
        if usersByUsername[user.username] != nil {
            throw UserStorageError.usernameAlreadyExists
        }
        
        // Store user
        users[user.id] = user
        usersByUsername[user.username] = user.id
        
        // Store password hash
        let hashedPassword = hashPassword(password, salt: user.id.uuidString)
        passwordHashes[user.id] = hashedPassword
        
        return user
    }
    
    func getUser(id: UUID) async -> User? {
        return users[id]
    }
    
    func getUser(username: String) async -> User? {
        guard let userId = usersByUsername[username] else { return nil }
        return users[userId]
    }
    
    func updateUser(_ user: User) async throws {
        guard users[user.id] != nil else {
            throw UserStorageError.userNotFound
        }
        
        // Update username mapping if changed
        if let existingUser = users[user.id], existingUser.username != user.username {
            usersByUsername.removeValue(forKey: existingUser.username)
            usersByUsername[user.username] = user.id
        }
        
        users[user.id] = user
    }
    
    func deleteUser(id: UUID) async throws {
        guard let user = users[id] else {
            throw UserStorageError.userNotFound
        }
        
        users.removeValue(forKey: id)
        usersByUsername.removeValue(forKey: user.username)
        passwordHashes.removeValue(forKey: id)
    }
    
    func getAllUsers() async -> [User] {
        return Array(users.values)
    }
    
    func getUsersByRole(_ role: UserRole) async -> [User] {
        return users.values.filter { $0.role == role }
    }
    
    func getActiveUsers() async -> [User] {
        return users.values.filter { $0.isActive }
    }
    
    // MARK: - Password Management
    
    func getPasswordHash(for userId: UUID) async -> String? {
        return passwordHashes[userId]
    }
    
    func updatePassword(for userId: UUID, newPassword: String) async throws {
        guard users[userId] != nil else {
            throw UserStorageError.userNotFound
        }
        
        let hashedPassword = hashPassword(newPassword, salt: userId.uuidString)
        passwordHashes[userId] = hashedPassword
    }
    
    func verifyPassword(_ password: String, for userId: UUID) async -> Bool {
        guard let storedHash = passwordHashes[userId] else { return false }
        let hashedPassword = hashPassword(password, salt: userId.uuidString)
        return hashedPassword == storedHash
    }
    
    // MARK: - Private Methods
    
    private func createDefaultUsers() async {
        // Create default admin user
        let adminUser = User(
            username: "admin",
            email: "admin@bdscoringmodule.com",
            role: .admin
        )
        
        try? await createUser(adminUser, password: "admin123")
        
        // Create default analyst user
        let analystUser = User(
            username: "analyst",
            email: "analyst@bdscoringmodule.com",
            role: .analyst
        )
        
        try? await createUser(analystUser, password: "analyst123")
        
        // Create default viewer user
        let viewerUser = User(
            username: "viewer",
            email: "viewer@bdscoringmodule.com",
            role: .viewer
        )
        
        try? await createUser(viewerUser, password: "viewer123")
    }
    
    private func hashPassword(_ password: String, salt: String) -> String {
        let data = Data((password + salt).utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Token Storage Service

actor TokenStorageService {
    static let shared = TokenStorageService()
    
    private var tokens: [String: AuthToken] = [:]
    private var userTokens: [UUID: Set<String>] = [:]
    
    private init() {
        // Start cleanup timer
        Task {
            await startTokenCleanup()
        }
    }
    
    // MARK: - Token Management
    
    func storeToken(_ token: AuthToken) async {
        tokens[token.token] = token
        
        // Track tokens by user
        if userTokens[token.userId] == nil {
            userTokens[token.userId] = Set<String>()
        }
        userTokens[token.userId]?.insert(token.token)
    }
    
    func getToken(_ tokenString: String) async -> AuthToken? {
        guard let token = tokens[tokenString] else { return nil }
        
        // Remove expired tokens
        if token.isExpired {
            await removeToken(tokenString)
            return nil
        }
        
        return token
    }
    
    func removeToken(_ tokenString: String) async {
        guard let token = tokens[tokenString] else { return }
        
        tokens.removeValue(forKey: tokenString)
        userTokens[token.userId]?.remove(tokenString)
        
        if userTokens[token.userId]?.isEmpty == true {
            userTokens.removeValue(forKey: token.userId)
        }
    }
    
    func removeAllTokensForUser(_ userId: UUID) async {
        guard let userTokenSet = userTokens[userId] else { return }
        
        for tokenString in userTokenSet {
            tokens.removeValue(forKey: tokenString)
        }
        
        userTokens.removeValue(forKey: userId)
    }
    
    func getCurrentToken() async -> AuthToken? {
        // In a real implementation, this would get the current user's token from secure storage
        // For demo purposes, return the most recent non-expired token
        let validTokens = tokens.values.filter { !$0.isExpired }
        return validTokens.max { $0.createdAt < $1.createdAt }
    }
    
    func getAllTokensForUser(_ userId: UUID) async -> [AuthToken] {
        guard let userTokenSet = userTokens[userId] else { return [] }
        
        return userTokenSet.compactMap { tokens[$0] }.filter { !$0.isExpired }
    }
    
    // MARK: - Private Methods
    
    private func startTokenCleanup() async {
        while true {
            await cleanupExpiredTokens()
            try? await Task.sleep(nanoseconds: 60_000_000_000) // 1 minute
        }
    }
    
    private func cleanupExpiredTokens() async {
        let expiredTokens = tokens.filter { $0.value.isExpired }
        
        for (tokenString, token) in expiredTokens {
            tokens.removeValue(forKey: tokenString)
            userTokens[token.userId]?.remove(tokenString)
            
            if userTokens[token.userId]?.isEmpty == true {
                userTokens.removeValue(forKey: token.userId)
            }
        }
    }
}

// MARK: - Storage Errors

enum UserStorageError: LocalizedError {
    case userNotFound
    case usernameAlreadyExists
    case invalidUserData
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .usernameAlreadyExists:
            return "Username already exists"
        case .invalidUserData:
            return "Invalid user data"
        }
    }
}