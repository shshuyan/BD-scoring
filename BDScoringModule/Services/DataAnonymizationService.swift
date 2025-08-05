import Foundation

// MARK: - Data Anonymization Service

actor DataAnonymizationService {
    static let shared = DataAnonymizationService()
    
    private let anonymizationRules: [String: AnonymizationRule]
    private let seedValue: UInt64
    
    private init() {
        self.seedValue = UInt64(Date().timeIntervalSince1970)
        self.anonymizationRules = [
            "company_name": .companyName,
            "person_name": .personName,
            "email": .email,
            "phone": .phoneNumber,
            "address": .address,
            "financial_amount": .financialAmount,
            "date": .dateShift,
            "ticker": .ticker,
            "drug_name": .drugName,
            "indication": .indication
        ]
    }
    
    // MARK: - Company Data Anonymization
    
    func anonymizeCompanyData(_ companyData: CompanyData) async -> CompanyData {
        var anonymized = companyData
        
        // Anonymize basic info
        anonymized.basicInfo.name = anonymizeValue(companyData.basicInfo.name, rule: .companyName)
        anonymized.basicInfo.ticker = companyData.basicInfo.ticker.map { anonymizeValue($0, rule: .ticker) }
        
        // Anonymize financial data
        anonymized.financials.cashPosition = anonymizeFinancialAmount(companyData.financials.cashPosition)
        anonymized.financials.burnRate = anonymizeFinancialAmount(companyData.financials.burnRate)
        
        // Anonymize pipeline programs
        anonymized.pipeline.programs = companyData.pipeline.programs.map { program in
            var anonymizedProgram = program
            anonymizedProgram.name = anonymizeValue(program.name, rule: .drugName)
            anonymizedProgram.indication = anonymizeValue(program.indication, rule: .indication)
            return anonymizedProgram
        }
        
        // Update lead program if it exists
        if let leadProgram = anonymized.pipeline.programs.first {
            anonymized.pipeline.leadProgram = leadProgram
        }
        
        return anonymized
    }
    
    func anonymizeUserData(_ user: User) async -> User {
        let anonymizedUsername = anonymizeValue(user.username, rule: .personName)
        let anonymizedEmail = anonymizeValue(user.email, rule: .email)
        
        return User(
            id: user.id, // Keep ID for referential integrity
            username: anonymizedUsername,
            email: anonymizedEmail,
            role: user.role, // Keep role for testing purposes
            isActive: user.isActive
        )
    }
    
    func anonymizeAuditLog(_ auditLog: AuditLogEntry) async -> AuditLogEntry {
        return AuditLogEntry(
            userId: auditLog.userId, // Keep for referential integrity
            username: auditLog.username.map { anonymizeValue($0, rule: .personName) },
            action: auditLog.action, // Keep for analysis
            resource: auditLog.resource, // Keep for analysis
            resourceId: auditLog.resourceId, // Keep for referential integrity
            details: anonymizeDetails(auditLog.details),
            ipAddress: auditLog.ipAddress.map { anonymizeIPAddress($0) },
            userAgent: auditLog.userAgent, // Keep for analysis
            success: auditLog.success
        )
    }
    
    // MARK: - Batch Anonymization
    
    func anonymizeDataset(_ companies: [CompanyData]) async -> [CompanyData] {
        var anonymizedCompanies: [CompanyData] = []
        
        for company in companies {
            let anonymized = await anonymizeCompanyData(company)
            anonymizedCompanies.append(anonymized)
        }
        
        return anonymizedCompanies
    }
    
    func createAnonymizedTestDataset(from companies: [CompanyData], count: Int? = nil) async -> [CompanyData] {
        let targetCount = count ?? companies.count
        var testDataset: [CompanyData] = []
        
        for i in 0..<targetCount {
            let sourceCompany = companies[i % companies.count]
            let anonymized = await anonymizeCompanyData(sourceCompany)
            testDataset.append(anonymized)
        }
        
        return testDataset
    }
    
    // MARK: - Anonymization Rules Implementation
    
    private func anonymizeValue(_ value: String, rule: AnonymizationRule) -> String {
        switch rule {
        case .companyName:
            return generateCompanyName(from: value)
        case .personName:
            return generatePersonName(from: value)
        case .email:
            return generateEmail(from: value)
        case .phoneNumber:
            return generatePhoneNumber()
        case .address:
            return generateAddress()
        case .ticker:
            return generateTicker(from: value)
        case .drugName:
            return generateDrugName(from: value)
        case .indication:
            return generateIndication(from: value)
        case .financialAmount:
            return value // Handled separately
        case .dateShift:
            return value // Handled separately
        }
    }
    
    private func anonymizeFinancialAmount(_ amount: Double) -> Double {
        // Add noise while preserving order of magnitude
        let noise = Double.random(in: 0.8...1.2)
        let anonymized = amount * noise
        
        // Round to appropriate precision
        if anonymized > 1_000_000 {
            return (anonymized / 1_000_000).rounded() * 1_000_000
        } else if anonymized > 1_000 {
            return (anonymized / 1_000).rounded() * 1_000
        } else {
            return anonymized.rounded()
        }
    }
    
    private func anonymizeDetails(_ details: [String: String]) -> [String: String] {
        var anonymizedDetails: [String: String] = [:]
        
        for (key, value) in details {
            let anonymizedValue: String
            
            if key.contains("name") || key.contains("user") {
                anonymizedValue = anonymizeValue(value, rule: .personName)
            } else if key.contains("email") {
                anonymizedValue = anonymizeValue(value, rule: .email)
            } else if key.contains("company") {
                anonymizedValue = anonymizeValue(value, rule: .companyName)
            } else {
                anonymizedValue = value // Keep non-sensitive details
            }
            
            anonymizedDetails[key] = anonymizedValue
        }
        
        return anonymizedDetails
    }
    
    private func anonymizeIPAddress(_ ipAddress: String) -> String {
        // Replace last octet with random value
        let components = ipAddress.components(separatedBy: ".")
        if components.count == 4 {
            let randomOctet = Int.random(in: 1...254)
            return "\(components[0]).\(components[1]).\(components[2]).\(randomOctet)"
        }
        return "192.168.1.\(Int.random(in: 1...254))"
    }
    
    // MARK: - Name Generators
    
    private func generateCompanyName(from original: String) -> String {
        let prefixes = ["Bio", "Pharma", "Therapeutics", "Sciences", "Medical", "Health", "Life", "Gene", "Cell", "Immuno"]
        let suffixes = ["Corp", "Inc", "Ltd", "Therapeutics", "Pharma", "Biosciences", "Medical", "Health", "Labs", "Systems"]
        
        let hash = abs(original.hashValue)
        let prefix = prefixes[hash % prefixes.count]
        let suffix = suffixes[(hash / prefixes.count) % suffixes.count]
        
        return "\(prefix)\(suffix)"
    }
    
    private func generatePersonName(from original: String) -> String {
        let firstNames = ["Alex", "Jordan", "Taylor", "Casey", "Morgan", "Riley", "Avery", "Quinn", "Sage", "River"]
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
        
        let hash = abs(original.hashValue)
        let firstName = firstNames[hash % firstNames.count]
        let lastName = lastNames[(hash / firstNames.count) % lastNames.count]
        
        return "\(firstName) \(lastName)"
    }
    
    private func generateEmail(from original: String) -> String {
        let domains = ["example.com", "test.org", "demo.net", "sample.io", "placeholder.co"]
        let hash = abs(original.hashValue)
        let domain = domains[hash % domains.count]
        let username = "user\(hash % 10000)"
        
        return "\(username)@\(domain)"
    }
    
    private func generatePhoneNumber() -> String {
        let areaCode = Int.random(in: 200...999)
        let exchange = Int.random(in: 200...999)
        let number = Int.random(in: 1000...9999)
        
        return "(\(areaCode)) \(exchange)-\(number)"
    }
    
    private func generateAddress() -> String {
        let streetNumbers = Int.random(in: 100...9999)
        let streetNames = ["Main St", "Oak Ave", "Pine Rd", "Elm Dr", "Maple Ln", "Cedar Blvd", "Park Ave", "First St"]
        let cities = ["Springfield", "Franklin", "Georgetown", "Madison", "Arlington", "Fairview", "Riverside", "Hillside"]
        let states = ["CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI"]
        
        let streetName = streetNames.randomElement()!
        let city = cities.randomElement()!
        let state = states.randomElement()!
        let zipCode = Int.random(in: 10000...99999)
        
        return "\(streetNumbers) \(streetName), \(city), \(state) \(zipCode)"
    }
    
    private func generateTicker(from original: String) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let hash = abs(original.hashValue)
        var ticker = ""
        
        for i in 0..<min(4, original.count) {
            let index = (hash + i) % letters.count
            let letterIndex = letters.index(letters.startIndex, offsetBy: index)
            ticker += String(letters[letterIndex])
        }
        
        return ticker
    }
    
    private func generateDrugName(from original: String) -> String {
        let prefixes = ["Ther", "Bio", "Onco", "Neuro", "Cardio", "Immuno", "Anti", "Pro"]
        let suffixes = ["mab", "nib", "zumab", "tinib", "ciclib", "parin", "statin", "mycin"]
        
        let hash = abs(original.hashValue)
        let prefix = prefixes[hash % prefixes.count]
        let suffix = suffixes[(hash / prefixes.count) % suffixes.count]
        let number = (hash % 100) + 1
        
        return "\(prefix)-\(number)\(suffix)"
    }
    
    private func generateIndication(from original: String) -> String {
        let indications = [
            "Oncology - Solid Tumors",
            "Oncology - Hematologic Malignancies",
            "Autoimmune Disorders",
            "Cardiovascular Disease",
            "Neurological Disorders",
            "Metabolic Disorders",
            "Infectious Diseases",
            "Rare Genetic Disorders",
            "Inflammatory Conditions",
            "Respiratory Diseases"
        ]
        
        let hash = abs(original.hashValue)
        return indications[hash % indications.count]
    }
}

// MARK: - Anonymization Rules

enum AnonymizationRule {
    case companyName
    case personName
    case email
    case phoneNumber
    case address
    case financialAmount
    case dateShift
    case ticker
    case drugName
    case indication
}

// MARK: - Anonymization Configuration

struct AnonymizationConfig {
    let preserveStructure: Bool
    let preserveRelationships: Bool
    let noiseLevel: Double
    let dateShiftRange: TimeInterval
    
    static let `default` = AnonymizationConfig(
        preserveStructure: true,
        preserveRelationships: true,
        noiseLevel: 0.1,
        dateShiftRange: 30 * 24 * 60 * 60 // 30 days
    )
    
    static let testing = AnonymizationConfig(
        preserveStructure: true,
        preserveRelationships: false,
        noiseLevel: 0.2,
        dateShiftRange: 90 * 24 * 60 * 60 // 90 days
    )
}

// MARK: - Anonymization Report

struct AnonymizationReport {
    let originalCount: Int
    let anonymizedCount: Int
    let fieldsAnonymized: [String]
    let preservedFields: [String]
    let timestamp: Date
    let config: AnonymizationConfig
    
    var summary: String {
        return """
        Anonymization Report
        ===================
        Original Records: \(originalCount)
        Anonymized Records: \(anonymizedCount)
        Fields Anonymized: \(fieldsAnonymized.count)
        Fields Preserved: \(preservedFields.count)
        Timestamp: \(timestamp)
        """
    }
}