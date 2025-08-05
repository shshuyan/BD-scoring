import SwiftUI

struct ContentView: View {
    @State private var activeSection = "dashboard"
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(activeSection: $activeSection)
            
            // Main Content
            mainContentView
        }
        .background(DesignSystem.Colors.background)
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        switch activeSection {
        case "dashboard":
            DashboardView()
        case "evaluation":
            CompanyEvaluationView()
        case "pillars":
            ScoringPillarsPlaceholder()
        case "comparables":
            ComparablesPlaceholder()
        case "valuation":
            ValuationEnginePlaceholder()
        case "reports":
            ReportsAnalyticsPlaceholder()
        case "settings":
            SettingsPlaceholder()
        default:
            DashboardView()
        }
    }
}

// MARK: - Placeholder Views
struct CompanyEvaluationPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Company Evaluation")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Evaluate biotech companies using comprehensive scoring criteria")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ScoringPillarsPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Scoring Pillars")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Configure and manage scoring criteria and weightings")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ComparablesPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "externaldrive")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Comparables Database")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Access and manage comparable company data")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ValuationEnginePlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "function")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Valuation Engine")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Advanced valuation models and calculations")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ReportsAnalyticsPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Reports & Analytics")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Generate comprehensive reports and analytics")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct SettingsPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "gearshape")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Text("Settings")
                .font(DesignSystem.Typography.h2)
                .foregroundColor(DesignSystem.Colors.foreground)
            
            Text("Configure application settings and preferences")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

#Preview {
    ContentView()
}