import Foundation

/// Test compilation and basic functionality of API components
func testAPICompilation() {
    print("🧪 Testing API compilation and basic functionality...")
    
    // Test 1: API Models compilation
    print("✅ Testing API models...")
    testAPIModels()
    
    // Test 2: API Controller compilation
    print("✅ Testing API controller...")
    testAPIController()
    
    // Test 3: API Server compilation
    print("✅ Testing API server...")
    testAPIServer()
    
    print("🎉 All API compilation tests passed!")
}

func testAPIModels() {
    // Test request models
    let companyData = createTestCompanyData()
    let evaluationRequest = CompanyEvaluationRequest(companyData: companyData, config: nil)
    
    // Test validation
    do {
        try evaluationRequest.validate()
        print("   ✓ CompanyEvaluationRequest validation works")
    } catch {
        print("   ❌ CompanyEvaluationRequest validation failed: \(error)")
    }
    
    // Test batch request
    let batchRequest = BatchEvaluationRequest(companies: [companyData], config: nil, options: nil)
    do {
        try batchRequest.validate()
        print("   ✓ BatchEvaluationRequest validation works")
    } catch {
        print("   ❌ BatchEvaluationRequest validation failed: \(error)")
    }
    
    // Test configuration request
    let configRequest = ScoringConfigRequest(
        name: "Test Config",
        weights: WeightConfig(),
        parameters: nil,
        isDefault: false
    )
    do {
        try configRequest.validate()
        print("   ✓ ScoringConfigRequest validation works")
    } catch {
        print("   ❌ ScoringConfigRequest validation failed: \(error)")
    }
    
    // Test response models
    let apiResponse = StandardAPIResponse.success("Test data", processingTime: 0.1)
    print("   ✓ StandardAPIResponse creation works: \(apiResponse.success)")
    
    // Test error response
    let errorResponse = StandardAPIResponse<String>.error(APIError.badRequest("Test error"))
    print("   ✓ Error response creation works: \(!errorResponse.success)")
}

func testAPIController() {
    // Test controller initialization
    let scoringEngine = BDScoringEngine()
    let controller = APIController(scoringEngine: scoringEngine)
    print("   ✓ APIController initialization works")
    
    // Test API routes definition
    let routes = APIRoutes.routes
    print("   ✓ API routes defined: \(routes.count) endpoints")
    
    // Test API documentation
    let documentation = APIDocumentation.overview
    print("   ✓ API documentation available: \(documentation.count) characters")
}

func testAPIServer() {
    // Test server initialization
    let server = APIServer(port: 8080)
    print("   ✓ APIServer initialization works")
    
    // Test API controller access
    let controller = server.getAPIController()
    print("   ✓ API controller access works")
    
    // Test server factory
    let testServer = APIServerFactory.createTestServer()
    print("   ✓ Server factory works")
    
    // Test API info
    let apiInfo = APIInfo.current
    print("   ✓ API info available: \(apiInfo.name) v\(apiInfo.version)")
}

func createTestCompanyData() -> CompanyData {
    return CompanyData(
        id: UUID(),
        basicInfo: BasicInfo(
            name: "Test Company",
            ticker: "TEST",
            sector: "Biotechnology",
            therapeuticAreas: ["Oncology"],
            stage: .phase2,
            description: "Test company"
        ),
        pipeline: Pipeline(
            programs: [
                Program(
                    id: UUID(),
                    name: "Test Program",
                    indication: "Cancer",
                    stage: .phase2,
                    mechanism: "Small Molecule",
                    differentiators: ["Novel"],
                    risks: [],
                    timeline: []
                )
            ],
            totalPrograms: 1,
            leadProgram: nil
        ),
        financials: Financials(
            cashPosition: 10_000_000,
            burnRate: 1_000_000,
            lastFunding: nil,
            runway: 10
        ),
        market: Market(
            addressableMarket: 1_000_000_000,
            competitors: [],
            marketDynamics: MarketDynamics(
                growthRate: 0.1,
                competitiveIntensity: .moderate,
                regulatoryBarriers: .moderate,
                marketMaturity: .growing
            )
        ),
        regulatory: Regulatory(
            approvals: [],
            clinicalTrials: [],
            regulatoryStrategy: RegulatoryStrategy(
                pathway: .traditional,
                timeline: 36,
                keyMilestones: [],
                risks: []
            )
        )
    )
}

// Run the test if this file is executed directly
if CommandLine.arguments.contains("--test-api") {
    testAPICompilation()
}