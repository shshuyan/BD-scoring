import SwiftUI

struct ValuationEngineView: View {
    // MARK: - State Properties
    @State private var selectedCompany: String = ""
    @State private var valuationMethod: ValuationMethodology = .comparableTransactions
    @State private var riskFreeRate: String = "2.5"
    @State private var discountRate: String = "12.0"
    @State private var peakSales: String = "500"
    @State private var successProbability: String = "65"
    @State private var timeToPeak: String = "8"
    @State private var selectedTab: String = "summary"
    @State private var isCalculating: Bool = false
    @State private var valuationResult: ValuationResult?
    
    // MARK: - Sample Data
    private let companies = [
        CompanyOption(id: "1", name: "BioTech Alpha", score: 4.2, stage: "Phase II"),
        CompanyOption(id: "2", name: "Genomics Beta", score: 3.8, stage: "Phase III"),
        CompanyOption(id: "3", name: "Neuro Gamma", score: 3.5, stage: "Phase I")
    ]
    
    private let valuationScenarios = [
        ScenarioData(scenario: "Bear Case", probability: 20, valuation: 850, multiple: "6.2x"),
        ScenarioData(scenario: "Base Case", probability: 50, valuation: 1200, multiple: "8.7x"),
        ScenarioData(scenario: "Bull Case", probability: 30, valuation: 1650, multiple: "12.1x")
    ]
    
    private let comparableMetrics = [
        ComparableMetric(metric: "Revenue Multiple", value: "8.7x", benchmark: "7.2x - 12.4x"),
        ComparableMetric(metric: "EBITDA Multiple", value: "15.2x", benchmark: "12.1x - 18.8x"),
        ComparableMetric(metric: "Peak Sales Multiple", value: "3.4x", benchmark: "2.8x - 4.9x"),
        ComparableMetric(metric: "R&D Multiple", value: "12.8x", benchmark: "9.5x - 16.2x")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Input Panel (Left Side)
            inputPanel
                .frame(width: 350)
                .background(Color(.systemGroupedBackground))
            
            // Results Panel (Right Side)
            resultsPanel
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
        .navigationTitle("Valuation Engine")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PrimaryButton("Run Valuation", icon: "calculator") {
                    runValuation()
                }
                .disabled(selectedCompany.isEmpty || isCalculating)
            }
        }
    }
    
    // MARK: - Input Panel
    private var inputPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Valuation Engine")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Generate comprehensive valuations using multiple methodologies")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Valuation Inputs Card
                Card {
                    CardHeader {
                        CardTitle(text: "Valuation Inputs")
                        CardDescription(text: "Select company and methodology")
                    }
                    
                    CardContent {
                        VStack(spacing: 16) {
                            // Company Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target Company")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Menu {
                                    ForEach(companies, id: \.id) { company in
                                        Button("\(company.name) (\(company.stage))") {
                                            selectedCompany = company.id
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCompany.isEmpty ? "Select company" : 
                                             companies.first { $0.id == selectedCompany }?.name ?? "Select company")
                                            .foregroundColor(selectedCompany.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Valuation Method
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Valuation Method")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Menu {
                                    ForEach(ValuationMethodology.allCases, id: \.self) { method in
                                        Button(method.rawValue) {
                                            valuationMethod = method
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(valuationMethod.rawValue)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Risk-Free Rate
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Risk-Free Rate (%)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("2.5", text: $riskFreeRate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Discount Rate
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Discount Rate (%)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("12.0", text: $discountRate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Calculate Button
                            PrimaryButton("Calculate Valuation") {
                                runValuation()
                            }
                            .disabled(selectedCompany.isEmpty || isCalculating)
                        }
                    }
                }
                
                // Key Assumptions Card
                Card {
                    CardHeader {
                        CardTitle(text: "Key Assumptions")
                    }
                    
                    CardContent {
                        VStack(spacing: 16) {
                            // Peak Sales
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peak Sales ($M)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("500", text: $peakSales)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Success Probability
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Success Probability (%)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("65", text: $successProbability)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Time to Peak
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time to Peak (Years)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("8", text: $timeToPeak)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(24)
        }
    }
    
    // MARK: - Results Panel
    private var resultsPanel: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(["summary", "scenarios", "comparables", "sensitivity"], id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.capitalized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                                    .frame(height: 2),
                                alignment: .bottom
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.systemGray6))
            
            // Tab Content
            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case "summary":
                        summaryTab
                    case "scenarios":
                        scenariosTab
                    case "comparables":
                        comparablesTab
                    case "sensitivity":
                        sensitivityTab
                    default:
                        summaryTab
                    }
                }
                .padding(24)
            }
        }
    }
    
    // MARK: - Summary Tab
    private var summaryTab: some View {
        VStack(spacing: 24) {
            // Valuation Summary Card
            Card {
                CardHeader {
                    CardTitle(text: "Valuation Summary")
                    if !selectedCompany.isEmpty {
                        CardDescription(text: companies.first { $0.id == selectedCompany }?.name ?? "")
                    }
                }
                
                CardContent {
                    if isCalculating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Calculating valuation...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        VStack(spacing: 24) {
                            // Main Valuation Display
                            HStack(spacing: 24) {
                                // Base Case
                                VStack(spacing: 8) {
                                    Text("$1,200M")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.accentColor)
                                    
                                    Text("Base Case Valuation")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    StatusBadge(text: "8.7x Revenue", style: .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(24)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // Valuation Range
                                VStack(spacing: 8) {
                                    Text("$850M - $1,650M")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                    
                                    Text("Valuation Range")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    StatusBadge(text: "High Confidence", style: .success)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(24)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Key Metrics
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recommendation")
                                        .font(.subheadline)
                                    Spacer()
                                    StatusBadge(text: "Strong Buy", style: .success)
                                }
                                
                                HStack {
                                    Text("Confidence Level")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("82%")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Risk Level")
                                        .font(.subheadline)
                                    Spacer()
                                    StatusBadge(text: "Medium", style: .warning)
                                }
                            }
                        }
                    }
                }
            }
            
            // Key Value Drivers Card
            if !isCalculating {
                Card {
                    CardHeader {
                        CardTitle(text: "Key Value Drivers")
                    }
                    
                    CardContent {
                        VStack(spacing: 16) {
                            valueDriverRow(name: "Market Size Impact", percentage: 35)
                            valueDriverRow(name: "Competitive Position", percentage: 28)
                            valueDriverRow(name: "Development Risk", percentage: 22)
                            valueDriverRow(name: "Regulatory Timeline", percentage: 15)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Scenarios Tab
    private var scenariosTab: some View {
        VStack(spacing: 24) {
            Card {
                CardHeader {
                    CardTitle(text: "Scenario Analysis")
                    CardDescription(text: "Probability-weighted valuation scenarios")
                }
                
                CardContent {
                    VStack(spacing: 16) {
                        ForEach(valuationScenarios, id: \.scenario) { scenario in
                            scenarioRow(scenario: scenario)
                        }
                    }
                }
            }
            
            // Expected Value Card
            Card {
                CardHeader {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.accentColor)
                        Text("Expected Value")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
                
                CardContent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("$1,245M")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Probability-weighted average valuation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Comparables Tab
    private var comparablesTab: some View {
        VStack(spacing: 24) {
            Card {
                CardHeader {
                    CardTitle(text: "Comparable Multiples")
                    CardDescription(text: "Benchmarking against similar transactions")
                }
                
                CardContent {
                    VStack(spacing: 16) {
                        ForEach(comparableMetrics, id: \.metric) { metric in
                            comparableMetricRow(metric: metric)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sensitivity Tab
    private var sensitivityTab: some View {
        VStack(spacing: 24) {
            Card {
                CardHeader {
                    CardTitle(text: "Sensitivity Analysis")
                    CardDescription(text: "Impact of key variables on valuation")
                }
                
                CardContent {
                    VStack(spacing: 32) {
                        // Peak Sales Sensitivity
                        VStack(spacing: 16) {
                            HStack {
                                Text("Peak Sales Sensitivity")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("±20% impact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                sensitivityCell(value: "$400M", result: "$960M", isBase: false)
                                sensitivityCell(value: "$500M", result: "$1,200M", isBase: true)
                                sensitivityCell(value: "$600M", result: "$1,440M", isBase: false)
                            }
                        }
                        
                        // Success Probability Sensitivity
                        VStack(spacing: 16) {
                            HStack {
                                Text("Success Probability Sensitivity")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("±15% impact")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                sensitivityCell(value: "50%", result: "$920M", isBase: false)
                                sensitivityCell(value: "65%", result: "$1,200M", isBase: true)
                                sensitivityCell(value: "80%", result: "$1,480M", isBase: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func valueDriverRow(name: String, percentage: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressBar(value: Double(percentage) / 100.0, height: 6)
        }
    }
    
    private func scenarioRow(scenario: ScenarioData) -> some View {
        VStack(spacing: 12) {
            HStack {
                StatusBadge(
                    text: scenario.scenario,
                    style: scenario.scenario == "Bull Case" ? .success :
                           scenario.scenario == "Base Case" ? .primary : .secondary
                )
                
                Text("\(scenario.probability)% probability")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(scenario.valuation)M")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(scenario.multiple)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressBar(value: Double(scenario.probability) / 100.0 * 5, height: 4)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func comparableMetricRow(metric: ComparableMetric) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.metric)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Industry Range: \(metric.benchmark)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(metric.value)
                    .font(.headline)
                    .fontWeight(.semibold)
                StatusBadge(text: "Within Range", style: .success)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func sensitivityCell(value: String, result: String, isBase: Bool) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(result)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isBase ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isBase ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func runValuation() {
        guard !selectedCompany.isEmpty else { return }
        
        isCalculating = true
        
        // Simulate calculation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCalculating = false
            // In a real implementation, this would call the actual valuation service
        }
    }
}

// MARK: - Supporting Data Models
private struct CompanyOption {
    let id: String
    let name: String
    let score: Double
    let stage: String
}

private struct ScenarioData {
    let scenario: String
    let probability: Int
    let valuation: Int
    let multiple: String
}

private struct ComparableMetric {
    let metric: String
    let value: String
    let benchmark: String
}

// MARK: - Valuation Summary Model
struct ValuationSummary: Codable {
    var baseCase: Double
    var bearCase: Double
    var bullCase: Double
    var methodology: String
    var confidence: Double
}

#Preview {
    NavigationView {
        ValuationEngineView()
    }
}