import XCTest
import SwiftUI
@testable import BDScoringModule

final class CompanyEvaluationViewTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    private func createSampleCompany() -> CompanyData {
        return CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: "Test Biotech",
                ticker: "TEST",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology"],
                stage: .phase2,
                description: "Test company for evaluation"
            ),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(
                cashPosition: 50.0,
                burnRate: 4.0,
                lastFunding: nil
            ),
            market: CompanyData.Market(
                addressableMarket: 10.0,
                competitors: [],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 0.15,
                    barriers: [],
                    drivers: [],
                    reimbursement: .favorable
                )
            ),
            regulatory: CompanyData.Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: CompanyData.RegulatoryStrategy(
                    pathway: .standard,
                    timeline: 36,
                    risks: [],
                    mitigations: []
                )
            )
        )
    }
    
    // MARK: - Company Selection Tests
    
    func testCompanySelectionInitialState() {
        // Test that the view starts in selection mode
        let view = CompanyEvaluationView()
        
        // Verify initial state
        XCTAssertEqual(view.evaluationStep, .selection)
        XCTAssertNil(view.selectedCompany)
        XCTAssertEqual(view.searchText, "")
        XCTAssertEqual(view.selectedFilter, .all)
        XCTAssertFalse(view.showingNewCompanyForm)
        XCTAssertFalse(view.isCalculatingScore)
        XCTAssertTrue(view.validationErrors.isEmpty)
    }
    
    func testCompanySearch() {
        // Test search functionality
        let view = CompanyEvaluationView()
        
        // Test search filtering
        view.searchText = "BioTech"
        let filteredCompanies = view.filteredCompanies
        
        // Should find companies with "BioTech" in name
        XCTAssertTrue(filteredCompanies.contains { $0.basicInfo.name.contains("BioTech") })
        
        // Test therapeutic area search
        view.searchText = "Oncology"
        let therapeuticFiltered = view.filteredCompanies
        XCTAssertTrue(therapeuticFiltered.contains { $0.basicInfo.therapeuticAreas.contains("Oncology") })
        
        // Test empty search returns all companies
        view.searchText = ""
        XCTAssertEqual(view.filteredCompanies.count, view.companies.count)
    }
    
    func testCompanySelection() {
        // Test company selection functionality
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        // Add test company to the list
        view.companies.append(testCompany)
        
        // Select the company
        view.selectedCompany = testCompany
        
        // Verify selection
        XCTAssertEqual(view.selectedCompany?.id, testCompany.id)
        XCTAssertEqual(view.selectedCompany?.basicInfo.name, "Test Biotech")
    }
    
    func testNavigationToBasicInfo() {
        // Test navigation from selection to basic info
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        view.selectedCompany = testCompany
        view.evaluationStep = .basicInfo
        
        XCTAssertEqual(view.evaluationStep, .basicInfo)
        XCTAssertNotNil(view.selectedCompany)
    }
    
    // MARK: - Basic Info Form Tests
    
    func testCompanyFormDataInitialization() {
        // Test form data initialization
        let formData = CompanyFormData()
        
        XCTAssertEqual(formData.name, "")
        XCTAssertEqual(formData.ticker, "")
        XCTAssertEqual(formData.stage, .preclinical)
        XCTAssertEqual(formData.therapeuticArea, "Oncology")
        XCTAssertEqual(formData.description, "")
        XCTAssertEqual(formData.cashPosition, 0)
        XCTAssertEqual(formData.burnRate, 0)
        XCTAssertEqual(formData.runway, 0)
    }
    
    func testRunwayCalculation() {
        // Test runway calculation logic
        var formData = CompanyFormData()
        
        // Test with valid data
        formData.cashPosition = 50.0
        formData.burnRate = 5.0
        XCTAssertEqual(formData.runway, 10)
        
        // Test with zero burn rate
        formData.burnRate = 0
        XCTAssertEqual(formData.runway, 0)
        
        // Test with fractional result
        formData.cashPosition = 33.0
        formData.burnRate = 2.5
        XCTAssertEqual(formData.runway, 13) // 33/2.5 = 13.2, truncated to 13
    }
    
    func testFormDataValidation() {
        // Test form data validation
        let formData = CompanyFormData()
        
        // Test empty name validation
        XCTAssertTrue(formData.name.isEmpty)
        
        // Test with valid data
        var validFormData = CompanyFormData()
        validFormData.name = "Valid Company"
        validFormData.cashPosition = 25.0
        validFormData.burnRate = 2.0
        
        XCTAssertFalse(validFormData.name.isEmpty)
        XCTAssertGreaterThan(validFormData.cashPosition, 0)
        XCTAssertGreaterThan(validFormData.burnRate, 0)
    }
    
    func testUpdateSelectedCompanyData() {
        // Test updating selected company with form data
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        view.selectedCompany = testCompany
        view.companyFormData.name = "Updated Company"
        view.companyFormData.ticker = "UPD"
        view.companyFormData.stage = .phase3
        view.companyFormData.therapeuticArea = "CNS"
        view.companyFormData.description = "Updated description"
        view.companyFormData.cashPosition = 75.0
        view.companyFormData.burnRate = 6.0
        
        view.updateSelectedCompanyData()
        
        // Verify updates
        XCTAssertEqual(view.selectedCompany?.basicInfo.name, "Updated Company")
        XCTAssertEqual(view.selectedCompany?.basicInfo.ticker, "UPD")
        XCTAssertEqual(view.selectedCompany?.basicInfo.stage, .phase3)
        XCTAssertEqual(view.selectedCompany?.basicInfo.therapeuticAreas.first, "CNS")
        XCTAssertEqual(view.selectedCompany?.basicInfo.description, "Updated description")
        XCTAssertEqual(view.selectedCompany?.financials.cashPosition, 75.0)
        XCTAssertEqual(view.selectedCompany?.financials.burnRate, 6.0)
    }
    
    // MARK: - Scoring Assessment Tests
    
    func testScoringCalculation() {
        // Test scoring calculation functionality
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        view.selectedCompany = testCompany
        view.calculateScore()
        
        // Verify scoring result is created
        XCTAssertNotNil(view.scoringResult)
        XCTAssertEqual(view.scoringResult?.companyId, testCompany.id)
        XCTAssertEqual(view.scoringResult?.overallScore, 3.84)
        XCTAssertEqual(view.scoringResult?.investmentRecommendation, .strongBuy)
        XCTAssertEqual(view.scoringResult?.riskLevel, .medium)
    }
    
    func testScoringPillarData() {
        // Test scoring pillar data structure
        let view = CompanyEvaluationView()
        let pillars = view.scoringPillars
        
        XCTAssertEqual(pillars.count, 6)
        
        // Verify pillar names
        let pillarNames = pillars.map { $0.name }
        XCTAssertTrue(pillarNames.contains("Asset Quality"))
        XCTAssertTrue(pillarNames.contains("Market Outlook"))
        XCTAssertTrue(pillarNames.contains("Capital Intensity"))
        XCTAssertTrue(pillarNames.contains("Strategic Fit"))
        XCTAssertTrue(pillarNames.contains("Financial Readiness"))
        XCTAssertTrue(pillarNames.contains("Regulatory Risk"))
        
        // Verify weights sum to 100%
        let totalWeight = pillars.reduce(0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 100)
        
        // Verify score ranges
        for pillar in pillars {
            XCTAssertGreaterThanOrEqual(pillar.score, 1.0)
            XCTAssertLessThanOrEqual(pillar.score, 5.0)
            XCTAssertGreaterThanOrEqual(pillar.confidence, 0.0)
            XCTAssertLessThanOrEqual(pillar.confidence, 1.0)
        }
    }
    
    func testScoringResultStructure() {
        // Test scoring result data structure
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        view.selectedCompany = testCompany
        view.calculateScore()
        
        guard let result = view.scoringResult else {
            XCTFail("Scoring result should not be nil")
            return
        }
        
        // Verify result structure
        XCTAssertEqual(result.companyId, testCompany.id)
        XCTAssertGreaterThan(result.overallScore, 0)
        XCTAssertLessThanOrEqual(result.overallScore, 5.0)
        XCTAssertFalse(result.recommendations.isEmpty)
        XCTAssertGreaterThan(result.confidence.overall, 0)
        XCTAssertLessThanOrEqual(result.confidence.overall, 1.0)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationFlow() {
        // Test complete navigation flow
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        // Start at selection
        XCTAssertEqual(view.evaluationStep, .selection)
        
        // Select company and navigate to basic info
        view.selectedCompany = testCompany
        view.evaluationStep = .basicInfo
        XCTAssertEqual(view.evaluationStep, .basicInfo)
        
        // Navigate to scoring
        view.evaluationStep = .scoring
        XCTAssertEqual(view.evaluationStep, .scoring)
        
        // Test back navigation
        view.navigateBack()
        XCTAssertEqual(view.evaluationStep, .basicInfo)
        
        view.navigateBack()
        XCTAssertEqual(view.evaluationStep, .selection)
        
        // Back from selection should stay at selection
        view.navigateBack()
        XCTAssertEqual(view.evaluationStep, .selection)
    }
    
    func testHeaderTitles() {
        // Test header titles for different steps
        let view = CompanyEvaluationView()
        
        view.evaluationStep = .selection
        XCTAssertEqual(view.headerTitle, "Company Evaluation")
        XCTAssertEqual(view.headerSubtitle, "Choose a company to evaluate or create a new evaluation")
        
        view.evaluationStep = .basicInfo
        XCTAssertEqual(view.headerTitle, "Basic Information")
        XCTAssertEqual(view.headerSubtitle, "Enter fundamental company details")
        
        view.evaluationStep = .scoring
        XCTAssertEqual(view.headerTitle, "Scoring Assessment")
        XCTAssertEqual(view.headerSubtitle, "Assess the company across all scoring pillars")
    }
    
    // MARK: - New Company Form Tests
    
    func testNewCompanyFormCreation() {
        // Test new company form functionality
        let view = CompanyEvaluationView()
        
        // Test showing form
        view.showingNewCompanyForm = true
        XCTAssertTrue(view.showingNewCompanyForm)
        
        // Test form data
        var formData = CompanyFormData()
        formData.name = "New Test Company"
        formData.ticker = "NTC"
        formData.stage = .phase1
        formData.therapeuticArea = "Rare Disease"
        formData.description = "New company description"
        formData.cashPosition = 30.0
        formData.burnRate = 3.0
        
        // Create company from form data
        let newCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(
                name: formData.name,
                ticker: formData.ticker.isEmpty ? nil : formData.ticker,
                sector: "Biotechnology",
                therapeuticAreas: [formData.therapeuticArea],
                stage: formData.stage,
                description: formData.description.isEmpty ? nil : formData.description
            ),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(
                cashPosition: formData.cashPosition,
                burnRate: formData.burnRate,
                lastFunding: nil
            ),
            market: CompanyData.Market(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: CompanyData.MarketDynamics(
                    growthRate: 0,
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
                    timeline: 36,
                    risks: [],
                    mitigations: []
                )
            )
        )
        
        // Verify company creation
        XCTAssertEqual(newCompany.basicInfo.name, "New Test Company")
        XCTAssertEqual(newCompany.basicInfo.ticker, "NTC")
        XCTAssertEqual(newCompany.basicInfo.stage, .phase1)
        XCTAssertEqual(newCompany.basicInfo.therapeuticAreas.first, "Rare Disease")
        XCTAssertEqual(newCompany.financials.cashPosition, 30.0)
        XCTAssertEqual(newCompany.financials.burnRate, 3.0)
    }
    
    // MARK: - Data Validation Tests
    
    func testCompanyDataValidation() {
        // Test company data validation
        let validCompany = createSampleCompany()
        
        // Test valid company
        XCTAssertFalse(validCompany.basicInfo.name.isEmpty)
        XCTAssertNotNil(validCompany.basicInfo.ticker)
        XCTAssertFalse(validCompany.basicInfo.therapeuticAreas.isEmpty)
        XCTAssertGreaterThan(validCompany.financials.cashPosition, 0)
        XCTAssertGreaterThan(validCompany.financials.burnRate, 0)
        
        // Test runway calculation
        let expectedRunway = Int(validCompany.financials.cashPosition / validCompany.financials.burnRate)
        XCTAssertEqual(validCompany.financials.runway, expectedRunway)
    }
    
    func testFormValidationStates() {
        // Test form validation states
        var formData = CompanyFormData()
        
        // Test invalid state (empty name)
        XCTAssertTrue(formData.name.isEmpty)
        
        // Test valid state
        formData.name = "Valid Company"
        formData.cashPosition = 25.0
        formData.burnRate = 2.5
        
        XCTAssertFalse(formData.name.isEmpty)
        XCTAssertGreaterThan(formData.cashPosition, 0)
        XCTAssertGreaterThan(formData.burnRate, 0)
        XCTAssertEqual(formData.runway, 10) // 25/2.5 = 10
    }
    
    // MARK: - Integration Tests
    
    func testCompleteEvaluationWorkflow() {
        // Test complete evaluation workflow
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        // Step 1: Company Selection
        XCTAssertEqual(view.evaluationStep, .selection)
        view.selectedCompany = testCompany
        XCTAssertNotNil(view.selectedCompany)
        
        // Step 2: Basic Info
        view.evaluationStep = .basicInfo
        view.companyFormData.name = testCompany.basicInfo.name
        view.companyFormData.cashPosition = 60.0
        view.companyFormData.burnRate = 5.0
        view.updateSelectedCompanyData()
        
        XCTAssertEqual(view.selectedCompany?.financials.cashPosition, 60.0)
        XCTAssertEqual(view.selectedCompany?.financials.burnRate, 5.0)
        
        // Step 3: Scoring
        view.evaluationStep = .scoring
        view.calculateScore()
        
        XCTAssertNotNil(view.scoringResult)
        XCTAssertEqual(view.scoringResult?.companyId, testCompany.id)
        
        // Verify complete workflow
        XCTAssertEqual(view.evaluationStep, .scoring)
        XCTAssertNotNil(view.selectedCompany)
        XCTAssertNotNil(view.scoringResult)
    }
    
    func testErrorHandling() {
        // Test error handling scenarios
        let view = CompanyEvaluationView()
        
        // Test calculating score without selected company
        view.selectedCompany = nil
        view.calculateScore()
        XCTAssertNil(view.scoringResult)
        
        // Test updating company data without selected company
        view.updateSelectedCompanyData()
        // Should not crash
        
        // Test with invalid form data
        view.companyFormData.name = ""
        view.companyFormData.cashPosition = -10.0
        view.companyFormData.burnRate = 0
        
        // Should handle gracefully
        XCTAssertEqual(view.companyFormData.runway, 0)
    }
    
    // MARK: - Filtering Tests
    
    func testCompanyFiltering() {
        // Test company filtering functionality
        let view = CompanyEvaluationView()
        
        // Test filter by status
        view.selectedFilter = .new
        let newCompanies = view.filteredCompanies
        XCTAssertTrue(newCompanies.allSatisfy { company in
            !company.basicInfo.name.contains("Alpha") && !company.basicInfo.name.contains("Beta")
        })
        
        // Test filter by stage
        view.selectedFilter = .phase2
        let phase2Companies = view.filteredCompanies
        XCTAssertTrue(phase2Companies.allSatisfy { $0.basicInfo.stage == .phase2 })
        
        // Test filter by therapeutic area
        view.selectedFilter = .oncology
        let oncologyCompanies = view.filteredCompanies
        XCTAssertTrue(oncologyCompanies.allSatisfy { $0.basicInfo.therapeuticAreas.contains("Oncology") })
        
        // Test reset to all
        view.selectedFilter = .all
        XCTAssertEqual(view.filteredCompanies.count, view.companies.count)
    }
    
    func testValidationErrors() {
        // Test form validation error handling
        let view = CompanyEvaluationView()
        
        // Test with invalid form data
        view.companyFormData.name = ""
        view.companyFormData.cashPosition = -5.0
        view.companyFormData.burnRate = -2.0
        
        let errors = view.validateFormData()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains("Company name is required"))
        XCTAssertTrue(errors.contains("Cash position cannot be negative"))
        XCTAssertTrue(errors.contains("Burn rate cannot be negative"))
        
        // Test with valid data
        view.companyFormData.name = "Valid Company"
        view.companyFormData.cashPosition = 50.0
        view.companyFormData.burnRate = 5.0
        
        let validErrors = view.validateFormData()
        XCTAssertTrue(validErrors.isEmpty)
    }
    
    func testScoringLoadingState() {
        // Test scoring calculation loading state
        let view = CompanyEvaluationView()
        let testCompany = createSampleCompany()
        
        view.selectedCompany = testCompany
        XCTAssertFalse(view.isCalculatingScore)
        
        view.calculateScore()
        // Note: In real implementation, this would test the loading state
        // but since we have a mock delay, we can't easily test the intermediate state
    }
    
    func testCompanyStatusLogic() {
        // Test company status determination logic
        let view = CompanyEvaluationView()
        
        // Test completed status (contains "Alpha")
        let alphaCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(name: "Alpha Biotech", ticker: nil, sector: "Biotechnology", therapeuticAreas: ["Oncology"], stage: .phase2, description: nil),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(cashPosition: 10.0, burnRate: 1.0, lastFunding: nil),
            market: CompanyData.Market(addressableMarket: 1.0, competitors: [], marketDynamics: CompanyData.MarketDynamics(growthRate: 0.1, barriers: [], drivers: [], reimbursement: .unknown)),
            regulatory: CompanyData.Regulatory(approvals: [], clinicalTrials: [], regulatoryStrategy: CompanyData.RegulatoryStrategy(pathway: .standard, timeline: 24, risks: [], mitigations: []))
        )
        
        let alphaStatus = view.getCompanyStatus(alphaCompany)
        XCTAssertEqual(alphaStatus, .completed)
        
        // Test in-progress status (contains "Beta")
        let betaCompany = CompanyData(
            basicInfo: CompanyData.BasicInfo(name: "Beta Therapeutics", ticker: nil, sector: "Biotechnology", therapeuticAreas: ["CNS"], stage: .phase1, description: nil),
            pipeline: CompanyData.Pipeline(programs: []),
            financials: CompanyData.Financials(cashPosition: 10.0, burnRate: 1.0, lastFunding: nil),
            market: CompanyData.Market(addressableMarket: 1.0, competitors: [], marketDynamics: CompanyData.MarketDynamics(growthRate: 0.1, barriers: [], drivers: [], reimbursement: .unknown)),
            regulatory: CompanyData.Regulatory(approvals: [], clinicalTrials: [], regulatoryStrategy: CompanyData.RegulatoryStrategy(pathway: .standard, timeline: 24, risks: [], mitigations: []))
        )
        
        let betaStatus = view.getCompanyStatus(betaCompany)
        XCTAssertEqual(betaStatus, .inProgress)
        
        // Test new status (default)
        let newCompany = createSampleCompany()
        let newStatus = view.getCompanyStatus(newCompany)
        XCTAssertEqual(newStatus, .new)
    }
    
    // MARK: - Performance Tests
    
    func testSearchPerformance() {
        // Test search performance with large dataset
        let view = CompanyEvaluationView()
        
        // Add many companies
        for i in 0..<1000 {
            let company = CompanyData(
                basicInfo: CompanyData.BasicInfo(
                    name: "Company \(i)",
                    ticker: "C\(i)",
                    sector: "Biotechnology",
                    therapeuticAreas: ["Oncology"],
                    stage: .phase1,
                    description: nil
                ),
                pipeline: CompanyData.Pipeline(programs: []),
                financials: CompanyData.Financials(cashPosition: 10.0, burnRate: 1.0, lastFunding: nil),
                market: CompanyData.Market(addressableMarket: 1.0, competitors: [], marketDynamics: CompanyData.MarketDynamics(growthRate: 0.1, barriers: [], drivers: [], reimbursement: .unknown)),
                regulatory: CompanyData.Regulatory(approvals: [], clinicalTrials: [], regulatoryStrategy: CompanyData.RegulatoryStrategy(pathway: .standard, timeline: 24, risks: [], mitigations: []))
            )
            view.companies.append(company)
        }
        
        // Measure search performance
        measure {
            view.searchText = "Company 500"
            let _ = view.filteredCompanies
        }
    }
}

// MARK: - Test Extensions

extension CompanyEvaluationView {
    // Expose private properties for testing
    var evaluationStep: EvaluationStep {
        get { _evaluationStep.wrappedValue }
        set { _evaluationStep.wrappedValue = newValue }
    }
    
    var selectedCompany: CompanyData? {
        get { _selectedCompany.wrappedValue }
        set { _selectedCompany.wrappedValue = newValue }
    }
    
    var searchText: String {
        get { _searchText.wrappedValue }
        set { _searchText.wrappedValue = newValue }
    }
    
    var showingNewCompanyForm: Bool {
        get { _showingNewCompanyForm.wrappedValue }
        set { _showingNewCompanyForm.wrappedValue = newValue }
    }
    
    var companyFormData: CompanyFormData {
        get { _companyFormData.wrappedValue }
        set { _companyFormData.wrappedValue = newValue }
    }
    
    var scoringResult: ScoringResult? {
        get { _scoringResult.wrappedValue }
        set { _scoringResult.wrappedValue = newValue }
    }
    
    var companies: [CompanyData] {
        get { _companies.wrappedValue }
        set { _companies.wrappedValue = newValue }
    }
    
    var selectedFilter: CompanyFilter {
        get { _selectedFilter.wrappedValue }
        set { _selectedFilter.wrappedValue = newValue }
    }
    
    var isCalculatingScore: Bool {
        get { _isCalculatingScore.wrappedValue }
        set { _isCalculatingScore.wrappedValue = newValue }
    }
    
    var validationErrors: [String] {
        get { _validationErrors.wrappedValue }
        set { _validationErrors.wrappedValue = newValue }
    }
}