import SwiftUI

struct DashboardView: View {
    @State private var recentEvaluations = [
        RecentEvaluation(
            id: 1,
            name: "BioTech Alpha",
            stage: "Phase II",
            score: 4.2,
            status: .completed,
            indication: "Oncology",
            lastUpdated: "2 hours ago"
        ),
        RecentEvaluation(
            id: 2,
            name: "Genomics Beta",
            stage: "Phase III",
            score: 3.8,
            status: .inProgress,
            indication: "Rare Disease",
            lastUpdated: "1 day ago"
        ),
        RecentEvaluation(
            id: 3,
            name: "Neuro Gamma",
            stage: "Phase I",
            score: 3.5,
            status: .completed,
            indication: "CNS",
            lastUpdated: "3 days ago"
        )
    ]
    
    @State private var upcomingDeadlines = [
        UpcomingDeadline(company: "BioTech Alpha", task: "Due Diligence Report", dueIn: "2 days"),
        UpcomingDeadline(company: "Pharma Delta", task: "Valuation Update", dueIn: "5 days"),
        UpcomingDeadline(company: "Gene Epsilon", task: "Competitive Analysis", dueIn: "1 week")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                headerSection
                
                // Key Metrics
                keyMetricsSection
                
                // Recent Evaluations and Scoring Distribution
                HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                    recentEvaluationsSection
                    scoringDistributionSection
                }
                
                // Upcoming Deadlines and Quick Actions
                HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                    upcomingDeadlinesSection
                    quickActionsSection
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(DesignSystem.Typography.h1)
                    .foregroundColor(DesignSystem.Colors.foreground)
                
                Text("Overview of biotech investment opportunities and scoring metrics")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.mutedForeground)
            }
            
            Spacer()
            
            BDButton("New Evaluation", icon: "building.2") {
                // Handle new evaluation action
            }
        }
    }
    
    private var keyMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.lg), count: 4), spacing: DesignSystem.Spacing.lg) {
            MetricCard(
                title: "Total Companies",
                value: "247",
                subtitle: "+12 from last month",
                icon: "building.2"
            )
            
            MetricCard(
                title: "Average Score",
                value: "3.84",
                subtitle: "+0.15 from last quarter",
                icon: "target"
            )
            
            MetricCard(
                title: "Deal Value",
                value: "$2.4B",
                subtitle: "Active pipeline value",
                icon: "dollarsign.circle"
            )
            
            MetricCard(
                title: "Success Rate",
                value: "68%",
                subtitle: "Recommendations approved",
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }
    
    private var recentEvaluationsSection: some View {
        BDCard {
            BDCardHeader {
                BDCardTitle("Recent Evaluations")
                BDCardDescription("Latest company scoring results")
            }
            
            BDCardContent {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(recentEvaluations) { evaluation in
                        EvaluationRow(evaluation: evaluation)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var scoringDistributionSection: some View {
        BDCard {
            BDCardHeader {
                BDCardTitle("Scoring Distribution")
                BDCardDescription("Company scores across evaluation criteria")
            }
            
            BDCardContent {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ScoringRow(title: "Asset Quality", score: "4.1/5.0", progress: 0.82)
                    ScoringRow(title: "Market Outlook", score: "3.8/5.0", progress: 0.76)
                    ScoringRow(title: "Financial Readiness", score: "3.5/5.0", progress: 0.70)
                    ScoringRow(title: "Strategic Fit", score: "4.0/5.0", progress: 0.80)
                    ScoringRow(title: "Regulatory Risk", score: "3.2/5.0", progress: 0.64)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var upcomingDeadlinesSection: some View {
        BDCard {
            BDCardHeader {
                BDCardTitle("Upcoming Deadlines")
                BDCardDescription("Reports and tasks requiring attention")
            }
            
            BDCardContent {
                VStack(spacing: 12) {
                    ForEach(upcomingDeadlines, id: \.task) { deadline in
                        DeadlineRow(deadline: deadline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickActionsSection: some View {
        BDCard {
            BDCardHeader {
                BDCardTitle("Quick Actions")
                BDCardDescription("Common tasks and shortcuts")
            }
            
            BDCardContent {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    QuickActionButton(title: "New Company", icon: "building.2") {
                        // Handle action
                    }
                    
                    QuickActionButton(title: "Generate Report", icon: "doc.text") {
                        // Handle action
                    }
                    
                    QuickActionButton(title: "Score Review", icon: "target") {
                        // Handle action
                    }
                    
                    QuickActionButton(title: "Valuation", icon: "dollarsign.circle") {
                        // Handle action
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        BDCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.mutedForeground)
                        
                        Spacer()
                        
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.mutedForeground)
                    }
                    
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
            }
        }
    }
}

struct EvaluationRow: View {
    let evaluation: RecentEvaluation
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(evaluation.name)
                        .font(DesignSystem.Typography.label)
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    HStack(spacing: 8) {
                        BDBadge(evaluation.stage, variant: .outline)
                        
                        Text(evaluation.indication)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.mutedForeground)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text(String(format: "%.1f", evaluation.score))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Image(systemName: evaluation.status == .completed ? "checkmark.circle.fill" : "clock")
                        .font(.system(size: 16))
                        .foregroundColor(evaluation.status == .completed ? .green : .orange)
                }
                
                Text(evaluation.lastUpdated)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.mutedForeground)
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

struct ScoringRow: View {
    let title: String
    let score: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.foreground)
                
                Spacer()
                
                Text(score)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.foreground)
            }
            
            BDProgress(value: progress, height: 8)
        }
    }
}

struct DeadlineRow: View {
    let deadline: UpcomingDeadline
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(deadline.task)
                        .font(DesignSystem.Typography.label)
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Text(deadline.company)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
            }
            
            Spacer()
            
            BDBadge(deadline.dueIn, variant: .outline)
        }
        .padding(12)
        .background(DesignSystem.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.foreground)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.foreground)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models
struct RecentEvaluation: Identifiable {
    let id: Int
    let name: String
    let stage: String
    let score: Double
    let status: EvaluationStatus
    let indication: String
    let lastUpdated: String
}

enum EvaluationStatus {
    case completed
    case inProgress
}

struct UpcomingDeadline {
    let company: String
    let task: String
    let dueIn: String
}

#Preview {
    DashboardView()
}