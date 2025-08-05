import SwiftUI

struct CompanyEvaluationView: View {
    @State private var selectedCompany: String? = nil
    @State private var evaluationStep: EvaluationStep = .companySelection
    @State private var searchText = ""
    
    private let companies = [
        CompanyData(
            id: "1",
            name: "BioTech Alpha",
            stage: "Phase II",
            indication: "Oncology",
            lastScore: 4.2,
            status: .completed
        ),
        CompanyData(
            id: "2",
            name: "Genomics Beta",
            stage: "Phase III",
            indication: "Rare Disease",
            lastScore: 3.8,
            status: .inProgress
        ),
        CompanyData(
            id: "3",
            name: "Neuro Gamma",
            stage: "Phase I",
            indication: "CNS",
            lastScore: nil,
            status: .new
        )
    ]
    
    private let scoringPillars = [
        ScoringPillar(name: "Asset Quality", score: 4.2, weight: 25, confidence: 0.85),
        ScoringPillar(name: "Market Outlook", score: 3.8, weight: 20, confidence: 0.78),
        ScoringPillar(name: "Capital Intensity", score: 3.5, weight: 15, confidence: 0.82),
        ScoringPillar(name: "Strategic Fit", score: 4.0, weight: 20, confidence: 0.90),
        ScoringPillar(name: "Financial Readiness", score: 3.2, weight: 10, confidence: 0.75),
        ScoringPillar(name: "Regulatory Risk", score: 3.7, weight: 10, confidence: 0.80)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                switch evaluationStep {
                case .companySelection:
                    companySelectionView
                case .basicInfo:
                    basicInfoView
                case .scoring:
                    scoringView
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Company Selection View
    private var companySelectionView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Company")
                        .font(DesignSystem.Typography.h1)
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Text("Choose a company to evaluate or create a new evaluation")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
                
                Spacer()
                
                BDButton("New Company", icon: "plus") {
                    // Handle new company action
                }
            }
            
            // Search and Filter
            HStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                    
                    BDInput("Search companies...", text: $searchText)
                }
                
                BDButton("Filter", variant: .outline, icon: "line.3.horizontal.decrease") {
                    // Handle filter action
                }
            }
            
            // Company Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 3), spacing: DesignSystem.Spacing.md) {
                ForEach(companies) { company in
                    CompanyCard(
                        company: company,
                        isSelected: selectedCompany == company.id
                    ) {
                        selectedCompany = company.id
                    }
                }
            }
            
            // Continue Button
            if selectedCompany != nil {
                HStack {
                    Spacer()
                    BDButton("Continue Evaluation") {
                        evaluationStep = .basicInfo
                    }
                }
            }
        }
    }
    
    // MARK: - Basic Info View
    private var basicInfoView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Basic Information")
                        .font(DesignSystem.Typography.h1)
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Text("Enter fundamental company details")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
                
                Spacer()
                
                BDButton("Back to Selection", variant: .outline) {
                    selectedCompany = nil
                    evaluationStep = .companySelection
                }
            }
            
            // Company Details Card
            BDCard {
                BDCardHeader {
                    BDCardTitle("Company Details")
                }
                
                BDCardContent {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading, spacing: 8) {
                                BDLabel("Company Name")
                                BDInput("Enter company name", text: .constant(""))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BDLabel("Ticker Symbol")
                                BDInput("Optional ticker symbol", text: .constant(""))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BDLabel("Development Stage")
                                // Custom picker would go here
                                BDInput("Select stage", text: .constant(""))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BDLabel("Therapeutic Area")
                                // Custom picker would go here
                                BDInput("Select area", text: .constant(""))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BDLabel("Company Description")
                            BDInput("Brief description of the company and its focus areas", text: .constant(""))
                        }
                    }
                }
            }
            
            // Financial Information Card
            BDCard {
                BDCardHeader {
                    BDCardTitle("Financial Information")
                }
                
                BDCardContent {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 3), spacing: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: 8) {
                            BDLabel("Cash Position ($M)")
                            BDInput("Current cash", text: .constant(""))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BDLabel("Monthly Burn Rate ($M)")
                            BDInput("Monthly burn", text: .constant(""))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BDLabel("Runway (Months)")
                            BDInput("Calculated runway", text: .constant(""))
                        }
                    }
                }
            }
            
            // Continue Button
            HStack {
                Spacer()
                BDButton("Continue to Scoring") {
                    evaluationStep = .scoring
                }
            }
        }
    }
    
    // MARK: - Scoring View
    private var scoringView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scoring Evaluation")
                        .font(DesignSystem.Typography.h1)
                        .foregroundColor(DesignSystem.Colors.foreground)
                    
                    Text("Assess the company across all scoring pillars")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    BDButton("Back", variant: .outline) {
                        evaluationStep = .basicInfo
                    }
                    
                    BDButton("Calculate Score", icon: "function") {
                        // Handle calculate action
                    }
                }
            }
            
            // Scoring Content
            HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                // Scoring Pillars
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(scoringPillars, id: \.name) { pillar in
                        ScoringPillarCard(pillar: pillar)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Overall Assessment
                BDCard {
                    BDCardHeader {
                        BDCardTitle("Overall Assessment")
                        BDCardDescription("Comprehensive evaluation summary")
                    }
                    
                    BDCardContent {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Overall Score
                            VStack(spacing: 8) {
                                Text("3.84")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text("Overall Score")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.mutedForeground)
                                
                                BDProgress(value: 0.768, height: 8)
                            }
                            
                            BDSeparator()
                            
                            // Assessment Details
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Investment Recommendation")
                                        .font(DesignSystem.Typography.body)
                                    Spacer()
                                    BDBadge("Strong Buy")
                                }
                                
                                HStack {
                                    Text("Risk Level")
                                        .font(DesignSystem.Typography.body)
                                    Spacer()
                                    BDBadge("Medium", variant: .outline)
                                }
                                
                                HStack {
                                    Text("Confidence Level")
                                        .font(DesignSystem.Typography.body)
                                    Spacer()
                                    Text("82%")
                                        .font(DesignSystem.Typography.label)
                                }
                            }
                            
                            BDSeparator()
                            
                            // Key Strengths
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Strengths")
                                    .font(DesignSystem.Typography.label)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Strong intellectual property portfolio")
                                    Text("• Large addressable market opportunity")
                                    Text("• Experienced management team")
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.mutedForeground)
                            }
                            
                            BDSeparator()
                            
                            // Areas of Concern
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Areas of Concern")
                                    .font(DesignSystem.Typography.label)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Limited cash runway")
                                    Text("• Competitive landscape intensity")
                                    Text("• Regulatory pathway uncertainty")
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.mutedForeground)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Action Buttons
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    BDButton("Generate Report", variant: .outline, icon: "doc.text") {
                        // Handle generate report
                    }
                    
                    BDButton("Save Evaluation") {
                        // Handle save evaluation
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct CompanyCard: View {
    let company: CompanyData
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            BDCard {
                BDCardHeader {
                    HStack {
                        BDCardTitle(company.name)
                        Spacer()
                        BDBadge(company.status.rawValue, variant: badgeVariant)
                    }
                    BDCardDescription("\(company.indication) • \(company.stage)")
                }
                
                BDCardContent {
                    HStack(spacing: 8) {
                        if let score = company.lastScore {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f/5.0", score))
                                .font(DesignSystem.Typography.label)
                            
                            Text("Overall Score")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.mutedForeground)
                        } else {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.mutedForeground)
                            
                            Text("No evaluation yet")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.mutedForeground)
                        }
                        
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var badgeVariant: BDBadge.Variant {
        switch company.status {
        case .completed:
            return .default
        case .inProgress:
            return .secondary
        case .new:
            return .outline
        }
    }
}

struct ScoringPillarCard: View {
    let pillar: ScoringPillar
    
    var body: some View {
        BDCard {
            BDCardHeader {
                HStack {
                    BDCardTitle(pillar.name)
                    Spacer()
                    BDBadge("\(pillar.weight)% weight", variant: .outline)
                }
            }
            
            BDCardContent {
                VStack(spacing: 12) {
                    HStack {
                        Text("Score: \(String(format: "%.1f", pillar.score))/5.0")
                            .font(DesignSystem.Typography.caption)
                        
                        Spacer()
                        
                        Text("Confidence: \(Int(pillar.confidence * 100))%")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.mutedForeground)
                    }
                    
                    BDProgress(value: pillar.score / 5.0, height: 8)
                    
                    BDButton("Review Details", variant: .outline, size: .sm) {
                        // Handle review details
                    }
                }
            }
        }
    }
}

// MARK: - Data Models
struct CompanyData: Identifiable {
    let id: String
    let name: String
    let stage: String
    let indication: String
    let lastScore: Double?
    let status: CompanyStatus
}

enum CompanyStatus: String, CaseIterable {
    case completed = "completed"
    case inProgress = "in-progress"
    case new = "new"
}

struct ScoringPillar {
    let name: String
    let score: Double
    let weight: Int
    let confidence: Double
}

enum EvaluationStep {
    case companySelection
    case basicInfo
    case scoring
}

#Preview {
    CompanyEvaluationView()
}