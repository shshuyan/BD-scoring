import Foundation
import CryptoKit

// MARK: - Encryption Service

actor EncryptionService {
    static let shared = EncryptionService()
    
    private let keychain: KeychainService
    private var encryptionKey: SymmetricKey?
    
    private init(keychain: KeychainService = KeychainService.shared) {
        self.keychain = keychain
        Task {
            await loadOrGenerateEncryptionKey()
        }
    }
    
    // MARK: - Data Encryption/Decryption
    
    func encryptData(_ data: Data) async throws -> EncryptedData {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return EncryptedData(
            data: encryptedData,
            algorithm: .aesGCM,
            keyId: await keychain.getCurrentKeyId(),
            timestamp: Date()
        )
    }
    
    func decryptData(_ encryptedData: EncryptedData) async throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        guard encryptedData.algorithm == .aesGCM else {
            throw EncryptionError.unsupportedAlgorithm
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData.data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func encryptString(_ string: String) async throws -> EncryptedData {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try await encryptData(data)
    }
    
    func decryptString(_ encryptedData: EncryptedData) async throws -> String {
        let data = try await decryptData(encryptedData)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }
    
    // MARK: - Field-Level Encryption
    
    func encryptSensitiveFields<T: SensitiveDataProtocol>(_ object: T) async throws -> T {
        var encryptedObject = object
        
        for field in T.sensitiveFields {
            if let value = object.getValue(for: field) {
                let encryptedValue = try await encryptString(value)
                encryptedObject.setValue(encryptedValue.base64EncodedString(), for: field)
            }
        }
        
        return encryptedObject
    }
    
    func decryptSensitiveFields<T: SensitiveDataProtocol>(_ object: T) async throws -> T {
        var decryptedObject = object
        
        for field in T.sensitiveFields {
            if let encryptedValue = object.getValue(for: field),
               let encryptedData = EncryptedData(base64EncodedString: encryptedValue) {
                let decryptedValue = try await decryptString(encryptedData)
                decryptedObject.setValue(decryptedValue, for: field)
            }
        }
        
        return decryptedObject
    }
    
    // MARK: - Key Management
    
    func rotateEncryptionKey() async throws {
        let newKey = SymmetricKey(size: .bits256)
        let keyId = UUID().uuidString
        
        try await keychain.storeKey(newKey, withId: keyId)
        encryptionKey = newKey
        
        // In production, you would re-encrypt all existing data with the new key
        await auditKeyRotation(keyId: keyId)
    }
    
    private func loadOrGenerateEncryptionKey() async {
        do {
            if let existingKey = await keychain.getCurrentKey() {
                encryptionKey = existingKey
            } else {
                let newKey = SymmetricKey(size: .bits256)
                let keyId = UUID().uuidString
                try await keychain.storeKey(newKey, withId: keyId)
                encryptionKey = newKey
            }
        } catch {
            // Log error but don't crash - encryption will be unavailable
            print("Failed to load/generate encryption key: \(error)")
        }
    }
    
    private func auditKeyRotation(keyId: String) async {
        await AuditService.shared.logAction(
            .systemConfiguration,
            resource: "encryption",
            details: ["action": "key_rotation", "key_id": keyId]
        )
    }
}

// MARK: - Keychain Service

actor KeychainService {
    static let shared = KeychainService()
    
    private let service = "BDScoringModule"
    private let currentKeyAccount = "current_encryption_key"
    private let keyIdAccount = "current_key_id"
    
    private init() {}
    
    func storeKey(_ key: SymmetricKey, withId keyId: String) async throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Store the key
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyId,
            kSecValueData as String: keyData
        ]
        
        let keyStatus = SecItemAdd(keyQuery as CFDictionary, nil)
        guard keyStatus == errSecSuccess else {
            throw KeychainError.storeFailed(keyStatus)
        }
        
        // Store the current key ID
        let keyIdData = keyId.data(using: .utf8)!
        let keyIdQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyIdAccount,
            kSecValueData as String: keyIdData
        ]
        
        // Delete existing key ID first
        SecItemDelete(keyIdQuery as CFDictionary)
        
        let keyIdStatus = SecItemAdd(keyIdQuery as CFDictionary, nil)
        guard keyIdStatus == errSecSuccess else {
            throw KeychainError.storeFailed(keyIdStatus)
        }
    }
    
    func getCurrentKey() async -> SymmetricKey? {
        guard let keyId = await getCurrentKeyId() else { return nil }
        return await getKey(withId: keyId)
    }
    
    func getCurrentKeyId() async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyIdAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let keyId = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return keyId
    }
    
    private func getKey(withId keyId: String) async -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
}

// MARK: - Data Models

struct EncryptedData: Codable {
    let data: Data
    let algorithm: EncryptionAlgorithm
    let keyId: String?
    let timestamp: Date
    
    func base64EncodedString() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(self) else {
            return data.base64EncodedString()
        }
        
        return jsonData.base64EncodedString()
    }
    
    init?(base64EncodedString: String) {
        guard let jsonData = Data(base64Encoded: base64EncodedString) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let decoded = try? decoder.decode(EncryptedData.self, from: jsonData) else {
            return nil
        }
        
        self = decoded
    }
    
    init(data: Data, algorithm: EncryptionAlgorithm, keyId: String?, timestamp: Date) {
        self.data = data
        self.algorithm = algorithm
        self.keyId = keyId
        self.timestamp = timestamp
    }
}

enum EncryptionAlgorithm: String, Codable {
    case aesGCM = "AES-GCM"
    case aesGCM256 = "AES-GCM-256"
}

// MARK: - Sensitive Data Protocol

protocol SensitiveDataProtocol {
    static var sensitiveFields: [String] { get }
    func getValue(for field: String) -> String?
    mutating func setValue(_ value: String, for field: String)
}

// MARK: - Company Data Encryption Extension

extension CompanyData: SensitiveDataProtocol {
    static var sensitiveFields: [String] {
        return [
            "basicInfo.name",
            "basicInfo.ticker",
            "financials.cashPosition",
            "financials.burnRate",
            "pipeline.programs.name"
        ]
    }
    
    func getValue(for field: String) -> String? {
        switch field {
        case "basicInfo.name":
            return basicInfo.name
        case "basicInfo.ticker":
            return basicInfo.ticker
        case "financials.cashPosition":
            return String(financials.cashPosition)
        case "financials.burnRate":
            return String(financials.burnRate)
        default:
            return nil
        }
    }
    
    mutating func setValue(_ value: String, for field: String) {
        switch field {
        case "basicInfo.name":
            basicInfo.name = value
        case "basicInfo.ticker":
            basicInfo.ticker = value
        case "financials.cashPosition":
            if let doubleValue = Double(value) {
                financials.cashPosition = doubleValue
            }
        case "financials.burnRate":
            if let doubleValue = Double(value) {
                financials.burnRate = doubleValue
            }
        default:
            break
        }
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case keyNotAvailable
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedAlgorithm
    
    var errorDescription: String? {
        switch self {
        case .keyNotAvailable:
            return "Encryption key not available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "Invalid data format"
        case .unsupportedAlgorithm:
            return "Unsupported encryption algorithm"
        }
    }
}

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store in keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}