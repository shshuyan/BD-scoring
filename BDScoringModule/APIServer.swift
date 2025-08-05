import Foundation

/// Simple HTTP server for BD Scoring Module API (Foundation-based)
public class APIServer {
    
    // MARK: - Properties
    
    private let scoringEngine: BDScoringEngine
    private let apiController: APIController
    private let port: Int
    private var isRunning = false
    
    // MARK: - Initialization
    
    public init(port: Int = 8080) {
        self.port = port
        self.scoringEngine = BDScoringEngine()
        self.apiController = APIController(scoringEngine: scoringEngine)
    }
    
    // MARK: - Server Control
    
    /// Start the API server (placeholder implementation)
    public func start() async throws {
        print("🚀 BD Scoring Module API Server would start on port \(port)")
        print("📚 API Documentation:")
        print(APIDocumentation.overview)
        print("\n🛣️  Available Routes:")
        for (route, description) in APIRoutes.routes {
            print("   \(route) - \(description)")
        }
        print("\n💡 Examples:")
        print(APIDocumentation.examples)
        
        isRunning = true
        print("\n✅ Server simulation started successfully!")
        
        // In a real implementation, this would start an HTTP server
        // For now, we'll just demonstrate the API structure
        await demonstrateAPI()
    }
    
    /// Stop the API server
    public func stop() async throws {
        isRunning = false
        print("🛑 Server stopped")
    }
    
    /// Get the API controller for testing
    public func getAPIController() -> APIController {
        return apiController
    }
    
    // MARK: - API Demonstration
    
    /// Demonstrate API functionality without actual HTTP server
    private func demonstrateAPI() async {
        print("\n🧪 Demonstrating API functionality...")
        
        // Test health check
        let healthResponse = await apiController.healthCheck()
        print("✅ Health Check: \(healthResponse.success ? "Healthy" : "Unhealthy")")
        
        // Test company evaluation
        let testCompany = createTestCompanyData()
        let evaluationRequest = CompanyEvaluationRequest(companyData: testCompany, config: nil)
        let evaluationResponse = await apiController.evaluateCompany(evaluationRequest)
        print("✅ Company Evaluation: \(evaluationResponse.success ? "Success" : "Failed")")
        if evaluationResponse.success, let data = evaluationResponse.data {
            print("   Overall Score: \(data.result.overallScore)")
            print("   Processing Time: \(data.processingTime)s")
        }
        
        // Test configuration management
        let configResponse = await apiController.getConfigurations()
        print("✅ Configuration Management: \(configResponse.success ? "Success" : "Failed")")
        if configResponse.success, let data = configResponse.data {
            print("   Available Configurations: \(data.configurations.count)")
        }
        
        // Test batch evaluation
        let batchRequest = BatchEvaluationRequest(companies: [testCompany], config: nil, options: nil)
        let batchResponse = await apiController.batchEvaluate(batchRequest)
        print("✅ Batch Evaluation: \(batchResponse.success ? "Success" : "Failed")")
        if batchResponse.success, let data = batchResponse.data {
            print("   Processed Companies: \(data.summary.totalCompanies)")
            print("   Success Rate: \(data.summary.successfulEvaluations)/\(data.summary.totalCompanies)")
        }
        
        print("\n🎉 API demonstration completed!")
    }
    
    // MARK: - Helper Methods
    
    private func createTestCompanyData() -> CompanyData {
        return CompanyData(
            id: UUID(),
            basicInfo: BasicInfo(
                name: "Demo Biotech Company",
                ticker: "DEMO",
                sector: "Biotechnology",
                therapeuticAreas: ["Oncology", "Immunology"],
                stage: .phase2,
                description: "A demonstration biotech company for API testing"
            ),
            pipeline: Pipeline(
                programs: [
                    Program(
                        id: UUID(),
                        name: "Demo Program 1",
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

// MARK: - Server Factory

/// Factory for creating configured API server instances
public struct APIServerFactory {
    
    /// Create a production server with full services
    public static func createProductionServer(
        port: Int = 8080,
        dataService: DataService? = nil,
        reportGenerator: ReportGenerator? = nil,
        validationService: ValidationService? = nil
    ) -> APIServer {
        let server = APIServer(port: port)
        
        // Configure with production services if provided
        // This would involve dependency injection setup
        
        return server
    }
    
    /// Create a development server with mock services
    public static func createDevelopmentServer(port: Int = 8080) -> APIServer {
        let server = APIServer(port: port)
        
        // Configure with development/mock services
        
        return server
    }
    
    /// Create a test server for integration testing
    public static func createTestServer() -> APIServer {
        let server = APIServer(port: 0) // Use random available port for testing
        
        return server
    }
}

// MARK: - CLI Support

/// Command-line interface for running the API server
public struct APIServerCLI {
    
    public static func main() async {
        print("🚀 Starting BD Scoring Module API Server...")
        
        do {
            let server = APIServer()
            
            // Handle graceful shutdown
            let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            signalSource.setEventHandler {
                print("\n🛑 Shutting down server...")
                Task {
                    try await server.stop()
                    exit(0)
                }
            }
            signalSource.resume()
            signal(SIGINT, SIG_IGN)
            
            // Start server
            try await server.start()
            
            // Keep the server running
            while true {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
            }
            
        } catch {
            print("❌ Failed to start server: \(error)")
            exit(1)
        }
    }
}

// MARK: - API Information

/// API information and metadata
public struct APIInfo: Codable {
    let name: String
    let version: String
    let description: String
    let endpoints: [String]
    
    public static let current = APIInfo(
        name: "BD & IPO Scoring Module API",
        version: "1.0.0",
        description: "REST API for biotech company scoring and evaluation",
        endpoints: Array(APIRoutes.routes.keys)
    )
}