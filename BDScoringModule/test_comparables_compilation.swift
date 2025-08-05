import Foundation

// Test compilation of comparables functionality
func testComparablesCompilation() {
    // Test creating a comparable
    let comparable = Comparable(
        companyName: "Test Company",
        transactionType: .acquisition,
        date: Date(),
        valuation: 500.0,
        stage: .phase2,
        therapeuticAreas: ["Oncology"],
        leadProgram: ComparableProgram(
            name: "Test Program",
            indication: "Test Indication",
            mechanism: "Test Mechanism",
            stage: .phase2,
            differentiators: ["Test Diff"],
            competitivePosition: .bestInClass
        ),
        marketSize: 10.0,
        financials: ComparableFinancials(
            cashAtTransaction: 50.0,
            burnRate: 5.0,
            runway: 10,
            lastFundingAmount: 25.0,
            revenue: nil,
            employees: 50
        ),
        dealStructure: nil,
        confidence: 0.8
    )
    
    // Test creating search criteria
    let criteria = ComparableCriteria(
        therapeuticAreas: ["Oncology"],
        stages: [.phase2],
        transactionTypes: [.acquisition],
        maxAge: 3.0,
        minConfidence: 0.7
    )
    
    // Test creating service
    let service = DefaultComparablesService()
    
    // Test validation
    let validation = service.validateComparable(comparable)
    print("Validation result: \(validation.isValid)")
    print("Completeness: \(validation.completeness)")
    print("Confidence: \(validation.confidence)")
    
    print("Comparables compilation test completed successfully!")
}

// Run the test
testComparablesCompilation()