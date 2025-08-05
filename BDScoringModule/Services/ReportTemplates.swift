import Foundation

/// Service for managing report templates and configurations
class ReportTemplateService {
    
    // MARK: - Template Creation
    
    /// Creates a default template for the specified report type
    static func createDefaultTemplate(for type: ReportType) -> ReportTemplate {
        switch type {
        case .full:
            return createFullAnalysisTemplate()
        case .executiveSummary:
            return createExecutiveSummaryTemplate()
        case .pillarAnalysis:
            return createPillarAnalysisTemplate()
        case .valuation:
            return createValuationTemplate()
        }
    }
    
    /// Creates all default templates
    static func createAllDefaultTemplates() -> [ReportTemplate] {
        return ReportType.allCases.map { createDefaultTemplate(for: $0) }
    }
    
    // MARK: - Full Analysis Template
    
    private static func createFullAnalysisTemplate() -> ReportTemplate {
        let sections = [
            ReportSection(
                name: "Executive Summary",
                type: .executiveSummary,
                order: 1,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: false,
                    includeBenchmarks: true,
                    pageBreakAfter: true,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Scoring Overview",
                type: .scoringOverview,
                order: 2,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Pillar Analysis",
                type: .pillarAnalysis,
                order: 3,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: true,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Risk Assessment",
                type: .riskAssessment,
                order: 4,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Valuation Analysis",
                type: .valuation,
                order: 5,
                isRequired: false,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: true,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Recommendations",
                type: .recommendations,
                order: 6,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Methodology",
                type: .methodology,
                order: 7,
                isRequired: false,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [
                        "scoring_methodology": "Six-pillar scoring framework with configurable weights",
                        "data_sources": "Company filings, clinical trial databases, market research",
                        "validation_process": "Multi-stage validation with confidence scoring"
                    ]
                )
            )
        ]
        
        return ReportTemplate(
            name: "Full Analysis Report",
            type: .full,
            sections: sections,
            formatting: createProfessionalFormatting(),
            branding: createDefaultBranding()
        )
    }
    
    // MARK: - Executive Summary Template
    
    private static func createExecutiveSummaryTemplate() -> ReportTemplate {
        let sections = [
            ReportSection(
                name: "Executive Summary",
                type: .executiveSummary,
                order: 1,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: false,
                    includeBenchmarks: true,
                    pageBreakAfter: false,
                    customContent: [
                        "focus": "high_level_insights",
                        "length": "2_pages_max"
                    ]
                )
            ),
            ReportSection(
                name: "Key Recommendations",
                type: .recommendations,
                order: 2,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [
                        "format": "bullet_points",
                        "max_items": "5"
                    ]
                )
            )
        ]
        
        return ReportTemplate(
            name: "Executive Summary",
            type: .executiveSummary,
            sections: sections,
            formatting: createExecutiveFormatting(),
            branding: createDefaultBranding()
        )
    }
    
    // MARK: - Pillar Analysis Template
    
    private static func createPillarAnalysisTemplate() -> ReportTemplate {
        let sections = [
            ReportSection(
                name: "Scoring Overview",
                type: .scoringOverview,
                order: 1,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            ),
            ReportSection(
                name: "Detailed Pillar Analysis",
                type: .pillarAnalysis,
                order: 2,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: false,
                    customContent: [
                        "pillar_detail_level": "comprehensive",
                        "include_factor_breakdown": "true",
                        "include_peer_comparison": "true"
                    ]
                )
            ),
            ReportSection(
                name: "Methodology",
                type: .methodology,
                order: 3,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [
                        "focus": "scoring_methodology",
                        "include_weights": "true"
                    ]
                )
            )
        ]
        
        return ReportTemplate(
            name: "Pillar Analysis Report",
            type: .pillarAnalysis,
            sections: sections,
            formatting: createAnalyticalFormatting(),
            branding: createDefaultBranding()
        )
    }
    
    // MARK: - Valuation Template
    
    private static func createValuationTemplate() -> ReportTemplate {
        let sections = [
            ReportSection(
                name: "Valuation Summary",
                type: .executiveSummary,
                order: 1,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [
                        "focus": "valuation_highlights"
                    ]
                )
            ),
            ReportSection(
                name: "Valuation Analysis",
                type: .valuation,
                order: 2,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: true,
                    includeBenchmarks: true,
                    pageBreakAfter: false,
                    customContent: [
                        "include_scenarios": "true",
                        "include_sensitivity": "true",
                        "include_comparables": "true"
                    ]
                )
            ),
            ReportSection(
                name: "Risk Assessment",
                type: .riskAssessment,
                order: 3,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: true,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [
                        "focus": "valuation_risks"
                    ]
                )
            )
        ]
        
        return ReportTemplate(
            name: "Valuation Report",
            type: .valuation,
            sections: sections,
            formatting: createFinancialFormatting(),
            branding: createDefaultBranding()
        )
    }
    
    // MARK: - Formatting Configurations
    
    private static func createProfessionalFormatting() -> ReportFormatting {
        return ReportFormatting(
            pageSize: .letter,
            margins: PageMargins(top: 1.0, bottom: 1.0, left: 1.0, right: 1.0),
            fonts: FontConfiguration(
                headingFont: "Helvetica-Bold",
                bodyFont: "Helvetica",
                headingSize: 16.0,
                bodySize: 11.0
            ),
            colors: ColorScheme(
                primary: "#1f4e79",
                secondary: "#4472c4",
                accent: "#70ad47",
                background: "#ffffff",
                text: "#333333"
            ),
            chartStyle: .professional
        )
    }
    
    private static func createExecutiveFormatting() -> ReportFormatting {
        return ReportFormatting(
            pageSize: .letter,
            margins: PageMargins(top: 1.0, bottom: 1.0, left: 1.0, right: 1.0),
            fonts: FontConfiguration(
                headingFont: "Helvetica-Bold",
                bodyFont: "Helvetica",
                headingSize: 18.0,
                bodySize: 12.0
            ),
            colors: ColorScheme(
                primary: "#1f4e79",
                secondary: "#4472c4",
                accent: "#c5504b",
                background: "#ffffff",
                text: "#333333"
            ),
            chartStyle: .modern
        )
    }
    
    private static func createAnalyticalFormatting() -> ReportFormatting {
        return ReportFormatting(
            pageSize: .letter,
            margins: PageMargins(top: 0.75, bottom: 0.75, left: 0.75, right: 0.75),
            fonts: FontConfiguration(
                headingFont: "Helvetica-Bold",
                bodyFont: "Helvetica",
                headingSize: 14.0,
                bodySize: 10.0
            ),
            colors: ColorScheme(
                primary: "#2f5597",
                secondary: "#5b9bd5",
                accent: "#a5a5a5",
                background: "#ffffff",
                text: "#333333"
            ),
            chartStyle: .minimal
        )
    }
    
    private static func createFinancialFormatting() -> ReportFormatting {
        return ReportFormatting(
            pageSize: .letter,
            margins: PageMargins(top: 1.0, bottom: 1.0, left: 1.0, right: 1.0),
            fonts: FontConfiguration(
                headingFont: "Times-Bold",
                bodyFont: "Times-Roman",
                headingSize: 16.0,
                bodySize: 11.0
            ),
            colors: ColorScheme(
                primary: "#0f243e",
                secondary: "#2e75b6",
                accent: "#c55a11",
                background: "#ffffff",
                text: "#333333"
            ),
            chartStyle: .professional
        )
    }
    
    // MARK: - Branding Configuration
    
    private static func createDefaultBranding() -> ReportBranding {
        return ReportBranding(
            companyName: "BD & IPO Scoring Module",
            logoUrl: nil,
            headerText: "Confidential Analysis",
            footerText: "Generated by BD & IPO Scoring Module",
            watermark: nil,
            contactInfo: ContactInfo(
                email: "analysis@bdiposcoring.com",
                phone: nil,
                website: "www.bdiposcoring.com",
                address: nil
            )
        )
    }
    
    // MARK: - Template Validation
    
    /// Validates that a template is properly configured
    static func validateTemplate(_ template: ReportTemplate) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check required sections
        let requiredSections = template.sections.filter { $0.isRequired }
        if requiredSections.isEmpty {
            errors.append(ValidationError(
                field: "sections",
                message: "Template must have at least one required section",
                severity: .error
            ))
        }
        
        // Check section ordering
        let orders = template.sections.map { $0.order }
        let uniqueOrders = Set(orders)
        if orders.count != uniqueOrders.count {
            errors.append(ValidationError(
                field: "sections.order",
                message: "Section orders must be unique",
                severity: .error
            ))
        }
        
        // Check formatting
        if template.formatting.fonts.headingSize <= 0 || template.formatting.fonts.bodySize <= 0 {
            errors.append(ValidationError(
                field: "formatting.fonts",
                message: "Font sizes must be positive",
                severity: .error
            ))
        }
        
        // Check margins
        let margins = template.formatting.margins
        if margins.top < 0 || margins.bottom < 0 || margins.left < 0 || margins.right < 0 {
            errors.append(ValidationError(
                field: "formatting.margins",
                message: "Margins must be non-negative",
                severity: .error
            ))
        }
        
        // Warnings for best practices
        if template.sections.count > 10 {
            warnings.append(ValidationWarning(
                field: "sections",
                message: "Template has many sections, consider consolidating",
                suggestion: "Combine related sections for better readability"
            ))
        }
        
        if template.formatting.fonts.headingSize < template.formatting.fonts.bodySize {
            warnings.append(ValidationWarning(
                field: "formatting.fonts",
                message: "Heading font size should be larger than body font size",
                suggestion: "Increase heading font size for better hierarchy"
            ))
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            completeness: calculateTemplateCompleteness(template)
        )
    }
    
    private static func calculateTemplateCompleteness(_ template: ReportTemplate) -> Double {
        var score = 0.0
        let maxScore = 10.0
        
        // Basic structure (3 points)
        if !template.sections.isEmpty { score += 1.0 }
        if template.sections.contains(where: { $0.type == .executiveSummary }) { score += 1.0 }
        if template.sections.contains(where: { $0.isRequired }) { score += 1.0 }
        
        // Formatting (3 points)
        if !template.formatting.fonts.headingFont.isEmpty { score += 1.0 }
        if !template.formatting.colors.primary.isEmpty { score += 1.0 }
        if template.formatting.margins.top > 0 { score += 1.0 }
        
        // Branding (2 points)
        if !template.branding.companyName.isEmpty { score += 1.0 }
        if template.branding.contactInfo != nil { score += 1.0 }
        
        // Advanced features (2 points)
        if template.sections.contains(where: { $0.configuration.includeCharts }) { score += 1.0 }
        if template.sections.contains(where: { !$0.configuration.customContent.isEmpty }) { score += 1.0 }
        
        return score / maxScore
    }
}

// MARK: - Template Extensions

extension ReportTemplate {
    
    /// Gets sections of a specific type
    func sections(ofType type: SectionType) -> [ReportSection] {
        return sections.filter { $0.type == type }
    }
    
    /// Gets required sections only
    var requiredSections: [ReportSection] {
        return sections.filter { $0.isRequired }.sorted { $0.order < $1.order }
    }
    
    /// Gets optional sections only
    var optionalSections: [ReportSection] {
        return sections.filter { !$0.isRequired }.sorted { $0.order < $1.order }
    }
    
    /// Creates a copy with modified sections
    func withSections(_ newSections: [ReportSection]) -> ReportTemplate {
        var copy = self
        copy.sections = newSections
        return copy
    }
    
    /// Creates a copy with modified formatting
    func withFormatting(_ newFormatting: ReportFormatting) -> ReportTemplate {
        var copy = self
        copy.formatting = newFormatting
        return copy
    }
}

extension ReportSection {
    
    /// Creates a copy with modified configuration
    func withConfiguration(_ newConfiguration: SectionConfiguration) -> ReportSection {
        var copy = self
        copy.configuration = newConfiguration
        return copy
    }
    
    /// Checks if section should include charts
    var shouldIncludeCharts: Bool {
        return configuration.includeCharts
    }
    
    /// Checks if section should include detailed metrics
    var shouldIncludeDetailedMetrics: Bool {
        return configuration.includeDetailedMetrics
    }
    
    /// Checks if section should include benchmarks
    var shouldIncludeBenchmarks: Bool {
        return configuration.includeBenchmarks
    }
}