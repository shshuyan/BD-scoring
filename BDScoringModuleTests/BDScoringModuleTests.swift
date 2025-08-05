import XCTest
@testable import BDScoringModule

final class BDScoringModuleTests: XCTestCase {
    
    func testCompanyDataCreation() {
        // Test basic company data creation
        let basicInfo = CompanyData.BasicInfo(
            name: "Test Biotech",
            ticker: "TBIO",
            sector: "Biotechnology",
            therapeuticAreas: ["Oncology"],
            stage: .phase2,
            description: "Test company for unit testing"
        )
        
        let pipeline = CompanyData.Pipeline(programs: [])
        let financials = CompanyData.Financials(cashPosition: 100.0, burnRate: 5.0, lastFunding: nil)
        let market = CompanyData.Market(
            addressableMarket: 10.0,
            competitors: [],
            marketDynamics: MarketDynamics(
                growthRate: 0.15,
                barriers: [],
                drivers: [],
                reimbursement: .moderate
            )
        )
        let regulatory = CompanyData.Regulatory(
            approvals: [],
            clinicalTrials: [],
            regulatoryStrategy: RegulatoryStrategy(
                pathway: .standard,
                timeline: 36,
                risks: [],
                mitigations: []
            )
        )
        
        let company = CompanyData(
            basicInfo: basicInfo,
            pipeline: pipeline,
            financials: financials,
            market: market,
            regulatory: regulatory
        )
        
        XCTAssertEqual(company.basicInfo.name, "Test Biotech")
        XCTAssertEqual(company.basicInfo.stage, .phase2)
        XCTAssertEqual(company.financials.runway, 20) // 100/5 = 20 months
    }
    
    func testWeightConfigValidation() {
        var weights = WeightConfig()
        XCTAssertTrue(weights.isValid, "Default weights should be valid")
        
        // Test invalid weights
        weights.assetQuality = 0.5
        XCTAssertFalse(weights.isValid, "Modified weights should be invalid")
        
        // Test normalization
        weights.normalize()
        XCTAssertTrue(weights.isValid, "Normalized weights should be valid")
    }
    
    func testScoringResultCreation() {
        let pillarScore = PillarScore(
            rawScore: 4.0,
            confidence: 0.8,
            factors: [],
            warnings: []
        )
        
        let pillarScores = PillarScores(
            assetQuality: pillarScore,
            marketOutlook: pillarScore,
            capitalIntensity: pillarScore,
            strategicFit: pillarScore,
            financialReadiness: pillarScore,
            regulatoryRisk: pillarScore
        )
        
        let weightedScores = WeightedScores(
            assetQuality: 1.0,
            marketOutlook: 0.8,
            capitalIntensity: 0.6,
            strategicFit: 0.8,
            financialReadiness: 0.4,
            regulatoryRisk: 0.4
        )
        
        let confidence = ConfidenceMetrics(
            overall: 0.8,
            dataCompleteness: 0.9,
            modelAccuracy: 0.75,
            comparableQuality: 0.8
        )
        
        let result = ScoringResult(
            companyId: UUID(),
            overallScore: 4.0,
            pillarScores: pillarScores,
            weightedScores: weightedScores,
            confidence: confidence,
            recommendations: ["Strong investment opportunity"],
            timestamp: Date(),
            investmentRecommendation: .strongBuy,
            riskLevel: .medium
        )
        
        XCTAssertEqual(result.overallScore, 4.0)
        XCTAssertEqual(result.investmentRecommendation, .strongBuy)
        XCTAssertEqual(result.riskLevel, .medium)
    }
}