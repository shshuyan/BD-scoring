import SwiftUI

// Test compilation of UI components
struct TestUICompilation: View {
    var body: some View {
        VStack {
            // Test Card component
            Card {
                CardHeader {
                    CardTitle(text: "Test Card")
                    CardDescription(text: "Testing card component")
                }
                CardContent {
                    Text("Card content")
                }
            }
            
            // Test Button components
            PrimaryButton("Primary", icon: "star") { }
            SecondaryButton("Secondary", icon: "heart") { }
            
            // Test Progress Bar
            ProgressBar(value: 0.7)
            
            // Test Badge
            StatusBadge(text: "Test", style: .primary)
            
            // Test Metric Card
            MetricCard(
                title: "Test Metric",
                value: "123",
                subtitle: "Test subtitle",
                icon: "chart.bar"
            )
        }
    }
}

// Test navigation components
struct TestNavigationCompilation: View {
    @StateObject private var navigationState = NavigationState()
    
    var body: some View {
        HStack {
            SidebarView(
                navigationState: navigationState,
                quickStats: QuickStats.sample
            )
            
            DashboardView()
        }
    }
}

// Test all view components
struct TestAllViews: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar") }
            
            CompanyEvaluationView()
                .tabItem { Label("Evaluation", systemImage: "building.2") }
            
            ScoringPillarsView()
                .tabItem { Label("Pillars", systemImage: "target") }
            
            ComparablesView()
                .tabItem { Label("Database", systemImage: "externaldrive") }
            
            ValuationEngineView()
                .tabItem { Label("Valuation", systemImage: "calculator") }
            
            ReportsAnalyticsView()
                .tabItem { Label("Reports", systemImage: "doc.text") }
        }
    }
}