import Foundation
import SQLite3

/// Service for managing historical scoring data storage and retrieval
class HistoricalDataService {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init(databasePath: String = "historical_scores.db") {
        self.dbPath = databasePath
        initializeDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Initialization
    
    private func initializeDatabase() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("Unable to open database at path: \(dbPath)")
            return
        }
        
        createTables()
    }
    
    private func createTables() {
        createHistoricalScoresTable()
        createActualOutcomesTable()
        createScoringConfigurationsTable()
        createPerformanceMetricsTable()
    }
    
    private func createHistoricalScoresTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS historical_scores (
                id TEXT PRIMARY KEY,
                company_id TEXT NOT NULL,
                company_name TEXT NOT NULL,
                overall_score REAL NOT NULL,
                asset_quality_score REAL NOT NULL,
                market_outlook_score REAL NOT NULL,
                capital_intensity_score REAL NOT NULL,
                strategic_fit_score REAL NOT NULL,
                financial_readiness_score REAL NOT NULL,
                regulatory_risk_score REAL NOT NULL,
                confidence_overall REAL NOT NULL,
                confidence_data_completeness REAL NOT NULL,
                confidence_model_accuracy REAL NOT NULL,
                confidence_comparable_quality REAL NOT NULL,
                investment_recommendation TEXT NOT NULL,
                risk_level TEXT NOT NULL,
                scoring_config_id TEXT NOT NULL,
                scoring_data TEXT NOT NULL,
                timestamp DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        executeSQL(createTableSQL, errorMessage: "Error creating historical_scores table")
        
        // Create indexes for better query performance
        let indexSQL = """
            CREATE INDEX IF NOT EXISTS idx_historical_scores_company_id ON historical_scores(company_id);
            CREATE INDEX IF NOT EXISTS idx_historical_scores_timestamp ON historical_scores(timestamp);
            CREATE INDEX IF NOT EXISTS idx_historical_scores_overall_score ON historical_scores(overall_score);
        """
        
        executeSQL(indexSQL, errorMessage: "Error creating indexes for historical_scores table")
    }
    
    private func createActualOutcomesTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS actual_outcomes (
                id TEXT PRIMARY KEY,
                historical_score_id TEXT NOT NULL,
                company_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                event_date DATETIME NOT NULL,
                valuation REAL,
                details TEXT,
                prediction_accuracy REAL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (historical_score_id) REFERENCES historical_scores(id)
            );
        """
        
        executeSQL(createTableSQL, errorMessage: "Error creating actual_outcomes table")
        
        let indexSQL = """
            CREATE INDEX IF NOT EXISTS idx_actual_outcomes_company_id ON actual_outcomes(company_id);
            CREATE INDEX IF NOT EXISTS idx_actual_outcomes_event_date ON actual_outcomes(event_date);
            CREATE INDEX IF NOT EXISTS idx_actual_outcomes_event_type ON actual_outcomes(event_type);
        """
        
        executeSQL(indexSQL, errorMessage: "Error creating indexes for actual_outcomes table")
    }
    
    private func createScoringConfigurationsTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS scoring_configurations (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                weight_asset_quality REAL NOT NULL,
                weight_market_outlook REAL NOT NULL,
                weight_capital_intensity REAL NOT NULL,
                weight_strategic_fit REAL NOT NULL,
                weight_financial_readiness REAL NOT NULL,
                weight_regulatory_risk REAL NOT NULL,
                parameters TEXT NOT NULL,
                is_default INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        executeSQL(createTableSQL, errorMessage: "Error creating scoring_configurations table")
    }
    
    private func createPerformanceMetricsTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS performance_metrics (
                id TEXT PRIMARY KEY,
                metric_name TEXT NOT NULL,
                metric_value REAL NOT NULL,
                calculation_date DATETIME NOT NULL,
                period_start DATETIME,
                period_end DATETIME,
                details TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        executeSQL(createTableSQL, errorMessage: "Error creating performance_metrics table")
        
        let indexSQL = """
            CREATE INDEX IF NOT EXISTS idx_performance_metrics_name ON performance_metrics(metric_name);
            CREATE INDEX IF NOT EXISTS idx_performance_metrics_date ON performance_metrics(calculation_date);
        """
        
        executeSQL(indexSQL, errorMessage: "Error creating indexes for performance_metrics table")
    }
    
    private func executeSQL(_ sql: String, errorMessage: String) {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("\(errorMessage): \(errmsg)")
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing database")
        }
        db = nil
    }
}    

    // MARK: - Historical Score Storage
    
    /// Saves a scoring result to historical data
    func saveHistoricalScore(_ scoringResult: ScoringResult, companyName: String, configId: String) -> Bool {
        let insertSQL = """
            INSERT INTO historical_scores (
                id, company_id, company_name, overall_score,
                asset_quality_score, market_outlook_score, capital_intensity_score,
                strategic_fit_score, financial_readiness_score, regulatory_risk_score,
                confidence_overall, confidence_data_completeness, confidence_model_accuracy, confidence_comparable_quality,
                investment_recommendation, risk_level, scoring_config_id, scoring_data, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement for historical score")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Serialize scoring result to JSON
        guard let scoringData = try? JSONEncoder().encode(scoringResult),
              let scoringDataString = String(data: scoringData, encoding: .utf8) else {
            print("Error serializing scoring result")
            return false
        }
        
        // Bind parameters
        sqlite3_bind_text(statement, 1, scoringResult.id.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, scoringResult.companyId.uuidString, -1, nil)
        sqlite3_bind_text(statement, 3, companyName, -1, nil)
        sqlite3_bind_double(statement, 4, scoringResult.overallScore)
        sqlite3_bind_double(statement, 5, scoringResult.pillarScores.assetQuality.rawScore)
        sqlite3_bind_double(statement, 6, scoringResult.pillarScores.marketOutlook.rawScore)
        sqlite3_bind_double(statement, 7, scoringResult.pillarScores.capitalIntensity.rawScore)
        sqlite3_bind_double(statement, 8, scoringResult.pillarScores.strategicFit.rawScore)
        sqlite3_bind_double(statement, 9, scoringResult.pillarScores.financialReadiness.rawScore)
        sqlite3_bind_double(statement, 10, scoringResult.pillarScores.regulatoryRisk.rawScore)
        sqlite3_bind_double(statement, 11, scoringResult.confidence.overall)
        sqlite3_bind_double(statement, 12, scoringResult.confidence.dataCompleteness)
        sqlite3_bind_double(statement, 13, scoringResult.confidence.modelAccuracy)
        sqlite3_bind_double(statement, 14, scoringResult.confidence.comparableQuality)
        sqlite3_bind_text(statement, 15, scoringResult.investmentRecommendation.rawValue, -1, nil)
        sqlite3_bind_text(statement, 16, scoringResult.riskLevel.rawValue, -1, nil)
        sqlite3_bind_text(statement, 17, configId, -1, nil)
        sqlite3_bind_text(statement, 18, scoringDataString, -1, nil)
        
        // Format timestamp for SQLite
        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: scoringResult.timestamp)
        sqlite3_bind_text(statement, 19, timestampString, -1, nil)
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error inserting historical score: \(errmsg)")
            return false
        }
        
        return true
    }
    
    /// Retrieves historical scores for a specific company
    func getHistoricalScores(for companyId: UUID, limit: Int = 100) -> [HistoricalScoreRecord] {
        let selectSQL = """
            SELECT id, company_id, company_name, overall_score, timestamp, 
                   investment_recommendation, risk_level, scoring_data
            FROM historical_scores 
            WHERE company_id = ? 
            ORDER BY timestamp DESC 
            LIMIT ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement for historical scores")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, companyId.uuidString, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(limit))
        
        var records: [HistoricalScoreRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idString = sqlite3_column_text(statement, 0),
                  let companyIdString = sqlite3_column_text(statement, 1),
                  let companyName = sqlite3_column_text(statement, 2),
                  let timestampString = sqlite3_column_text(statement, 5),
                  let recommendationString = sqlite3_column_text(statement, 6),
                  let riskLevelString = sqlite3_column_text(statement, 7),
                  let scoringDataString = sqlite3_column_text(statement, 8) else {
                continue
            }
            
            let id = String(cString: idString)
            let companyIdStr = String(cString: companyIdString)
            let name = String(cString: companyName)
            let overallScore = sqlite3_column_double(statement, 3)
            let timestampStr = String(cString: timestampString)
            let recommendation = String(cString: recommendationString)
            let riskLevel = String(cString: riskLevelString)
            let scoringData = String(cString: scoringDataString)
            
            // Parse timestamp
            let formatter = ISO8601DateFormatter()
            guard let timestamp = formatter.date(from: timestampStr) else { continue }
            
            // Deserialize scoring result
            guard let data = scoringData.data(using: .utf8),
                  let scoringResult = try? JSONDecoder().decode(ScoringResult.self, from: data) else {
                continue
            }
            
            let record = HistoricalScoreRecord(
                id: id,
                companyId: companyIdStr,
                companyName: name,
                overallScore: overallScore,
                timestamp: timestamp,
                investmentRecommendation: recommendation,
                riskLevel: riskLevel,
                scoringResult: scoringResult
            )
            
            records.append(record)
        }
        
        return records
    }
    
    /// Retrieves all historical scores within a date range
    func getHistoricalScores(from startDate: Date, to endDate: Date) -> [HistoricalScoreRecord] {
        let selectSQL = """
            SELECT id, company_id, company_name, overall_score, timestamp, 
                   investment_recommendation, risk_level, scoring_data
            FROM historical_scores 
            WHERE timestamp BETWEEN ? AND ?
            ORDER BY timestamp DESC;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement for date range query")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        let formatter = ISO8601DateFormatter()
        let startDateString = formatter.string(from: startDate)
        let endDateString = formatter.string(from: endDate)
        
        sqlite3_bind_text(statement, 1, startDateString, -1, nil)
        sqlite3_bind_text(statement, 2, endDateString, -1, nil)
        
        var records: [HistoricalScoreRecord] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idString = sqlite3_column_text(statement, 0),
                  let companyIdString = sqlite3_column_text(statement, 1),
                  let companyName = sqlite3_column_text(statement, 2),
                  let timestampString = sqlite3_column_text(statement, 4),
                  let recommendationString = sqlite3_column_text(statement, 5),
                  let riskLevelString = sqlite3_column_text(statement, 6),
                  let scoringDataString = sqlite3_column_text(statement, 7) else {
                continue
            }
            
            let id = String(cString: idString)
            let companyIdStr = String(cString: companyIdString)
            let name = String(cString: companyName)
            let overallScore = sqlite3_column_double(statement, 3)
            let timestampStr = String(cString: timestampString)
            let recommendation = String(cString: recommendationString)
            let riskLevel = String(cString: riskLevelString)
            let scoringData = String(cString: scoringDataString)
            
            // Parse timestamp
            guard let timestamp = formatter.date(from: timestampStr) else { continue }
            
            // Deserialize scoring result
            guard let data = scoringData.data(using: .utf8),
                  let scoringResult = try? JSONDecoder().decode(ScoringResult.self, from: data) else {
                continue
            }
            
            let record = HistoricalScoreRecord(
                id: id,
                companyId: companyIdStr,
                companyName: name,
                overallScore: overallScore,
                timestamp: timestamp,
                investmentRecommendation: recommendation,
                riskLevel: riskLevel,
                scoringResult: scoringResult
            )
            
            records.append(record)
        }
        
        return records
    }
    
    // MARK: - Scoring Configuration Storage
    
    /// Saves a scoring configuration
    func saveScoringConfiguration(_ config: ScoringConfig) -> Bool {
        let insertSQL = """
            INSERT OR REPLACE INTO scoring_configurations (
                id, name, weight_asset_quality, weight_market_outlook, weight_capital_intensity,
                weight_strategic_fit, weight_financial_readiness, weight_regulatory_risk,
                parameters, is_default
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement for scoring configuration")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Serialize parameters to JSON
        guard let parametersData = try? JSONEncoder().encode(config.parameters),
              let parametersString = String(data: parametersData, encoding: .utf8) else {
            print("Error serializing scoring parameters")
            return false
        }
        
        sqlite3_bind_text(statement, 1, config.id.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, config.name, -1, nil)
        sqlite3_bind_double(statement, 3, config.weights.assetQuality)
        sqlite3_bind_double(statement, 4, config.weights.marketOutlook)
        sqlite3_bind_double(statement, 5, config.weights.capitalIntensity)
        sqlite3_bind_double(statement, 6, config.weights.strategicFit)
        sqlite3_bind_double(statement, 7, config.weights.financialReadiness)
        sqlite3_bind_double(statement, 8, config.weights.regulatoryRisk)
        sqlite3_bind_text(statement, 9, parametersString, -1, nil)
        sqlite3_bind_int(statement, 10, config.isDefault ? 1 : 0)
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error inserting scoring configuration: \(errmsg)")
            return false
        }
        
        return true
    }
    
    /// Retrieves all scoring configurations
    func getScoringConfigurations() -> [ScoringConfig] {
        let selectSQL = """
            SELECT id, name, weight_asset_quality, weight_market_outlook, weight_capital_intensity,
                   weight_strategic_fit, weight_financial_readiness, weight_regulatory_risk,
                   parameters, is_default
            FROM scoring_configurations 
            ORDER BY is_default DESC, name ASC;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement for scoring configurations")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        var configurations: [ScoringConfig] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idString = sqlite3_column_text(statement, 0),
                  let nameString = sqlite3_column_text(statement, 1),
                  let parametersString = sqlite3_column_text(statement, 8) else {
                continue
            }
            
            let idStr = String(cString: idString)
            let name = String(cString: nameString)
            let parametersStr = String(cString: parametersString)
            
            guard let configId = UUID(uuidString: idStr) else { continue }
            
            let weights = WeightConfig(
                assetQuality: sqlite3_column_double(statement, 2),
                marketOutlook: sqlite3_column_double(statement, 3),
                capitalIntensity: sqlite3_column_double(statement, 4),
                strategicFit: sqlite3_column_double(statement, 5),
                financialReadiness: sqlite3_column_double(statement, 6),
                regulatoryRisk: sqlite3_column_double(statement, 7)
            )
            
            // Deserialize parameters
            guard let parametersData = parametersStr.data(using: .utf8),
                  let parameters = try? JSONDecoder().decode(ScoringParameters.self, from: parametersData) else {
                continue
            }
            
            let isDefault = sqlite3_column_int(statement, 9) == 1
            
            let config = ScoringConfig(
                id: configId,
                name: name,
                weights: weights,
                parameters: parameters,
                isDefault: isDefault
            )
            
            configurations.append(config)
        }
        
        return configurations
    }
}

// MARK: - Supporting Data Models

/// Simplified historical score record for queries
struct HistoricalScoreRecord: Identifiable {
    let id: String
    let companyId: String
    let companyName: String
    let overallScore: Double
    let timestamp: Date
    let investmentRecommendation: String
    let riskLevel: String
    let scoringResult: ScoringResult
}
/
/ MARK: - Actual Outcomes Management

extension HistoricalDataService {
    
    /// Saves an actual outcome for a historical score
    func saveActualOutcome(_ outcome: ActualOutcome, for historicalScoreId: String, companyId: UUID) -> Bool {
        let insertSQL = """
            INSERT INTO actual_outcomes (
                id, historical_score_id, company_id, event_type, event_date, valuation, details
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement for actual outcome")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        let outcomeId = UUID().uuidString
        let formatter = ISO8601DateFormatter()
        let eventDateString = formatter.string(from: outcome.date)
        
        sqlite3_bind_text(statement, 1, outcomeId, -1, nil)
        sqlite3_bind_text(statement, 2, historicalScoreId, -1, nil)
        sqlite3_bind_text(statement, 3, companyId.uuidString, -1, nil)
        sqlite3_bind_text(statement, 4, outcome.eventType.rawValue, -1, nil)
        sqlite3_bind_text(statement, 5, eventDateString, -1, nil)
        
        if let valuation = outcome.valuation {
            sqlite3_bind_double(statement, 6, valuation)
        } else {
            sqlite3_bind_null(statement, 6)
        }
        
        if let details = outcome.details {
            sqlite3_bind_text(statement, 7, details, -1, nil)
        } else {
            sqlite3_bind_null(statement, 7)
        }
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error inserting actual outcome: \(errmsg)")
            return false
        }
        
        return true
    }
    
    /// Updates prediction accuracy for a historical score based on actual outcome
    func updatePredictionAccuracy(historicalScoreId: String, accuracy: Double) -> Bool {
        let updateSQL = """
            UPDATE actual_outcomes 
            SET prediction_accuracy = ? 
            WHERE historical_score_id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing update statement for prediction accuracy")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_double(statement, 1, accuracy)
        sqlite3_bind_text(statement, 2, historicalScoreId, -1, nil)
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error updating prediction accuracy: \(errmsg)")
            return false
        }
        
        return true
    }
    
    /// Retrieves actual outcomes for a company
    func getActualOutcomes(for companyId: UUID) -> [ActualOutcomeRecord] {
        let selectSQL = """
            SELECT ao.id, ao.historical_score_id, ao.event_type, ao.event_date, 
                   ao.valuation, ao.details, ao.prediction_accuracy,
                   hs.overall_score, hs.investment_recommendation
            FROM actual_outcomes ao
            JOIN historical_scores hs ON ao.historical_score_id = hs.id
            WHERE ao.company_id = ?
            ORDER BY ao.event_date DESC;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement for actual outcomes")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, companyId.uuidString, -1, nil)
        
        var outcomes: [ActualOutcomeRecord] = []
        let formatter = ISO8601DateFormatter()
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idString = sqlite3_column_text(statement, 0),
                  let historicalScoreIdString = sqlite3_column_text(statement, 1),
                  let eventTypeString = sqlite3_column_text(statement, 2),
                  let eventDateString = sqlite3_column_text(statement, 3),
                  let recommendationString = sqlite3_column_text(statement, 8) else {
                continue
            }
            
            let id = String(cString: idString)
            let historicalScoreId = String(cString: historicalScoreIdString)
            let eventType = String(cString: eventTypeString)
            let eventDateStr = String(cString: eventDateString)
            let recommendation = String(cString: recommendationString)
            
            guard let eventDate = formatter.date(from: eventDateStr) else { continue }
            
            let valuation = sqlite3_column_type(statement, 4) != SQLITE_NULL ? 
                sqlite3_column_double(statement, 4) : nil
            
            let details = sqlite3_column_type(statement, 5) != SQLITE_NULL ? 
                String(cString: sqlite3_column_text(statement, 5)!) : nil
            
            let predictionAccuracy = sqlite3_column_type(statement, 6) != SQLITE_NULL ? 
                sqlite3_column_double(statement, 6) : nil
            
            let overallScore = sqlite3_column_double(statement, 7)
            
            let outcome = ActualOutcomeRecord(
                id: id,
                historicalScoreId: historicalScoreId,
                eventType: eventType,
                eventDate: eventDate,
                valuation: valuation,
                details: details,
                predictionAccuracy: predictionAccuracy,
                originalScore: overallScore,
                originalRecommendation: recommendation
            )
            
            outcomes.append(outcome)
        }
        
        return outcomes
    }
    
    // MARK: - Performance Metrics Storage
    
    /// Saves a performance metric
    func savePerformanceMetric(name: String, value: Double, calculationDate: Date, 
                              periodStart: Date? = nil, periodEnd: Date? = nil, 
                              details: String? = nil) -> Bool {
        let insertSQL = """
            INSERT INTO performance_metrics (
                id, metric_name, metric_value, calculation_date, period_start, period_end, details
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing insert statement for performance metric")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        let metricId = UUID().uuidString
        let formatter = ISO8601DateFormatter()
        let calculationDateString = formatter.string(from: calculationDate)
        
        sqlite3_bind_text(statement, 1, metricId, -1, nil)
        sqlite3_bind_text(statement, 2, name, -1, nil)
        sqlite3_bind_double(statement, 3, value)
        sqlite3_bind_text(statement, 4, calculationDateString, -1, nil)
        
        if let periodStart = periodStart {
            let periodStartString = formatter.string(from: periodStart)
            sqlite3_bind_text(statement, 5, periodStartString, -1, nil)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        if let periodEnd = periodEnd {
            let periodEndString = formatter.string(from: periodEnd)
            sqlite3_bind_text(statement, 6, periodEndString, -1, nil)
        } else {
            sqlite3_bind_null(statement, 6)
        }
        
        if let details = details {
            sqlite3_bind_text(statement, 7, details, -1, nil)
        } else {
            sqlite3_bind_null(statement, 7)
        }
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error inserting performance metric: \(errmsg)")
            return false
        }
        
        return true
    }
    
    /// Retrieves performance metrics by name and date range
    func getPerformanceMetrics(name: String, from startDate: Date? = nil, to endDate: Date? = nil) -> [PerformanceMetricRecord] {
        var selectSQL = """
            SELECT id, metric_name, metric_value, calculation_date, period_start, period_end, details
            FROM performance_metrics 
            WHERE metric_name = ?
        """
        
        var parameters: [String] = [name]
        
        if let startDate = startDate {
            selectSQL += " AND calculation_date >= ?"
            let formatter = ISO8601DateFormatter()
            parameters.append(formatter.string(from: startDate))
        }
        
        if let endDate = endDate {
            selectSQL += " AND calculation_date <= ?"
            let formatter = ISO8601DateFormatter()
            parameters.append(formatter.string(from: endDate))
        }
        
        selectSQL += " ORDER BY calculation_date DESC;"
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing select statement for performance metrics")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), parameter, -1, nil)
        }
        
        var metrics: [PerformanceMetricRecord] = []
        let formatter = ISO8601DateFormatter()
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idString = sqlite3_column_text(statement, 0),
                  let metricNameString = sqlite3_column_text(statement, 1),
                  let calculationDateString = sqlite3_column_text(statement, 3) else {
                continue
            }
            
            let id = String(cString: idString)
            let metricName = String(cString: metricNameString)
            let metricValue = sqlite3_column_double(statement, 2)
            let calculationDateStr = String(cString: calculationDateString)
            
            guard let calculationDate = formatter.date(from: calculationDateStr) else { continue }
            
            let periodStart = sqlite3_column_type(statement, 4) != SQLITE_NULL ? 
                formatter.date(from: String(cString: sqlite3_column_text(statement, 4)!)) : nil
            
            let periodEnd = sqlite3_column_type(statement, 5) != SQLITE_NULL ? 
                formatter.date(from: String(cString: sqlite3_column_text(statement, 5)!)) : nil
            
            let details = sqlite3_column_type(statement, 6) != SQLITE_NULL ? 
                String(cString: sqlite3_column_text(statement, 6)!) : nil
            
            let metric = PerformanceMetricRecord(
                id: id,
                metricName: metricName,
                metricValue: metricValue,
                calculationDate: calculationDate,
                periodStart: periodStart,
                periodEnd: periodEnd,
                details: details
            )
            
            metrics.append(metric)
        }
        
        return metrics
    }
    
    // MARK: - Data Integrity and Maintenance
    
    /// Validates data integrity across all tables
    func validateDataIntegrity() -> DataIntegrityReport {
        var report = DataIntegrityReport()
        
        // Check for orphaned actual outcomes
        let orphanedOutcomesSQL = """
            SELECT COUNT(*) FROM actual_outcomes ao
            LEFT JOIN historical_scores hs ON ao.historical_score_id = hs.id
            WHERE hs.id IS NULL;
        """
        
        if let orphanedCount = executeScalarQuery(orphanedOutcomesSQL) {
            report.orphanedOutcomes = Int(orphanedCount)
        }
        
        // Check for missing scoring configurations
        let missingConfigsSQL = """
            SELECT COUNT(DISTINCT scoring_config_id) FROM historical_scores hs
            LEFT JOIN scoring_configurations sc ON hs.scoring_config_id = sc.id
            WHERE sc.id IS NULL;
        """
        
        if let missingCount = executeScalarQuery(missingConfigsSQL) {
            report.missingConfigurations = Int(missingCount)
        }
        
        // Check for data consistency issues
        let inconsistentScoresSQL = """
            SELECT COUNT(*) FROM historical_scores 
            WHERE overall_score < 1.0 OR overall_score > 5.0;
        """
        
        if let inconsistentCount = executeScalarQuery(inconsistentScoresSQL) {
            report.inconsistentScores = Int(inconsistentCount)
        }
        
        return report
    }
    
    private func executeScalarQuery(_ sql: String) -> Double? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return sqlite3_column_double(statement, 0)
        }
        
        return nil
    }
    
    /// Cleans up old data based on retention policy
    func cleanupOldData(retentionDays: Int = 365) -> Bool {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let cutoffDateString = formatter.string(from: cutoffDate)
        
        let deleteSQL = """
            DELETE FROM historical_scores 
            WHERE timestamp < ? AND id NOT IN (
                SELECT DISTINCT historical_score_id FROM actual_outcomes
            );
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Error preparing delete statement for cleanup")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, cutoffDateString, -1, nil)
        
        let result = sqlite3_step(statement)
        if result != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error during cleanup: \(errmsg)")
            return false
        }
        
        return true
    }
}

// MARK: - Supporting Data Models

struct ActualOutcomeRecord: Identifiable {
    let id: String
    let historicalScoreId: String
    let eventType: String
    let eventDate: Date
    let valuation: Double?
    let details: String?
    let predictionAccuracy: Double?
    let originalScore: Double
    let originalRecommendation: String
}

struct PerformanceMetricRecord: Identifiable {
    let id: String
    let metricName: String
    let metricValue: Double
    let calculationDate: Date
    let periodStart: Date?
    let periodEnd: Date?
    let details: String?
}

struct DataIntegrityReport {
    var orphanedOutcomes: Int = 0
    var missingConfigurations: Int = 0
    var inconsistentScores: Int = 0
    
    var hasIssues: Bool {
        orphanedOutcomes > 0 || missingConfigurations > 0 || inconsistentScores > 0
    }
}