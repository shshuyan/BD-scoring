import SwiftUI

// Test compilation of navigation components
func testNavigationCompilation() {
    // Test NavigationState
    let navigationState = NavigationState()
    navigationState.selectTab(.dashboard)
    navigationState.selectTab(.evaluation, animated: false)
    _ = navigationState.canGoBack()
    _ = navigationState.goBack()
    
    // Test QuickStats
    let quickStats = QuickStats.sample
    _ = quickStats.formattedValuation
    _ = quickStats.formattedSuccessRate
    
    // Test QuickStatsService
    let quickStatsService = QuickStatsService()
    quickStatsService.refreshStats()
    quickStatsService.startPeriodicUpdates()
    quickStatsService.stopPeriodicUpdates()
    
    // Test AppTab properties
    let tab = NavigationState.AppTab.dashboard
    _ = tab.title
    _ = tab.shortTitle
    _ = tab.icon
    _ = tab.description
    
    // Test SidebarView creation
    let sidebarView = SidebarView(
        navigationState: navigationState,
        quickStats: quickStats,
        isCompact: false
    )
    
    let compactSidebarView = SidebarView(
        navigationState: navigationState,
        quickStats: quickStats,
        isCompact: true
    )
    
    // Test TopNavigationBar creation
    let topNavBar = TopNavigationBar(
        navigationState: navigationState,
        quickStats: quickStats,
        onMenuTap: {}
    )
    
    // Test OverlaySidebarView creation
    let overlaySidebar = OverlaySidebarView(
        navigationState: navigationState,
        quickStats: quickStats,
        onDismiss: {}
    )
    
    // Test SidebarMenuItem creation
    let menuItem = SidebarMenuItem(
        tab: .dashboard,
        isSelected: true,
        isCompact: false,
        isNavigating: false,
        action: {}
    )
    
    // Test supporting components
    let compactStatItem = CompactStatItem(
        title: "Companies",
        value: "247",
        icon: "building.2"
    )
    
    let overlayStatCard = OverlayStatCard(
        title: "Companies",
        value: "247"
    )
    
    let quickStatRow = QuickStatRow(
        title: "Companies Evaluated:",
        value: "247",
        isCompact: false
    )
    
    // Test MainAppView creation
    let mainAppView = MainAppView()
    
    print("✅ All navigation components compiled successfully!")
}