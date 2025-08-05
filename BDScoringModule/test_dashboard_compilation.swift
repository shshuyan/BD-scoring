import SwiftUI

// Test compilation of Dashboard components
func testDashboardCompilation() {
    let navigationState = NavigationState()
    
    // Test DashboardView compilation
    let dashboardView = DashboardView()
        .environmentObject(navigationState)
    
    // Test RecentEvaluationRow compilation
    let evaluationRow = RecentEvaluationRow(
        name: "Test Company",
        stage: "Phase II",
        indication: "Oncology",
        score: 4.2,
        status: .completed,
        lastUpdated: "2 hours ago"
    )
    
    // Test ScoringPillarRow compilation
    let pillarRow = ScoringPillarRow(
        name: "Asset Quality",
        score: 4.1,
        maxScore: 5.0
    )
    
    // Test DeadlineRow compilation
    let deadlineRow = DeadlineRow(
        company: "Test Company",
        task: "Test Task",
        dueIn: "2 days"
    )
    
    // Test QuickActionButton compilation
    let quickActionButton = QuickActionButton(
        title: "Test Action",
        icon: "test.icon",
        action: { }
    )
    
    print("Dashboard compilation test passed")
}