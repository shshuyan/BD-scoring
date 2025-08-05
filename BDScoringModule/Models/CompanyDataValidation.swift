import Foundation

// MARK: - CompanyData Validation Extension

extension CompanyData {
    
    /// Validates the complete company data structure
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Validate each section
        let basicInfoValidation = validateBasicInfo()
        let pipelineValidation = validatePipeline()
        let financialsValidation = validateFinancials()
        let marketValidation = validateMarket()
        let regulatoryValidation = validateRegulatory()
        
        // Combine all validation results
        errors.append(contentsOf: basicInfoValidation.errors)
        errors.append(contentsOf: pipelineValidation.errors)
        errors.append(contentsOf: financialsValidation.errors)
        errors.append(contentsOf: marketValidation.errors)
        errors.append(contentsOf: regulatoryValidation.errors)
        
        warnings.append(contentsOf: basicInfoValidation.warnings)
        warnings.append(contentsOf: pipelineValidation.warnings)
        warnings.append(contentsOf: financialsValidation.warnings)
        warnings.append(contentsOf: marketValidation.warnings)
        warnings.append(contentsOf: regulatoryValidation.warnings)
        
        // Calculate overall completeness
        let completeness = calculateCompleteness()
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: completeness
        )
    }
    
    /// Validates basic company information
    private func validateBasicInfo() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Required field validations
        if basicInfo.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.name",
                message: "Company name is required",
                severity: .critical
            ))
        }
        
        if basicInfo.sector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.sector",
                message: "Company sector is required",
                severity: .error
            ))
        }
        
        if basicInfo.therapeuticAreas.isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.therapeuticAreas",
                message: "At least one therapeutic area must be specified",
                severity: .error
            ))
        }
        
        // Validation warnings
        if basicInfo.ticker == nil {
            warnings.append(ValidationWarning(
                field: "basicInfo.ticker",
                message: "Ticker symbol not provided",
                suggestion: "Adding ticker symbol improves comparable matching accuracy"
            ))
        }
        
        if basicInfo.description == nil || basicInfo.description?.isEmpty == true {
            warnings.append(ValidationWarning(
                field: "basicInfo.description",
                message: "Company description not provided",
                suggestion: "Adding description helps with strategic fit assessment"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateBasicInfoCompleteness()
        )
    }
    
    /// Validates pipeline data
    private func validatePipeline() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        if pipeline.programs.isEmpty {
            errors.append(ValidationError(
                field: "pipeline.programs",
                message: "At least one pipeline program is required",
                severity: .critical
            ))
        }
        
        // Validate individual programs
        for (index, program) in pipeline.programs.enumerated() {
            let programValidation = program.validate()
            
            // Add field prefix to errors and warnings
            for error in programValidation.errors {
                errors.append(ValidationError(
                    field: "pipeline.programs[\(index)].\(error.field)",
                    message: error.message,
                    severity: error.severity
                ))
            }
            
            for warning in programValidation.warnings {
                warnings.append(ValidationWarning(
                    field: "pipeline.programs[\(index)].\(warning.field)",
                    message: warning.message,
                    suggestion: warning.suggestion
                ))
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculatePipelineCompleteness()
        )
    }
    
    /// Validates financial data
    private func validateFinancials() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Cash position validation
        if financials.cashPosition < 0 {
            errors.append(ValidationError(
                field: "financials.cashPosition",
                message: "Cash position cannot be negative",
                severity: .error
            ))
        }
        
        if financials.cashPosition == 0 {
            warnings.append(ValidationWarning(
                field: "financials.cashPosition",
                message: "Zero cash position indicates potential financial distress",
                suggestion: "Verify cash position accuracy or consider immediate funding needs"
            ))
        }
        
        // Burn rate validation
        if financials.burnRate < 0 {
            errors.append(ValidationError(
                field: "financials.burnRate",
                message: "Burn rate cannot be negative",
                severity: .error
            ))
        }
        
        if financials.burnRate == 0 {
            warnings.append(ValidationWarning(
                field: "financials.burnRate",
                message: "Zero burn rate is unusual for biotech companies",
                suggestion: "Verify burn rate calculation includes R&D and operational expenses"
            ))
        }
        
        // Runway validation
        let runway = financials.runway
        if runway < 12 {
            warnings.append(ValidationWarning(
                field: "financials.runway",
                message: "Runway less than 12 months indicates urgent funding need",
                suggestion: "Company may be under pressure for quick partnership or financing"
            ))
        }
        
        // Last funding validation
        if let lastFunding = financials.lastFunding {
            let daysSinceLastFunding = Calendar.current.dateComponents([.day], from: lastFunding.date, to: Date()).day ?? 0
            
            if daysSinceLastFunding > 730 { // 2 years
                warnings.append(ValidationWarning(
                    field: "financials.lastFunding.date",
                    message: "Last funding was over 2 years ago",
                    suggestion: "Financial data may be stale, consider updating cash position and burn rate"
                ))
            }
            
            if lastFunding.amount <= 0 {
                errors.append(ValidationError(
                    field: "financials.lastFunding.amount",
                    message: "Funding amount must be positive",
                    severity: .error
                ))
            }
        } else {
            warnings.append(ValidationWarning(
                field: "financials.lastFunding",
                message: "No funding history provided",
                suggestion: "Funding history helps assess financial management and investor confidence"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateFinancialsCompleteness()
        )
    }
    
    /// Validates market data
    private func validateMarket() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Addressable market validation
        if market.addressableMarket <= 0 {
            errors.append(ValidationError(
                field: "market.addressableMarket",
                message: "Addressable market size must be positive",
                severity: .error
            ))
        }
        
        if market.addressableMarket < 0.1 { // Less than $100M
            warnings.append(ValidationWarning(
                field: "market.addressableMarket",
                message: "Small addressable market may limit commercial potential",
                suggestion: "Consider niche market dynamics and pricing strategies"
            ))
        }
        
        // Market dynamics validation
        if market.marketDynamics.growthRate < -50 || market.marketDynamics.growthRate > 200 {
            warnings.append(ValidationWarning(
                field: "market.marketDynamics.growthRate",
                message: "Unusual market growth rate detected",
                suggestion: "Verify growth rate calculation and market assumptions"
            ))
        }
        
        if market.competitors.isEmpty {
            warnings.append(ValidationWarning(
                field: "market.competitors",
                message: "No competitors identified",
                suggestion: "Competitive analysis is important for market positioning assessment"
            ))
        }
        
        // Validate individual competitors
        for (index, competitor) in market.competitors.enumerated() {
            if competitor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError(
                    field: "market.competitors[\(index)].name",
                    message: "Competitor name is required",
                    severity: .error
                ))
            }
            
            if let marketShare = competitor.marketShare {
                if marketShare < 0 || marketShare > 100 {
                    errors.append(ValidationError(
                        field: "market.competitors[\(index)].marketShare",
                        message: "Market share must be between 0 and 100 percent",
                        severity: .error
                    ))
                }
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateMarketCompleteness()
        )
    }
    
    /// Validates regulatory data
    private func validateRegulatory() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Regulatory strategy validation
        if regulatory.regulatoryStrategy.timeline <= 0 {
            errors.append(ValidationError(
                field: "regulatory.regulatoryStrategy.timeline",
                message: "Regulatory timeline must be positive",
                severity: .error
            ))
        }
        
        if regulatory.regulatoryStrategy.timeline > 180 { // 15 years
            warnings.append(ValidationWarning(
                field: "regulatory.regulatoryStrategy.timeline",
                message: "Very long regulatory timeline detected",
                suggestion: "Consider if timeline is realistic for the development stage"
            ))
        }
        
        // Clinical trials validation
        for (index, trial) in regulatory.clinicalTrials.enumerated() {
            if trial.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError(
                    field: "regulatory.clinicalTrials[\(index)].name",
                    message: "Clinical trial name is required",
                    severity: .error
                ))
            }
            
            if trial.indication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError(
                    field: "regulatory.clinicalTrials[\(index)].indication",
                    message: "Clinical trial indication is required",
                    severity: .error
                ))
            }
            
            // Date validation
            if let startDate = trial.startDate, let completionDate = trial.expectedCompletion {
                if startDate >= completionDate {
                    errors.append(ValidationError(
                        field: "regulatory.clinicalTrials[\(index)].expectedCompletion",
                        message: "Expected completion date must be after start date",
                        severity: .error
                    ))
                }
            }
            
            // Patient count validation
            if let patientCount = trial.patientCount {
                if patientCount <= 0 {
                    errors.append(ValidationError(
                        field: "regulatory.clinicalTrials[\(index)].patientCount",
                        message: "Patient count must be positive",
                        severity: .error
                    ))
                }
                
                // Phase-specific patient count warnings
                switch trial.phase {
                case .phase1:
                    if patientCount > 100 {
                        warnings.append(ValidationWarning(
                            field: "regulatory.clinicalTrials[\(index)].patientCount",
                            message: "Large patient count for Phase I trial",
                            suggestion: "Verify patient count is appropriate for safety study"
                        ))
                    }
                case .phase2:
                    if patientCount < 20 || patientCount > 500 {
                        warnings.append(ValidationWarning(
                            field: "regulatory.clinicalTrials[\(index)].patientCount",
                            message: "Unusual patient count for Phase II trial",
                            suggestion: "Typical Phase II trials have 20-500 patients"
                        ))
                    }
                case .phase3:
                    if patientCount < 100 {
                        warnings.append(ValidationWarning(
                            field: "regulatory.clinicalTrials[\(index)].patientCount",
                            message: "Small patient count for Phase III trial",
                            suggestion: "Phase III trials typically require larger patient populations"
                        ))
                    }
                default:
                    break
                }
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateRegulatoryCompleteness()
        )
    }
    
    // MARK: - Completeness Calculations
    
    private func calculateCompleteness() -> Double {
        let basicInfoCompleteness = calculateBasicInfoCompleteness()
        let pipelineCompleteness = calculatePipelineCompleteness()
        let financialsCompleteness = calculateFinancialsCompleteness()
        let marketCompleteness = calculateMarketCompleteness()
        let regulatoryCompleteness = calculateRegulatoryCompleteness()
        
        return (basicInfoCompleteness + pipelineCompleteness + financialsCompleteness + 
                marketCompleteness + regulatoryCompleteness) / 5.0
    }
    
    private func calculateBasicInfoCompleteness() -> Double {
        var score = 0.0
        let totalFields = 5.0
        
        if !basicInfo.name.isEmpty { score += 1.0 }
        if basicInfo.ticker != nil { score += 1.0 }
        if !basicInfo.sector.isEmpty { score += 1.0 }
        if !basicInfo.therapeuticAreas.isEmpty { score += 1.0 }
        if basicInfo.description != nil && !basicInfo.description!.isEmpty { score += 1.0 }
        
        return score / totalFields
    }
    
    private func calculatePipelineCompleteness() -> Double {
        guard !pipeline.programs.isEmpty else { return 0.0 }
        
        let programCompleteness = pipeline.programs.map { program in
            program.calculateCompleteness()
        }
        
        return programCompleteness.reduce(0, +) / Double(programCompleteness.count)
    }
    
    private func calculateFinancialsCompleteness() -> Double {
        var score = 0.0
        let totalFields = 3.0
        
        if financials.cashPosition > 0 { score += 1.0 }
        if financials.burnRate > 0 { score += 1.0 }
        if financials.lastFunding != nil { score += 1.0 }
        
        return score / totalFields
    }
    
    private func calculateMarketCompleteness() -> Double {
        var score = 0.0
        let totalFields = 3.0
        
        if market.addressableMarket > 0 { score += 1.0 }
        if !market.competitors.isEmpty { score += 1.0 }
        if !market.marketDynamics.barriers.isEmpty || !market.marketDynamics.drivers.isEmpty { score += 1.0 }
        
        return score / totalFields
    }
    
    private func calculateRegulatoryCompleteness() -> Double {
        var score = 0.0
        let totalFields = 3.0
        
        if regulatory.regulatoryStrategy.timeline > 0 { score += 1.0 }
        if !regulatory.clinicalTrials.isEmpty { score += 1.0 }
        if !regulatory.regulatoryStrategy.risks.isEmpty { score += 1.0 }
        
        return score / totalFields
    }
}

// MARK: - Program Validation Extension

extension Program {
    
    /// Validates individual program data
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Required field validations
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Program name is required",
                severity: .critical
            ))
        }
        
        if indication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "indication",
                message: "Program indication is required",
                severity: .error
            ))
        }
        
        if mechanism.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "mechanism",
                message: "Mechanism of action is required",
                severity: .error
            ))
        }
        
        // Validation warnings
        if differentiators.isEmpty {
            warnings.append(ValidationWarning(
                field: "differentiators",
                message: "No differentiators specified",
                suggestion: "Identifying key differentiators helps with competitive positioning"
            ))
        }
        
        if risks.isEmpty {
            warnings.append(ValidationWarning(
                field: "risks",
                message: "No risks identified",
                suggestion: "Risk assessment is important for comprehensive evaluation"
            ))
        }
        
        if timeline.isEmpty {
            warnings.append(ValidationWarning(
                field: "timeline",
                message: "No milestones defined",
                suggestion: "Development timeline helps assess program maturity and timing"
            ))
        }
        
        // Validate timeline consistency
        let sortedMilestones = timeline.sorted { $0.expectedDate < $1.expectedDate }
        for i in 1..<sortedMilestones.count {
            if sortedMilestones[i].expectedDate <= sortedMilestones[i-1].expectedDate {
                warnings.append(ValidationWarning(
                    field: "timeline",
                    message: "Milestone dates may not be in chronological order",
                    suggestion: "Review milestone sequencing for logical development progression"
                ))
                break
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateCompleteness()
        )
    }
    
    /// Calculates completeness score for the program
    func calculateCompleteness() -> Double {
        var score = 0.0
        let totalFields = 6.0
        
        if !name.isEmpty { score += 1.0 }
        if !indication.isEmpty { score += 1.0 }
        if !mechanism.isEmpty { score += 1.0 }
        if !differentiators.isEmpty { score += 1.0 }
        if !risks.isEmpty { score += 1.0 }
        if !timeline.isEmpty { score += 1.0 }
        
        return score / totalFields
    }
}