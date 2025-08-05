import SwiftUI

// Test compilation of CompanyEvaluationView
func testCompanyEvaluationCompilation() {
    let _ = CompanyEvaluationView()
    print("CompanyEvaluationView compiles successfully")
}

// Test supporting types compilation
func testSupportingTypesCompilation() {
    let _ = EvaluationStep.selection
    let _ = CompanyFormData()
    let _ = ScoringPillarData(name: "Test", score: 4.0, weight: 25, confidence: 0.8)
    print("Supporting types compile successfully")
}

// Test view components compilation
func testViewComponentsCompilation() {
    let sampleCompany = CompanyData(
        basicInfo: CompanyData.BasicInfo(
            name: "Test",
            ticker: nil,
            sector: "Biotech",
            therapeuticAreas: ["Oncology"],
            stage: .phase1,
            description: nil
        ),
        pipeline: CompanyData.Pipeline(programs: []),
        financials: CompanyData.Financials(cashPosition: 10.0, burnRate: 1.0, lastFunding: nil),
        market: CompanyData.Market(
            addressableMarket: 5.0,
            competitors: [],
            marketDynamics: CompanyData.MarketDynamics(
                growthRate: 0.1,
                barriers: [],
                drivers: [],
                reimbursement: .unknown
            )
        ),
        regulatory: CompanyData.Regulatory(
            approvals: [],
            clinicalTrials: [],
            regulatoryStrategy: CompanyData.RegulatoryStrategy(
                pathway: .standard,
                timeline: 24,
                risks: [],
                mitigations: []
            )
        )
    )
    
    let _ = CompanyCard(company: sampleCompany, isSelected: false) { }
    let _ = ScoringPillarCard(pillar: ScoringPillarData(name: "Test", score: 4.0, weight: 25, confidence: 0.8))
    
    print("View components compile successfully")
}

testCompanyEvaluationCompilation()
testSupportingTypesCompilation()
testViewComponentsCompilation()