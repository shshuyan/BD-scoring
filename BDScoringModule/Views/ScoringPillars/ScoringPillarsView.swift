import SwiftUI

struct ScoringPillarsView: View {
    @State private var selectedPillar: PillarData?
    @State private var weightConfig = WeightConfig()
    @State private var showingWeightConfiguration = false
    
    var body: some View {
        NavigationStack {
            Group {
                if selectedPillar == nil {
                    pillarOverviewView
                } else {
                    pillarDetailView
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingWeightConfiguration) {
            WeightConfigurationSheet(weightConfig: $weightConfig)
        }
    }
    
    // MARK: - Pillar Overview
    private var pillarOverviewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scoring Pillars")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Configure and analyze the six key evaluation criteria for biotech companies")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        PrimaryButton("Configure Weights", icon: "gearshape") {
                            showingWeightConfiguration = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Pillar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(PillarData.allPillars) { pillar in
                        PillarCard(pillar: pillar) {
                            selectedPillar = pillar
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Weight Distribution Card
                WeightDistributionCard(weightConfig: weightConfig)
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 24)
            }
        }
    }
    
    // MARK: - Pillar Detail View
    private var pillarDetailView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 12) {
                            SecondaryButton("← Back") {
                                selectedPillar = nil
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: selectedPillar?.icon ?? "target")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedPillar?.name ?? "")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Text(selectedPillar?.description ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        StatusBadge(
                            text: "\(Int((selectedPillar?.weight ?? 0) * 100))% weight",
                            style: .primary
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Tabbed Content
                if let pillar = selectedPillar {
                    PillarDetailTabs(pillar: pillar, weightConfig: $weightConfig)
                        .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 24)
            }
        }
    }
}

// MARK: - Pillar Card Component
struct PillarCard: View {
    let pillar: PillarData
    let action: () -> Void
    
    var body: some View {
        Card {
            CardHeader {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: pillar.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            CardTitle(text: pillar.name)
                            StatusBadge(text: "\(Int(pillar.weight * 100))% weight", style: .secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            CardContent {
                VStack(alignment: .leading, spacing: 12) {
                    CardDescription(text: pillar.description)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Average Score")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(pillar.averageScore, specifier: "%.1f")/5.0")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        ProgressBar(value: pillar.averageScore / 5.0, height: 6)
                        
                        Text("Based on \(pillar.companies) companies")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Weight Distribution Card
struct WeightDistributionCard: View {
    let weightConfig: WeightConfig
    
    var body: some View {
        Card {
            CardHeader {
                CardTitle(text: "Weight Distribution")
                CardDescription(text: "Current allocation across all scoring pillars")
            }
            
            CardContent {
                VStack(spacing: 12) {
                    ForEach(PillarData.allPillars) { pillar in
                        HStack {
                            Text(pillar.name)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(Int(pillar.weight * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressBar(value: pillar.weight, height: 4)
                    }
                }
            }
        }
    }
}

// MARK: - Pillar Detail Tabs
struct PillarDetailTabs: View {
    let pillar: PillarData
    @Binding var weightConfig: WeightConfig
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(Array(["Configuration", "Analytics", "Benchmarks"].enumerated()), id: \.offset) { index, title in
                    Button(action: {
                        selectedTab = index
                    }) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == index ? 
                                Color.accentColor.opacity(0.1) : 
                                Color.clear
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
            
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    ConfigurationTab(pillar: pillar, weightConfig: $weightConfig)
                case 1:
                    AnalyticsTab(pillar: pillar)
                case 2:
                    BenchmarksTab(pillar: pillar)
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Configuration Tab
struct ConfigurationTab: View {
    let pillar: PillarData
    @Binding var weightConfig: WeightConfig
    
    var body: some View {
        VStack(spacing: 16) {
            // Metric Configuration Card
            Card {
                CardHeader {
                    CardTitle(text: "Metric Configuration")
                    CardDescription(text: "Adjust weights and enable/disable metrics for this pillar")
                }
                
                CardContent {
                    VStack(spacing: 16) {
                        ForEach(pillar.metrics) { metric in
                            MetricConfigurationRow(metric: metric)
                        }
                    }
                }
            }
            
            // Scoring Criteria Card
            Card {
                CardHeader {
                    CardTitle(text: "Scoring Criteria")
                    CardDescription(text: "Define the evaluation criteria for each score level")
                }
                
                CardContent {
                    VStack(spacing: 12) {
                        ForEach([5, 4, 3, 2, 1], id: \.self) { score in
                            ScoringCriteriaRow(score: score)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Analytics Tab
struct AnalyticsTab: View {
    let pillar: PillarData
    
    var body: some View {
        VStack(spacing: 16) {
            // Key Metrics
            HStack(spacing: 16) {
                MetricCard(
                    title: "Average Score",
                    value: String(format: "%.1f", pillar.averageScore),
                    subtitle: "Across all companies",
                    icon: "target"
                )
                
                MetricCard(
                    title: "Standard Deviation",
                    value: "0.73",
                    subtitle: "Score variability",
                    icon: "chart.bar"
                )
                
                MetricCard(
                    title: "Correlation",
                    value: "0.67",
                    subtitle: "With overall score",
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            
            // Score Distribution Card
            Card {
                CardHeader {
                    CardTitle(text: "Score Distribution")
                }
                
                CardContent {
                    VStack(spacing: 12) {
                        ForEach(ScoreDistribution.sampleData, id: \.range) { distribution in
                            HStack {
                                Text(distribution.range)
                                    .font(.caption)
                                    .frame(width: 60, alignment: .leading)
                                
                                ProgressBar(value: Double(distribution.percentage) / 100.0, height: 4)
                                
                                Text("\(distribution.count) cos.")
                                    .font(.caption)
                                    .frame(width: 50, alignment: .trailing)
                                
                                Text("\(distribution.percentage)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Benchmarks Tab
struct BenchmarksTab: View {
    let pillar: PillarData
    
    var body: some View {
        Card {
            CardHeader {
                CardTitle(text: "Industry Benchmarks")
                CardDescription(text: "Compare scores across different therapeutic areas")
            }
            
            CardContent {
                VStack(spacing: 12) {
                    ForEach(IndustryBenchmark.sampleData, id: \.area) { benchmark in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(benchmark.area)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(benchmark.companies) companies")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(benchmark.score, specifier: "%.1f")/5.0")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ProgressBar(value: benchmark.score / 5.0, height: 4)
                                    .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components
struct MetricConfigurationRow: View {
    let metric: MetricData
    @State private var isEnabled = true
    @State private var weight: Double = 40.0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 12) {
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                    
                    Text(metric.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text("\(Int(weight))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $weight, in: 0...100, step: 5)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
}

struct ScoringCriteriaRow: View {
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StatusBadge(
                    text: "Score: \(score)",
                    style: score >= 4 ? .success : score >= 3 ? .secondary : .warning
                )
                
                Text(scoreLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text("Define criteria for score level \(score)...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var scoreLabel: String {
        switch score {
        case 5: return "Excellent"
        case 4: return "Good"
        case 3: return "Average"
        case 2: return "Below Average"
        case 1: return "Poor"
        default: return ""
        }
    }
}

// MARK: - Weight Configuration Sheet
struct WeightConfigurationSheet: View {
    @Binding var weightConfig: WeightConfig
    @Environment(\.dismiss) private var dismiss
    @State private var localWeights = WeightConfig()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configure Pillar Weights")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Adjust the relative importance of each scoring pillar. Weights will be automatically normalized to sum to 100%.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        WeightSlider(
                            title: "Asset Quality",
                            weight: $localWeights.assetQuality,
                            icon: "target"
                        )
                        
                        WeightSlider(
                            title: "Market Outlook",
                            weight: $localWeights.marketOutlook,
                            icon: "chart.line.uptrend.xyaxis"
                        )
                        
                        WeightSlider(
                            title: "Capital Intensity",
                            weight: $localWeights.capitalIntensity,
                            icon: "dollarsign.circle"
                        )
                        
                        WeightSlider(
                            title: "Strategic Fit",
                            weight: $localWeights.strategicFit,
                            icon: "person.2"
                        )
                        
                        WeightSlider(
                            title: "Financial Readiness",
                            weight: $localWeights.financialReadiness,
                            icon: "creditcard"
                        )
                        
                        WeightSlider(
                            title: "Regulatory Risk",
                            weight: $localWeights.regulatoryRisk,
                            icon: "shield"
                        )
                    }
                    
                    // Total Weight Display
                    Card {
                        CardContent {
                            HStack {
                                Text("Total Weight")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(Int(totalWeight * 100))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(abs(totalWeight - 1.0) < 0.01 ? .green : .orange)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        weightConfig = localWeights
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            localWeights = weightConfig
        }
    }
    
    private var totalWeight: Double {
        localWeights.assetQuality + localWeights.marketOutlook + 
        localWeights.capitalIntensity + localWeights.strategicFit + 
        localWeights.financialReadiness + localWeights.regulatoryRisk
    }
}

struct WeightSlider: View {
    let title: String
    @Binding var weight: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text("\(Int(weight * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            Slider(value: $weight, in: 0.05...0.50, step: 0.01)
                .accentColor(.accentColor)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Data Models
struct PillarData: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let weight: Double
    let description: String
    let metrics: [MetricData]
    let averageScore: Double
    let companies: Int
    
    static let allPillars: [PillarData] = [
        PillarData(
            name: "Asset Quality",
            icon: "target",
            weight: 0.25,
            description: "Evaluates pipeline strength, development stage, and competitive positioning",
            metrics: [
                MetricData(name: "Pipeline Strength", weight: 40, enabled: true),
                MetricData(name: "IP Portfolio", weight: 30, enabled: true),
                MetricData(name: "Competitive Position", weight: 20, enabled: true),
                MetricData(name: "Differentiation", weight: 10, enabled: true)
            ],
            averageScore: 4.2,
            companies: 247
        ),
        PillarData(
            name: "Market Outlook",
            icon: "chart.line.uptrend.xyaxis",
            weight: 0.20,
            description: "Analyzes addressable market size, growth potential, and competitive landscape",
            metrics: [
                MetricData(name: "Market Size", weight: 35, enabled: true),
                MetricData(name: "Growth Rate", weight: 25, enabled: true),
                MetricData(name: "Competition", weight: 25, enabled: true),
                MetricData(name: "Market Access", weight: 15, enabled: true)
            ],
            averageScore: 3.8,
            companies: 247
        ),
        PillarData(
            name: "Capital Intensity",
            icon: "dollarsign.circle",
            weight: 0.15,
            description: "Assesses development costs, capital requirements, and scalability",
            metrics: [
                MetricData(name: "Development Costs", weight: 40, enabled: true),
                MetricData(name: "Manufacturing", weight: 30, enabled: true),
                MetricData(name: "Clinical Trials", weight: 20, enabled: true),
                MetricData(name: "Scalability", weight: 10, enabled: true)
            ],
            averageScore: 3.5,
            companies: 247
        ),
        PillarData(
            name: "Strategic Fit",
            icon: "person.2",
            weight: 0.20,
            description: "Analyzes alignment with acquirer capabilities and synergy potential",
            metrics: [
                MetricData(name: "Capability Alignment", weight: 35, enabled: true),
                MetricData(name: "Synergy Potential", weight: 30, enabled: true),
                MetricData(name: "Integration Risk", weight: 20, enabled: true),
                MetricData(name: "Geographic Fit", weight: 15, enabled: true)
            ],
            averageScore: 4.0,
            companies: 247
        ),
        PillarData(
            name: "Financial Readiness",
            icon: "creditcard",
            weight: 0.10,
            description: "Evaluates financial position, funding needs, and management quality",
            metrics: [
                MetricData(name: "Cash Position", weight: 40, enabled: true),
                MetricData(name: "Burn Rate", weight: 25, enabled: true),
                MetricData(name: "Funding History", weight: 20, enabled: true),
                MetricData(name: "Financial Management", weight: 15, enabled: true)
            ],
            averageScore: 3.2,
            companies: 247
        ),
        PillarData(
            name: "Regulatory Risk",
            icon: "shield",
            weight: 0.10,
            description: "Assesses regulatory pathway complexity, timeline, and compliance risks",
            metrics: [
                MetricData(name: "Pathway Complexity", weight: 35, enabled: true),
                MetricData(name: "Timeline Risk", weight: 30, enabled: true),
                MetricData(name: "Safety Profile", weight: 20, enabled: true),
                MetricData(name: "Precedent Analysis", weight: 15, enabled: true)
            ],
            averageScore: 3.7,
            companies: 247
        )
    ]
}

struct MetricData: Identifiable {
    let id = UUID()
    let name: String
    let weight: Double
    let enabled: Bool
}

struct ScoreDistribution {
    let range: String
    let count: Int
    let percentage: Int
    
    static let sampleData = [
        ScoreDistribution(range: "4.5-5.0", count: 42, percentage: 17),
        ScoreDistribution(range: "4.0-4.5", count: 74, percentage: 30),
        ScoreDistribution(range: "3.5-4.0", count: 86, percentage: 35),
        ScoreDistribution(range: "3.0-3.5", count: 32, percentage: 13),
        ScoreDistribution(range: "2.5-3.0", count: 10, percentage: 4),
        ScoreDistribution(range: "<2.5", count: 3, percentage: 1)
    ]
}

struct IndustryBenchmark {
    let area: String
    let score: Double
    let companies: Int
    
    static let sampleData = [
        IndustryBenchmark(area: "Oncology", score: 4.1, companies: 89),
        IndustryBenchmark(area: "Rare Disease", score: 4.3, companies: 42),
        IndustryBenchmark(area: "CNS", score: 3.6, companies: 35),
        IndustryBenchmark(area: "Cardiovascular", score: 3.9, companies: 28),
        IndustryBenchmark(area: "Immunology", score: 4.0, companies: 53)
    ]
}

#Preview {
    ScoringPillarsView()
}