import Foundation

/// Main scoring engine that orchestrates all pillar evaluations and weighting
/// Coordinates the complete scoring workflow for biotech companies
public class BDScoringEngine: ScoringEngine {
    
    // MARK: - Properties
    
    /// Individual scoring pillars
    private let assetQualityPillar: AssetQualityPillar
    private let marketOutlookPillar: MarketOutlookPillar
    private let capitalIntensityPillar: CapitalIntensityPillar
    private let strategicFitPillar: StrategicFitPillar
    private let financialReadinessPillar: FinancialReadinessPillar
    private let regulatoryRiskPillar: RegulatoryRiskPillar
    
    /// Weighting engine for applying configurable weights
    private let weightingEngine: BDWeightingEngine
    
    /// Validation service for data quality checks
    private let validationService: ValidationService?
    
    /// Market context provider
    private var marketContext: MarketContext
    
    /// Performance monitoring service
    private let performanceMonitor: PerformanceMonitoringService
    
    /// Caching service for optimization
    private let cachingService: CachingService
    
    // MARK: - Initialization
    
    public init(validationService: ValidationService? = nil, marketContext: MarketContext? = nil) {
        // Initialize all scoring pillars
        self.assetQualityPillar = AssetQualityPillar()
        self.marketOutlookPillar = MarketOutlookPillar()
        self.capitalIntensityPillar = CapitalIntensityPillar()
        self.strategicFitPillar = StrategicFitPillar()
        self.financialReadinessPillar = FinancialReadinessPillar()
        self.regulatoryRiskPillar = RegulatoryRiskPillar()
        
        // Initialize weighting engine
        self.weightingEngine = BDWeightingEngine()
        
        // Set validation service
        self.validationService = validationService
        
        // Set default market context if none provided
        self.marketContext = marketContext ?? createDefaultMarketContext()
        
        // Initialize performance monitoring and caching services
        self.performanceMonitor = PerformanceMonitoringService.shared
        self.cachingService = CachingService.shared
    }
    
    // MARK: - ScoringEngine Protocol Implementation
    
    /// Evaluate a company across all pillars
    public func evaluateCompany(_ companyData: CompanyData, config: ScoringConfig) async throws -> ScoringResult {
        return try await performanceMonitor.measureAsyncOperation("scoring") {
            // Generate cache key based on company data and config
            let configHash = generateConfigHash(config)
            
            // Check cache first
            if let cachedResult: ScoringResult = await MainActor.run(body: {
                cachingService.getCachedScoringResult(for: companyData.id, configHash: configHash)
            }) {
                return cachedResult
            }
            
            // Validate input data
            let dataValidation = validateInputData(companyData)
            guard dataValidation.isValid || dataValidation.errors.allSatisfy({ $0.severity != .critical }) else {
                throw ScoringError.invalidData("Critical data validation errors: \(dataValidation.errors.map { $0.message }.joined(separator: ", "))")
            }
            
            // Validate scoring configuration
            let configValidation = weightingEngine.validateWeights(config.weights)
            guard configValidation.isValid || configValidation.errors.allSatisfy({ $0.severity != .critical }) else {
                throw ScoringError.configurationError("Invalid scoring configuration: \(configValidation.errors.map { $0.message }.joined(separator: ", "))")
            }
            
            // Calculate individual pillar scores concurrently with performance monitoring
            async let assetQualityScore = performanceMonitor.measureAsyncOperation("pillar_asset_quality") {
                try await assetQualityPillar.calculateScore(data: companyData, context: marketContext)
            }
            async let marketOutlookScore = performanceMonitor.measureAsyncOperation("pillar_market_outlook") {
                try await marketOutlookPillar.calculateScore(data: companyData, context: marketContext)
            }
            async let capitalIntensityScore = performanceMonitor.measureAsyncOperation("pillar_capital_intensity") {
                try await capitalIntensityPillar.calculateScore(data: companyData, context: marketContext)
            }
            async let strategicFitScore = performanceMonitor.measureAsyncOperation("pillar_strategic_fit") {
                try await strategicFitPillar.calculateScore(data: companyData, context: marketContext)
            }
            async let financialReadinessScore = performanceMonitor.measureAsyncOperation("pillar_financial_readiness") {
                try await financialReadinessPillar.calculateScore(data: companyData, context: marketContext)
            }
            async let regulatoryRiskScore = performanceMonitor.measureAsyncOperation("pillar_regulatory_risk") {
                try await regulatoryRiskPillar.calculateScore(data: companyData, context: marketContext)
            }
            
            // Await all pillar scores
            let pillarScores = try await PillarScores(
                assetQuality: assetQualityScore,
                marketOutlook: marketOutlookScore,
                capitalIntensity: capitalIntensityScore,
                strategicFit: strategicFitScore,
                financialReadiness: financialReadinessScore,
                regulatoryRisk: regulatoryRiskScore
            )
            
            // Apply weights to get weighted scores
            let weightedScores = weightingEngine.applyWeights(pillarScores, weights: config.weights)
            
            // Calculate overall score
            let overallScore = weightedScores.total
            
            // Calculate confidence metrics
            let confidence = calculateConfidence(pillarScores, data: companyData)
            
            // Generate recommendations
            let recommendations = generateRecommendations(pillarScores: pillarScores, weightedScores: weightedScores, confidence: confidence)
            
            // Determine investment recommendation and risk level
            let investmentRecommendation = determineInvestmentRecommendation(overallScore: overallScore, confidence: confidence)
            let riskLevel = determineRiskLevel(pillarScores: pillarScores, confidence: confidence)
            
            let result = ScoringResult(
                companyId: companyData.id,
                overallScore: overallScore,
                pillarScores: pillarScores,
                weightedScores: weightedScores,
                confidence: confidence,
                recommendations: recommendations,
                timestamp: Date(),
                investmentRecommendation: investmentRecommendation,
                riskLevel: riskLevel
            )
            
            // Cache the result
            await MainActor.run {
                cachingService.cacheScoringResult(result, for: companyData.id, configHash: configHash)
            }
            
            return result
        }
    }
    
    /// Validate input data completeness
    public func validateInputData(_ data: CompanyData) -> ValidationResult {
        if let validationService = validationService {
            return validationService.validateCompanyData(data)
        }
        
        // Fallback validation if no validation service provided
        return performBasicValidation(data)
    }
    
    /// Calculate weighted score from pillar scores
    public func calculateWeightedScore(_ pillarScores: PillarScores, weights: WeightConfig) -> WeightedScore {
        let weightedScores = weightingEngine.applyWeights(pillarScores, weights: weights)
        
        return WeightedScore(
            score: weightedScores.total,
            breakdown: [
                "assetQuality": weightedScores.assetQuality,
                "marketOutlook": weightedScores.marketOutlook,
                "capitalIntensity": weightedScores.capitalIntensity,
                "strategicFit": weightedScores.strategicFit,
                "financialReadiness": weightedScores.financialReadiness,
                "regulatoryRisk": weightedScores.regulatoryRisk
            ],
            confidence: calculateOverallConfidence(pillarScores)
        )
    }
    
    /// Get confidence metrics for the scoring
    public func calculateConfidence(_ pillarScores: PillarScores, data: CompanyData) -> ConfidenceMetrics {
        // Calculate individual confidence components
        let pillarConfidences = [
            pillarScores.assetQuality.confidence,
            pillarScores.marketOutlook.confidence,
            pillarScores.capitalIntensity.confidence,
            pillarScores.strategicFit.confidence,
            pillarScores.financialReadiness.confidence,
            pillarScores.regulatoryRisk.confidence
        ]
        
        // Overall confidence is the weighted average of pillar confidences
        let overallConfidence = pillarConfidences.reduce(0, +) / Double(pillarConfidences.count)
        
        // Data completeness based on available fields
        let dataCompleteness = calculateDataCompleteness(data)
        
        // Model accuracy based on historical performance (placeholder for now)
        let modelAccuracy = 0.85 // This would come from historical validation
        
        // Comparable quality based on market context
        let comparableQuality = calculateComparableQuality()
        
        return ConfidenceMetrics(
            overall: overallConfidence,
            dataCompleteness: dataCompleteness,
            modelAccuracy: modelAccuracy,
            comparableQuality: comparableQuality
        )
    }
    
    // MARK: - Public Methods
    
    /// Update market context for scoring
    public func updateMarketContext(_ context: MarketContext) {
        self.marketContext = context
    }
    
    /// Get current market context
    public func getCurrentMarketContext() -> MarketContext {
        return marketContext
    }
    
    /// Evaluate multiple companies in batch
    public func evaluateCompanies(_ companies: [CompanyData], config: ScoringConfig) async throws -> [ScoringResult] {
        var results: [ScoringResult] = []
        
        for company in companies {
            do {
                let result = try await evaluateCompany(company, config: config)
                results.append(result)
            } catch {
                // Log error but continue with other companies
                print("Error evaluating company \(company.basicInfo.name): \(error)")
                // Could optionally create a failed result entry
            }
        }
        
        return results
    }
    
    /// Get scoring summary statistics for a batch of results
    public func getScoringStatistics(_ results: [ScoringResult]) -> ScoringStatistics {
        guard !results.isEmpty else {
            return ScoringStatistics(
                totalCompanies: 0,
                averageScore: 0,
                scoreDistribution: [:],
                averageConfidence: 0,
                recommendationDistribution: [:]
            )
        }
        
        let totalCompanies = results.count
        let averageScore = results.map { $0.overallScore }.reduce(0, +) / Double(totalCompanies)
        let averageConfidence = results.map { $0.confidence.overall }.reduce(0, +) / Double(totalCompanies)
        
        // Calculate score distribution
        let scoreRanges = ["1.0-2.0", "2.0-3.0", "3.0-4.0", "4.0-5.0"]
        var scoreDistribution: [String: Int] = [:]
        
        for range in scoreRanges {
            scoreDistribution[range] = 0
        }
        
        for result in results {
            let score = result.overallScore
            if score >= 1.0 && score < 2.0 {
                scoreDistribution["1.0-2.0"]! += 1
            } else if score >= 2.0 && score < 3.0 {
                scoreDistribution["2.0-3.0"]! += 1
            } else if score >= 3.0 && score < 4.0 {
                scoreDistribution["3.0-4.0"]! += 1
            } else if score >= 4.0 && score <= 5.0 {
                scoreDistribution["4.0-5.0"]! += 1
            }
        }
        
        // Calculate recommendation distribution
        var recommendationDistribution: [String: Int] = [:]
        for recommendation in InvestmentRecommendation.allCases {
            recommendationDistribution[recommendation.rawValue] = 0
        }
        
        for result in results {
            recommendationDistribution[result.investmentRecommendation.rawValue]! += 1
        }
        
        return ScoringStatistics(
            totalCompanies: totalCompanies,
            averageScore: averageScore,
            scoreDistribution: scoreDistribution,
            averageConfidence: averageConfidence,
            recommendationDistribution: recommendationDistribution
        )
    }
    
    // MARK: - Private Methods
    
    /// Perform basic data validation when no validation service is provided
    private func performBasicValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check basic info
        if data.basicInfo.name.isEmpty {
            errors.append(ValidationError(field: "basicInfo.name", message: "Company name is required", severity: .critical))
        }
        
        if data.basicInfo.therapeuticAreas.isEmpty {
            warnings.append(ValidationWarning(field: "basicInfo.therapeuticAreas", message: "No therapeutic areas specified", suggestion: "Add therapeutic areas for better scoring accuracy"))
        }
        
        // Check pipeline
        if data.pipeline.programs.isEmpty {
            errors.append(ValidationError(field: "pipeline.programs", message: "At least one pipeline program is required", severity: .critical))
        }
        
        // Check financials
        if data.financials.cashPosition <= 0 {
            warnings.append(ValidationWarning(field: "financials.cashPosition", message: "Cash position not specified or zero", suggestion: "Provide current cash position for financial analysis"))
        }
        
        if data.financials.burnRate <= 0 {
            warnings.append(ValidationWarning(field: "financials.burnRate", message: "Burn rate not specified", suggestion: "Provide monthly burn rate for runway calculation"))
        }
        
        let completeness = calculateDataCompleteness(data)
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: completeness
        )
    }
    
    /// Calculate data completeness score
    private func calculateDataCompleteness(_ data: CompanyData) -> Double {
        var totalFields = 0
        var completedFields = 0
        
        // Basic info completeness
        totalFields += 5
        if !data.basicInfo.name.isEmpty { completedFields += 1 }
        if data.basicInfo.ticker != nil { completedFields += 1 }
        if !data.basicInfo.sector.isEmpty { completedFields += 1 }
        if !data.basicInfo.therapeuticAreas.isEmpty { completedFields += 1 }
        if data.basicInfo.description != nil { completedFields += 1 }
        
        // Pipeline completeness
        totalFields += 2
        if !data.pipeline.programs.isEmpty { completedFields += 1 }
        if data.pipeline.leadProgram != nil { completedFields += 1 }
        
        // Financial completeness
        totalFields += 3
        if data.financials.cashPosition > 0 { completedFields += 1 }
        if data.financials.burnRate > 0 { completedFields += 1 }
        if data.financials.lastFunding != nil { completedFields += 1 }
        
        // Market completeness
        totalFields += 3
        if data.market.addressableMarket > 0 { completedFields += 1 }
        if !data.market.competitors.isEmpty { completedFields += 1 }
        completedFields += 1 // marketDynamics always present
        
        // Regulatory completeness
        totalFields += 3
        if !data.regulatory.approvals.isEmpty { completedFields += 1 }
        if !data.regulatory.clinicalTrials.isEmpty { completedFields += 1 }
        completedFields += 1 // regulatoryStrategy always present
        
        return Double(completedFields) / Double(totalFields)
    }
    
    /// Calculate comparable quality based on market context
    private func calculateComparableQuality() -> Double {
        // This would analyze the quality and relevance of comparable companies
        // For now, return a reasonable default
        let comparableCount = marketContext.comparableCompanies.count
        
        if comparableCount >= 10 {
            return 0.9
        } else if comparableCount >= 5 {
            return 0.7
        } else if comparableCount >= 2 {
            return 0.5
        } else {
            return 0.3
        }
    }
    
    /// Calculate overall confidence from pillar scores
    private func calculateOverallConfidence(_ pillarScores: PillarScores) -> Double {
        let confidences = [
            pillarScores.assetQuality.confidence,
            pillarScores.marketOutlook.confidence,
            pillarScores.capitalIntensity.confidence,
            pillarScores.strategicFit.confidence,
            pillarScores.financialReadiness.confidence,
            pillarScores.regulatoryRisk.confidence
        ]
        
        return confidences.reduce(0, +) / Double(confidences.count)
    }
    
    /// Generate recommendations based on scoring results
    private func generateRecommendations(pillarScores: PillarScores, weightedScores: WeightedScores, confidence: ConfidenceMetrics) -> [String] {
        var recommendations: [String] = []
        
        // Overall score recommendations
        if weightedScores.total >= 4.0 {
            recommendations.append("Strong candidate for partnership or acquisition")
        } else if weightedScores.total >= 3.0 {
            recommendations.append("Moderate investment opportunity with specific strengths")
        } else {
            recommendations.append("High-risk investment requiring careful evaluation")
        }
        
        // Pillar-specific recommendations
        if pillarScores.assetQuality.rawScore >= 4.0 {
            recommendations.append("Strong pipeline assets with competitive advantages")
        } else if pillarScores.assetQuality.rawScore < 2.5 {
            recommendations.append("Pipeline quality concerns require further due diligence")
        }
        
        if pillarScores.financialReadiness.rawScore < 2.5 {
            recommendations.append("Financial runway concerns - consider timing of investment")
        }
        
        if pillarScores.regulatoryRisk.rawScore < 2.5 {
            recommendations.append("High regulatory risk - monitor clinical trial progress closely")
        }
        
        // Confidence-based recommendations
        if confidence.overall < 0.6 {
            recommendations.append("Low confidence in scoring - gather additional data before decision")
        }
        
        if confidence.dataCompleteness < 0.7 {
            recommendations.append("Incomplete data - request additional company information")
        }
        
        return recommendations
    }
    
    /// Determine investment recommendation based on overall score and confidence
    private func determineInvestmentRecommendation(overallScore: Double, confidence: ConfidenceMetrics) -> InvestmentRecommendation {
        // Adjust recommendation based on confidence
        let confidenceAdjustedScore = overallScore * confidence.overall
        
        if confidenceAdjustedScore >= 4.0 {
            return .strongBuy
        } else if confidenceAdjustedScore >= 3.5 {
            return .buy
        } else if confidenceAdjustedScore >= 2.5 {
            return .hold
        } else if confidenceAdjustedScore >= 2.0 {
            return .sell
        } else {
            return .strongSell
        }
    }
    
    /// Determine risk level based on pillar scores and confidence
    private func determineRiskLevel(pillarScores: PillarScores, confidence: ConfidenceMetrics) -> RiskLevel {
        // Calculate risk factors
        let regulatoryRisk = 5.0 - pillarScores.regulatoryRisk.rawScore // Invert since lower score = higher risk
        let financialRisk = 5.0 - pillarScores.financialReadiness.rawScore
        let marketRisk = 5.0 - pillarScores.marketOutlook.rawScore
        let confidenceRisk = 1.0 - confidence.overall
        
        let averageRisk = (regulatoryRisk + financialRisk + marketRisk + (confidenceRisk * 4)) / 4.0
        
        if averageRisk >= 3.5 {
            return .veryHigh
        } else if averageRisk >= 2.5 {
            return .high
        } else if averageRisk >= 1.5 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Create default market context
    private func createDefaultMarketContext() -> MarketContext {
        return MarketContext(
            benchmarkData: [],
            marketConditions: MarketConditions(
                biotechIndex: 1000.0,
                ipoActivity: .moderate,
                fundingEnvironment: .moderate,
                regulatoryClimate: .neutral
            ),
            comparableCompanies: [],
            industryMetrics: IndustryMetrics(
                averageValuation: 500.0,
                medianTimeline: 36,
                successRate: 0.15,
                averageRunway: 18
            )
        )
    }
    
    /// Generate a hash for the scoring configuration to use as cache key
    private func generateConfigHash(_ config: ScoringConfig) -> String {
        let weights = config.weights
        let weightsString = "\(weights.assetQuality)_\(weights.marketOutlook)_\(weights.capitalIntensity)_\(weights.strategicFit)_\(weights.financialReadiness)_\(weights.regulatoryRisk)"
        
        // Include custom parameters if any
        let parametersString = config.customParameters.keys.sorted().map { key in
            "\(key):\(config.customParameters[key] ?? "")"
        }.joined(separator: "_")
        
        let combinedString = "\(weightsString)_\(parametersString)"
        return String(combinedString.hashValue)
    }
}

// MARK: - Supporting Types

/// Statistics for a batch of scoring results
public struct ScoringStatistics {
    let totalCompanies: Int
    let averageScore: Double
    let scoreDistribution: [String: Int]
    let averageConfidence: Double
    let recommendationDistribution: [String: Int]
}

// MARK: - Extensions

extension BDScoringEngine {
    /// Convenience method to evaluate a company with default configuration
    public func evaluateCompany(_ companyData: CompanyData) async throws -> ScoringResult {
        let defaultConfig = ScoringConfig(
            name: "Default",
            weights: WeightConfig(),
            parameters: ScoringParameters()
        )
        return try await evaluateCompany(companyData, config: defaultConfig)
    }
    
    /// Get pillar-specific insights for a company
    public func getPillarInsights(_ companyData: CompanyData) async throws -> [String: String] {
        let context = marketContext
        
        async let assetInsight = assetQualityPillar.explainScore(try await assetQualityPillar.calculateScore(data: companyData, context: context))
        async let marketInsight = marketOutlookPillar.explainScore(try await marketOutlookPillar.calculateScore(data: companyData, context: context))
        async let capitalInsight = capitalIntensityPillar.explainScore(try await capitalIntensityPillar.calculateScore(data: companyData, context: context))
        async let strategicInsight = strategicFitPillar.explainScore(try await strategicFitPillar.calculateScore(data: companyData, context: context))
        async let financialInsight = financialReadinessPillar.explainScore(try await financialReadinessPillar.calculateScore(data: companyData, context: context))
        async let regulatoryInsight = regulatoryRiskPillar.explainScore(try await regulatoryRiskPillar.calculateScore(data: companyData, context: context))
        
        return try await [
            "Asset Quality": assetInsight.summary,
            "Market Outlook": marketInsight.summary,
            "Capital Intensity": capitalInsight.summary,
            "Strategic Fit": strategicInsight.summary,
            "Financial Readiness": financialInsight.summary,
            "Regulatory Risk": regulatoryInsight.summary
        ]
    }
}