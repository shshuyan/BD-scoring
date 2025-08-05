import XCTest
@testable import BDScoringModule

class ReportTemplatesTests: XCTestCase {
    
    // MARK: - Template Creation Tests
    
    func testCreateDefaultTemplateForFullAnalysis() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        XCTAssertEqual(template.name, "Full Analysis Report")
        XCTAssertEqual(template.type, .full)
        XCTAssertFalse(template.sections.isEmpty)
        
        // Check required sections are present
        let sectionTypes = template.sections.map { $0.type }
        XCTAssertTrue(sectionTypes.contains(.executiveSummary))
        XCTAssertTrue(sectionTypes.contains(.scoringOverview))
        XCTAssertTrue(sectionTypes.contains(.pillarAnalysis))
        XCTAssertTrue(sectionTypes.contains(.recommendations))
        
        // Check section ordering
        let orderedSections = template.sections.sorted { $0.order < $1.order }
        XCTAssertEqual(template.sections, orderedSections)
    }
    
    func testCreateDefaultTemplateForExecutiveSummary() {
        let template = ReportTemplateService.createDefaultTemplate(for: .executiveSummary)
        
        XCTAssertEqual(template.name, "Executive Summary")
        XCTAssertEqual(template.type, .executiveSummary)
        XCTAssertEqual(template.sections.count, 2)
        
        let sectionTypes = template.sections.map { $0.type }
        XCTAssertTrue(sectionTypes.contains(.executiveSummary))
        XCTAssertTrue(sectionTypes.contains(.recommendations))
        
        // Check executive summary specific configuration
        let execSection = template.sections.first { $0.type == .executiveSummary }
        XCTAssertNotNil(execSection)
        XCTAssertEqual(execSection?.configuration.customContent["focus"], "high_level_insights")
        XCTAssertEqual(execSection?.configuration.customContent["length"], "2_pages_max")
    }
    
    func testCreateDefaultTemplateForPillarAnalysis() {
        let template = ReportTemplateService.createDefaultTemplate(for: .pillarAnalysis)
        
        XCTAssertEqual(template.name, "Pillar Analysis Report")
        XCTAssertEqual(template.type, .pillarAnalysis)
        
        let sectionTypes = template.sections.map { $0.type }
        XCTAssertTrue(sectionTypes.contains(.scoringOverview))
        XCTAssertTrue(sectionTypes.contains(.pillarAnalysis))
        XCTAssertTrue(sectionTypes.contains(.methodology))
        
        // Check pillar analysis specific configuration
        let pillarSection = template.sections.first { $0.type == .pillarAnalysis }
        XCTAssertNotNil(pillarSection)
        XCTAssertEqual(pillarSection?.configuration.customContent["pillar_detail_level"], "comprehensive")
        XCTAssertEqual(pillarSection?.configuration.customContent["include_factor_breakdown"], "true")
    }
    
    func testCreateDefaultTemplateForValuation() {
        let template = ReportTemplateService.createDefaultTemplate(for: .valuation)
        
        XCTAssertEqual(template.name, "Valuation Report")
        XCTAssertEqual(template.type, .valuation)
        
        let sectionTypes = template.sections.map { $0.type }
        XCTAssertTrue(sectionTypes.contains(.executiveSummary))
        XCTAssertTrue(sectionTypes.contains(.valuation))
        XCTAssertTrue(sectionTypes.contains(.riskAssessment))
        
        // Check valuation specific configuration
        let valuationSection = template.sections.first { $0.type == .valuation }
        XCTAssertNotNil(valuationSection)
        XCTAssertEqual(valuationSection?.configuration.customContent["include_scenarios"], "true")
        XCTAssertEqual(valuationSection?.configuration.customContent["include_sensitivity"], "true")
    }
    
    func testCreateAllDefaultTemplates() {
        let templates = ReportTemplateService.createAllDefaultTemplates()
        
        XCTAssertEqual(templates.count, ReportType.allCases.count)
        
        let templateTypes = templates.map { $0.type }
        for reportType in ReportType.allCases {
            XCTAssertTrue(templateTypes.contains(reportType))
        }
    }
    
    // MARK: - Template Validation Tests
    
    func testValidateValidTemplate() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        XCTAssertGreaterThan(validation.completeness, 0.8)
    }
    
    func testValidateTemplateWithNoRequiredSections() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        // Make all sections optional
        template.sections = template.sections.map { section in
            var modifiedSection = section
            modifiedSection.isRequired = false
            return modifiedSection
        }
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "sections" })
    }
    
    func testValidateTemplateWithDuplicateOrders() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        // Set duplicate orders
        if template.sections.count >= 2 {
            template.sections[1].order = template.sections[0].order
        }
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "sections.order" })
    }
    
    func testValidateTemplateWithInvalidFontSizes() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        template.formatting.fonts.headingSize = -1.0
        template.formatting.fonts.bodySize = 0.0
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "formatting.fonts" })
    }
    
    func testValidateTemplateWithNegativeMargins() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        template.formatting.margins.top = -0.5
        template.formatting.margins.left = -1.0
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.field == "formatting.margins" })
    }
    
    func testValidateTemplateWithTooManySections() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        // Add many sections to trigger warning
        for i in 8...15 {
            let section = ReportSection(
                name: "Extra Section \(i)",
                type: .appendix,
                order: i,
                isRequired: false,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            )
            template.sections.append(section)
        }
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertTrue(validation.isValid) // Should still be valid
        XCTAssertTrue(validation.warnings.contains { $0.field == "sections" })
    }
    
    func testValidateTemplateWithSmallHeadingFont() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        template.formatting.fonts.headingSize = 8.0
        template.formatting.fonts.bodySize = 12.0
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertTrue(validation.isValid) // Should still be valid
        XCTAssertTrue(validation.warnings.contains { $0.field == "formatting.fonts" })
    }
    
    // MARK: - Template Configuration Tests
    
    func testReportFormattingConfiguration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let formatting = template.formatting
        
        XCTAssertEqual(formatting.pageSize, .letter)
        XCTAssertGreaterThan(formatting.margins.top, 0)
        XCTAssertGreaterThan(formatting.margins.bottom, 0)
        XCTAssertGreaterThan(formatting.margins.left, 0)
        XCTAssertGreaterThan(formatting.margins.right, 0)
        
        XCTAssertFalse(formatting.fonts.headingFont.isEmpty)
        XCTAssertFalse(formatting.fonts.bodyFont.isEmpty)
        XCTAssertGreaterThan(formatting.fonts.headingSize, 0)
        XCTAssertGreaterThan(formatting.fonts.bodySize, 0)
        
        XCTAssertFalse(formatting.colors.primary.isEmpty)
        XCTAssertFalse(formatting.colors.secondary.isEmpty)
        XCTAssertFalse(formatting.colors.background.isEmpty)
        XCTAssertFalse(formatting.colors.text.isEmpty)
    }
    
    func testReportBrandingConfiguration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let branding = template.branding
        
        XCTAssertEqual(branding.companyName, "BD & IPO Scoring Module")
        XCTAssertNotNil(branding.headerText)
        XCTAssertNotNil(branding.footerText)
        XCTAssertNotNil(branding.contactInfo)
        
        if let contactInfo = branding.contactInfo {
            XCTAssertNotNil(contactInfo.email)
            XCTAssertNotNil(contactInfo.website)
        }
    }
    
    func testSectionConfiguration() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        // Test executive summary section
        let execSection = template.sections.first { $0.type == .executiveSummary }
        XCTAssertNotNil(execSection)
        XCTAssertTrue(execSection!.isRequired)
        XCTAssertTrue(execSection!.configuration.includeCharts)
        XCTAssertTrue(execSection!.configuration.pageBreakAfter)
        
        // Test methodology section
        let methodSection = template.sections.first { $0.type == .methodology }
        XCTAssertNotNil(methodSection)
        XCTAssertFalse(methodSection!.isRequired)
        XCTAssertFalse(methodSection!.configuration.includeCharts)
        XCTAssertFalse(methodSection!.configuration.customContent.isEmpty)
    }
    
    // MARK: - Template Extension Tests
    
    func testTemplateSectionsOfType() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        let execSections = template.sections(ofType: .executiveSummary)
        XCTAssertEqual(execSections.count, 1)
        XCTAssertEqual(execSections.first?.type, .executiveSummary)
        
        let appendixSections = template.sections(ofType: .appendix)
        XCTAssertTrue(appendixSections.isEmpty)
    }
    
    func testTemplateRequiredSections() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let requiredSections = template.requiredSections
        
        XCTAssertFalse(requiredSections.isEmpty)
        XCTAssertTrue(requiredSections.allSatisfy { $0.isRequired })
        
        // Check ordering
        for i in 1..<requiredSections.count {
            XCTAssertLessThan(requiredSections[i-1].order, requiredSections[i].order)
        }
    }
    
    func testTemplateOptionalSections() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let optionalSections = template.optionalSections
        
        XCTAssertTrue(optionalSections.allSatisfy { !$0.isRequired })
        
        // Check ordering
        for i in 1..<optionalSections.count {
            XCTAssertLessThan(optionalSections[i-1].order, optionalSections[i].order)
        }
    }
    
    func testTemplateWithSections() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let newSections = [
            ReportSection(
                name: "New Section",
                type: .appendix,
                order: 1,
                isRequired: true,
                configuration: SectionConfiguration(
                    includeCharts: false,
                    includeDetailedMetrics: false,
                    includeBenchmarks: false,
                    pageBreakAfter: false,
                    customContent: [:]
                )
            )
        ]
        
        let modifiedTemplate = template.withSections(newSections)
        
        XCTAssertEqual(modifiedTemplate.sections.count, 1)
        XCTAssertEqual(modifiedTemplate.sections.first?.name, "New Section")
        XCTAssertNotEqual(template.sections.count, modifiedTemplate.sections.count)
    }
    
    func testTemplateWithFormatting() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let newFormatting = ReportFormatting(
            pageSize: .a4,
            margins: PageMargins(top: 2.0, bottom: 2.0, left: 2.0, right: 2.0),
            fonts: FontConfiguration(
                headingFont: "Arial-Bold",
                bodyFont: "Arial",
                headingSize: 20.0,
                bodySize: 14.0
            ),
            colors: ColorScheme(
                primary: "#000000",
                secondary: "#666666",
                accent: "#ff0000",
                background: "#ffffff",
                text: "#333333"
            ),
            chartStyle: .colorful
        )
        
        let modifiedTemplate = template.withFormatting(newFormatting)
        
        XCTAssertEqual(modifiedTemplate.formatting.pageSize, .a4)
        XCTAssertEqual(modifiedTemplate.formatting.fonts.headingFont, "Arial-Bold")
        XCTAssertEqual(modifiedTemplate.formatting.chartStyle, .colorful)
        XCTAssertNotEqual(template.formatting.pageSize, modifiedTemplate.formatting.pageSize)
    }
    
    // MARK: - Section Extension Tests
    
    func testSectionWithConfiguration() {
        let section = ReportSection(
            name: "Test Section",
            type: .pillarAnalysis,
            order: 1,
            isRequired: true,
            configuration: SectionConfiguration(
                includeCharts: false,
                includeDetailedMetrics: false,
                includeBenchmarks: false,
                pageBreakAfter: false,
                customContent: [:]
            )
        )
        
        let newConfiguration = SectionConfiguration(
            includeCharts: true,
            includeDetailedMetrics: true,
            includeBenchmarks: true,
            pageBreakAfter: true,
            customContent: ["test": "value"]
        )
        
        let modifiedSection = section.withConfiguration(newConfiguration)
        
        XCTAssertTrue(modifiedSection.configuration.includeCharts)
        XCTAssertTrue(modifiedSection.configuration.includeDetailedMetrics)
        XCTAssertTrue(modifiedSection.configuration.includeBenchmarks)
        XCTAssertTrue(modifiedSection.configuration.pageBreakAfter)
        XCTAssertEqual(modifiedSection.configuration.customContent["test"], "value")
        
        XCTAssertFalse(section.configuration.includeCharts)
    }
    
    func testSectionShouldIncludeFlags() {
        let section = ReportSection(
            name: "Test Section",
            type: .pillarAnalysis,
            order: 1,
            isRequired: true,
            configuration: SectionConfiguration(
                includeCharts: true,
                includeDetailedMetrics: false,
                includeBenchmarks: true,
                pageBreakAfter: false,
                customContent: [:]
            )
        )
        
        XCTAssertTrue(section.shouldIncludeCharts)
        XCTAssertFalse(section.shouldIncludeDetailedMetrics)
        XCTAssertTrue(section.shouldIncludeBenchmarks)
    }
    
    // MARK: - Template Completeness Tests
    
    func testTemplateCompletenessCalculation() {
        let template = ReportTemplateService.createDefaultTemplate(for: .full)
        let validation = ReportTemplateService.validateTemplate(template)
        
        // Default templates should have high completeness
        XCTAssertGreaterThan(validation.completeness, 0.8)
    }
    
    func testIncompleteTemplateCompleteness() {
        var template = ReportTemplateService.createDefaultTemplate(for: .full)
        
        // Remove key elements to reduce completeness
        template.sections = []
        template.formatting.fonts.headingFont = ""
        template.formatting.colors.primary = ""
        template.branding.companyName = ""
        
        let validation = ReportTemplateService.validateTemplate(template)
        
        XCTAssertLessThan(validation.completeness, 0.5)
    }
    
    // MARK: - Template Codable Tests
    
    func testTemplateCodable() throws {
        let originalTemplate = ReportTemplateService.createDefaultTemplate(for: .full)
        
        let data = try JSONEncoder().encode(originalTemplate)
        let decodedTemplate = try JSONDecoder().decode(ReportTemplate.self, from: data)
        
        XCTAssertEqual(originalTemplate.name, decodedTemplate.name)
        XCTAssertEqual(originalTemplate.type, decodedTemplate.type)
        XCTAssertEqual(originalTemplate.sections.count, decodedTemplate.sections.count)
        XCTAssertEqual(originalTemplate.formatting.pageSize, decodedTemplate.formatting.pageSize)
        XCTAssertEqual(originalTemplate.branding.companyName, decodedTemplate.branding.companyName)
    }
    
    func testSectionCodable() throws {
        let section = ReportSection(
            name: "Test Section",
            type: .pillarAnalysis,
            order: 1,
            isRequired: true,
            configuration: SectionConfiguration(
                includeCharts: true,
                includeDetailedMetrics: false,
                includeBenchmarks: true,
                pageBreakAfter: false,
                customContent: ["key": "value"]
            )
        )
        
        let data = try JSONEncoder().encode(section)
        let decodedSection = try JSONDecoder().decode(ReportSection.self, from: data)
        
        XCTAssertEqual(section.name, decodedSection.name)
        XCTAssertEqual(section.type, decodedSection.type)
        XCTAssertEqual(section.order, decodedSection.order)
        XCTAssertEqual(section.isRequired, decodedSection.isRequired)
        XCTAssertEqual(section.configuration.includeCharts, decodedSection.configuration.includeCharts)
        XCTAssertEqual(section.configuration.customContent["key"], decodedSection.configuration.customContent["key"])
    }
}