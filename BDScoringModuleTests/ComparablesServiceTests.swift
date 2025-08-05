import XCTest
@testable import BDScoringModule

final class ComparablesServiceTests: XCTestCase {
    
    var service: DefaultComparablesService!
    var sampleCompany: CompanyData!
    var sampleComparable: Comparable!
    
    override func setUp() {
        super.setUp()
        service = DefaultComparablesService()
        setupSampleData()
    }
    
    override func tearDown() {
        service = nil
        sampleCompany = nil
        sampleComparable = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupSampleData() {
        // Create sample company data
        sampleCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech",
                ticker: "TBIO",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "Test biotech company"
            ),
            pipeline: CompanyData.Pipeline(
                programs: [
                    Program(
                        name: "TB-001",
                        indication: "Breast cancer",
                        stage: .phase2,
                        mechanism: "CDK4/6 inhibitor",
                        differentiators: ["Improved selectivity", "Oral bioavailability"],
                        risks: [],
                        timeline: []
                    )
                ]
            ),
            financials: CompanyData.Financials(
                cashPosition: 85.0,
                burnRate: 6.5,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: 50.0,
                    date: Date(),
                    investors: ["VC Fund A"]
                )
            ),
            market: CompanyData.Market(
                addressableMarket: 12.5,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 8.5,
                    barriers: [],
                    drivers: [],
                    reimbursement: .favorable
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 36,
                    risks: [],
                    mitigations: []
                )
            )
        )
        
        // Create sample comparable
        sampleComparable = Comparable(
            companyName: "Sample Comparable",
            transactionType: .acquisition,
            date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
            valuation: 750.0,
            stage: .phase2,
            therapeuticAreas: ["Oncology"],
            leadProgram: ComparableProgram(
                name: "SC-001",
                indication: "Lung cancer",
                mechanism: "EGFR inhibitor",
                stage: .phase2,
                differentiators: ["Novel mechanism"],
                competitivePosition: .bestInClass
            ),
            marketSize: 10.0,
            financials: ComparableFinancials(
                cashAtTransaction: 80.0,
                burnRate: 5.0,
                runway: 16,
                lastFundingAmount: 40.0,
                revenue: nil,
                employees: 65
            ),
            dealStructure: DealStructure(
                upfront: 750.0,
                milestones: 1000.0,
                royalties: 10.0,
                equity: nil,
                terms: ["Exclusive rights"]
            ),
            confidence: 0.8
        )
    }
    
    // MARK: - Basic CRUD Tests
    
    func testAddComparable() async throws {
        // Given
        let initialCount = try await service.getAllComparables().count
        
        // When
        try await service.addComparable(sampleComparable)
        
        // Then
        let finalCount = try await service.getAllComparables().count
        XCTAssertEqual(finalCount, initialCount + 1)
        
        let retrieved = try await service.getComparable(id: sampleComparable.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.companyName, sampleComparable.companyName)
    }
    
    func testUpdateComparable() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        var updatedComparable = sampleComparable!
        updatedComparable.valuation = 900.0
        
        // When
        try await service.updateComparable(updatedComparable)
        
        // Then
        let retrieved = try await service.getComparable(id: sampleComparable.id)
        XCTAssertEqual(retrieved?.valuation, 900.0)
    }
    
    func testDeleteComparable() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let initialCount = try await service.getAllComparables().count
        
        // When
        try await service.deleteComparable(id: sampleComparable.id)
        
        // Then
        let finalCount = try await service.getAllComparables().count
        XCTAssertEqual(finalCount, initialCount - 1)
        
        let retrieved = try await service.getComparable(id: sampleComparable.id)
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Search Tests
    
    func testSearchComparablesWithTherapeuticAreaFilter() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(therapeuticAreas: ["Oncology"])
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { match in
            match.comparable.therapeuticAreas.contains { $0.contains("Oncology") }
        })
    }
    
    func testSearchComparablesWithStageFilter() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(stages: [.phase2])
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { $0.comparable.stage == .phase2 })
    }
    
    func testSearchComparablesWithTransactionTypeFilter() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(transactionTypes: [.acquisition])
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { $0.comparable.transactionType == .acquisition })
    }
    
    func testSearchComparablesWithValuationRange() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(
            minValuation: 500.0,
            maxValuation: 1000.0
        )
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { 
            $0.comparable.valuation >= 500.0 && $0.comparable.valuation <= 1000.0 
        })
    }
    
    func testSearchComparablesWithMarketSizeRange() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(
            minMarketSize: 5.0,
            maxMarketSize: 15.0
        )
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { 
            $0.comparable.marketSize >= 5.0 && $0.comparable.marketSize <= 15.0 
        })
    }
    
    func testSearchComparablesWithAgeFilter() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(maxAge: 2.0)
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { $0.comparable.ageInYears <= 2.0 })
    }
    
    func testSearchComparablesWithConfidenceFilter() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(minConfidence: 0.7)
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertTrue(result.comparables.allSatisfy { $0.comparable.confidence >= 0.7 })
    }
    
    func testSearchComparablesWithMultipleFilters() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria(
            therapeuticAreas: ["Oncology"],
            stages: [.phase2],
            transactionTypes: [.acquisition],
            minValuation: 500.0,
            maxAge: 2.0,
            minConfidence: 0.7
        )
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        for match in result.comparables {
            XCTAssertTrue(match.comparable.therapeuticAreas.contains { $0.contains("Oncology") })
            XCTAssertEqual(match.comparable.stage, .phase2)
            XCTAssertEqual(match.comparable.transactionType, .acquisition)
            XCTAssertGreaterThanOrEqual(match.comparable.valuation, 500.0)
            XCTAssertLessThanOrEqual(match.comparable.ageInYears, 2.0)
            XCTAssertGreaterThanOrEqual(match.comparable.confidence, 0.7)
        }
    }
    
    func testSearchResultsSortedBySimilarity() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let criteria = ComparableCriteria.default
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        
        // Verify sorting by similarity (descending)
        for i in 0..<(result.comparables.count - 1) {
            XCTAssertGreaterThanOrEqual(
                result.comparables[i].similarity,
                result.comparables[i + 1].similarity
            )
        }
    }
    
    // MARK: - Company-Specific Search Tests
    
    func testFindComparablesForCompany() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let result = try await service.findComparablesForCompany(sampleCompany, maxResults: 5)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
        XCTAssertLessThanOrEqual(result.comparables.count, 5)
        
        // Verify results are sorted by similarity
        for i in 0..<(result.comparables.count - 1) {
            XCTAssertGreaterThanOrEqual(
                result.comparables[i].similarity,
                result.comparables[i + 1].similarity
            )
        }
    }
    
    func testFindComparablesForCompanyWithMaxResults() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let result = try await service.findComparablesForCompany(sampleCompany, maxResults: 2)
        
        // Then
        XCTAssertLessThanOrEqual(result.comparables.count, 2)
    }
    
    // MARK: - Similarity Calculation Tests
    
    func testCalculateSimilarityWithIdenticalTherapeuticAreas() {
        // Given
        var testComparable = sampleComparable!
        testComparable.therapeuticAreas = ["Oncology", "Immunology"]
        
        // When
        let similarity = service.calculateSimilarity(company: sampleCompany, comparable: testComparable)
        
        // Then
        XCTAssertGreaterThan(similarity, 0.5)
    }
    
    func testCalculateSimilarityWithSameStage() {
        // Given
        var testComparable = sampleComparable!
        testComparable.stage = .phase2
        
        // When
        let similarity = service.calculateSimilarity(company: sampleCompany, comparable: testComparable)
        
        // Then
        XCTAssertGreaterThan(similarity, 0.3)
    }
    
    func testCalculateSimilarityWithSimilarMarketSize() {
        // Given
        var testComparable = sampleComparable!
        testComparable.marketSize = 12.0 // Close to company's 12.5
        
        // When
        let similarity = service.calculateSimilarity(company: sampleCompany, comparable: testComparable)
        
        // Then
        XCTAssertGreaterThan(similarity, 0.3)
    }
    
    func testCalculateSimilarityWithRecentTransaction() {
        // Given
        var testComparable = sampleComparable!
        testComparable.date = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        
        // When
        let similarity = service.calculateSimilarity(company: sampleCompany, comparable: testComparable)
        
        // Then
        XCTAssertGreaterThan(similarity, 0.2)
    }
    
    func testCalculateSimilarityWithHighConfidence() {
        // Given
        var testComparable = sampleComparable!
        testComparable.confidence = 0.95
        
        // When
        let similarity = service.calculateSimilarity(company: sampleCompany, comparable: testComparable)
        
        // Then
        XCTAssertGreaterThan(similarity, 0.2)
    }
    
    // MARK: - Validation Tests
    
    func testValidateComparableWithValidData() {
        // Given
        let validComparable = sampleComparable!
        
        // When
        let validation = service.validateComparable(validComparable)
        
        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertGreaterThan(validation.completeness, 0.5)
        XCTAssertGreaterThan(validation.confidence, 0.5)
        XCTAssertEqual(validation.issues.filter { $0.severity == .critical }.count, 0)
    }
    
    func testValidateComparableWithMissingCompanyName() {
        // Given
        var invalidComparable = sampleComparable!
        invalidComparable.companyName = ""
        
        // When
        let validation = service.validateComparable(invalidComparable)
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.issues.contains { $0.field == "companyName" && $0.severity == .critical })
    }
    
    func testValidateComparableWithInvalidValuation() {
        // Given
        var invalidComparable = sampleComparable!
        invalidComparable.valuation = -100.0
        
        // When
        let validation = service.validateComparable(invalidComparable)
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.issues.contains { $0.field == "valuation" && $0.severity == .critical })
    }
    
    func testValidateComparableWithInvalidMarketSize() {
        // Given
        var invalidComparable = sampleComparable!
        invalidComparable.marketSize = -5.0
        
        // When
        let validation = service.validateComparable(invalidComparable)
        
        // Then
        XCTAssertTrue(validation.issues.contains { $0.field == "marketSize" && $0.severity == .error })
    }
    
    func testValidateComparableWithEmptyTherapeuticAreas() {
        // Given
        var invalidComparable = sampleComparable!
        invalidComparable.therapeuticAreas = []
        
        // When
        let validation = service.validateComparable(invalidComparable)
        
        // Then
        XCTAssertTrue(validation.issues.contains { $0.field == "therapeuticAreas" && $0.severity == .error })
    }
    
    func testValidateComparableWithLowConfidence() {
        // Given
        var lowConfidenceComparable = sampleComparable!
        lowConfidenceComparable.confidence = 0.3
        
        // When
        let validation = service.validateComparable(lowConfidenceComparable)
        
        // Then
        XCTAssertLessThan(validation.confidence, 0.7)
        XCTAssertTrue(validation.recommendations.contains { $0.contains("verifying transaction details") })
    }
    
    func testValidateComparableWithOldTransaction() {
        // Given
        var oldComparable = sampleComparable!
        oldComparable.date = Calendar.current.date(byAdding: .year, value: -6, to: Date())!
        
        // When
        let validation = service.validateComparable(oldComparable)
        
        // Then
        XCTAssertTrue(validation.recommendations.contains { $0.contains("older than 3 years") })
    }
    
    // MARK: - Confidence Level Tests
    
    func testConfidenceLevelCalculationWithCompleteData() {
        // Given
        let completeComparable = sampleComparable!
        
        // When
        let validation = service.validateComparable(completeComparable)
        
        // Then
        XCTAssertGreaterThan(validation.confidence, 0.7)
        XCTAssertGreaterThan(validation.completeness, 0.8)
    }
    
    func testConfidenceLevelCalculationWithIncompleteData() {
        // Given
        var incompleteComparable = sampleComparable!
        incompleteComparable.financials = ComparableFinancials(
            cashAtTransaction: nil,
            burnRate: nil,
            runway: nil,
            lastFundingAmount: nil,
            revenue: nil,
            employees: nil
        )
        incompleteComparable.dealStructure = nil
        
        // When
        let validation = service.validateComparable(incompleteComparable)
        
        // Then
        XCTAssertLessThan(validation.completeness, 0.8)
        XCTAssertLessThan(validation.confidence, 0.8)
    }
    
    // MARK: - Analytics Tests
    
    func testGetDatabaseAnalytics() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let analytics = try await service.getDatabaseAnalytics()
        
        // Then
        XCTAssertGreaterThan(analytics.totalComparables, 0)
        XCTAssertGreaterThan(analytics.averageValuation, 0)
        XCTAssertGreaterThan(analytics.medianValuation, 0)
        XCTAssertNotNil(analytics.byTransactionType[.acquisition])
        XCTAssertNotNil(analytics.byStage[.phase2])
        XCTAssertGreaterThan(analytics.qualityMetrics.averageConfidence, 0)
    }
    
    func testAnalyticsTransactionTypeDistribution() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let analytics = try await service.getDatabaseAnalytics()
        
        // Then
        let totalByType = analytics.byTransactionType.values.reduce(0, +)
        XCTAssertEqual(totalByType, analytics.totalComparables)
    }
    
    func testAnalyticsTherapeuticAreaDistribution() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let analytics = try await service.getDatabaseAnalytics()
        
        // Then
        XCTAssertGreaterThan(analytics.byTherapeuticArea.count, 0)
        XCTAssertNotNil(analytics.byTherapeuticArea["Oncology"])
    }
    
    func testAnalyticsStageDistribution() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        
        // When
        let analytics = try await service.getDatabaseAnalytics()
        
        // Then
        let totalByStage = analytics.byStage.values.reduce(0, +)
        XCTAssertEqual(totalByStage, analytics.totalComparables)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSearchWithEmptyCriteria() async throws {
        // Given
        try await service.addComparable(sampleComparable)
        let emptyCriteria = ComparableCriteria()
        
        // When
        let result = try await service.searchComparables(criteria: emptyCriteria)
        
        // Then
        XCTAssertGreaterThan(result.comparables.count, 0)
    }
    
    func testSearchWithNoMatches() async throws {
        // Given
        let restrictiveCriteria = ComparableCriteria(
            therapeuticAreas: ["NonExistentArea"],
            minValuation: 10000.0
        )
        
        // When
        let result = try await service.searchComparables(criteria: restrictiveCriteria)
        
        // Then
        XCTAssertEqual(result.comparables.count, 0)
        XCTAssertEqual(result.totalFound, 0)
    }
    
    func testGetNonExistentComparable() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let result = try await service.getComparable(id: nonExistentId)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testDeleteNonExistentComparable() async throws {
        // Given
        let nonExistentId = UUID()
        let initialCount = try await service.getAllComparables().count
        
        // When
        try await service.deleteComparable(id: nonExistentId)
        
        // Then
        let finalCount = try await service.getAllComparables().count
        XCTAssertEqual(finalCount, initialCount) // Should remain unchanged
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformanceWithLargeDataset() async throws {
        // Given
        let startTime = Date()
        
        // Add multiple comparables
        for i in 0..<100 {
            var comparable = sampleComparable!
            comparable.companyName = "Company \(i)"
            comparable.valuation = Double(i * 10 + 100)
            try await service.addComparable(comparable)
        }
        
        let criteria = ComparableCriteria(therapeuticAreas: ["Oncology"])
        
        // When
        let result = try await service.searchComparables(criteria: criteria)
        
        // Then
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
        XCTAssertGreaterThan(result.comparables.count, 0)
    }
}