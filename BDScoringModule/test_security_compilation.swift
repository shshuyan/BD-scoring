import Foundation

// Test compilation of security components
func testSecurityCompilation() {
    // Test User and Role models
    let user = User(username: "testuser", email: "test@example.com", role: .analyst)
    print("User created: \(user.username) with role: \(user.role.displayName)")
    
    // Test permissions
    let hasViewPermission = user.permissions.contains(.viewCompanies)
    let hasAdminPermission = user.permissions.contains(.manageUsers)
    print("Has view permission: \(hasViewPermission), Has admin permission: \(hasAdminPermission)")
    
    // Test authentication request/response
    let authRequest = AuthenticationRequest(username: "testuser", password: "password")
    let authResponse = AuthenticationResponse(success: true, token: "test-token", user: user, expiresAt: Date(), message: "Success")
    print("Auth request for: \(authRequest.username), Response success: \(authResponse.success)")
    
    // Test audit log entry
    let auditEntry = AuditLogEntry(
        userId: user.id,
        username: user.username,
        action: .login,
        resource: "authentication",
        success: true
    )
    print("Audit entry created: \(auditEntry.action.displayName) at \(auditEntry.timestamp)")
    
    // Test token
    let token = AuthToken(token: "test-token", userId: user.id, expiresAt: Date().addingTimeInterval(3600), createdAt: Date())
    print("Token created, expires: \(token.expiresAt), is expired: \(token.isExpired)")
    
    print("✅ Security models compilation test passed!")
}

// Run the test
testSecurityCompilation()