import SwiftUI
import Combine

// MARK: - Navigation State Management
class NavigationState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var sidebarSelection: String = "dashboard"
    @Published var navigationHistory: [AppTab] = []
    @Published var isNavigating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Track navigation changes for analytics
        $selectedTab
            .dropFirst()
            .sink { [weak self] newTab in
                self?.trackNavigation(to: newTab)
            }
            .store(in: &cancellables)
    }
    
    enum AppTab: String, CaseIterable, Identifiable {
        case dashboard = "dashboard"
        case evaluation = "evaluation"
        case pillars = "pillars"
        case comparables = "comparables"
        case valuation = "valuation"
        case reports = "reports"
        case settings = "settings"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .evaluation: return "Company Evaluation"
            case .pillars: return "Scoring Pillars"
            case .comparables: return "Database"
            case .valuation: return "Valuation Engine"
            case .reports: return "Reports & Analytics"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .evaluation: return "building.2.fill"
            case .pillars: return "target"
            case .comparables: return "externaldrive.fill"
            case .valuation: return "calculator.fill"
            case .reports: return "doc.text.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var shortTitle: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .evaluation: return "Evaluation"
            case .pillars: return "Pillars"
            case .comparables: return "Database"
            case .valuation: return "Valuation"
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }
        
        var description: String {
            switch self {
            case .dashboard: return "Overview of biotech investment opportunities"
            case .evaluation: return "Evaluate companies across scoring criteria"
            case .pillars: return "Configure and analyze scoring pillars"
            case .comparables: return "Browse comparable transactions database"
            case .valuation: return "Calculate company valuations"
            case .reports: return "Generate and view analytical reports"
            case .settings: return "Application preferences and configuration"
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    func selectTab(_ tab: AppTab, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                isNavigating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.selectedTab = tab
                self.sidebarSelection = tab.rawValue
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isNavigating = false
                }
            }
        } else {
            selectedTab = tab
            sidebarSelection = tab.rawValue
        }
    }
    
    func selectSidebarItem(_ item: String) {
        if let tab = AppTab(rawValue: item) {
            selectTab(tab)
        }
    }
    
    func goBack() -> Bool {
        guard navigationHistory.count > 1 else { return false }
        
        navigationHistory.removeLast()
        let previousTab = navigationHistory.last ?? .dashboard
        selectTab(previousTab)
        return true
    }
    
    func canGoBack() -> Bool {
        return navigationHistory.count > 1
    }
    
    // MARK: - Private Methods
    
    private func trackNavigation(to tab: AppTab) {
        // Add to history if different from current
        if navigationHistory.last != tab {
            navigationHistory.append(tab)
            
            // Keep history manageable
            if navigationHistory.count > 10 {
                navigationHistory.removeFirst()
            }
        }
        
        // Analytics tracking could be added here
        print("Navigation: \(tab.title)")
    }
}

// MARK: - Quick Stats Data
struct QuickStats {
    let companiesEvaluated: Int
    let activeDeals: Int
    let totalValuation: Double
    let successRate: Double
    let lastUpdated: Date
    
    static let sample = QuickStats(
        companiesEvaluated: 247,
        activeDeals: 12,
        totalValuation: 2.4,
        successRate: 0.68,
        lastUpdated: Date()
    )
    
    var formattedValuation: String {
        return String(format: "$%.1fB", totalValuation)
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.0f%%", successRate * 100)
    }
}

// MARK: - Quick Stats Service
class QuickStatsService: ObservableObject {
    @Published var stats: QuickStats = .sample
    @Published var isLoading: Bool = false
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInitialStats()
    }
    
    deinit {
        stopPeriodicUpdates()
    }
    
    // MARK: - Public Methods
    
    func startPeriodicUpdates() {
        stopPeriodicUpdates()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.refreshStats()
        }
    }
    
    func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func refreshStats() {
        isLoading = true
        
        // Simulate API call with realistic delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStats()
            self.isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialStats() {
        // In a real app, this would load from UserDefaults or cache
        stats = .sample
    }
    
    private func updateStats() {
        // Simulate realistic stat changes
        let companiesChange = Int.random(in: -2...5)
        let dealsChange = Int.random(in: -1...2)
        let valuationChange = Double.random(in: -0.2...0.3)
        let successRateChange = Double.random(in: -0.05...0.05)
        
        stats = QuickStats(
            companiesEvaluated: max(0, stats.companiesEvaluated + companiesChange),
            activeDeals: max(0, stats.activeDeals + dealsChange),
            totalValuation: max(0, stats.totalValuation + valuationChange),
            successRate: max(0, min(1, stats.successRate + successRateChange)),
            lastUpdated: Date()
        )
    }
}