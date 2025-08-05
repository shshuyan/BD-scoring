import XCTest
@testable import BDScoringModule

/// Integration tests for API endpoints
final class APIControllerTests: XCTestCase {
    
    // MARK: - Properties
    
    var scoringEngine: BDScoringEngine!
    var apiController: APIController!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize services
        scoringEngine = BDScoringEngine()
        apiController = APIController(scoringEngine: scoringEngine)
    }
    
    override func tearDownWithError() throws {
        // Clean up
        scoringEngine = nil
        apiController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Health Check Tests
    
    func testHealthCheck() async throws {
        let response = await apiController.healthCheck()
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        XCTAssertEqual(response.data?.status, "healthy")
        XCTAssertEqual(response.data?.version, "1.0.0")
        XCTAssertNotNil(response.data?.uptime)
        XCTAssertFalse(response.data?.dependencies.isEmpty ?? true)
    }
    
    // MARK: - Company Evaluation Tests
    
    func testEvaluateCompany_Success() async throws {
        let companyData = createTestCompanyData()
        let request = CompanyEvaluationRequest(companyData: companyData, config: nil)
        
        let response = await apiController.evaluateCompany(request)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        
        let evaluationResponse = response.data!
        XCTAssertEqual(evaluationResponse.result.companyId, companyData.id)
        XCTAssertGreaterThan(evaluationResponse.result.overallScore, 0)
        XCTAssertLessThanOrEqual(evaluationResponse.result.overallScore, 5)
        XCTAssertNotNil(evaluationResponse.insights)
        XCTAssertFalse(evaluationResponse.recommendations.isEmpty)
        XCTAssertGreaterThan(evaluationResponse.processingTime, 0)
    }
    
    func testEvaluateCompany_InvalidData() async throws {
        let invalidCompanyData = CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: "", // Invalid: empty name
                ticker: nil,
                sector: "Biotechnology",
                therapeuticAreas: [],
                stage: .preclinical,
                description: nil
            ),
            pipeline: Pipeline(programs: [], totalPrograms: 0, leadProgram: nil),
            financials: Financials(
                cashPosition: 0,
                burnRate: 0,
                lastFunding: nil,
                runway: 0
            ),
            market: Market(
                addressableMarket: 0,
                competitors: [],
                marketDynamics: MarketDynamics(
                    growthRate: 0,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .emerging
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 0,
                    keyMilestones: [],
                    risks: []
                )
            )
        )
        
        let request = CompanyEvaluationRequest(companyData: invalidCompanyData, config: nil)
        let response = await apiController.evaluateCompany(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Company name is required"))
    }
    
    func testEvaluateCompany_WithCustomConfig() async throws {
        let companyData = createTestCompanyData()
        let customWeights = WeightConfig(
            assetQuality: 0.4,
            marketOutlook: 0.3,
            capitalIntensity: 0.1,
            strategicFit: 0.1,
            financialReadiness: 0.05,
            regulatoryRisk: 0.05
        )
        let customConfig = ScoringConfig(
            name: "Custom Test Config",
            weights: customWeights,
            parameters: ScoringParameters()
        )
        let request = CompanyEvaluationRequest(companyData: companyData, config: customConfig)
        
        let response = await apiController.evaluateCompany(request)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
    }
    
    // MARK: - Batch Evaluation Tests
    
    func testBatchEvaluate_Success() async throws {
        let companies = [
            createTestCompanyData(name: "Company A"),
            createTestCompanyData(name: "Company B"),
            createTestCompanyData(name: "Company C")
        ]
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let response = await apiController.batchEvaluate(request)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        
        let batchResponse = response.data!
        XCTAssertNotNil(batchResponse.jobId)
        XCTAssertEqual(batchResponse.status, .completed)
        XCTAssertEqual(batchResponse.results.count, 3)
        XCTAssertTrue(batchResponse.errors.isEmpty)
        XCTAssertEqual(batchResponse.summary.totalCompanies, 3)
        XCTAssertEqual(batchResponse.summary.successfulEvaluations, 3)
        XCTAssertEqual(batchResponse.summary.failedEvaluations, 0)
        XCTAssertNotNil(batchResponse.summary.averageScore)
        XCTAssertNotNil(batchResponse.summary.averageConfidence)
    }
    
    func testBatchEvaluate_EmptyList() async throws {
        let request = BatchEvaluationRequest(companies: [], config: nil, options: nil)
        
        let response = await apiController.batchEvaluate(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("At least one company is required"))
    }
    
    func testBatchEvaluate_TooManyCompanies() async throws {
        let companies = Array(repeating: createTestCompanyData(), count: 101)
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let response = await apiController.batchEvaluate(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Maximum 100 companies allowed"))
    }
    
    func testBatchEvaluate_WithOptions() async throws {
        let companies = [createTestCompanyData()]
        let options = BatchOptions(
            continueOnError: true,
            maxConcurrency: 2,
            notifyOnCompletion: false,
            webhookUrl: nil
        )
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: options)
        
        let response = await apiController.batchEvaluate(request)
        
        XCTAssertTrue(response.success)
    }
    
    // MARK: - Configuration Management Tests
    
    func testGetConfigurations() async throws {
        let response = await apiController.getConfigurations()
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        
        let configResponse = response.data!
        XCTAssertFalse(configResponse.configurations.isEmpty)
        XCTAssertNotNil(configResponse.defaultConfiguration)
        XCTAssertTrue(configResponse.defaultConfiguration!.isDefault)
    }
    
    func testCreateConfiguration_Success() async throws {
        let weights = WeightConfig(
            assetQuality: 0.3,
            marketOutlook: 0.25,
            capitalIntensity: 0.15,
            strategicFit: 0.15,
            financialReadiness: 0.1,
            regulatoryRisk: 0.05
        )
        let request = ScoringConfigRequest(
            name: "Test Configuration",
            weights: weights,
            parameters: nil,
            isDefault: false
        )
        
        let response = await apiController.createConfiguration(request)
        
        XCTAssertTrue(response.success)
        XCTAssertNotNil(response.data)
        
        let config = response.data!
        XCTAssertEqual(config.name, "Test Configuration")
        XCTAssertEqual(config.weights.assetQuality, 0.3)
        XCTAssertFalse(config.isDefault)
    }
    
    func testCreateConfiguration_InvalidWeights() async throws {
        let invalidWeights = WeightConfig(
            assetQuality: 0.5,
            marketOutlook: 0.5,
            capitalIntensity: 0.5, // Total > 1.0
            strategicFit: 0.5,
            financialReadiness: 0.5,
            regulatoryRisk: 0.5
        )
        let request = ScoringConfigRequest(
            name: "Invalid Configuration",
            weights: invalidWeights,
            parameters: nil,
            isDefault: false
        )
        
        let response = await apiController.createConfiguration(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Invalid weight configuration"))
    }
    
    func testCreateConfiguration_EmptyName() async throws {
        let request = ScoringConfigRequest(
            name: "",
            weights: WeightConfig(),
            parameters: nil,
            isDefault: false
        )
        
        let response = await apiController.createConfiguration(request)
        
        XCTAssertFalse(response.success)
        XCTAssertNotNil(response.error)
        XCTAssertTrue(response.error!.message.contains("Configuration name is required"))
    }
    
    // MARK: - Error Handling Tests
    
    func testAPIErrorHandling() async throws {
        // Test API error creation and handling
        let validationError = APIError.validationError("Test validation error")
        XCTAssertEqual(validationError.httpStatusCode, 400)
        
        let notFoundError = APIError.notFound("Test not found error")
        XCTAssertEqual(notFoundError.httpStatusCode, 404)
        
        let internalError = APIError.internalError("Test internal error")
        XCTAssertEqual(internalError.httpStatusCode, 500)
    }
    
    func testAPIResponseErrorHandling() async throws {
        // Test error response creation
        let error = APIError.badRequest("Test bad request")
        let errorResponse = StandardAPIResponse<String>.error(error)
        
        XCTAssertFalse(errorResponse.success)
        XCTAssertNotNil(errorResponse.error)
        XCTAssertEqual(errorResponse.error?.code, "400")
        XCTAssertTrue(errorResponse.error?.message.contains("Test bad request") ?? false)
    }
    
    // MARK: - Performance Tests
    
    func testEvaluateCompany_Performance() async throws {
        let companyData = createTestCompanyData()
        let request = CompanyEvaluationRequest(companyData: companyData, config: nil)
        
        let startTime = Date()
        let response = await apiController.evaluateCompany(request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(response.success)
        XCTAssertLessThan(processingTime, 5.0, "API response should be under 5 seconds")
        XCTAssertNotNil(response.metadata?.processingTime)
    }
    
    func testBatchEvaluate_Performance() async throws {
        let companies = Array(repeating: createTestCompanyData(), count: 10)
        let request = BatchEvaluationRequest(companies: companies, config: nil, options: nil)
        
        let startTime = Date()
        let response = await apiController.batchEvaluate(request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(response.success)
        XCTAssertLessThan(processingTime, 30.0, "Batch processing should be under 30 seconds for 10 companies")
        XCTAssertEqual(response.data?.results.count, 10)
    }
    
    // MARK: - Concurrent Request Tests
    
    func testConcurrentRequests() async throws {
        let companyData = createTestCompanyData()
        let request = CompanyEvaluationRequest(companyData: companyData, config: nil)
        
        // Make 5 concurrent requests
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let response = await self.apiController.evaluateCompany(request)
                    XCTAssertTrue(response.success, "Request \(i) should succeed")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestCompanyData(name: String = "Test Biotech Company") -> CompanyData {
        return CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: name,
                ticker: "TEST",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "A test biotech company for API testing"
            ),
            pipeline: Pipeline(
                programs: [
                    Program(
                        id: UUID(),
                        name: "Test Program 1",
                        indication: "Cancer",
                        stage: .phase2,
                        mechanism: "Monoclonal Antibody",
                        differentiators: ["Novel target", "Best-in-class"],
                        risks: [
                            Risk(
                                category: "Clinical",
                                description: "Phase 2 trial risk",
                                probability: .medium,
                                impact: .high,
                                mitigation: "Robust trial design"
                            )
                        ],
                        timeline: [
                            Milestone(
                                name: "Phase 2 Completion",
                                date: Calendar.current.date(byAdding: .month, value: 18, to: Date())!,
                                description: "Complete Phase 2 clinical trial"
                            )
                        ]
                    )
                ],
                totalPrograms: 1,
                leadProgram: nil
            ),
            financials: Financials(
                cashPosition: 50_000_000,
                burnRate: 2_000_000,
                lastFunding: FundingRound(
                    type: .seriesB,
                    amount: 75_000_000,
                    date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                    investors: ["VC Fund A", "VC Fund B"],
                    valuation: 300_000_000
                ),
                runway: 25
            ),
            market: Market(
                addressableMarket: 5_000_000_000,
                competitors: [
                    Competitor(
                        name: "Big Pharma Co",
                        stage: .marketed,
                        marketShare: 0.3,
                        strengths: ["Established presence"],
                        weaknesses: ["Old technology"]
                    )
                ],
                marketDynamics: MarketDynamics(
                    growthRate: 0.15,
                    competitiveIntensity: .moderate,
                    regulatoryBarriers: .moderate,
                    marketMaturity: .growing
                )
            ),
            regulatory: Regulatory(
                approvals: [],
                clinicalTrials: [
                    ClinicalTrial(
                        id: "NCT12345678",
                        phase: .phase2,
                        status: .active,
                        indication: "Cancer",
                        patientCount: 200,
                        startDate: Calendar.current.date(byAdding: .month, value: -12, to: Date())!,
                        estimatedCompletion: Calendar.current.date(byAdding: .month, value: 18, to: Date())!
                    )
                ],
                regulatoryStrategy: RegulatoryStrategy(
                    pathway: .traditional,
                    timeline: 60,
                    keyMilestones: ["IND Filing", "Phase 2 Start", "Phase 3 Start"],
                    risks: ["Regulatory delay"]
                )
            )
        )
    }
}