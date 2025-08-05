import XCTest
@testable import BDScoringModule

@MainActor
final class AuthenticationServiceTests: XCTestCase {
    var authService: AuthenticationService!
    var mockAuditService: MockAuditService!
    var mockUserStorage: MockUserStorageService!
    var mockTokenStorage: MockTokenStorageService!
    
    override func setUp() async throws {
        mockAuditService = MockAuditService()
        mockUserStorage = MockUserStorageService()
        mockTokenStorage = MockTokenStorageService()
        
        authService = AuthenticationService(
            auditService: mockAuditService,
            userStorage: mockUserStorage,
            tokenStorage: mockTokenStorage
        )
    }
    
    override func tearDown() async throws {
        authService = nil
        mockAuditService = nil
        mockUserStorage = nil
        mockTokenStorage = nil
    }
    
    // MARK: - Authentication Tests
    
    func testSuccessfulAuthentication() async throws {
        // Given
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        
        // When
        let response = await authService.authenticate(username: "testuser", password: "password123")
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.token)
        XCTAssertNotNil(response.user)
        XCTAssertEqual(response.user?.username, "testuser")
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.username, "testuser")
        
        // Verify audit log
        let auditLogs = await mockAuditService.getAuditLogs()
        XCTAssertTrue(auditLogs.contains { $0.action == .login && $0.success })
    }
    
    func testFailedAuthenticationInvalidUser() async throws {
        // When
        let response = await authService.authenticate(username: "nonexistent", password: "password123")
        
        // Then
        XCTAssertFalse(response.success)
        XCTAssertNil(response.token)
        XCTAssertNil(response.user)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertEqual(response.message, "Invalid username or password")
        
        // Verify audit log
        let auditLogs = await mockAuditService.getAuditLogs()
        XCTAssertTrue(auditLogs.contains { $0.action == .loginFailed && !$0.success })
    }
    
    func testFailedAuthenticationInvalidPassword() async throws {
        // Given
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        
        // When
        let response = await authService.authenticate(username: "testuser", password: "wrongpassword")
        
        // Then
        XCTAssertFalse(response.success)
        XCTAssertNil(response.token)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertEqual(response.message, "Invalid username or password")
        
        // Verify audit log
        let auditLogs = await mockAuditService.getAuditLogs()
        XCTAssertTrue(auditLogs.contains { $0.action == .loginFailed && !$0.success })
    }
    
    func testFailedAuthenticationInactiveUser() async throws {
        // Given
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst, isActive: false)
        await mockUserStorage.addUser(testUser, password: "password123")
        
        // When
        let response = await authService.authenticate(username: "testuser", password: "password123")
        
        // Then
        XCTAssertFalse(response.success)
        XCTAssertNil(response.token)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertEqual(response.message, "Account is inactive")
        
        // Verify audit log
        let auditLogs = await mockAuditService.getAuditLogs()
        XCTAssertTrue(auditLogs.contains { $0.action == .loginFailed && !$0.success })
    }
    
    func testLogout() async throws {
        // Given - authenticate first
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "testuser", password: "password123")
        
        XCTAssertTrue(authService.isAuthenticated)
        
        // When
        await authService.logout()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertNil(authService.authToken)
        
        // Verify audit log
        let auditLogs = await mockAuditService.getAuditLogs()
        XCTAssertTrue(auditLogs.contains { $0.action == .logout && $0.success })
    }
    
    func testTokenValidation() async throws {
        // Given
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst)
        let token = AuthToken(token: "valid-token", userId: testUser.id, 
                             expiresAt: Date().addingTimeInterval(3600), createdAt: Date())
        
        await mockUserStorage.addUser(testUser, password: "password123")
        await mockTokenStorage.storeToken(token)
        
        // When
        let isValid = await authService.validateToken("valid-token")
        
        // Then
        XCTAssertTrue(isValid)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.username, "testuser")
    }
    
    func testTokenValidationExpiredToken() async throws {
        // Given
        let testUser = User(username: "testuser", email: "test@example.com", role: .analyst)
        let expiredToken = AuthToken(token: "expired-token", userId: testUser.id, 
                                   expiresAt: Date().addingTimeInterval(-3600), createdAt: Date())
        
        await mockUserStorage.addUser(testUser, password: "password123")
        await mockTokenStorage.storeToken(expiredToken)
        
        // When
        let isValid = await authService.validateToken("expired-token")
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    // MARK: - Authorization Tests
    
    func testHasPermission() async throws {
        // Given
        let testUser = User(username: "analyst", email: "analyst@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "analyst", password: "password123")
        
        // Then
        XCTAssertTrue(authService.hasPermission(.viewCompanies))
        XCTAssertTrue(authService.hasPermission(.scoreCompanies))
        XCTAssertFalse(authService.hasPermission(.manageUsers))
    }
    
    func testHasRole() async throws {
        // Given
        let testUser = User(username: "analyst", email: "analyst@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "analyst", password: "password123")
        
        // Then
        XCTAssertTrue(authService.hasRole(.analyst))
        XCTAssertFalse(authService.hasRole(.admin))
    }
    
    func testRequirePermissionSuccess() async throws {
        // Given
        let testUser = User(username: "analyst", email: "analyst@example.com", role: .analyst)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "analyst", password: "password123")
        
        // When/Then - should not throw
        XCTAssertNoThrow(try authService.requirePermission(.viewCompanies))
    }
    
    func testRequirePermissionFailure() async throws {
        // Given
        let testUser = User(username: "viewer", email: "viewer@example.com", role: .viewer)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "viewer", password: "password123")
        
        // When/Then - should throw
        XCTAssertThrowsError(try authService.requirePermission(.manageUsers)) { error in
            XCTAssertTrue(error is AuthorizationError)
        }
    }
    
    func testRequireRoleSuccess() async throws {
        // Given
        let testUser = User(username: "admin", email: "admin@example.com", role: .admin)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "admin", password: "password123")
        
        // When/Then - should not throw
        XCTAssertNoThrow(try authService.requireRole(.admin))
    }
    
    func testRequireRoleFailure() async throws {
        // Given
        let testUser = User(username: "viewer", email: "viewer@example.com", role: .viewer)
        await mockUserStorage.addUser(testUser, password: "password123")
        _ = await authService.authenticate(username: "viewer", password: "password123")
        
        // When/Then - should throw
        XCTAssertThrowsError(try authService.requireRole(.admin)) { error in
            XCTAssertTrue(error is AuthorizationError)
        }
    }
}

// MARK: - Mock Services

class MockAuditService: AuditService {
    private var logs: [AuditLogEntry] = []
    
    override func logAction(_ action: AuditAction, resource: String, resourceId: String? = nil, details: [String : String] = [:], userId: UUID? = nil, username: String? = nil, ipAddress: String? = nil, userAgent: String? = nil, success: Bool = true) {
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
        logs.append(entry)
    }
    
    func getAuditLogs() async -> [AuditLogEntry] {
        return logs
    }
}

actor MockUserStorageService: UserStorageService {
    private var users: [String: User] = [:]
    private var passwords: [UUID: String] = [:]
    
    func addUser(_ user: User, password: String) async {
        users[user.username] = user
        passwords[user.id] = hashPassword(password, salt: user.id.uuidString)
    }
    
    override func getUser(username: String) async -> User? {
        return users[username]
    }
    
    override func getUser(id: UUID) async -> User? {
        return users.values.first { $0.id == id }
    }
    
    override func getPasswordHash(for userId: UUID) async -> String? {
        return passwords[userId]
    }
    
    private func hashPassword(_ password: String, salt: String) -> String {
        // Simple hash for testing
        return "\(password)-\(salt)".data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

actor MockTokenStorageService: TokenStorageService {
    private var tokens: [String: AuthToken] = [:]
    
    override func storeToken(_ token: AuthToken) async {
        tokens[token.token] = token
    }
    
    override func getToken(_ tokenString: String) async -> AuthToken? {
        return tokens[tokenString]
    }
    
    override func removeToken(_ tokenString: String) async {
        tokens.removeValue(forKey: tokenString)
    }
}