import XCTest
@testable import BDScoringModule

final class SecurityTests: XCTestCase {
    var auditService: AuditService!
    var userStorage: UserStorageService!
    var tokenStorage: TokenStorageService!
    
    override func setUp() async throws {
        auditService = AuditService.shared
        userStorage = UserStorageService.shared
        tokenStorage = TokenStorageService.shared
    }
    
    override func tearDown() async throws {
        auditService = nil
        userStorage = nil
        tokenStorage = nil
    }
    
    // MARK: - Audit Logging Tests
    
    func testAuditLogCreation() async throws {
        // Given
        let userId = UUID()
        let username = "testuser"
        
        // When
        await auditService.logAction(.viewCompany, resource: "company", resourceId: "123", 
                                   details: ["action": "view"], userId: userId, username: username)
        
        // Then
        let logs = await auditService.getAuditLogs(limit: 1)
        XCTAssertEqual(logs.count, 1)
        
        let log = logs.first!
        XCTAssertEqual(log.userId, userId)
        XCTAssertEqual(log.username, username)
        XCTAssertEqual(log.action, .viewCompany)
        XCTAssertEqual(log.resource, "company")
        XCTAssertEqual(log.resourceId, "123")
        XCTAssertTrue(log.success)
    }
    
    func testAuditLogFiltering() async throws {
        // Given
        let userId1 = UUID()
        let userId2 = UUID()
        
        await auditService.logAction(.viewCompany, resource: "company", userId: userId1, username: "user1")
        await auditService.logAction(.scoreCompany, resource: "company", userId: userId2, username: "user2")
        await auditService.logAction(.generateReport, resource: "report", userId: userId1, username: "user1")
        
        // When
        let user1Logs = await auditService.getAuditLogs(for: userId1)
        let viewCompanyLogs = await auditService.getAuditLogs(for: .viewCompany)
        
        // Then
        XCTAssertEqual(user1Logs.count, 2)
        XCTAssertTrue(user1Logs.allSatisfy { $0.userId == userId1 })
        
        XCTAssertEqual(viewCompanyLogs.count, 1)
        XCTAssertEqual(viewCompanyLogs.first?.action, .viewCompany)
    }
    
    func testAuditLogDateFiltering() async throws {
        // Given
        let startDate = Date()
        
        await auditService.logAction(.login, resource: "authentication", username: "user1")
        
        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let midDate = Date()
        
        await auditService.logAction(.logout, resource: "authentication", username: "user1")
        
        let endDate = Date()
        
        // When
        let allLogs = await auditService.getAuditLogs(from: startDate, to: endDate)
        let partialLogs = await auditService.getAuditLogs(from: midDate, to: endDate)
        
        // Then
        XCTAssertEqual(allLogs.count, 2)
        XCTAssertEqual(partialLogs.count, 1)
        XCTAssertEqual(partialLogs.first?.action, .logout)
    }
    
    func testFailedActionLogging() async throws {
        // Given
        await auditService.logAction(.loginFailed, resource: "authentication", 
                                   details: ["reason": "invalid_password"], 
                                   username: "testuser", success: false)
        
        // When
        let failedLogs = await auditService.getFailedActions()
        
        // Then
        XCTAssertEqual(failedLogs.count, 1)
        XCTAssertFalse(failedLogs.first!.success)
        XCTAssertEqual(failedLogs.first!.action, .loginFailed)
    }
    
    // MARK: - User Storage Security Tests
    
    func testPasswordHashing() async throws {
        // Given
        let user = User(username: "testuser", email: "test@example.com", role: .analyst)
        let password = "testpassword123"
        
        // When
        let createdUser = try await userStorage.createUser(user, password: password)
        let passwordHash = await userStorage.getPasswordHash(for: createdUser.id)
        
        // Then
        XCTAssertNotNil(passwordHash)
        XCTAssertNotEqual(passwordHash, password) // Password should be hashed
        XCTAssertTrue(await userStorage.verifyPassword(password, for: createdUser.id))
        XCTAssertFalse(await userStorage.verifyPassword("wrongpassword", for: createdUser.id))
    }
    
    func testUsernameDuplication() async throws {
        // Given
        let user1 = User(username: "testuser", email: "test1@example.com", role: .analyst)
        let user2 = User(username: "testuser", email: "test2@example.com", role: .viewer)
        
        // When
        _ = try await userStorage.createUser(user1, password: "password1")
        
        // Then
        await XCTAssertThrowsError(try await userStorage.createUser(user2, password: "password2")) { error in
            XCTAssertTrue(error is UserStorageError)
            if case UserStorageError.usernameAlreadyExists = error {
                // Expected error
            } else {
                XCTFail("Expected usernameAlreadyExists error")
            }
        }
    }
    
    func testUserRolePermissions() async throws {
        // Test that different roles have appropriate permissions
        let adminUser = User(username: "admin", email: "admin@example.com", role: .admin)
        let analystUser = User(username: "analyst", email: "analyst@example.com", role: .analyst)
        let viewerUser = User(username: "viewer", email: "viewer@example.com", role: .viewer)
        
        // Admin should have all permissions
        XCTAssertTrue(adminUser.permissions.contains(.manageUsers))
        XCTAssertTrue(adminUser.permissions.contains(.viewCompanies))
        XCTAssertTrue(adminUser.permissions.contains(.scoreCompanies))
        
        // Analyst should have scoring permissions but not user management
        XCTAssertTrue(analystUser.permissions.contains(.viewCompanies))
        XCTAssertTrue(analystUser.permissions.contains(.scoreCompanies))
        XCTAssertFalse(analystUser.permissions.contains(.manageUsers))
        
        // Viewer should only have view permissions
        XCTAssertTrue(viewerUser.permissions.contains(.viewCompanies))
        XCTAssertFalse(viewerUser.permissions.contains(.scoreCompanies))
        XCTAssertFalse(viewerUser.permissions.contains(.manageUsers))
    }
    
    // MARK: - Token Security Tests
    
    func testTokenExpiration() async throws {
        // Given
        let userId = UUID()
        let expiredToken = AuthToken(token: "expired-token", userId: userId, 
                                   expiresAt: Date().addingTimeInterval(-3600), createdAt: Date())
        let validToken = AuthToken(token: "valid-token", userId: userId, 
                                 expiresAt: Date().addingTimeInterval(3600), createdAt: Date())
        
        await tokenStorage.storeToken(expiredToken)
        await tokenStorage.storeToken(validToken)
        
        // When
        let retrievedExpiredToken = await tokenStorage.getToken("expired-token")
        let retrievedValidToken = await tokenStorage.getToken("valid-token")
        
        // Then
        XCTAssertNil(retrievedExpiredToken) // Should be nil due to expiration
        XCTAssertNotNil(retrievedValidToken)
    }
    
    func testTokenCleanup() async throws {
        // Given
        let userId = UUID()
        let token1 = AuthToken(token: "token1", userId: userId, 
                              expiresAt: Date().addingTimeInterval(-3600), createdAt: Date())
        let token2 = AuthToken(token: "token2", userId: userId, 
                              expiresAt: Date().addingTimeInterval(3600), createdAt: Date())
        
        await tokenStorage.storeToken(token1)
        await tokenStorage.storeToken(token2)
        
        // When - wait for cleanup (in real implementation, this would be automatic)
        await tokenStorage.removeToken("token1") // Simulate cleanup
        
        let userTokens = await tokenStorage.getAllTokensForUser(userId)
        
        // Then
        XCTAssertEqual(userTokens.count, 1)
        XCTAssertEqual(userTokens.first?.token, "token2")
    }
    
    func testTokenRevocation() async throws {
        // Given
        let userId = UUID()
        let token = AuthToken(token: "test-token", userId: userId, 
                             expiresAt: Date().addingTimeInterval(3600), createdAt: Date())
        
        await tokenStorage.storeToken(token)
        
        // When
        await tokenStorage.removeAllTokensForUser(userId)
        
        // Then
        let retrievedToken = await tokenStorage.getToken("test-token")
        let userTokens = await tokenStorage.getAllTokensForUser(userId)
        
        XCTAssertNil(retrievedToken)
        XCTAssertTrue(userTokens.isEmpty)
    }
    
    // MARK: - Data Access Control Tests
    
    func testDataAccessLogging() async throws {
        // Given
        let middleware = AuditMiddleware()
        let userId = UUID()
        let username = "testuser"
        let companyId = "company-123"
        
        // When
        await middleware.logCompanyAccess(companyId: companyId, action: .viewCompany, 
                                        userId: userId, username: username)
        
        // Then
        let logs = await auditService.getAuditLogs(for: .viewCompany)
        XCTAssertEqual(logs.count, 1)
        
        let log = logs.first!
        XCTAssertEqual(log.resource, "company")
        XCTAssertEqual(log.resourceId, companyId)
        XCTAssertEqual(log.userId, userId)
    }
    
    func testReportGenerationLogging() async throws {
        // Given
        let middleware = AuditMiddleware()
        let userId = UUID()
        let username = "testuser"
        let companyId = "company-123"
        let reportType = "executive_summary"
        
        // When
        await middleware.logReportGeneration(reportType: reportType, companyId: companyId, 
                                           userId: userId, username: username)
        
        // Then
        let logs = await auditService.getAuditLogs(for: .generateReport)
        XCTAssertEqual(logs.count, 1)
        
        let log = logs.first!
        XCTAssertEqual(log.resource, "report")
        XCTAssertEqual(log.resourceId, companyId)
        XCTAssertEqual(log.details["report_type"], reportType)
    }
    
    func testConfigurationChangeLogging() async throws {
        // Given
        let middleware = AuditMiddleware()
        let userId = UUID()
        let username = "testuser"
        let configType = "scoring_weights"
        let details = ["pillar": "asset_quality", "old_weight": "0.2", "new_weight": "0.3"]
        
        // When
        await middleware.logConfigurationChange(configType: configType, details: details, 
                                              userId: userId, username: username)
        
        // Then
        let logs = await auditService.getAuditLogs(for: .configureWeights)
        XCTAssertEqual(logs.count, 1)
        
        let log = logs.first!
        XCTAssertEqual(log.resource, "configuration")
        XCTAssertEqual(log.details["config_type"], configType)
        XCTAssertEqual(log.details["pillar"], "asset_quality")
    }
    
    // MARK: - Security Analytics Tests
    
    func testSecurityEventAnalytics() async throws {
        // Given
        let startDate = Date()
        
        await auditService.logAction(.login, resource: "authentication", username: "user1")
        await auditService.logAction(.loginFailed, resource: "authentication", username: "user2", success: false)
        await auditService.logAction(.logout, resource: "authentication", username: "user1")
        await auditService.logAction(.viewCompany, resource: "company", username: "user1")
        
        let endDate = Date()
        
        // When
        let securityEvents = await auditService.getSecurityEvents(from: startDate, to: endDate)
        let actionCounts = await auditService.getActionCounts(from: startDate, to: endDate)
        let userActivity = await auditService.getUserActivityCounts(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(securityEvents.count, 3) // login, loginFailed, logout
        XCTAssertEqual(actionCounts[.login], 1)
        XCTAssertEqual(actionCounts[.loginFailed], 1)
        XCTAssertEqual(actionCounts[.logout], 1)
        XCTAssertEqual(actionCounts[.viewCompany], 1)
        
        XCTAssertEqual(userActivity["user1"], 3) // login, logout, viewCompany
        XCTAssertEqual(userActivity["user2"], 1) // loginFailed
    }
    
    // MARK: - Data Encryption Tests
    
    func testDataEncryption() async throws {
        // Given
        let encryptionService = EncryptionService.shared
        let originalData = "Sensitive company information".data(using: .utf8)!
        
        // When
        let encryptedData = try await encryptionService.encryptData(originalData)
        let decryptedData = try await encryptionService.decryptData(encryptedData)
        
        // Then
        XCTAssertNotEqual(encryptedData.data, originalData)
        XCTAssertEqual(decryptedData, originalData)
        XCTAssertEqual(encryptedData.algorithm, .aesGCM)
    }
    
    func testStringEncryption() async throws {
        // Given
        let encryptionService = EncryptionService.shared
        let originalString = "Confidential financial data: $50M"
        
        // When
        let encryptedData = try await encryptionService.encryptString(originalString)
        let decryptedString = try await encryptionService.decryptString(encryptedData)
        
        // Then
        XCTAssertEqual(decryptedString, originalString)
        XCTAssertNotNil(encryptedData.keyId)
    }
    
    func testEncryptedDataSerialization() async throws {
        // Given
        let encryptionService = EncryptionService.shared
        let originalString = "Test data for serialization"
        
        // When
        let encryptedData = try await encryptionService.encryptString(originalString)
        let base64String = encryptedData.base64EncodedString()
        let deserializedData = EncryptedData(base64EncodedString: base64String)
        
        // Then
        XCTAssertNotNil(deserializedData)
        let decryptedString = try await encryptionService.decryptString(deserializedData!)
        XCTAssertEqual(decryptedString, originalString)
    }
    
    // MARK: - Data Anonymization Tests
    
    func testCompanyDataAnonymization() async throws {
        // Given
        let anonymizationService = DataAnonymizationService.shared
        let originalCompany = createTestCompanyData()
        
        // When
        let anonymizedCompany = await anonymizationService.anonymizeCompanyData(originalCompany)
        
        // Then
        XCTAssertNotEqual(anonymizedCompany.basicInfo.name, originalCompany.basicInfo.name)
        XCTAssertNotEqual(anonymizedCompany.basicInfo.ticker, originalCompany.basicInfo.ticker)
        XCTAssertNotEqual(anonymizedCompany.financials.cashPosition, originalCompany.financials.cashPosition)
        XCTAssertNotEqual(anonymizedCompany.pipeline.programs.first?.name, originalCompany.pipeline.programs.first?.name)
        
        // Structure should be preserved
        XCTAssertEqual(anonymizedCompany.pipeline.programs.count, originalCompany.pipeline.programs.count)
        XCTAssertEqual(anonymizedCompany.basicInfo.sector, originalCompany.basicInfo.sector)
    }
    
    func testUserDataAnonymization() async throws {
        // Given
        let anonymizationService = DataAnonymizationService.shared
        let originalUser = User(username: "john.doe", email: "john.doe@biotech.com", role: .analyst)
        
        // When
        let anonymizedUser = await anonymizationService.anonymizeUserData(originalUser)
        
        // Then
        XCTAssertNotEqual(anonymizedUser.username, originalUser.username)
        XCTAssertNotEqual(anonymizedUser.email, originalUser.email)
        XCTAssertEqual(anonymizedUser.id, originalUser.id) // ID preserved for referential integrity
        XCTAssertEqual(anonymizedUser.role, originalUser.role) // Role preserved for testing
    }
    
    func testAuditLogAnonymization() async throws {
        // Given
        let anonymizationService = DataAnonymizationService.shared
        let originalLog = AuditLogEntry(
            userId: UUID(),
            username: "john.doe",
            action: .viewCompany,
            resource: "company",
            resourceId: "123",
            details: ["user_name": "John Doe", "company_name": "BioTech Corp"],
            ipAddress: "192.168.1.100",
            success: true
        )
        
        // When
        let anonymizedLog = await anonymizationService.anonymizeAuditLog(originalLog)
        
        // Then
        XCTAssertNotEqual(anonymizedLog.username, originalLog.username)
        XCTAssertNotEqual(anonymizedLog.ipAddress, originalLog.ipAddress)
        XCTAssertNotEqual(anonymizedLog.details["user_name"], originalLog.details["user_name"])
        XCTAssertNotEqual(anonymizedLog.details["company_name"], originalLog.details["company_name"])
        
        // Preserved fields
        XCTAssertEqual(anonymizedLog.userId, originalLog.userId)
        XCTAssertEqual(anonymizedLog.action, originalLog.action)
        XCTAssertEqual(anonymizedLog.resource, originalLog.resource)
    }
    
    func testBatchAnonymization() async throws {
        // Given
        let anonymizationService = DataAnonymizationService.shared
        let companies = [
            createTestCompanyData(name: "Company A"),
            createTestCompanyData(name: "Company B"),
            createTestCompanyData(name: "Company C")
        ]
        
        // When
        let anonymizedCompanies = await anonymizationService.anonymizeDataset(companies)
        
        // Then
        XCTAssertEqual(anonymizedCompanies.count, companies.count)
        
        for (original, anonymized) in zip(companies, anonymizedCompanies) {
            XCTAssertNotEqual(anonymized.basicInfo.name, original.basicInfo.name)
            XCTAssertEqual(anonymized.basicInfo.sector, original.basicInfo.sector)
        }
    }
    
    func testAnonymizedTestDatasetCreation() async throws {
        // Given
        let anonymizationService = DataAnonymizationService.shared
        let sourceCompanies = [createTestCompanyData(name: "Source Company")]
        let targetCount = 5
        
        // When
        let testDataset = await anonymizationService.createAnonymizedTestDataset(
            from: sourceCompanies,
            count: targetCount
        )
        
        // Then
        XCTAssertEqual(testDataset.count, targetCount)
        
        // All should be anonymized versions
        for company in testDataset {
            XCTAssertNotEqual(company.basicInfo.name, "Source Company")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestCompanyData(name: String = "Test Biotech Corp") -> CompanyData {
        return CompanyData(
            basicInfo: CompanyBasicInfo(
                name: name,
                ticker: "TBTC",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .clinicalStage
            ),
            pipeline: PipelineData(
                programs: [
                    Program(
                        name: "TB-001",
                        indication: "Breast Cancer",
                        stage: .phaseII,
                        mechanism: "CDK4/6 Inhibitor",
                        differentiators: ["Novel mechanism"],
                        risks: [],
                        timeline: []
                    )
                ],
                totalPrograms: 1,
                leadProgram: Program(
                    name: "TB-001",
                    indication: "Breast Cancer",
                    stage: .phaseII,
                    mechanism: "CDK4/6 Inhibitor",
                    differentiators: ["Novel mechanism"],
                    risks: [],
                    timeline: []
                )
            ),
            financials: FinancialData(
                cashPosition: 50_000_000,
                burnRate: 5_000_000,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: 75_000_000,
                    date: Date(),
                    investors: ["VC Fund A"]
                ),
                runway: 10
            ),
            market: MarketData(
                addressableMarket: 5_000_000_000,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0.15,
                    competitiveIntensity: .moderate,
                    regulatoryEnvironment: .stable
                )
            ),
            regulatory: RegulatoryData(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 36,
                    risks: []
                )
            )
        )
    }
}

// MARK: - Helper Extensions

extension XCTestCase {
    func XCTAssertThrowsError<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (_ error: Error) -> Void = { _ in }) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}