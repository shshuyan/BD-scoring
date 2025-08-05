import SwiftUI

// Test compilation of ReportsAnalyticsView
struct TestReportsAnalyticsCompilation {
    func testCompilation() {
        let view = ReportsAnalyticsView()
        print("ReportsAnalyticsView compiled successfully")
        
        // Test data models
        let reports = ReportItem.sampleReports
        let metrics = AnalyticsMetric.sampleMetrics
        let distribution = ScoreDistributionItem.sampleDistribution
        let breakdown = TherapeuticAreaItem.sampleBreakdown
        
        print("Sample data created successfully:")
        print("- Reports: \(reports.count)")
        print("- Metrics: \(metrics.count)")
        print("- Distribution: \(distribution.count)")
        print("- Breakdown: \(breakdown.count)")
        
        // Test export formats
        let formats = ExportFormat.allCases
        print("- Export formats: \(formats.count)")
        
        print("All ReportsAnalytics components compiled successfully!")
    }
}