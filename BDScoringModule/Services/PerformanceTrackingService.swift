import Foundation

/// Service for tracking model performance and prediction accuracy
class PerformanceTrackingService {
    private let historicalDataService: HistoricalDataService
    
    init(historicalDataService: HistoricalDataService) {
        self.historicalDataService = historicalDataService
    }
    
    // MARK: - Outcome Recording
    
    /// Records an actual outcome for a company and calculates prediction accuracy
    func recordActualOutcome(
        companyId: UUID,
        outcome: ActualOutcome,
        originalPrediction: InvestmentRecommendation? = nil
    ) -> Bool {
        // Find the most recent historical score for this company
        let historicalScores = historicalDataService.getHistoricalScores(for: companyId, limit: 1)
        guard let latestScore = historicalScores.first else {
            print("No historical score found for company \(companyId)")
            return false
        }
        
        // Save the actual outcome
        let outcomeSuccess = historicalDataService.saveActualOutcome(
            outcome,
            for: latestScore.id,
            companyId: companyId
        )
        
        guard outcomeSuccess else {
            print("Failed to save actual outcome")
            return false
        }
        
        // Calculate prediction accuracy
        let accuracy = calculatePredictionAccuracy(
            originalScore: latestScore.scoringResult,
            actualOutcome: outcome,
            originalPrediction: originalPrediction
        )
        
        // Update the prediction accuracy
        let accuracySuccess = historicalDataService.updatePredictionAccuracy(
            historicalScoreId: latestScore.id,
            accuracy: accuracy
        )
        
        if accuracySuccess {
            // Update overall model performance metrics
            updateModelPerformanceMetrics()
        }
        
        return accuracySuccess
    }
    
    /// Records multiple outcomes for batch processing
    func recordBatchOutcomes(_ outcomes: [(companyId: UUID, outcome: ActualOutcome)]) -> BatchProcessingResult {
        var successCount = 0
        var failureCount = 0
        var errors: [String] = []
        
        for (companyId, outcome) in outcomes {
            if recordActualOutcome(companyId: companyId, outcome: outcome) {
                successCount += 1
            } else {
                failureCount += 1
                errors.append("Failed to record outcome for company \(companyId)")
            }
        }
        
        return BatchProcessingResult(
            totalProcessed: outcomes.count,
            successCount: successCount,
            failureCount: failureCount,
            errors: errors
        )
    }
    
    // MARK: - Accuracy Calculation
    
    /// Calculates prediction accuracy based on original score and actual outcome
    private func calculatePredictionAccuracy(
        originalScore: ScoringResult,
        actualOutcome: ActualOutcome,
        originalPrediction: InvestmentRecommendation?
    ) -> Double {
        var accuracyComponents: [Double] = []
        
        // 1. Recommendation accuracy (40% weight)
        let recommendationAccuracy = calculateRecommendationAccuracy(
            originalRecommendation: originalPrediction ?? originalScore.investmentRecommendation,
            actualOutcome: actualOutcome
        )
        accuracyComponents.append(recommendationAccuracy * 0.4)
        
        // 2. Score-based accuracy (30% weight)
        let scoreAccuracy = calculateScoreBasedAccuracy(
            originalScore: originalScore.overallScore,
            actualOutcome: actualOutcome
        )
        accuracyComponents.append(scoreAccuracy * 0.3)
        
        // 3. Risk assessment accuracy (20% weight)
        let riskAccuracy = calculateRiskAccuracy(
            originalRiskLevel: originalScore.riskLevel,
            actualOutcome: actualOutcome
        )
        accuracyComponents.append(riskAccuracy * 0.2)
        
        // 4. Timing accuracy (10% weight)
        let timingAccuracy = calculateTimingAccuracy(
            originalTimestamp: originalScore.timestamp,
            actualOutcomeDate: actualOutcome.date
        )
        accuracyComponents.append(timingAccuracy * 0.1)
        
        return accuracyComponents.reduce(0, +)
    }
    
    private func calculateRecommendationAccuracy(
        originalRecommendation: InvestmentRecommendation,
        actualOutcome: ActualOutcome
    ) -> Double {
        switch (originalRecommendation, actualOutcome.eventType) {
        case (.strongBuy, .acquisition), (.strongBuy, .ipo):
            return 1.0
        case (.buy, .acquisition), (.buy, .ipo), (.buy, .partnership):
            return 0.8
        case (.hold, .partnership), (.hold, .licensing):
            return 0.6
        case (.sell, .bankruptcy), (.strongSell, .bankruptcy):
            return 1.0
        case (.hold, .ongoing):
            return 0.7
        default:
            // Partial credit for reasonable predictions
            return 0.3
        }
    }
    
    private func calculateScoreBasedAccuracy(
        originalScore: Double,
        actualOutcome: ActualOutcome
    ) -> Double {
        let expectedOutcomeScore: Double
        
        switch actualOutcome.eventType {
        case .acquisition, .ipo:
            expectedOutcomeScore = 4.0 // High score events
        case .partnership, .licensing:
            expectedOutcomeScore = 3.0 // Medium score events
        case .bankruptcy:
            expectedOutcomeScore = 1.5 // Low score events
        case .ongoing:
            expectedOutcomeScore = 2.5 // Neutral events
        }
        
        let scoreDifference = abs(originalScore - expectedOutcomeScore)
        return max(0.0, 1.0 - (scoreDifference / 4.0)) // Normalize to 0-1 scale
    }
    
    private func calculateRiskAccuracy(
        originalRiskLevel: RiskLevel,
        actualOutcome: ActualOutcome
    ) -> Double {
        let expectedRiskLevel: RiskLevel
        
        switch actualOutcome.eventType {
        case .acquisition, .ipo:
            expectedRiskLevel = .low
        case .partnership, .licensing:
            expectedRiskLevel = .medium
        case .bankruptcy:
            expectedRiskLevel = .veryHigh
        case .ongoing:
            expectedRiskLevel = .medium
        }
        
        let riskLevels: [RiskLevel] = [.low, .medium, .high, .veryHigh]
        guard let originalIndex = riskLevels.firstIndex(of: originalRiskLevel),
              let expectedIndex = riskLevels.firstIndex(of: expectedRiskLevel) else {
            return 0.5
        }
        
        let difference = abs(originalIndex - expectedIndex)
        return max(0.0, 1.0 - (Double(difference) / 3.0))
    }
    
    private func calculateTimingAccuracy(
        originalTimestamp: Date,
        actualOutcomeDate: Date
    ) -> Double {
        let timeDifference = abs(actualOutcomeDate.timeIntervalSince(originalTimestamp))
        let daysDifference = timeDifference / (24 * 60 * 60) // Convert to days
        
        // Accuracy decreases as time difference increases
        // Perfect accuracy within 30 days, decreasing to 0 at 2 years
        let maxDays: Double = 730 // 2 years
        let optimalDays: Double = 30
        
        if daysDifference <= optimalDays {
            return 1.0
        } else if daysDifference >= maxDays {
            return 0.0
        } else {
            return 1.0 - ((daysDifference - optimalDays) / (maxDays - optimalDays))
        }
    }
    
    // MARK: - Performance Metrics Calculation
    
    /// Updates overall model performance metrics
    private func updateModelPerformanceMetrics() {
        let now = Date()
        
        // Calculate metrics for different time periods
        calculateAndSaveMetrics(for: .monthly, date: now)
        calculateAndSaveMetrics(for: .quarterly, date: now)
        calculateAndSaveMetrics(for: .yearly, date: now)
    }
    
    private func calculateAndSaveMetrics(for period: MetricPeriod, date: Date) {
        let (startDate, endDate) = period.dateRange(from: date)
        
        // Get all outcomes in the period
        let historicalScores = historicalDataService.getHistoricalScores(from: startDate, to: endDate)
        let companiesWithOutcomes = Set(historicalScores.compactMap { score in
            let outcomes = historicalDataService.getActualOutcomes(for: UUID(uuidString: score.companyId) ?? UUID())
            return outcomes.isEmpty ? nil : score.companyId
        })
        
        guard !companiesWithOutcomes.isEmpty else { return }
        
        // Calculate various performance metrics
        let overallAccuracy = calculateOverallAccuracy(for: companiesWithOutcomes, in: startDate...endDate)
        let recommendationAccuracy = calculateRecommendationAccuracy(for: companiesWithOutcomes, in: startDate...endDate)
        let scoreCorrelation = calculateScoreCorrelation(for: companiesWithOutcomes, in: startDate...endDate)
        let predictionCoverage = calculatePredictionCoverage(for: companiesWithOutcomes, in: startDate...endDate)
        
        // Save metrics
        let periodName = period.rawValue
        _ = historicalDataService.savePerformanceMetric(
            name: "\(periodName)_overall_accuracy",
            value: overallAccuracy,
            calculationDate: date,
            periodStart: startDate,
            periodEnd: endDate,
            details: "Overall prediction accuracy for \(periodName) period"
        )
        
        _ = historicalDataService.savePerformanceMetric(
            name: "\(periodName)_recommendation_accuracy",
            value: recommendationAccuracy,
            calculationDate: date,
            periodStart: startDate,
            periodEnd: endDate,
            details: "Investment recommendation accuracy for \(periodName) period"
        )
        
        _ = historicalDataService.savePerformanceMetric(
            name: "\(periodName)_score_correlation",
            value: scoreCorrelation,
            calculationDate: date,
            periodStart: startDate,
            periodEnd: endDate,
            details: "Correlation between scores and outcomes for \(periodName) period"
        )
        
        _ = historicalDataService.savePerformanceMetric(
            name: "\(periodName)_prediction_coverage",
            value: predictionCoverage,
            calculationDate: date,
            periodStart: startDate,
            periodEnd: endDate,
            details: "Percentage of predictions with known outcomes for \(periodName) period"
        )
    }
    
    private func calculateOverallAccuracy(for companyIds: Set<String>, in dateRange: ClosedRange<Date>) -> Double {
        var totalAccuracy = 0.0
        var count = 0
        
        for companyId in companyIds {
            guard let uuid = UUID(uuidString: companyId) else { continue }
            let outcomes = historicalDataService.getActualOutcomes(for: uuid)
            
            for outcome in outcomes {
                if dateRange.contains(outcome.eventDate),
                   let accuracy = outcome.predictionAccuracy {
                    totalAccuracy += accuracy
                    count += 1
                }
            }
        }
        
        return count > 0 ? totalAccuracy / Double(count) : 0.0
    }
    
    private func calculateRecommendationAccuracy(for companyIds: Set<String>, in dateRange: ClosedRange<Date>) -> Double {
        var correctRecommendations = 0
        var totalRecommendations = 0
        
        for companyId in companyIds {
            guard let uuid = UUID(uuidString: companyId) else { continue }
            let outcomes = historicalDataService.getActualOutcomes(for: uuid)
            
            for outcome in outcomes {
                if dateRange.contains(outcome.eventDate) {
                    totalRecommendations += 1
                    
                    // Simple heuristic: positive outcomes should have buy/strong buy recommendations
                    let wasPositiveOutcome = outcome.eventType == "acquisition" || outcome.eventType == "ipo"
                    let wasPositiveRecommendation = outcome.originalRecommendation.contains("Buy")
                    
                    if wasPositiveOutcome == wasPositiveRecommendation {
                        correctRecommendations += 1
                    }
                }
            }
        }
        
        return totalRecommendations > 0 ? Double(correctRecommendations) / Double(totalRecommendations) : 0.0
    }
    
    private func calculateScoreCorrelation(for companyIds: Set<String>, in dateRange: ClosedRange<Date>) -> Double {
        var scores: [Double] = []
        var outcomeValues: [Double] = []
        
        for companyId in companyIds {
            guard let uuid = UUID(uuidString: companyId) else { continue }
            let outcomes = historicalDataService.getActualOutcomes(for: uuid)
            
            for outcome in outcomes {
                if dateRange.contains(outcome.eventDate) {
                    scores.append(outcome.originalScore)
                    
                    // Convert outcome to numeric value
                    let outcomeValue: Double
                    switch outcome.eventType {
                    case "acquisition", "ipo": outcomeValue = 5.0
                    case "partnership": outcomeValue = 3.5
                    case "licensing": outcomeValue = 3.0
                    case "bankruptcy": outcomeValue = 1.0
                    default: outcomeValue = 2.5
                    }
                    outcomeValues.append(outcomeValue)
                }
            }
        }
        
        return calculateCorrelation(scores, outcomeValues)
    }
    
    private func calculatePredictionCoverage(for companyIds: Set<String>, in dateRange: ClosedRange<Date>) -> Double {
        let totalPredictions = historicalDataService.getHistoricalScores(from: dateRange.lowerBound, to: dateRange.upperBound).count
        let predictionsWithOutcomes = companyIds.count
        
        return totalPredictions > 0 ? Double(predictionsWithOutcomes) / Double(totalPredictions) : 0.0
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0.0
    }
    
    // MARK: - Performance Analysis
    
    /// Generates a comprehensive performance report
    func generatePerformanceReport(for period: MetricPeriod = .quarterly) -> PerformanceReport {
        let now = Date()
        let (startDate, endDate) = period.dateRange(from: now)
        
        // Get recent metrics
        let overallAccuracyMetrics = historicalDataService.getPerformanceMetrics(
            name: "\(period.rawValue)_overall_accuracy",
            from: startDate,
            to: endDate
        )
        
        let recommendationAccuracyMetrics = historicalDataService.getPerformanceMetrics(
            name: "\(period.rawValue)_recommendation_accuracy",
            from: startDate,
            to: endDate
        )
        
        let scoreCorrelationMetrics = historicalDataService.getPerformanceMetrics(
            name: "\(period.rawValue)_score_correlation",
            from: startDate,
            to: endDate
        )
        
        let coverageMetrics = historicalDataService.getPerformanceMetrics(
            name: "\(period.rawValue)_prediction_coverage",
            from: startDate,
            to: endDate
        )
        
        // Calculate trends
        let accuracyTrend = calculateTrend(overallAccuracyMetrics.map { $0.metricValue })
        let recommendationTrend = calculateTrend(recommendationAccuracyMetrics.map { $0.metricValue })
        
        // Generate insights
        let insights = generatePerformanceInsights(
            overallAccuracy: overallAccuracyMetrics.first?.metricValue ?? 0.0,
            recommendationAccuracy: recommendationAccuracyMetrics.first?.metricValue ?? 0.0,
            scoreCorrelation: scoreCorrelationMetrics.first?.metricValue ?? 0.0,
            coverage: coverageMetrics.first?.metricValue ?? 0.0,
            accuracyTrend: accuracyTrend
        )
        
        return PerformanceReport(
            period: period,
            startDate: startDate,
            endDate: endDate,
            overallAccuracy: overallAccuracyMetrics.first?.metricValue ?? 0.0,
            recommendationAccuracy: recommendationAccuracyMetrics.first?.metricValue ?? 0.0,
            scoreCorrelation: scoreCorrelationMetrics.first?.metricValue ?? 0.0,
            predictionCoverage: coverageMetrics.first?.metricValue ?? 0.0,
            accuracyTrend: accuracyTrend,
            recommendationTrend: recommendationTrend,
            insights: insights,
            generatedAt: now
        )
    }
    
    private func calculateTrend(_ values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let recent = values.prefix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        let older = values.suffix(values.count / 2).reduce(0, +) / Double(values.count / 2)
        
        let difference = recent - older
        
        if difference > 0.05 {
            return .improving
        } else if difference < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func generatePerformanceInsights(
        overallAccuracy: Double,
        recommendationAccuracy: Double,
        scoreCorrelation: Double,
        coverage: Double,
        accuracyTrend: TrendDirection
    ) -> [String] {
        var insights: [String] = []
        
        // Overall accuracy insights
        if overallAccuracy >= 0.8 {
            insights.append("Excellent overall prediction accuracy (\(String(format: "%.1f", overallAccuracy * 100))%)")
        } else if overallAccuracy >= 0.6 {
            insights.append("Good prediction accuracy with room for improvement (\(String(format: "%.1f", overallAccuracy * 100))%)")
        } else {
            insights.append("Prediction accuracy needs significant improvement (\(String(format: "%.1f", overallAccuracy * 100))%)")
        }
        
        // Recommendation accuracy insights
        if recommendationAccuracy >= 0.75 {
            insights.append("Investment recommendations are highly reliable")
        } else if recommendationAccuracy >= 0.5 {
            insights.append("Investment recommendations show moderate reliability")
        } else {
            insights.append("Investment recommendation accuracy requires attention")
        }
        
        // Score correlation insights
        if scoreCorrelation >= 0.7 {
            insights.append("Strong correlation between scores and actual outcomes")
        } else if scoreCorrelation >= 0.4 {
            insights.append("Moderate correlation between scores and outcomes")
        } else {
            insights.append("Weak correlation suggests model calibration issues")
        }
        
        // Coverage insights
        if coverage >= 0.8 {
            insights.append("Excellent outcome tracking coverage")
        } else if coverage >= 0.5 {
            insights.append("Good outcome tracking, consider improving data collection")
        } else {
            insights.append("Low outcome coverage limits performance assessment")
        }
        
        // Trend insights
        switch accuracyTrend {
        case .improving:
            insights.append("Model performance is improving over time")
        case .declining:
            insights.append("Model performance is declining - review needed")
        case .stable:
            insights.append("Model performance is stable")
        }
        
        return insights
    }
    
    // MARK: - Trend Analysis
    
    /// Analyzes performance trends over time
    func analyzeTrends(for metricName: String, period: MetricPeriod = .monthly, lookbackMonths: Int = 12) -> TrendAnalysis {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -lookbackMonths, to: endDate) ?? endDate
        
        let metrics = historicalDataService.getPerformanceMetrics(name: metricName, from: startDate, to: endDate)
        let values = metrics.map { $0.metricValue }
        let dates = metrics.map { $0.calculationDate }
        
        let trend = calculateTrend(values)
        let volatility = calculateVolatility(values)
        let average = values.isEmpty ? 0.0 : values.reduce(0, +) / Double(values.count)
        
        return TrendAnalysis(
            metricName: metricName,
            period: period,
            startDate: startDate,
            endDate: endDate,
            values: values,
            dates: dates,
            trend: trend,
            average: average,
            volatility: volatility,
            dataPoints: values.count
        )
    }
    
    private func calculateVolatility(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1)
        
        return sqrt(variance)
    }
}
/
/ MARK: - Supporting Data Models

/// Result of batch processing outcomes
struct BatchProcessingResult {
    let totalProcessed: Int
    let successCount: Int
    let failureCount: Int
    let errors: [String]
    
    var successRate: Double {
        totalProcessed > 0 ? Double(successCount) / Double(totalProcessed) : 0.0
    }
}

/// Time period for metrics calculation
enum MetricPeriod: String, CaseIterable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = date
        
        let startDate: Date
        switch self {
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .quarterly:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .yearly:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
        
        return (startDate, endDate)
    }
}

/// Direction of performance trend
enum TrendDirection: String, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var description: String {
        switch self {
        case .improving: return "Performance is improving"
        case .stable: return "Performance is stable"
        case .declining: return "Performance is declining"
        }
    }
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "yellow"
        case .declining: return "red"
        }
    }
}

/// Comprehensive performance report
struct PerformanceReport {
    let period: MetricPeriod
    let startDate: Date
    let endDate: Date
    let overallAccuracy: Double
    let recommendationAccuracy: Double
    let scoreCorrelation: Double
    let predictionCoverage: Double
    let accuracyTrend: TrendDirection
    let recommendationTrend: TrendDirection
    let insights: [String]
    let generatedAt: Date
    
    /// Overall performance grade
    var performanceGrade: PerformanceGrade {
        let averageScore = (overallAccuracy + recommendationAccuracy + scoreCorrelation + predictionCoverage) / 4.0
        
        if averageScore >= 0.8 {
            return .excellent
        } else if averageScore >= 0.6 {
            return .good
        } else if averageScore >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
}

/// Performance grade classification
enum PerformanceGrade: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "lightGreen"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Model performance exceeds expectations"
        case .good: return "Model performance meets expectations"
        case .fair: return "Model performance is acceptable but has room for improvement"
        case .poor: return "Model performance requires immediate attention"
        }
    }
}

/// Trend analysis for a specific metric
struct TrendAnalysis {
    let metricName: String
    let period: MetricPeriod
    let startDate: Date
    let endDate: Date
    let values: [Double]
    let dates: [Date]
    let trend: TrendDirection
    let average: Double
    let volatility: Double
    let dataPoints: Int
    
    /// Latest value in the trend
    var latestValue: Double? {
        values.first
    }
    
    /// Change from first to last value
    var totalChange: Double? {
        guard let first = values.last, let last = values.first else { return nil }
        return last - first
    }
    
    /// Percentage change from first to last value
    var percentageChange: Double? {
        guard let first = values.last, let last = values.first, first != 0 else { return nil }
        return ((last - first) / first) * 100
    }
}

/// Performance benchmark for comparison
struct PerformanceBenchmark {
    let metricName: String
    let targetValue: Double
    let minimumAcceptable: Double
    let excellent: Double
    let description: String
    
    func evaluate(_ value: Double) -> BenchmarkResult {
        if value >= excellent {
            return .excellent
        } else if value >= targetValue {
            return .target
        } else if value >= minimumAcceptable {
            return .acceptable
        } else {
            return .belowStandard
        }
    }
}

enum BenchmarkResult: String, CaseIterable {
    case excellent = "Excellent"
    case target = "Target"
    case acceptable = "Acceptable"
    case belowStandard = "Below Standard"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .target: return "lightGreen"
        case .acceptable: return "yellow"
        case .belowStandard: return "red"
        }
    }
}

// MARK: - Performance Tracking Extensions

extension PerformanceTrackingService {
    
    /// Gets standard performance benchmarks
    static var standardBenchmarks: [PerformanceBenchmark] {
        return [
            PerformanceBenchmark(
                metricName: "overall_accuracy",
                targetValue: 0.7,
                minimumAcceptable: 0.5,
                excellent: 0.85,
                description: "Overall prediction accuracy across all metrics"
            ),
            PerformanceBenchmark(
                metricName: "recommendation_accuracy",
                targetValue: 0.65,
                minimumAcceptable: 0.45,
                excellent: 0.8,
                description: "Accuracy of investment recommendations"
            ),
            PerformanceBenchmark(
                metricName: "score_correlation",
                targetValue: 0.6,
                minimumAcceptable: 0.3,
                excellent: 0.8,
                description: "Correlation between scores and actual outcomes"
            ),
            PerformanceBenchmark(
                metricName: "prediction_coverage",
                targetValue: 0.7,
                minimumAcceptable: 0.4,
                excellent: 0.9,
                description: "Percentage of predictions with known outcomes"
            )
        ]
    }
    
    /// Evaluates current performance against benchmarks
    func evaluateAgainstBenchmarks(report: PerformanceReport) -> [BenchmarkEvaluation] {
        let benchmarks = Self.standardBenchmarks
        var evaluations: [BenchmarkEvaluation] = []
        
        for benchmark in benchmarks {
            let currentValue: Double
            switch benchmark.metricName {
            case "overall_accuracy":
                currentValue = report.overallAccuracy
            case "recommendation_accuracy":
                currentValue = report.recommendationAccuracy
            case "score_correlation":
                currentValue = report.scoreCorrelation
            case "prediction_coverage":
                currentValue = report.predictionCoverage
            default:
                continue
            }
            
            let result = benchmark.evaluate(currentValue)
            let evaluation = BenchmarkEvaluation(
                benchmark: benchmark,
                currentValue: currentValue,
                result: result,
                gap: currentValue - benchmark.targetValue
            )
            
            evaluations.append(evaluation)
        }
        
        return evaluations
    }
    
    /// Generates recommendations for improving performance
    func generateImprovementRecommendations(evaluations: [BenchmarkEvaluation]) -> [ImprovementRecommendation] {
        var recommendations: [ImprovementRecommendation] = []
        
        for evaluation in evaluations {
            if evaluation.result == .belowStandard || evaluation.result == .acceptable {
                let recommendation = generateRecommendation(for: evaluation)
                recommendations.append(recommendation)
            }
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func generateRecommendation(for evaluation: BenchmarkEvaluation) -> ImprovementRecommendation {
        let metricName = evaluation.benchmark.metricName
        let gap = abs(evaluation.gap)
        
        let priority: RecommendationPriority = gap > 0.2 ? .high : (gap > 0.1 ? .medium : .low)
        
        let actions: [String]
        let description: String
        
        switch metricName {
        case "overall_accuracy":
            description = "Improve overall prediction accuracy"
            actions = [
                "Review and retrain scoring models with recent data",
                "Enhance data quality and completeness checks",
                "Implement ensemble methods for better predictions",
                "Increase frequency of model validation and updates"
            ]
        case "recommendation_accuracy":
            description = "Enhance investment recommendation accuracy"
            actions = [
                "Refine recommendation thresholds based on historical outcomes",
                "Implement more sophisticated recommendation logic",
                "Add market condition adjustments to recommendations",
                "Increase training data for recommendation models"
            ]
        case "score_correlation":
            description = "Improve correlation between scores and outcomes"
            actions = [
                "Recalibrate scoring algorithms with outcome data",
                "Review and adjust pillar weights based on predictive power",
                "Implement feedback loops from actual outcomes",
                "Add new features that better predict outcomes"
            ]
        case "prediction_coverage":
            description = "Increase outcome tracking coverage"
            actions = [
                "Implement automated outcome tracking systems",
                "Establish partnerships for better market intelligence",
                "Create incentives for outcome reporting",
                "Develop web scraping for public outcome data"
            ]
        default:
            description = "Improve metric performance"
            actions = ["Review and optimize the underlying processes"]
        }
        
        return ImprovementRecommendation(
            metricName: metricName,
            description: description,
            priority: priority,
            actions: actions,
            estimatedImpact: gap,
            timeframe: priority == .high ? "1-2 months" : "3-6 months"
        )
    }
}

/// Benchmark evaluation result
struct BenchmarkEvaluation {
    let benchmark: PerformanceBenchmark
    let currentValue: Double
    let result: BenchmarkResult
    let gap: Double // Positive means above target, negative means below
    
    var isAboveTarget: Bool {
        gap >= 0
    }
    
    var percentageOfTarget: Double {
        benchmark.targetValue > 0 ? (currentValue / benchmark.targetValue) * 100 : 0
    }
}

/// Improvement recommendation
struct ImprovementRecommendation {
    let metricName: String
    let description: String
    let priority: RecommendationPriority
    let actions: [String]
    let estimatedImpact: Double
    let timeframe: String
}

enum RecommendationPriority: Int, CaseIterable {
    case high = 3
    case medium = 2
    case low = 1
    
    var description: String {
        switch self {
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .low: return "Low Priority"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "yellow"
        }
    }
}