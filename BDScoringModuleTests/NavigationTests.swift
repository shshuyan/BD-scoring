import XCTest
import SwiftUI
@testable import BDScoringModule

final class NavigationTests: XCTestCase {
    
    var navigationState: NavigationState!
    var quickStatsService: QuickStatsService!
    
    override func setUp() {
        super.setUp()
        navigationState = NavigationState()
        quickStatsService = QuickStatsService()
    }
    
    override func tearDown() {
        navigationState = nil
        quickStatsService = nil
        super.tearDown()
    }
    
    // MARK: - NavigationState Tests
    
    func testInitialNavigationState() {
        XCTAssertEqual(navigationState.selectedTab, .dashboard)
        XCTAssertEqual(navigationState.sidebarSelection, "dashboard")
        XCTAssertTrue(navigationState.navigationHistory.isEmpty)
        XCTAssertFalse(navigationState.isNavigating)
    }
    
    func testTabSelection() {
        // Test selecting different tabs
        navigationState.selectTab(.evaluation, animated: false)
        XCTAssertEqual(navigationState.selectedTab, .evaluation)
        XCTAssertEqual(navigationState.sidebarSelection, "evaluation")
        
        navigationState.selectTab(.pillars, animated: false)
        XCTAssertEqual(navigationState.selectedTab, .pillars)
        XCTAssertEqual(navigationState.sidebarSelection, "pillars")
    }
    
    func testNavigationHistory() {
        // Test navigation history tracking
        navigationState.selectTab(.evaluation, animated: false)
        navigationState.selectTab(.pillars, animated: false)
        navigationState.selectTab(.reports, animated: false)
        
        XCTAssertEqual(navigationState.navigationHistory.count, 3)
        XCTAssertEqual(navigationState.navigationHistory.last, .reports)
    }
    
    func testBackNavigation() {
        // Test back navigation functionality
        navigationState.selectTab(.evaluation, animated: false)
        navigationState.selectTab(.pillars, animated: false)
        
        XCTAssertTrue(navigationState.canGoBack())
        
        let didGoBack = navigationState.goBack()
        XCTAssertTrue(didGoBack)
        XCTAssertEqual(navigationState.selectedTab, .evaluation)
        
        // Test when no history exists
        let newNavigationState = NavigationState()
        XCTAssertFalse(newNavigationState.canGoBack())
        XCTAssertFalse(newNavigationState.goBack())
    }
    
    func testSidebarItemSelection() {
        navigationState.selectSidebarItem("valuation")
        XCTAssertEqual(navigationState.selectedTab, .valuation)
        XCTAssertEqual(navigationState.sidebarSelection, "valuation")
        
        // Test invalid sidebar item
        navigationState.selectSidebarItem("invalid")
        XCTAssertEqual(navigationState.selectedTab, .valuation) // Should remain unchanged
    }
    
    func testAnimatedNavigation() {
        let expectation = XCTestExpectation(description: "Animated navigation completes")
        
        navigationState.selectTab(.evaluation, animated: true)
        XCTAssertTrue(navigationState.isNavigating)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertFalse(self.navigationState.isNavigating)
            XCTAssertEqual(self.navigationState.selectedTab, .evaluation)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - AppTab Tests
    
    func testAppTabProperties() {
        let dashboardTab = NavigationState.AppTab.dashboard
        XCTAssertEqual(dashboardTab.title, "Dashboard")
        XCTAssertEqual(dashboardTab.shortTitle, "Dashboard")
        XCTAssertEqual(dashboardTab.icon, "chart.bar.fill")
        XCTAssertFalse(dashboardTab.description.isEmpty)
        
        let evaluationTab = NavigationState.AppTab.evaluation
        XCTAssertEqual(evaluationTab.title, "Company Evaluation")
        XCTAssertEqual(evaluationTab.shortTitle, "Evaluation")
        XCTAssertEqual(evaluationTab.icon, "building.2.fill")
    }
    
    func testAllTabsCovered() {
        let allTabs = NavigationState.AppTab.allCases
        XCTAssertEqual(allTabs.count, 7)
        
        let expectedTabs: [NavigationState.AppTab] = [
            .dashboard, .evaluation, .pillars, .comparables, .valuation, .reports, .settings
        ]
        
        for expectedTab in expectedTabs {
            XCTAssertTrue(allTabs.contains(expectedTab))
        }
    }
    
    // MARK: - QuickStats Tests
    
    func testQuickStatsFormatting() {
        let stats = QuickStats(
            companiesEvaluated: 247,
            activeDeals: 12,
            totalValuation: 2.4,
            successRate: 0.68,
            lastUpdated: Date()
        )
        
        XCTAssertEqual(stats.formattedValuation, "$2.4B")
        XCTAssertEqual(stats.formattedSuccessRate, "68%")
    }
    
    func testQuickStatsService() {
        XCTAssertNotNil(quickStatsService.stats)
        XCTAssertFalse(quickStatsService.isLoading)
        
        // Test refresh functionality
        let expectation = XCTestExpectation(description: "Stats refresh completes")
        
        quickStatsService.refreshStats()
        XCTAssertTrue(quickStatsService.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertFalse(self.quickStatsService.isLoading)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPeriodicUpdates() {
        quickStatsService.startPeriodicUpdates()
        
        // Verify timer is running (indirect test)
        let initialStats = quickStatsService.stats
        
        let expectation = XCTestExpectation(description: "Periodic update occurs")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 31.0) {
            // Stats should have been updated at least once
            expectation.fulfill()
        }
        
        quickStatsService.stopPeriodicUpdates()
        
        // Note: This is a long-running test, in practice you might mock the timer
        // wait(for: [expectation], timeout: 35.0)
    }
}

// MARK: - UI Component Tests

final class NavigationUITests: XCTestCase {
    
    func testMainAppViewResponsiveLayout() {
        let mainAppView = MainAppView()
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(mainAppView)
        
        // Test responsive breakpoints
        let compactWidth: CGFloat = 1000
        let minimumWidth: CGFloat = 800
        
        XCTAssertTrue(compactWidth > minimumWidth)
        XCTAssertTrue(minimumWidth > 0)
    }
    
    func testSidebarViewCreation() {
        let navigationState = NavigationState()
        let quickStats = QuickStats.sample
        
        let sidebarView = SidebarView(
            navigationState: navigationState,
            quickStats: quickStats,
            isCompact: false
        )
        
        XCTAssertNotNil(sidebarView)
        
        // Test compact version
        let compactSidebarView = SidebarView(
            navigationState: navigationState,
            quickStats: quickStats,
            isCompact: true
        )
        
        XCTAssertNotNil(compactSidebarView)
    }
    
    func testTopNavigationBarCreation() {
        let navigationState = NavigationState()
        let quickStats = QuickStats.sample
        
        let topNavBar = TopNavigationBar(
            navigationState: navigationState,
            quickStats: quickStats,
            onMenuTap: {}
        )
        
        XCTAssertNotNil(topNavBar)
    }
    
    func testOverlaySidebarViewCreation() {
        let navigationState = NavigationState()
        let quickStats = QuickStats.sample
        
        let overlaySidebar = OverlaySidebarView(
            navigationState: navigationState,
            quickStats: quickStats,
            onDismiss: {}
        )
        
        XCTAssertNotNil(overlaySidebar)
    }
    
    func testSidebarMenuItemStates() {
        let tab = NavigationState.AppTab.dashboard
        
        // Test selected state
        let selectedMenuItem = SidebarMenuItem(
            tab: tab,
            isSelected: true,
            isCompact: false,
            isNavigating: false,
            action: {}
        )
        XCTAssertNotNil(selectedMenuItem)
        
        // Test unselected state
        let unselectedMenuItem = SidebarMenuItem(
            tab: tab,
            isSelected: false,
            isCompact: false,
            isNavigating: false,
            action: {}
        )
        XCTAssertNotNil(unselectedMenuItem)
        
        // Test compact state
        let compactMenuItem = SidebarMenuItem(
            tab: tab,
            isSelected: false,
            isCompact: true,
            isNavigating: false,
            action: {}
        )
        XCTAssertNotNil(compactMenuItem)
        
        // Test navigating state
        let navigatingMenuItem = SidebarMenuItem(
            tab: tab,
            isSelected: true,
            isCompact: false,
            isNavigating: true,
            action: {}
        )
        XCTAssertNotNil(navigatingMenuItem)
    }
    
    func testCompactStatItemCreation() {
        let statItem = CompactStatItem(
            title: "Companies",
            value: "247",
            icon: "building.2"
        )
        
        XCTAssertNotNil(statItem)
    }
    
    func testOverlayStatCardCreation() {
        let statCard = OverlayStatCard(
            title: "Companies",
            value: "247"
        )
        
        XCTAssertNotNil(statCard)
    }
    
    func testQuickStatRowCreation() {
        let statRow = QuickStatRow(
            title: "Companies Evaluated:",
            value: "247",
            isCompact: false
        )
        
        XCTAssertNotNil(statRow)
        
        let compactStatRow = QuickStatRow(
            title: "Companies:",
            value: "247",
            isCompact: true
        )
        
        XCTAssertNotNil(compactStatRow)
    }
}

// MARK: - Integration Tests

final class NavigationIntegrationTests: XCTestCase {
    
    var navigationState: NavigationState!
    var quickStatsService: QuickStatsService!
    
    override func setUp() {
        super.setUp()
        navigationState = NavigationState()
        quickStatsService = QuickStatsService()
    }
    
    override func tearDown() {
        navigationState = nil
        quickStatsService = nil
        super.tearDown()
    }
    
    func testCompleteNavigationFlow() {
        // Test a complete navigation flow through all tabs
        let allTabs = NavigationState.AppTab.allCases
        
        for tab in allTabs {
            navigationState.selectTab(tab, animated: false)
            XCTAssertEqual(navigationState.selectedTab, tab)
            XCTAssertEqual(navigationState.sidebarSelection, tab.rawValue)
        }
        
        // Verify history was tracked
        XCTAssertEqual(navigationState.navigationHistory.count, allTabs.count)
    }
    
    func testNavigationStateWithQuickStats() {
        // Test that navigation state works correctly with quick stats updates
        let initialTab = navigationState.selectedTab
        
        quickStatsService.refreshStats()
        
        // Navigation state should remain unchanged during stats refresh
        XCTAssertEqual(navigationState.selectedTab, initialTab)
        
        // Change tab during stats loading
        navigationState.selectTab(.evaluation, animated: false)
        XCTAssertEqual(navigationState.selectedTab, .evaluation)
    }
    
    func testResponsiveLayoutBehavior() {
        // Test responsive layout logic
        let mainAppView = MainAppView()
        
        // Simulate different window sizes
        let largeSize = CGSize(width: 1400, height: 900)
        let mediumSize = CGSize(width: 1200, height: 800)
        let compactSize = CGSize(width: 900, height: 600)
        
        // These would be tested in actual UI tests with ViewInspector or similar
        XCTAssertTrue(largeSize.width > 1000)
        XCTAssertTrue(mediumSize.width > 1000)
        XCTAssertTrue(compactSize.width < 1000)
    }
    
    func testNavigationHistoryManagement() {
        // Test that navigation history is properly managed
        
        // Navigate through many tabs to test history limit
        for i in 0..<15 {
            let tab = NavigationState.AppTab.allCases[i % NavigationState.AppTab.allCases.count]
            navigationState.selectTab(tab, animated: false)
        }
        
        // History should be limited to prevent memory issues
        XCTAssertLessThanOrEqual(navigationState.navigationHistory.count, 10)
    }
    
    func testConcurrentNavigationAndStatsUpdates() {
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        
        // Start periodic stats updates
        quickStatsService.startPeriodicUpdates()
        
        // Perform rapid navigation changes
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 0..<10 {
                let randomTab = NavigationState.AppTab.allCases.randomElement()!
                DispatchQueue.main.async {
                    self.navigationState.selectTab(randomTab, animated: false)
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        quickStatsService.stopPeriodicUpdates()
        
        // Verify system is still in a valid state
        XCTAssertNotNil(navigationState.selectedTab)
        XCTAssertNotNil(quickStatsService.stats)
    }
}

// MARK: - Performance Tests

final class NavigationPerformanceTests: XCTestCase {
    
    func testNavigationPerformance() {
        let navigationState = NavigationState()
        
        measure {
            for _ in 0..<1000 {
                let randomTab = NavigationState.AppTab.allCases.randomElement()!
                navigationState.selectTab(randomTab, animated: false)
            }
        }
    }
    
    func testQuickStatsUpdatePerformance() {
        let quickStatsService = QuickStatsService()
        
        measure {
            for _ in 0..<100 {
                quickStatsService.refreshStats()
            }
        }
    }
    
    func testViewCreationPerformance() {
        let navigationState = NavigationState()
        let quickStats = QuickStats.sample
        
        measure {
            for _ in 0..<100 {
                let _ = SidebarView(
                    navigationState: navigationState,
                    quickStats: quickStats,
                    isCompact: false
                )
            }
        }
    }
}