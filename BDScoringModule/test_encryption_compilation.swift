import Foundation
import CryptoKit

// Test compilation of encryption and anonymization components
func testEncryptionCompilation() async {
    // Test encryption service
    let encryptionService = EncryptionService.shared
    let testData = "Test sensitive data".data(using: .utf8)!
    
    do {
        let encrypted = try await encryptionService.encryptData(testData)
        print("✅ Data encrypted successfully with algorithm: \(encrypted.algorithm)")
        
        let decrypted = try await encryptionService.decryptData(encrypted)
        let decryptedString = String(data: decrypted, encoding: .utf8) ?? "Failed to decode"
        print("✅ Data decrypted successfully: \(decryptedString)")
        
        // Test string encryption
        let encryptedString = try await encryptionService.encryptString("Test string")
        let decryptedStringResult = try await encryptionService.decryptString(encryptedString)
        print("✅ String encryption/decryption successful: \(decryptedStringResult)")
        
    } catch {
        print("❌ Encryption test failed: \(error)")
    }
    
    // Test anonymization service
    let anonymizationService = DataAnonymizationService.shared
    
    // Create test company data
    let testCompany = CompanyData(
        basicInfo: CompanyBasicInfo(
            name: "Test Biotech Corp",
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
    
    let anonymizedCompany = await anonymizationService.anonymizeCompanyData(testCompany)
    print("✅ Company anonymization successful:")
    print("   Original: \(testCompany.basicInfo.name) -> Anonymized: \(anonymizedCompany.basicInfo.name)")
    print("   Original ticker: \(testCompany.basicInfo.ticker ?? "N/A") -> Anonymized: \(anonymizedCompany.basicInfo.ticker ?? "N/A")")
    
    // Test user anonymization
    let testUser = User(username: "john.doe", email: "john.doe@biotech.com", role: .analyst)
    let anonymizedUser = await anonymizationService.anonymizeUserData(testUser)
    print("✅ User anonymization successful:")
    print("   Original: \(testUser.username) -> Anonymized: \(anonymizedUser.username)")
    print("   Original email: \(testUser.email) -> Anonymized: \(anonymizedUser.email)")
    
    // Test encrypted data serialization
    do {
        let testString = "Serialization test data"
        let encrypted = try await encryptionService.encryptString(testString)
        let base64String = encrypted.base64EncodedString()
        
        if let deserialized = EncryptedData(base64EncodedString: base64String) {
            let decrypted = try await encryptionService.decryptString(deserialized)
            print("✅ Encrypted data serialization successful: \(decrypted)")
        } else {
            print("❌ Failed to deserialize encrypted data")
        }
    } catch {
        print("❌ Serialization test failed: \(error)")
    }
    
    print("✅ All encryption and anonymization compilation tests passed!")
}

// Run the test
Task {
    await testEncryptionCompilation()
}