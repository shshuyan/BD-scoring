import Foundation

// MARK: - Comparables Service Protocol

protocol ComparablesService {
    /// Search for comparable transactions based on criteria
    func searchComparables(criteria: ComparableCriteria) async throws -> ComparableSearchResult
    
    /// Find comparables for a specific company
    func findComparablesForCompany(_ company: CompanyData, maxResults: Int) async throws -> ComparableSearchResult
    
    /// Add a new comparable transaction
    func addComparable(_ comparable: Comparable) async throws
    
    /// Update existing comparable
    func updateComparable(_ comparable: Comparable) async throws
    
    /// Delete comparable by ID
    func deleteComparable(id: UUID) async throws
    
    /// Get comparable by ID
    func getComparable(id: UUID) async throws -> Comparable?
    
    /// Get all comparables
    func getAllComparables() async throws -> [Comparable]
    
    /// Validate comparable data
    func validateComparable(_ comparable: Comparable) -> ComparableValidation
    
    /// Calculate similarity between company and comparable
    func calculateSimilarity(company: CompanyData, comparable: Comparable) -> Double
    
    /// Get database analytics
    func getDatabaseAnalytics() async throws -> ComparablesAnalytics
}

// MARK: - Default Implementation

class DefaultComparablesService: ComparablesService {
    
    // MARK: - Properties
    
    private var comparables: [Comparable] = []
    private let queue = DispatchQueue(label: "comparables.service", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        // Initialize with sample data for testing
        loadSampleData()
    }
    
    // MARK: - Public Methods
    
    func searchComparables(criteria: ComparableCriteria) async throws -> ComparableSearchResult {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.filterComparables(by: criteria)
                let matches = filtered.map { comparable in
                    ComparableMatch(
                        comparable: comparable,
                        similarity: self.calculateSimilarityScore(comparable, criteria: criteria),
                        matchingFactors: self.calculateMatchingFactors(comparable, criteria: criteria),
                        confidence: comparable.confidence
                    )
                }
                
                let result = ComparableSearchResult(
                    comparables: matches.sorted { $0.similarity > $1.similarity },
                    totalFound: matches.count,
                    searchCriteria: criteria,
                    averageConfidence: matches.isEmpty ? 0.0 : matches.map(\.confidence).reduce(0, +) / Double(matches.count),
                    searchTimestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    func findComparablesForCompany(_ company: CompanyData, maxResults: Int = 10) async throws -> ComparableSearchResult {
        let criteria = createCriteriaFromCompany(company)
        let searchResult = try await searchComparables(criteria: criteria)
        
        // Calculate similarity specifically for this company
        let enhancedMatches = searchResult.comparables.map { match in
            var enhancedMatch = match
            enhancedMatch.similarity = calculateSimilarity(company: company, comparable: match.comparable)
            enhancedMatch.matchingFactors = calculateCompanyMatchingFactors(company: company, comparable: match.comparable)
            return enhancedMatch
        }
        
        let topMatches = Array(enhancedMatches.sorted { $0.similarity > $1.similarity }.prefix(maxResults))
        
        return ComparableSearchResult(
            comparables: topMatches,
            totalFound: searchResult.totalFound,
            searchCriteria: criteria,
            averageConfidence: topMatches.isEmpty ? 0.0 : topMatches.map(\.confidence).reduce(0, +) / Double(topMatches.count),
            searchTimestamp: Date()
        )
    }
    
    func addComparable(_ comparable: Comparable) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.comparables.append(comparable)
                continuation.resume()
            }
        }
    }
    
    func updateComparable(_ comparable: Comparable) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.comparables.firstIndex(where: { $0.id == comparable.id }) {
                    self.comparables[index] = comparable
                }
                continuation.resume()
            }
        }
    }
    
    func deleteComparable(id: UUID) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.comparables.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }
    
    func getComparable(id: UUID) async throws -> Comparable? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let comparable = self.comparables.first { $0.id == id }
                continuation.resume(returning: comparable)
            }
        }
    }
    
    func getAllComparables() async throws -> [Comparable] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.comparables)
            }
        }
    }
    
    func validateComparable(_ comparable: Comparable) -> ComparableValidation {
        var issues: [ValidationIssue] = []
        var completeness: Double = 0.0
        var confidence: Double = comparable.confidence
        
        // Validate required fields
        if comparable.companyName.isEmpty {
            issues.append(ValidationIssue(
                field: "companyName",
                severity: .critical,
                message: "Company name is required",
                suggestion: "Provide a valid company name"
            ))
        }
        
        if comparable.valuation <= 0 {
            issues.append(ValidationIssue(
                field: "valuation",
                severity: .critical,
                message: "Valuation must be positive",
                suggestion: "Provide a valid valuation amount"
            ))
        }
        
        if comparable.marketSize <= 0 {
            issues.append(ValidationIssue(
                field: "marketSize",
                severity: .error,
                message: "Market size should be positive",
                suggestion: "Provide addressable market size"
            ))
        }
        
        if comparable.therapeuticAreas.isEmpty {
            issues.append(ValidationIssue(
                field: "therapeuticAreas",
                severity: .error,
                message: "At least one therapeutic area should be specified",
                suggestion: "Add relevant therapeutic areas"
            ))
        }
        
        // Calculate completeness
        let totalFields = 12.0 // Total number of key fields
        var populatedFields = 0.0
        
        if !comparable.companyName.isEmpty { populatedFields += 1 }
        if comparable.valuation > 0 { populatedFields += 1 }
        if comparable.marketSize > 0 { populatedFields += 1 }
        if !comparable.therapeuticAreas.isEmpty { populatedFields += 1 }
        if !comparable.leadProgram.name.isEmpty { populatedFields += 1 }
        if !comparable.leadProgram.indication.isEmpty { populatedFields += 1 }
        if !comparable.leadProgram.mechanism.isEmpty { populatedFields += 1 }
        if comparable.financials.cashAtTransaction != nil { populatedFields += 1 }
        if comparable.financials.burnRate != nil { populatedFields += 1 }
        if comparable.financials.revenue != nil { populatedFields += 1 }
        if comparable.dealStructure != nil { populatedFields += 1 }
        if comparable.ageInYears < 5 { populatedFields += 1 } // Recent data bonus
        
        completeness = populatedFields / totalFields
        
        // Adjust confidence based on data quality
        if completeness < 0.5 {
            confidence *= 0.8
        }
        
        if comparable.ageInYears > 5 {
            confidence *= 0.9
        }
        
        let recommendations = generateRecommendations(for: comparable, issues: issues)
        
        return ComparableValidation(
            isValid: issues.filter { $0.severity == .critical }.isEmpty,
            completeness: completeness,
            confidence: confidence,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    func calculateSimilarity(company: CompanyData, comparable: Comparable) -> Double {
        let factors = calculateCompanyMatchingFactors(company: company, comparable: comparable)
        return factors.overallSimilarity
    }
    
    func getDatabaseAnalytics() async throws -> ComparablesAnalytics {
        return await withCheckedContinuation { continuation in
            queue.async {
                let analytics = self.generateAnalytics()
                continuation.resume(returning: analytics)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func filterComparables(by criteria: ComparableCriteria) -> [Comparable] {
        return comparables.filter { comparable in
            // Filter by therapeutic areas
            if let areas = criteria.therapeuticAreas, !areas.isEmpty {
                let hasMatchingArea = areas.contains { area in
                    comparable.therapeuticAreas.contains { $0.lowercased().contains(area.lowercased()) }
                }
                if !hasMatchingArea { return false }
            }
            
            // Filter by stages
            if let stages = criteria.stages, !stages.isEmpty {
                if !stages.contains(comparable.stage) { return false }
            }
            
            // Filter by transaction types
            if let types = criteria.transactionTypes, !types.isEmpty {
                if !types.contains(comparable.transactionType) { return false }
            }
            
            // Filter by market size
            if let minSize = criteria.minMarketSize {
                if comparable.marketSize < minSize { return false }
            }
            
            if let maxSize = criteria.maxMarketSize {
                if comparable.marketSize > maxSize { return false }
            }
            
            // Filter by valuation
            if let minVal = criteria.minValuation {
                if comparable.valuation < minVal { return false }
            }
            
            if let maxVal = criteria.maxValuation {
                if comparable.valuation > maxVal { return false }
            }
            
            // Filter by age
            if let maxAge = criteria.maxAge {
                if comparable.ageInYears > maxAge { return false }
            }
            
            // Filter by confidence
            if let minConfidence = criteria.minConfidence {
                if comparable.confidence < minConfidence { return false }
            }
            
            // Filter by competitive positions
            if let positions = criteria.competitivePositions, !positions.isEmpty {
                if !positions.contains(comparable.leadProgram.competitivePosition) { return false }
            }
            
            // Filter by mechanisms
            if let mechanisms = criteria.mechanisms, !mechanisms.isEmpty {
                let hasMatchingMechanism = mechanisms.contains { mechanism in
                    comparable.leadProgram.mechanism.lowercased().contains(mechanism.lowercased())
                }
                if !hasMatchingMechanism { return false }
            }
            
            // Filter by indications
            if let indications = criteria.indications, !indications.isEmpty {
                let hasMatchingIndication = indications.contains { indication in
                    comparable.leadProgram.indication.lowercased().contains(indication.lowercased())
                }
                if !hasMatchingIndication { return false }
            }
            
            return true
        }
    }
    
    private func calculateSimilarityScore(_ comparable: Comparable, criteria: ComparableCriteria) -> Double {
        // Basic similarity calculation based on criteria match
        var score: Double = 0.0
        var factors: Int = 0
        
        // Therapeutic area match
        if let areas = criteria.therapeuticAreas, !areas.isEmpty {
            let matchCount = areas.filter { area in
                comparable.therapeuticAreas.contains { $0.lowercased().contains(area.lowercased()) }
            }.count
            score += Double(matchCount) / Double(areas.count) * 0.3
            factors += 1
        }
        
        // Stage match
        if let stages = criteria.stages, !stages.isEmpty {
            if stages.contains(comparable.stage) {
                score += 0.2
            }
            factors += 1
        }
        
        // Transaction type relevance
        score += comparable.transactionType == .acquisition ? 0.2 : 0.1
        factors += 1
        
        // Recency bonus
        let ageScore = max(0, 1.0 - (comparable.ageInYears / 10.0))
        score += ageScore * 0.15
        factors += 1
        
        // Confidence bonus
        score += comparable.confidence * 0.15
        factors += 1
        
        return factors > 0 ? score : 0.0
    }
    
    private func calculateMatchingFactors(_ comparable: Comparable, criteria: ComparableCriteria) -> MatchingFactors {
        var therapeuticAreaMatch: Double = 0.0
        var stageMatch: Double = 0.0
        var marketSizeMatch: Double = 0.0
        
        // Calculate therapeutic area match
        if let areas = criteria.therapeuticAreas, !areas.isEmpty {
            let matchCount = areas.filter { area in
                comparable.therapeuticAreas.contains { $0.lowercased().contains(area.lowercased()) }
            }.count
            therapeuticAreaMatch = Double(matchCount) / Double(areas.count)
        } else {
            therapeuticAreaMatch = 0.5 // Neutral if no criteria specified
        }
        
        // Calculate stage match
        if let stages = criteria.stages, !stages.isEmpty {
            stageMatch = stages.contains(comparable.stage) ? 1.0 : 0.0
        } else {
            stageMatch = 0.5
        }
        
        // Calculate market size match (proximity-based)
        if let minSize = criteria.minMarketSize, let maxSize = criteria.maxMarketSize {
            let targetSize = (minSize + maxSize) / 2
            let difference = abs(comparable.marketSize - targetSize)
            let maxDifference = max(targetSize, 10.0) // Avoid division by zero
            marketSizeMatch = max(0, 1.0 - (difference / maxDifference))
        } else {
            marketSizeMatch = 0.5
        }
        
        // Time relevance (newer is better)
        let timeRelevance = max(0, 1.0 - (comparable.ageInYears / 10.0))
        
        return MatchingFactors(
            therapeuticAreaMatch: therapeuticAreaMatch,
            stageMatch: stageMatch,
            marketSizeMatch: marketSizeMatch,
            mechanismMatch: 0.5, // Default for criteria-based search
            competitivePositionMatch: 0.5,
            timeRelevance: timeRelevance,
            financialSimilarity: 0.5
        )
    }
    
    private func calculateCompanyMatchingFactors(company: CompanyData, comparable: Comparable) -> MatchingFactors {
        // Therapeutic area match
        let therapeuticAreaMatch = calculateTherapeuticAreaSimilarity(
            company.basicInfo.therapeuticAreas,
            comparable.therapeuticAreas
        )
        
        // Stage match
        let stageMatch = company.basicInfo.stage == comparable.stage ? 1.0 : 
                        abs(stageToNumeric(company.basicInfo.stage) - stageToNumeric(comparable.stage)) <= 1 ? 0.7 : 0.3
        
        // Market size match
        let marketSizeMatch = calculateMarketSizeSimilarity(
            company.market.addressableMarket,
            comparable.marketSize
        )
        
        // Mechanism match (if lead program exists)
        let mechanismMatch: Double
        if let leadProgram = company.pipeline.leadProgram {
            mechanismMatch = leadProgram.mechanism.lowercased() == comparable.leadProgram.mechanism.lowercased() ? 1.0 : 0.3
        } else {
            mechanismMatch = 0.5
        }
        
        // Competitive position match
        let competitivePositionMatch: Double = 0.5 // Default since company data doesn't include this
        
        // Time relevance
        let timeRelevance = max(0, 1.0 - (comparable.ageInYears / 10.0))
        
        // Financial similarity
        let financialSimilarity = calculateFinancialSimilarity(company.financials, comparable.financials)
        
        return MatchingFactors(
            therapeuticAreaMatch: therapeuticAreaMatch,
            stageMatch: stageMatch,
            marketSizeMatch: marketSizeMatch,
            mechanismMatch: mechanismMatch,
            competitivePositionMatch: competitivePositionMatch,
            timeRelevance: timeRelevance,
            financialSimilarity: financialSimilarity
        )
    }
    
    private func calculateTherapeuticAreaSimilarity(_ areas1: [String], _ areas2: [String]) -> Double {
        guard !areas1.isEmpty && !areas2.isEmpty else { return 0.0 }
        
        let matchCount = areas1.filter { area1 in
            areas2.contains { area2 in
                area1.lowercased().contains(area2.lowercased()) || area2.lowercased().contains(area1.lowercased())
            }
        }.count
        
        return Double(matchCount) / Double(max(areas1.count, areas2.count))
    }
    
    private func calculateMarketSizeSimilarity(_ size1: Double, _ size2: Double) -> Double {
        let ratio = min(size1, size2) / max(size1, size2)
        return ratio
    }
    
    private func calculateFinancialSimilarity(_ financials1: CompanyData.Financials, _ financials2: ComparableFinancials) -> Double {
        var similarity: Double = 0.0
        var factors: Int = 0
        
        // Cash position similarity
        if let cash2 = financials2.cashAtTransaction {
            let ratio = min(financials1.cashPosition, cash2) / max(financials1.cashPosition, cash2)
            similarity += ratio
            factors += 1
        }
        
        // Burn rate similarity
        if let burn2 = financials2.burnRate {
            let ratio = min(financials1.burnRate, burn2) / max(financials1.burnRate, burn2)
            similarity += ratio
            factors += 1
        }
        
        return factors > 0 ? similarity / Double(factors) : 0.5
    }
    
    private func stageToNumeric(_ stage: DevelopmentStage) -> Int {
        switch stage {
        case .preclinical: return 0
        case .phase1: return 1
        case .phase2: return 2
        case .phase3: return 3
        case .approved: return 4
        case .marketed: return 5
        }
    }
    
    private func createCriteriaFromCompany(_ company: CompanyData) -> ComparableCriteria {
        return ComparableCriteria(
            therapeuticAreas: company.basicInfo.therapeuticAreas,
            stages: [company.basicInfo.stage],
            transactionTypes: [.acquisition, .licensing, .partnership],
            minMarketSize: company.market.addressableMarket * 0.5,
            maxMarketSize: company.market.addressableMarket * 2.0,
            maxAge: 5.0,
            minConfidence: 0.6
        )
    }
    
    private func generateRecommendations(for comparable: Comparable, issues: [ValidationIssue]) -> [String] {
        var recommendations: [String] = []
        
        if comparable.confidence < 0.7 {
            recommendations.append("Consider verifying transaction details from additional sources")
        }
        
        if comparable.ageInYears > 3 {
            recommendations.append("Transaction is older than 3 years - consider market condition changes")
        }
        
        if comparable.financials.cashAtTransaction == nil {
            recommendations.append("Add financial data for better comparability analysis")
        }
        
        if issues.contains(where: { $0.severity == .critical }) {
            recommendations.append("Resolve critical data issues before using for valuation")
        }
        
        return recommendations
    }
    
    private func generateAnalytics() -> ComparablesAnalytics {
        let totalComparables = comparables.count
        
        var byTransactionType: [TransactionType: Int] = [:]
        var byTherapeuticArea: [String: Int] = [:]
        var byStage: [DevelopmentStage: Int] = [:]
        
        var valuations: [Double] = []
        var ages: [Double] = []
        var confidences: [Double] = []
        
        for comparable in comparables {
            // Transaction type distribution
            byTransactionType[comparable.transactionType, default: 0] += 1
            
            // Therapeutic area distribution
            for area in comparable.therapeuticAreas {
                byTherapeuticArea[area, default: 0] += 1
            }
            
            // Stage distribution
            byStage[comparable.stage, default: 0] += 1
            
            // Collect metrics
            valuations.append(comparable.valuation)
            ages.append(comparable.ageInYears)
            confidences.append(comparable.confidence)
        }
        
        let averageValuation = valuations.isEmpty ? 0.0 : valuations.reduce(0, +) / Double(valuations.count)
        let medianValuation = valuations.isEmpty ? 0.0 : valuations.sorted()[valuations.count / 2]
        let valuationRange = valuations.isEmpty ? 0.0...0.0 : valuations.min()!...valuations.max()!
        
        let averageAge = ages.isEmpty ? 0.0 : ages.reduce(0, +) / Double(ages.count)
        let recentTransactions = ages.filter { $0 <= 2.0 }.count
        let oldestDate = Date().addingTimeInterval(-ages.max()! * 365.25 * 24 * 3600)
        let newestDate = Date().addingTimeInterval(-ages.min()! * 365.25 * 24 * 3600)
        
        let averageConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
        let highConfidenceCount = confidences.filter { $0 > 0.8 }.count
        
        return ComparablesAnalytics(
            totalComparables: totalComparables,
            byTransactionType: byTransactionType,
            byTherapeuticArea: byTherapeuticArea,
            byStage: byStage,
            averageValuation: averageValuation,
            medianValuation: medianValuation,
            valuationRange: valuationRange,
            dataFreshness: DataFreshness(
                averageAge: averageAge,
                recentTransactions: recentTransactions,
                oldestTransaction: oldestDate,
                newestTransaction: newestDate
            ),
            qualityMetrics: QualityMetrics(
                averageConfidence: averageConfidence,
                highConfidenceCount: highConfidenceCount,
                completeRecords: totalComparables, // Simplified
                verifiedTransactions: Int(Double(totalComparables) * 0.7) // Estimated
            )
        )
    }
    
    private func loadSampleData() {
        // Sample comparable transactions for testing
        let sampleComparables = [
            Comparable(
                companyName: "BioTech Alpha",
                transactionType: .acquisition,
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                valuation: 850.0,
                stage: .phase2,
                therapeuticAreas: ["Oncology", "Immunology"],
                leadProgram: ComparableProgram(
                    name: "BTA-001",
                    indication: "Non-small cell lung cancer",
                    mechanism: "PD-1 inhibitor",
                    stage: .phase2,
                    differentiators: ["Novel binding site", "Improved safety profile"],
                    competitivePosition: .bestInClass
                ),
                marketSize: 15.2,
                financials: ComparableFinancials(
                    cashAtTransaction: 120.0,
                    burnRate: 8.5,
                    runway: 14,
                    lastFundingAmount: 75.0,
                    revenue: nil,
                    employees: 85
                ),
                dealStructure: DealStructure(
                    upfront: 850.0,
                    milestones: 1200.0,
                    royalties: 12.5,
                    equity: nil,
                    terms: ["Exclusive worldwide rights", "Co-development option"]
                ),
                confidence: 0.85
            ),
            
            Comparable(
                companyName: "Neuro Innovations",
                transactionType: .licensing,
                date: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
                valuation: 450.0,
                stage: .phase1,
                therapeuticAreas: ["Neurology", "CNS"],
                leadProgram: ComparableProgram(
                    name: "NI-2023",
                    indication: "Alzheimer's disease",
                    mechanism: "Amyloid beta targeting",
                    stage: .phase1,
                    differentiators: ["Blood-brain barrier penetration", "Oral bioavailability"],
                    competitivePosition: .firstInClass
                ),
                marketSize: 8.7,
                financials: ComparableFinancials(
                    cashAtTransaction: 45.0,
                    burnRate: 3.2,
                    runway: 14,
                    lastFundingAmount: 25.0,
                    revenue: nil,
                    employees: 32
                ),
                dealStructure: DealStructure(
                    upfront: 50.0,
                    milestones: 400.0,
                    royalties: 8.0,
                    equity: nil,
                    terms: ["US and EU rights", "Development milestone payments"]
                ),
                confidence: 0.78
            ),
            
            Comparable(
                companyName: "CardioVascular Solutions",
                transactionType: .ipo,
                date: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
                valuation: 1250.0,
                stage: .phase3,
                therapeuticAreas: ["Cardiology"],
                leadProgram: ComparableProgram(
                    name: "CVS-100",
                    indication: "Heart failure",
                    mechanism: "ACE inhibitor",
                    stage: .phase3,
                    differentiators: ["Extended release formulation", "Reduced side effects"],
                    competitivePosition: .bestInClass
                ),
                marketSize: 22.1,
                financials: ComparableFinancials(
                    cashAtTransaction: 180.0,
                    burnRate: 12.0,
                    runway: 15,
                    lastFundingAmount: 95.0,
                    revenue: 15.0,
                    employees: 145
                ),
                dealStructure: nil,
                confidence: 0.92
            )
        ]
        
        comparables = sampleComparables
    }
}