import SwiftUI

struct ReportsAnalyticsView: View {
    @State private var selectedTab = "reports"
    @State private var selectedTimeframe = "last-quarter"
    @State private var showingExportSheet = false
    @State private var selectedReport: ReportItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reports & Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Generate comprehensive reports and analyze evaluation trends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        SecondaryButton("Share", icon: "square.and.arrow.up") {
                            // Share functionality
                        }
                        
                        PrimaryButton("New Report", icon: "doc.text") {
                            // New report functionality
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Tab Navigation
            HStack(spacing: 0) {
                TabButton(title: "Reports", isSelected: selectedTab == "reports") {
                    selectedTab = "reports"
                }
                TabButton(title: "Analytics", isSelected: selectedTab == "analytics") {
                    selectedTab = "analytics"
                }
                TabButton(title: "Trends", isSelected: selectedTab == "trends") {
                    selectedTab = "trends"
                }
                TabButton(title: "Benchmarks", isSelected: selectedTab == "benchmarks") {
                    selectedTab = "benchmarks"
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case "reports":
                        ReportsTabView(
                            selectedTimeframe: $selectedTimeframe,
                            selectedReport: $selectedReport,
                            showingExportSheet: $showingExportSheet
                        )
                    case "analytics":
                        AnalyticsTabView()
                    case "trends":
                        TrendsTabView()
                    case "benchmarks":
                        BenchmarksTabView()
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingExportSheet) {
            if let report = selectedReport {
                ExportReportSheet(report: report)
            }
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Reports Tab View
struct ReportsTabView: View {
    @Binding var selectedTimeframe: String
    @Binding var selectedReport: ReportItem?
    @Binding var showingExportSheet: Bool
    
    private let reports = ReportItem.sampleReports
    
    var body: some View {
        VStack(spacing: 20) {
            // Filters
            HStack {
                Menu {
                    Button("Last Week") { selectedTimeframe = "last-week" }
                    Button("Last Month") { selectedTimeframe = "last-month" }
                    Button("Last Quarter") { selectedTimeframe = "last-quarter" }
                    Button("Last Year") { selectedTimeframe = "last-year" }
                } label: {
                    HStack {
                        Text(timeframeDisplayText)
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                SecondaryButton("Filter", icon: "line.3.horizontal.decrease.circle") {
                    // Filter functionality
                }
                
                Spacer()
            }
            
            // Reports Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(reports) { report in
                    ReportCard(
                        report: report,
                        onView: { selectedReport = report },
                        onExport: { 
                            selectedReport = report
                            showingExportSheet = true
                        }
                    )
                }
            }
        }
    }
    
    private var timeframeDisplayText: String {
        switch selectedTimeframe {
        case "last-week": return "Last Week"
        case "last-month": return "Last Month"
        case "last-quarter": return "Last Quarter"
        case "last-year": return "Last Year"
        default: return "Last Quarter"
        }
    }
}

// MARK: - Report Card Component
struct ReportCard: View {
    let report: ReportItem
    let onView: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        Card {
            CardHeader {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            Text(report.company)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(
                            text: report.status.rawValue,
                            style: report.status == .completed ? .success : .secondary
                        )
                    }
                }
            }
            
            CardContent {
                VStack(spacing: 12) {
                    HStack {
                        Text("Type:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        StatusBadge(text: report.type.rawValue, style: .primary)
                    }
                    
                    HStack {
                        Text("Score:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(report.score, specifier: "%.1f")/5.0")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Recommendation:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        StatusBadge(
                            text: report.recommendation.rawValue,
                            style: badgeStyleForRecommendation(report.recommendation)
                        )
                    }
                    
                    HStack {
                        Text("Created:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(report.created, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: onView) {
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                    .font(.system(size: 12))
                                Text("View")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onExport) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12))
                                Text("Export")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private func badgeStyleForRecommendation(_ recommendation: InvestmentRecommendation) -> StatusBadge.BadgeStyle {
        switch recommendation {
        case .strongBuy, .buy: return .success
        case .hold: return .warning
        case .sell, .strongSell: return .danger
        }
    }
}

// MARK: - Analytics Tab View
struct AnalyticsTabView: View {
    private let analyticsData = AnalyticsMetric.sampleMetrics
    private let scoreDistribution = ScoreDistributionItem.sampleDistribution
    private let therapeuticBreakdown = TherapeuticAreaItem.sampleBreakdown
    
    var body: some View {
        VStack(spacing: 24) {
            // Key Metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(analyticsData) { metric in
                    MetricCard(
                        title: metric.name,
                        value: metric.value,
                        subtitle: metric.change,
                        icon: "chart.line.uptrend.xyaxis",
                        trend: metric.trend
                    )
                }
            }
            
            HStack(alignment: .top, spacing: 16) {
                // Score Distribution
                Card {
                    CardHeader {
                        VStack(alignment: .leading, spacing: 4) {
                            CardTitle(text: "Score Distribution")
                            CardDescription(text: "Distribution of evaluation scores")
                        }
                    }
                    
                    CardContent {
                        VStack(spacing: 16) {
                            ForEach(scoreDistribution) { item in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(item.range)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(item.count) companies (\(item.percentage)%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    ProgressBar(
                                        value: Double(item.percentage) / 100.0,
                                        height: 8,
                                        foregroundColor: item.color
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Therapeutic Area Breakdown
                Card {
                    CardHeader {
                        VStack(alignment: .leading, spacing: 4) {
                            CardTitle(text: "Therapeutic Area Breakdown")
                            CardDescription(text: "Evaluations by therapeutic focus")
                        }
                    }
                    
                    CardContent {
                        VStack(spacing: 12) {
                            ForEach(therapeuticBreakdown) { area in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(area.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(area.count) companies (\(area.percentage)%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(area.avgScore, specifier: "%.1f")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("avg score")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Trends Tab View
struct TrendsTabView: View {
    var body: some View {
        Card {
            CardHeader {
                VStack(alignment: .leading, spacing: 4) {
                    CardTitle(text: "Evaluation Trends")
                    CardDescription(text: "Historical trends in scoring and recommendations")
                }
            }
            
            CardContent {
                HStack(spacing: 16) {
                    TrendCard(
                        title: "Monthly Evaluations",
                        value: "23",
                        subtitle: "+12% vs last month",
                        progress: 0.65
                    )
                    
                    TrendCard(
                        title: "Score Trend",
                        value: "↗ 3.84",
                        subtitle: "+0.15 improvement",
                        progress: 0.77
                    )
                    
                    TrendCard(
                        title: "Success Rate",
                        value: "68%",
                        subtitle: "Recommendations approved",
                        progress: 0.68
                    )
                }
            }
        }
    }
}

// MARK: - Trend Card Component
struct TrendCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    
    var body: some View {
        Card {
            CardHeader {
                CardTitle(text: title)
            }
            
            CardContent {
                VStack(alignment: .leading, spacing: 8) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressBar(value: progress, height: 6)
                }
            }
        }
    }
}

// MARK: - Benchmarks Tab View
struct BenchmarksTabView: View {
    var body: some View {
        Card {
            CardHeader {
                VStack(alignment: .leading, spacing: 4) {
                    CardTitle(text: "Industry Benchmarks")
                    CardDescription(text: "Compare performance against industry standards")
                }
            }
            
            CardContent {
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        BenchmarkSection(
                            title: "Scoring Accuracy",
                            ourPerformance: 68,
                            industryAverage: 61
                        )
                        
                        BenchmarkSection(
                            title: "Deal Success Rate",
                            ourPerformance: 72,
                            industryAverage: 58
                        )
                    }
                    
                    HStack(spacing: 16) {
                        BenchmarkCard(
                            value: "+14%",
                            description: "Above Average Accuracy",
                            color: .green
                        )
                        
                        BenchmarkCard(
                            value: "+24%",
                            description: "Above Success Rate",
                            color: .green
                        )
                        
                        BenchmarkCard(
                            value: "92%",
                            description: "Client Satisfaction",
                            color: .blue
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Benchmark Components
struct BenchmarkSection: View {
    let title: String
    let ourPerformance: Int
    let industryAverage: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Our Performance")
                        .font(.caption)
                    Spacer()
                    Text("\(ourPerformance)%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressBar(value: Double(ourPerformance) / 100.0, height: 6)
                
                HStack {
                    Text("Industry Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(industryAverage)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct BenchmarkCard: View {
    let value: String
    let description: String
    let color: Color
    
    var body: some View {
        Card {
            CardContent {
                VStack(spacing: 8) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Export Sheet
struct ExportReportSheet: View {
    let report: ReportItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var includeCharts = true
    @State private var passwordProtected = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Report")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Export \"\(report.title)\" in your preferred format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Format")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: { selectedFormat = format }) {
                                HStack {
                                    Image(systemName: iconForFormat(format))
                                    Text(format.rawValue)
                                    Spacer()
                                    if selectedFormat == format {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(selectedFormat == format ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Options")
                        .font(.headline)
                    
                    Toggle("Include Charts", isOn: $includeCharts)
                    Toggle("Password Protected", isOn: $passwordProtected)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    SecondaryButton("Cancel") {
                        dismiss()
                    }
                    
                    PrimaryButton("Export") {
                        // Export functionality
                        dismiss()
                    }
                }
            }
            .padding(24)
            .navigationBarHidden(true)
        }
    }
    
    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .pdf: return "doc.fill"
        case .excel: return "tablecells.fill"
        case .powerpoint: return "rectangle.stack.fill"
        case .word: return "doc.text.fill"
        case .html: return "globe"
        }
    }
}

// MARK: - Data Models
struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let company: String
    let type: ReportType
    let status: ReportStatus
    let score: Double
    let recommendation: InvestmentRecommendation
    let created: Date
    
    static let sampleReports = [
        ReportItem(
            title: "BioTech Alpha - Investment Analysis",
            company: "BioTech Alpha",
            type: .executiveSummary,
            status: .completed,
            score: 4.2,
            recommendation: .strongBuy,
            created: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        ReportItem(
            title: "Q1 2024 Portfolio Review",
            company: "Multiple",
            type: .pillarAnalysis,
            status: .completed,
            score: 3.8,
            recommendation: .hold,
            created: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        ),
        ReportItem(
            title: "Genomics Beta - Due Diligence",
            company: "Genomics Beta",
            type: .full,
            status: .draft,
            score: 3.6,
            recommendation: .hold,
            created: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
        )
    ]
}

enum ReportStatus: String, CaseIterable {
    case completed = "Completed"
    case draft = "Draft"
    case inProgress = "In Progress"
}

struct AnalyticsMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let change: String
    let trend: String
    
    static let sampleMetrics = [
        AnalyticsMetric(name: "Total Evaluations", value: "247", change: "+12 from last period", trend: "up"),
        AnalyticsMetric(name: "Average Score", value: "3.84", change: "+0.15 from last period", trend: "up"),
        AnalyticsMetric(name: "Strong Buy Rate", value: "32%", change: "+5% from last period", trend: "up"),
        AnalyticsMetric(name: "Success Accuracy", value: "68%", change: "+3% from last period", trend: "up")
    ]
}

struct ScoreDistributionItem: Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let percentage: Int
    let color: Color
    
    static let sampleDistribution = [
        ScoreDistributionItem(range: "4.5 - 5.0", count: 42, percentage: 17, color: .green),
        ScoreDistributionItem(range: "4.0 - 4.5", count: 74, percentage: 30, color: Color.green.opacity(0.7)),
        ScoreDistributionItem(range: "3.5 - 4.0", count: 86, percentage: 35, color: .yellow),
        ScoreDistributionItem(range: "3.0 - 3.5", count: 32, percentage: 13, color: .orange),
        ScoreDistributionItem(range: "< 3.0", count: 13, percentage: 5, color: .red)
    ]
}

struct TherapeuticAreaItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Int
    let avgScore: Double
    
    static let sampleBreakdown = [
        TherapeuticAreaItem(name: "Oncology", count: 89, percentage: 36, avgScore: 4.1),
        TherapeuticAreaItem(name: "Rare Disease", count: 42, percentage: 17, avgScore: 4.3),
        TherapeuticAreaItem(name: "CNS", count: 35, percentage: 14, avgScore: 3.6),
        TherapeuticAreaItem(name: "Immunology", count: 53, percentage: 21, avgScore: 4.0),
        TherapeuticAreaItem(name: "Other", count: 28, percentage: 11, avgScore: 3.8)
    ]
}

#Preview {
    ReportsAnalyticsView()
}