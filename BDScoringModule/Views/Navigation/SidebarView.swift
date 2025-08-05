import SwiftUI

struct SidebarView: View {
    @Binding var activeSection: String
    
    private let menuItems = [
        MenuItem(id: "dashboard", label: "Dashboard", icon: "chart.bar.fill"),
        MenuItem(id: "evaluation", label: "Company Evaluation", icon: "building.2.fill"),
        MenuItem(id: "pillars", label: "Scoring Pillars", icon: "target"),
        MenuItem(id: "comparables", label: "Database", icon: "externaldrive.fill"),
        MenuItem(id: "valuation", label: "Valuation Engine", icon: "function"),
        MenuItem(id: "reports", label: "Reports & Analytics", icon: "doc.text.fill"),
        MenuItem(id: "settings", label: "Settings", icon: "gearshape.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Navigation
            navigationSection
            
            Spacer()
            
            // Quick Stats
            quickStatsSection
        }
        .frame(width: 256)
        .background(DesignSystem.Colors.sidebar)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.sidebarBorder)
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Logo
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.sidebarPrimary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.sidebarPrimaryForeground)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("BD & IPO Scoring")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.sidebarForeground)
                    
                    Text("Biotech Investment Platform")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.mutedForeground)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            
            Rectangle()
                .fill(DesignSystem.Colors.sidebarBorder)
                .frame(height: 1)
        }
    }
    
    private var navigationSection: some View {
        VStack(spacing: 8) {
            ForEach(menuItems) { item in
                NavigationButton(
                    item: item,
                    isActive: activeSection == item.id
                ) {
                    activeSection = item.id
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignSystem.Colors.sidebarBorder)
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.sidebarAccent)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Stats")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.sidebarAccentForeground)
                            
                            VStack(spacing: 4) {
                                StatRow(label: "Companies Evaluated:", value: "247")
                                StatRow(label: "Active Deals:", value: "12")
                            }
                        }
                        .padding(12)
                    )
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Supporting Views
struct NavigationButton: View {
    let item: MenuItem
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(foregroundColor)
                    .frame(width: 20)
                
                Text(item.label)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(foregroundColor)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isActive {
            return DesignSystem.Colors.sidebarAccent
        } else {
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        if isActive {
            return DesignSystem.Colors.sidebarAccentForeground
        } else {
            return DesignSystem.Colors.sidebarForeground
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.mutedForeground)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.mutedForeground)
        }
    }
}

// MARK: - Data Models
struct MenuItem: Identifiable {
    let id: String
    let label: String
    let icon: String
}

#Preview {
    SidebarView(activeSection: .constant("dashboard"))
}