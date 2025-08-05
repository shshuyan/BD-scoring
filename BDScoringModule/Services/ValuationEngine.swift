import Foundation

// MARK: - Valuation Engine Protocol

protocol ValuationEngine {
    /// Calculate valuation based on comparable transactions
    func calculateValuation(company: CompanyData, comparables: [Comparable]) async throws -> ValuationResult
    
    /// Generate multiple valuation scenarios
    func generateScenarios(baseValuation: Double, company: CompanyData, marketConditions: MarketConditions) -> [ValuationScenario]
    
    /// Calculate valuation using specific methodology
    func calculateValuationByMethodology(company: CompanyData, comparables: [Comparable], methodology: ValuationMethodology) -> ValuationCalculation
    
    /// Get confidence level for valuation estimate
    func calculateValuationConfidence(comparables: [Comparable], company: CompanyData) -> Double
    
    /// Generate valuation summary report
    func generateValuationSummary(result: ValuationResult) -> ValuationSummary
}

// MARK: - Valuation Models

struct ValuationResult: Codable, Identifiable {
    let id = UUID()
    var companyId: UUID
    var baseValuation: Double // in millions USD
    var scenarios: [ValuationScenario]
    var comparables: [ComparableMatch]
    var methodology: ValuationMethodology
    var confidence: Double // 0-1 scale
    var keyDrivers: [ValuationDriver]
    var risks: [ValuationRisk]
    var assumptions: [String]
    var timestamp: Date
    
    /// Get valuation range from scenarios
    var valuationRange: ClosedRange<Double> {
        let values = scenarios.map(\.valuation)
        guard !values.isEmpty else { return baseValuation...baseValuation }
        return values.min()!...values.max()!
    }
    
    /// Get probability-weighted valuation
    var probabilityWeightedValuation: Double {
        scenarios.reduce(0.0) { $0 + ($1.valuation * $1.probability) }
    }
}

enum ValuationMethodology: String, CaseIterable, Codable {
    case comparableTransactions = "Comparable Transactions"
    case discountedCashFlow = "Discounted Cash Flow"
    case riskAdjustedNPV = "Risk-Adjusted NPV"
    case marketMultiples = "Market Multiples"
    case optionValuation = "Real Options"
    case hybrid = "Hybrid Approach"
    
    var description: String {
        switch self {
        case .comparableTransactions:
            return "Values company based on similar transaction multiples"
        case .discountedCashFlow:
            return "Present value of projected cash flows"
        case .riskAdjustedNPV:
            return "NPV adjusted for development and commercial risks"
        case .marketMultiples:
            return "Trading multiples of comparable public companies"
        case .optionValuation:
            return "Real options approach for development programs"
        case .hybrid:
            return "Combination of multiple valuation approaches"
        }
    }
}

struct ValuationScenario: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var valuation: Double // in millions USD
    var probability: Double // 0-1 scale
    var keyAssumptions: [String]
    var marketConditions: ScenarioMarketConditions
    var exitStrategy: ExitStrategy
    var timeline: Int // months to exit
    
    /// Risk-adjusted valuation
    var riskAdjustedValuation: Double {
        valuation * probability
    }
}

enum ExitStrategy: String, CaseIterable, Codable {
    case acquisition = "Acquisition"
    case ipo = "IPO"
    case licensing = "Licensing"
    case partnership = "Strategic Partnership"
    case merger = "Merger"
    
    var typicalMultiples: ClosedRange<Double> {
        switch self {
        case .acquisition: return 3.0...8.0
        case .ipo: return 2.0...6.0
        case .licensing: return 1.5...4.0
        case .partnership: return 2.0...5.0
        case .merger: return 2.5...7.0
        }
    }
}

struct ScenarioMarketConditions: Codable {
    var biotechSentiment: MarketSentiment
    var fundingAvailability: FundingAvailability
    var regulatoryEnvironment: RegulatoryEnvironment
    var competitivePressure: CompetitivePressure
    
    /// Overall market attractiveness score (0-1)
    var attractivenessScore: Double {
        let sentimentScore = biotechSentiment.score
        let fundingScore = fundingAvailability.score
        let regulatoryScore = regulatoryEnvironment.score
        let competitiveScore = 1.0 - competitivePressure.score // Inverse for competitive pressure
        
        return (sentimentScore + fundingScore + regulatoryScore + competitiveScore) / 4.0
    }
}

enum MarketSentiment: String, CaseIterable, Codable {
    case bullish = "Bullish"
    case neutral = "Neutral"
    case bearish = "Bearish"
    
    var score: Double {
        switch self {
        case .bullish: return 1.0
        case .neutral: return 0.6
        case .bearish: return 0.2
        }
    }
    
    var multiplier: Double {
        switch self {
        case .bullish: return 1.3
        case .neutral: return 1.0
        case .bearish: return 0.7
        }
    }
}

enum FundingAvailability: String, CaseIterable, Codable {
    case abundant = "Abundant"
    case moderate = "Moderate"
    case scarce = "Scarce"
    
    var score: Double {
        switch self {
        case .abundant: return 1.0
        case .moderate: return 0.6
        case .scarce: return 0.2
        }
    }
}

enum RegulatoryEnvironment: String, CaseIterable, Codable {
    case supportive = "Supportive"
    case stable = "Stable"
    case restrictive = "Restrictive"
    
    var score: Double {
        switch self {
        case .supportive: return 1.0
        case .stable: return 0.7
        case .restrictive: return 0.3
        }
    }
}

enum CompetitivePressure: String, CaseIterable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    var score: Double {
        switch self {
        case .low: return 0.2
        case .moderate: return 0.6
        case .high: return 1.0
        }
    }
}

struct ValuationDriver: Codable, Identifiable {
    let id = UUID()
    var name: String
    var impact: DriverImpact
    var description: String
    var quantifiedImpact: Double? // Impact on valuation in millions
    var confidence: Double // 0-1 scale
}

enum DriverImpact: String, CaseIterable, Codable {
    case veryPositive = "Very Positive"
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
    case veryNegative = "Very Negative"
    
    var multiplier: Double {
        switch self {
        case .veryPositive: return 1.5
        case .positive: return 1.2
        case .neutral: return 1.0
        case .negative: return 0.8
        case .veryNegative: return 0.6
        }
    }
    
    var color: String {
        switch self {
        case .veryPositive: return "darkGreen"
        case .positive: return "green"
        case .neutral: return "gray"
        case .negative: return "orange"
        case .veryNegative: return "red"
        }
    }
}

struct ValuationRisk: Codable, Identifiable {
    let id = UUID()
    var name: String
    var category: RiskCategory
    var probability: Double // 0-1 scale
    var impact: Double // Impact on valuation as percentage
    var mitigation: String?
    var timeframe: RiskTimeframe
}

enum RiskCategory: String, CaseIterable, Codable {
    case clinical = "Clinical"
    case regulatory = "Regulatory"
    case commercial = "Commercial"
    case financial = "Financial"
    case competitive = "Competitive"
    case operational = "Operational"
    case market = "Market"
}

enum RiskTimeframe: String, CaseIterable, Codable {
    case immediate = "Immediate (0-6 months)"
    case nearTerm = "Near-term (6-18 months)"
    case mediumTerm = "Medium-term (1-3 years)"
    case longTerm = "Long-term (3+ years)"
}

struct ValuationCalculation: Codable {
    var methodology: ValuationMethodology
    var baseValue: Double
    var adjustments: [ValuationAdjustment]
    var finalValue: Double
    var confidence: Double
    var assumptions: [String]
    var limitations: [String]
}

struct ValuationAdjustment: Codable, Identifiable {
    let id = UUID()
    var name: String
    var amount: Double // Can be positive or negative
    var rationale: String
    var confidence: Double
}

// MARK: - Default Implementation

class DefaultValuationEngine: ValuationEngine {
    
    // MARK: - Properties
    
    private let comparablesService: ComparablesService
    
    // MARK: - Initialization
    
    init(comparablesService: ComparablesService = DefaultComparablesService()) {
        self.comparablesService = comparablesService
    }
    
    // MARK: - Public Methods
    
    func calculateValuation(company: CompanyData, comparables: [Comparable]) async throws -> ValuationResult {
        // Find best matching comparables if not provided
        let matchingComparables: [ComparableMatch]
        if comparables.isEmpty {
            let searchResult = try await comparablesService.findComparablesForCompany(company, maxResults: 10)
            matchingComparables = searchResult.comparables
        } else {
            matchingComparables = comparables.map { comparable in
                ComparableMatch(
                    comparable: comparable,
                    similarity: comparablesService.calculateSimilarity(company: company, comparable: comparable),
                    matchingFactors: MatchingFactors(
                        therapeuticAreaMatch: 0.8,
                        stageMatch: 0.8,
                        marketSizeMatch: 0.7,
                        mechanismMatch: 0.6,
                        competitivePositionMatch: 0.7,
                        timeRelevance: 0.8,
                        financialSimilarity: 0.6
                    ),
                    confidence: comparable.confidence
                )
            }
        }
        
        // Calculate base valuation using comparable transactions
        let baseValuation = calculateComparableTransactionValuation(company: company, comparables: matchingComparables)
        
        // Generate scenarios
        let marketConditions = createDefaultMarketConditions()
        let scenarios = generateScenarios(baseValuation: baseValuation.finalValue, company: company, marketConditions: marketConditions)
        
        // Calculate confidence
        let confidence = calculateValuationConfidence(comparables: matchingComparables.map(\.comparable), company: company)
        
        // Identify key drivers and risks
        let keyDrivers = identifyValuationDrivers(company: company, comparables: matchingComparables)
        let risks = identifyValuationRisks(company: company)
        
        return ValuationResult(
            companyId: company.id,
            baseValuation: baseValuation.finalValue,
            scenarios: scenarios,
            comparables: matchingComparables,
            methodology: .comparableTransactions,
            confidence: confidence,
            keyDrivers: keyDrivers,
            risks: risks,
            assumptions: baseValuation.assumptions,
            timestamp: Date()
        )
    }
    
    func generateScenarios(baseValuation: Double, company: CompanyData, marketConditions: MarketConditions) -> [ValuationScenario] {
        var scenarios: [ValuationScenario] = []
        
        // Bear Case Scenario
        let bearConditions = ScenarioMarketConditions(
            biotechSentiment: .bearish,
            fundingAvailability: .scarce,
            regulatoryEnvironment: .restrictive,
            competitivePressure: .high
        )
        
        scenarios.append(ValuationScenario(
            name: "Bear Case",
            description: "Conservative scenario with challenging market conditions",
            valuation: baseValuation * 0.6,
            probability: 0.2,
            keyAssumptions: [
                "Delayed clinical timelines",
                "Increased competition",
                "Challenging funding environment",
                "Conservative market penetration"
            ],
            marketConditions: bearConditions,
            exitStrategy: .licensing,
            timeline: 48
        ))
        
        // Base Case Scenario
        let baseConditions = ScenarioMarketConditions(
            biotechSentiment: .neutral,
            fundingAvailability: .moderate,
            regulatoryEnvironment: .stable,
            competitivePressure: .moderate
        )
        
        scenarios.append(ValuationScenario(
            name: "Base Case",
            description: "Most likely scenario based on current market conditions",
            valuation: baseValuation,
            probability: 0.5,
            keyAssumptions: [
                "On-track clinical development",
                "Stable regulatory environment",
                "Moderate market competition",
                "Expected market penetration"
            ],
            marketConditions: baseConditions,
            exitStrategy: .acquisition,
            timeline: 36
        ))
        
        // Bull Case Scenario
        let bullConditions = ScenarioMarketConditions(
            biotechSentiment: .bullish,
            fundingAvailability: .abundant,
            regulatoryEnvironment: .supportive,
            competitivePressure: .low
        )
        
        scenarios.append(ValuationScenario(
            name: "Bull Case",
            description: "Optimistic scenario with favorable market conditions",
            valuation: baseValuation * 1.8,
            probability: 0.2,
            keyAssumptions: [
                "Accelerated clinical success",
                "First-mover advantage",
                "Strong funding environment",
                "Premium market positioning"
            ],
            marketConditions: bullConditions,
            exitStrategy: .ipo,
            timeline: 24
        ))
        
        // IPO-Specific Scenario
        if company.basicInfo.stage == .phase3 || company.basicInfo.stage == .approved {
            scenarios.append(ValuationScenario(
                name: "IPO Scenario",
                description: "Public offering scenario for late-stage companies",
                valuation: baseValuation * 1.3,
                probability: 0.1,
                keyAssumptions: [
                    "Successful Phase 3 completion",
                    "Strong IPO market conditions",
                    "Institutional investor interest",
                    "Revenue visibility"
                ],
                marketConditions: baseConditions,
                exitStrategy: .ipo,
                timeline: 18
            ))
        }
        
        return scenarios
    }
    
    func calculateValuationByMethodology(company: CompanyData, comparables: [Comparable], methodology: ValuationMethodology) -> ValuationCalculation {
        switch methodology {
        case .comparableTransactions:
            return calculateComparableTransactionValuation(
                company: company,
                comparables: comparables.map { comparable in
                    ComparableMatch(
                        comparable: comparable,
                        similarity: 0.8,
                        matchingFactors: MatchingFactors(
                            therapeuticAreaMatch: 0.8,
                            stageMatch: 0.8,
                            marketSizeMatch: 0.7,
                            mechanismMatch: 0.6,
                            competitivePositionMatch: 0.7,
                            timeRelevance: 0.8,
                            financialSimilarity: 0.6
                        ),
                        confidence: comparable.confidence
                    )
                }
            )
        case .riskAdjustedNPV:
            return calculateRiskAdjustedNPV(company: company)
        case .marketMultiples:
            return calculateMarketMultiples(company: company, comparables: comparables)
        default:
            // Default to comparable transactions for other methodologies
            return calculateComparableTransactionValuation(
                company: company,
                comparables: comparables.map { comparable in
                    ComparableMatch(
                        comparable: comparable,
                        similarity: 0.8,
                        matchingFactors: MatchingFactors(
                            therapeuticAreaMatch: 0.8,
                            stageMatch: 0.8,
                            marketSizeMatch: 0.7,
                            mechanismMatch: 0.6,
                            competitivePositionMatch: 0.7,
                            timeRelevance: 0.8,
                            financialSimilarity: 0.6
                        ),
                        confidence: comparable.confidence
                    )
                }
            )
        }
    }
    
    func calculateValuationConfidence(comparables: [Comparable], company: CompanyData) -> Double {
        guard !comparables.isEmpty else { return 0.3 }
        
        // Base confidence from comparable quality
        let averageComparableConfidence = comparables.map(\.confidence).reduce(0, +) / Double(comparables.count)
        
        // Adjust for number of comparables
        let countAdjustment = min(1.0, Double(comparables.count) / 5.0) * 0.2
        
        // Adjust for recency of comparables
        let averageAge = comparables.map(\.ageInYears).reduce(0, +) / Double(comparables.count)
        let recencyAdjustment = max(0, 1.0 - (averageAge / 5.0)) * 0.2
        
        // Adjust for company data completeness
        let dataCompleteness = calculateCompanyDataCompleteness(company)
        let dataAdjustment = dataCompleteness * 0.2
        
        // Adjust for market size and stage maturity
        let stageAdjustment = getStageConfidenceAdjustment(company.basicInfo.stage) * 0.1
        
        let totalConfidence = averageComparableConfidence * 0.5 + countAdjustment + recencyAdjustment + dataAdjustment + stageAdjustment
        
        return min(1.0, max(0.1, totalConfidence))
    }
    
    func generateValuationSummary(result: ValuationResult) -> ValuationSummary {
        return ValuationSummary(
            baseCase: result.baseValuation,
            bearCase: result.scenarios.first { $0.name == "Bear Case" }?.valuation ?? result.baseValuation * 0.6,
            bullCase: result.scenarios.first { $0.name == "Bull Case" }?.valuation ?? result.baseValuation * 1.8,
            methodology: result.methodology.rawValue,
            confidence: result.confidence
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateComparableTransactionValuation(company: CompanyData, comparables: [ComparableMatch]) -> ValuationCalculation {
        guard !comparables.isEmpty else {
            return ValuationCalculation(
                methodology: .comparableTransactions,
                baseValue: 0,
                adjustments: [],
                finalValue: 0,
                confidence: 0.1,
                assumptions: ["No comparable transactions available"],
                limitations: ["Valuation not possible without comparable data"]
            )
        }
        
        // Calculate weighted average valuation based on similarity
        let weightedValuation = comparables.reduce(0.0) { total, match in
            total + (match.comparable.valuation * match.similarity)
        } / comparables.map(\.similarity).reduce(0, +)
        
        var adjustments: [ValuationAdjustment] = []
        var finalValue = weightedValuation
        
        // Stage adjustment
        let stageAdjustment = getStageValuationAdjustment(company.basicInfo.stage, comparables: comparables)
        if stageAdjustment.amount != 0 {
            adjustments.append(stageAdjustment)
            finalValue += stageAdjustment.amount
        }
        
        // Market size adjustment
        let marketAdjustment = getMarketSizeAdjustment(company: company, comparables: comparables)
        if marketAdjustment.amount != 0 {
            adjustments.append(marketAdjustment)
            finalValue += marketAdjustment.amount
        }
        
        // Financial position adjustment
        let financialAdjustment = getFinancialPositionAdjustment(company: company, comparables: comparables)
        if financialAdjustment.amount != 0 {
            adjustments.append(financialAdjustment)
            finalValue += financialAdjustment.amount
        }
        
        // Pipeline strength adjustment
        let pipelineAdjustment = getPipelineStrengthAdjustment(company: company)
        if pipelineAdjustment.amount != 0 {
            adjustments.append(pipelineAdjustment)
            finalValue += pipelineAdjustment.amount
        }
        
        let assumptions = [
            "Valuation based on \(comparables.count) comparable transactions",
            "Weighted by similarity to target company",
            "Adjusted for stage, market size, and financial position",
            "Market conditions assumed to remain stable"
        ]
        
        let limitations = [
            "Limited to available comparable transaction data",
            "Market conditions may change significantly",
            "Company-specific factors may not be fully captured",
            "Regulatory and competitive risks not fully quantified"
        ]
        
        return ValuationCalculation(
            methodology: .comparableTransactions,
            baseValue: weightedValuation,
            adjustments: adjustments,
            finalValue: max(0, finalValue),
            confidence: calculateValuationConfidence(comparables: comparables.map(\.comparable), company: company),
            assumptions: assumptions,
            limitations: limitations
        )
    }
    
    private func calculateRiskAdjustedNPV(company: CompanyData) -> ValuationCalculation {
        // Simplified risk-adjusted NPV calculation
        let marketSize = company.market.addressableMarket * 1000 // Convert to millions
        let marketPenetration = getExpectedMarketPenetration(stage: company.basicInfo.stage)
        let timeToMarket = getTimeToMarket(stage: company.basicInfo.stage)
        let discountRate = 0.15 // 15% discount rate for biotech
        
        let projectedRevenue = marketSize * marketPenetration
        let presentValue = projectedRevenue / pow(1 + discountRate, Double(timeToMarket) / 12.0)
        
        // Apply risk adjustments
        let clinicalRisk = getClinicalRiskAdjustment(stage: company.basicInfo.stage)
        let competitiveRisk = getCompetitiveRiskAdjustment(company: company)
        let regulatoryRisk = getRegulatoryRiskAdjustment(company: company)
        
        let riskAdjustedValue = presentValue * clinicalRisk * competitiveRisk * regulatoryRisk
        
        let adjustments = [
            ValuationAdjustment(
                name: "Clinical Risk Adjustment",
                amount: presentValue * (clinicalRisk - 1.0),
                rationale: "Adjustment for clinical development risks",
                confidence: 0.7
            ),
            ValuationAdjustment(
                name: "Competitive Risk Adjustment",
                amount: presentValue * clinicalRisk * (competitiveRisk - 1.0),
                rationale: "Adjustment for competitive landscape risks",
                confidence: 0.6
            ),
            ValuationAdjustment(
                name: "Regulatory Risk Adjustment",
                amount: presentValue * clinicalRisk * competitiveRisk * (regulatoryRisk - 1.0),
                rationale: "Adjustment for regulatory approval risks",
                confidence: 0.8
            )
        ]
        
        return ValuationCalculation(
            methodology: .riskAdjustedNPV,
            baseValue: presentValue,
            adjustments: adjustments,
            finalValue: riskAdjustedValue,
            confidence: 0.6,
            assumptions: [
                "Market penetration of \(Int(marketPenetration * 100))%",
                "Time to market: \(timeToMarket) months",
                "Discount rate: \(Int(discountRate * 100))%"
            ],
            limitations: [
                "Simplified revenue projections",
                "Static market assumptions",
                "Risk factors may be correlated"
            ]
        )
    }
    
    private func calculateMarketMultiples(company: CompanyData, comparables: [Comparable]) -> ValuationCalculation {
        // Simplified market multiples approach
        let averageMultiple = comparables.isEmpty ? 4.0 : 
            comparables.map { $0.valuation / max($0.marketSize * 1000, 1.0) }.reduce(0, +) / Double(comparables.count)
        
        let companyMarketValue = company.market.addressableMarket * 1000 // Convert to millions
        let baseValue = companyMarketValue * averageMultiple
        
        return ValuationCalculation(
            methodology: .marketMultiples,
            baseValue: baseValue,
            adjustments: [],
            finalValue: baseValue,
            confidence: 0.5,
            assumptions: [
                "Average market multiple: \(String(format: "%.1f", averageMultiple))x",
                "Based on addressable market size"
            ],
            limitations: [
                "Simplified multiple calculation",
                "May not reflect company-specific factors"
            ]
        )
    }
    
    private func getStageValuationAdjustment(stage: DevelopmentStage, comparables: [ComparableMatch]) -> ValuationAdjustment {
        let averageComparableStage = comparables.map { stageToNumeric($0.comparable.stage) }.reduce(0, +) / comparables.count
        let companyStageNumeric = Double(stageToNumeric(stage))
        let stageDifference = companyStageNumeric - averageComparableStage
        
        let adjustmentPercentage = stageDifference * 0.15 // 15% per stage difference
        let baseValuation = comparables.map(\.comparable.valuation).reduce(0, +) / Double(comparables.count)
        let adjustmentAmount = baseValuation * adjustmentPercentage
        
        return ValuationAdjustment(
            name: "Development Stage Adjustment",
            amount: adjustmentAmount,
            rationale: "Adjustment for development stage relative to comparables",
            confidence: 0.8
        )
    }
    
    private func getMarketSizeAdjustment(company: CompanyData, comparables: [ComparableMatch]) -> ValuationAdjustment {
        let averageComparableMarketSize = comparables.map(\.comparable.marketSize).reduce(0, +) / Double(comparables.count)
        let marketSizeRatio = company.market.addressableMarket / averageComparableMarketSize
        
        let adjustmentPercentage = (marketSizeRatio - 1.0) * 0.3 // 30% sensitivity to market size
        let baseValuation = comparables.map(\.comparable.valuation).reduce(0, +) / Double(comparables.count)
        let adjustmentAmount = baseValuation * adjustmentPercentage
        
        return ValuationAdjustment(
            name: "Market Size Adjustment",
            amount: adjustmentAmount,
            rationale: "Adjustment for addressable market size difference",
            confidence: 0.7
        )
    }
    
    private func getFinancialPositionAdjustment(company: CompanyData, comparables: [ComparableMatch]) -> ValuationAdjustment {
        let companyRunway = company.financials.runway
        let averageComparableRunway = comparables.compactMap(\.comparable.financials.runway).reduce(0, +) / comparables.compactMap(\.comparable.financials.runway).count
        
        guard averageComparableRunway > 0 else {
            return ValuationAdjustment(name: "Financial Position Adjustment", amount: 0, rationale: "No comparable financial data", confidence: 0.3)
        }
        
        let runwayRatio = Double(companyRunway) / Double(averageComparableRunway)
        let adjustmentPercentage = (runwayRatio - 1.0) * 0.1 // 10% sensitivity to runway
        let baseValuation = comparables.map(\.comparable.valuation).reduce(0, +) / Double(comparables.count)
        let adjustmentAmount = baseValuation * adjustmentPercentage
        
        return ValuationAdjustment(
            name: "Financial Position Adjustment",
            amount: adjustmentAmount,
            rationale: "Adjustment for cash runway relative to comparables",
            confidence: 0.6
        )
    }
    
    private func getPipelineStrengthAdjustment(company: CompanyData) -> ValuationAdjustment {
        let programCount = company.pipeline.programs.count
        let adjustmentPercentage = (Double(programCount) - 1.0) * 0.05 // 5% per additional program
        
        // Estimate base valuation (simplified)
        let estimatedBaseValuation = company.market.addressableMarket * 100 // Rough estimate
        let adjustmentAmount = estimatedBaseValuation * adjustmentPercentage
        
        return ValuationAdjustment(
            name: "Pipeline Strength Adjustment",
            amount: adjustmentAmount,
            rationale: "Adjustment for pipeline breadth (\(programCount) programs)",
            confidence: 0.5
        )
    }
    
    private func identifyValuationDrivers(company: CompanyData, comparables: [ComparableMatch]) -> [ValuationDriver] {
        var drivers: [ValuationDriver] = []
        
        // Market size driver
        let marketSize = company.market.addressableMarket
        let marketImpact: DriverImpact = marketSize > 10 ? .veryPositive : marketSize > 5 ? .positive : .neutral
        drivers.append(ValuationDriver(
            name: "Addressable Market Size",
            impact: marketImpact,
            description: "Market opportunity of $\(String(format: "%.1f", marketSize))B",
            quantifiedImpact: marketSize * 50, // Rough estimate
            confidence: 0.8
        ))
        
        // Development stage driver
        let stageImpact: DriverImpact = {
            switch company.basicInfo.stage {
            case .approved, .marketed: return .veryPositive
            case .phase3: return .positive
            case .phase2: return .neutral
            case .phase1: return .negative
            case .preclinical: return .veryNegative
            }
        }()
        drivers.append(ValuationDriver(
            name: "Development Stage",
            impact: stageImpact,
            description: "Currently in \(company.basicInfo.stage.rawValue)",
            quantifiedImpact: nil,
            confidence: 0.9
        ))
        
        // Financial runway driver
        let runway = company.financials.runway
        let runwayImpact: DriverImpact = runway > 24 ? .positive : runway > 12 ? .neutral : .negative
        drivers.append(ValuationDriver(
            name: "Financial Runway",
            impact: runwayImpact,
            description: "\(runway) months of cash runway",
            quantifiedImpact: nil,
            confidence: 0.7
        ))
        
        // Pipeline breadth driver
        let programCount = company.pipeline.programs.count
        let pipelineImpact: DriverImpact = programCount > 3 ? .positive : programCount > 1 ? .neutral : .negative
        drivers.append(ValuationDriver(
            name: "Pipeline Breadth",
            impact: pipelineImpact,
            description: "\(programCount) development programs",
            quantifiedImpact: Double(programCount - 1) * 50, // Rough estimate
            confidence: 0.6
        ))
        
        return drivers
    }
    
    private func identifyValuationRisks(company: CompanyData) -> [ValuationRisk] {
        var risks: [ValuationRisk] = []
        
        // Clinical risk
        let clinicalProbability = getClinicalRiskProbability(stage: company.basicInfo.stage)
        risks.append(ValuationRisk(
            name: "Clinical Development Risk",
            category: .clinical,
            probability: clinicalProbability,
            impact: 0.4, // 40% impact on valuation
            mitigation: "Robust clinical trial design and interim analyses",
            timeframe: .mediumTerm
        ))
        
        // Regulatory risk
        risks.append(ValuationRisk(
            name: "Regulatory Approval Risk",
            category: .regulatory,
            probability: 0.3,
            impact: 0.6, // 60% impact on valuation
            mitigation: "Early FDA engagement and regulatory strategy",
            timeframe: .mediumTerm
        ))
        
        // Competitive risk
        let competitorCount = company.market.competitors.count
        let competitiveProbability = min(0.8, Double(competitorCount) * 0.1)
        risks.append(ValuationRisk(
            name: "Competitive Threat",
            category: .competitive,
            probability: competitiveProbability,
            impact: 0.3, // 30% impact on valuation
            mitigation: "Differentiation strategy and IP protection",
            timeframe: .longTerm
        ))
        
        // Financial risk
        let runway = company.financials.runway
        let financialProbability = runway < 12 ? 0.7 : runway < 24 ? 0.4 : 0.2
        risks.append(ValuationRisk(
            name: "Funding Risk",
            category: .financial,
            probability: financialProbability,
            impact: 0.5, // 50% impact on valuation
            mitigation: "Diversified funding strategy and milestone-based financing",
            timeframe: .nearTerm
        ))
        
        return risks
    }
    
    // MARK: - Helper Methods
    
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
    
    private func createDefaultMarketConditions() -> MarketConditions {
        return MarketConditions(
            biotechIndex: 1000.0,
            ipoActivity: .moderate,
            fundingEnvironment: .moderate,
            regulatoryClimate: .neutral
        )
    }
    
    private func calculateCompanyDataCompleteness(_ company: CompanyData) -> Double {
        var completeness: Double = 0.0
        let totalFields: Double = 10.0
        
        if !company.basicInfo.name.isEmpty { completeness += 1.0 }
        if !company.basicInfo.therapeuticAreas.isEmpty { completeness += 1.0 }
        if !company.pipeline.programs.isEmpty { completeness += 1.0 }
        if company.financials.cashPosition > 0 { completeness += 1.0 }
        if company.financials.burnRate > 0 { completeness += 1.0 }
        if company.market.addressableMarket > 0 { completeness += 1.0 }
        if !company.market.competitors.isEmpty { completeness += 1.0 }
        if !company.regulatory.clinicalTrials.isEmpty { completeness += 1.0 }
        if company.financials.lastFunding != nil { completeness += 1.0 }
        if !company.basicInfo.sector.isEmpty { completeness += 1.0 }
        
        return completeness / totalFields
    }
    
    private func getStageConfidenceAdjustment(_ stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.3
        case .phase1: return 0.5
        case .phase2: return 0.7
        case .phase3: return 0.9
        case .approved: return 1.0
        case .marketed: return 1.0
        }
    }
    
    private func getExpectedMarketPenetration(stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.01
        case .phase1: return 0.02
        case .phase2: return 0.05
        case .phase3: return 0.10
        case .approved: return 0.15
        case .marketed: return 0.20
        }
    }
    
    private func getTimeToMarket(stage: DevelopmentStage) -> Int {
        switch stage {
        case .preclinical: return 84 // 7 years
        case .phase1: return 72 // 6 years
        case .phase2: return 48 // 4 years
        case .phase3: return 24 // 2 years
        case .approved: return 6 // 6 months
        case .marketed: return 0
        }
    }
    
    private func getClinicalRiskAdjustment(stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.1
        case .phase1: return 0.3
        case .phase2: return 0.5
        case .phase3: return 0.7
        case .approved: return 0.9
        case .marketed: return 1.0
        }
    }
    
    private func getCompetitiveRiskAdjustment(company: CompanyData) -> Double {
        let competitorCount = company.market.competitors.count
        return max(0.5, 1.0 - (Double(competitorCount) * 0.1))
    }
    
    private func getRegulatoryRiskAdjustment(company: CompanyData) -> Double {
        switch company.regulatory.regulatoryStrategy.pathway {
        case .breakthrough, .fastTrack: return 0.9
        case .accelerated: return 0.8
        case .orphan: return 0.85
        case .standard: return 0.7
        }
    }
    
    private func getClinicalRiskProbability(stage: DevelopmentStage) -> Double {
        switch stage {
        case .preclinical: return 0.9
        case .phase1: return 0.7
        case .phase2: return 0.5
        case .phase3: return 0.3
        case .approved: return 0.1
        case .marketed: return 0.05
        }
    }
}