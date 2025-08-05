import Foundation

// MARK: - Asset Quality Scoring Pillar

/// Evaluates pipeline strength, development stage, and competitive positioning
public class AssetQualityPillar: BaseScoringPillar {
    
    // MARK: - Initialization
    
    public init() {
        super.init(pillarInfo: PillarInfoFactory.createAssetQualityInfo())
    }
    
    // MARK: - ScoringPillar Implementation
    
    public override func calculateScore(data: CompanyData, context: MarketContext) async throws -> PillarScore {
        // Validate required data
        let validation = validateData(data)
        guard validation.isValid else {
            throw ScoringError.invalidData("Asset Quality scoring requires valid pipeline and therapeutic area data")
        }
        
        // Calculate individual scoring factors
        let pipelineStrengthFactor = calculatePipelineStrength(data)
        let developmentStageFactor = calculateDevelopmentStageScore(data)
        let competitivePositioningFactor = calculateCompetitivePositioning(data, context: context)
        let ipStrengthFactor = calculateIPStrength(data)
        let indicationSizeFactor = calculateIndicationSize(data)
        let unmetNeedFactor = calculateUnmetMedicalNeed(data, context: context)
        
        let factors = [
            pipelineStrengthFactor,
            developmentStageFactor,
            competitivePositioningFactor,
            ipStrengthFactor,
            indicationSizeFactor,
            unmetNeedFactor
        ]
        
        // Calculate weighted score
        let weightedScore = factors.reduce(0.0) { $0 + ($1.weight * $1.score) }
        let normalizedScore = normalizeScore(weightedScore)
        
        // Calculate confidence
        let dataCompleteness = calculateDataCompleteness(data)
        let confidence = calculateConfidence(
            dataCompleteness: dataCompleteness,
            dataQuality: assessDataQuality(data),
            methodologyReliability: 0.85 // Asset quality methodology is well-established
        )
        
        // Generate warnings
        let warnings = generateWarnings(
            score: normalizedScore,
            confidence: confidence,
            dataCompleteness: dataCompleteness
        ) + generateAssetSpecificWarnings(data)
        
        return PillarScore(
            rawScore: normalizedScore,
            confidence: confidence,
            factors: factors,
            warnings: warnings,
            explanation: "Asset quality evaluation based on pipeline strength, development stage, competitive positioning, IP strength, indication size, and unmet medical need"
        )
    }
    
    // MARK: - Specific Validation
    
    public override func performSpecificValidation(_ data: CompanyData) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check pipeline data
        if data.pipeline.programs.isEmpty {
            errors.append(ValidationError(
                field: "pipeline.programs",
                message: "At least one pipeline program is required for asset quality assessment",
                severity: .critical
            ))
        }
        
        // Check therapeutic areas
        if data.basicInfo.therapeuticAreas.isEmpty {
            errors.append(ValidationError(
                field: "basicInfo.therapeuticAreas",
                message: "Therapeutic areas are required for competitive positioning analysis",
                severity: .critical
            ))
        }
        
        // Check lead program data
        if data.pipeline.leadProgram.differentiators.isEmpty {
            warnings.append(ValidationWarning(
                field: "pipeline.leadProgram.differentiators",
                message: "No differentiators specified for lead program",
                suggestion: "Consider adding key differentiators to improve competitive positioning assessment"
            ))
        }
        
        // Check development stage consistency
        for program in data.pipeline.programs {
            if program.stage == .preclinical && program.indication.isEmpty {
                warnings.append(ValidationWarning(
                    field: "pipeline.programs.indication",
                    message: "Indication not specified for preclinical program: \(program.name)",
                    suggestion: "Specify target indication for more accurate assessment"
                ))
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateDataCompleteness(data)
        )
    }
    
    // MARK: - Scoring Factor Calculations
    
    private func calculatePipelineStrength(_ data: CompanyData) -> ScoringFactor {
        let programs = data.pipeline.programs
        let totalPrograms = programs.count
        
        // Score based on pipeline breadth and depth
        var score: Double = 1.0
        
        // Base score from number of programs
        switch totalPrograms {
        case 0:
            score = 1.0
        case 1:
            score = 2.5
        case 2...3:
            score = 3.5
        case 4...6:
            score = 4.0
        default:
            score = 4.5
        }
        
        // Adjust for program diversity (different indications)
        let uniqueIndications = Set(programs.