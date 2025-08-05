import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Light mode colors
        static let background = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff
        static let foreground = Color(red: 0.145, green: 0.145, blue: 0.145) // oklch(0.145 0 0)
        static let card = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff
        static let cardForeground = Color(red: 0.145, green: 0.145, blue: 0.145)
        static let primary = Color(red: 0.012, green: 0.008, blue: 0.075) // #030213
        static let primaryForeground = Color(red: 1.0, green: 1.0, blue: 1.0)
        static let secondary = Color(red: 0.95, green: 0.95, blue: 0.96) // oklch(0.95 0.0058 264.53)
        static let secondaryForeground = Color(red: 0.012, green: 0.008, blue: 0.075)
        static let muted = Color(red: 0.925, green: 0.925, blue: 0.941) // #ececf0
        static let mutedForeground = Color(red: 0.443, green: 0.443, blue: 0.510) // #717182
        static let accent = Color(red: 0.914, green: 0.922, blue: 0.937) // #e9ebef
        static let accentForeground = Color(red: 0.012, green: 0.008, blue: 0.075)
        static let destructive = Color(red: 0.831, green: 0.094, blue: 0.239) // #d4183d
        static let destructiveForeground = Color(red: 1.0, green: 1.0, blue: 1.0)
        static let border = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1)
        static let inputBackground = Color(red: 0.953, green: 0.953, blue: 0.961) // #f3f3f5
        static let ring = Color(red: 0.708, green: 0.708, blue: 0.708)
        
        // Chart colors
        static let chart1 = Color(red: 0.646, green: 0.222, blue: 0.116)
        static let chart2 = Color(red: 0.6, green: 0.118, blue: 0.704)
        static let chart3 = Color(red: 0.398, green: 0.07, blue: 0.392)
        static let chart4 = Color(red: 0.828, green: 0.189, blue: 0.429)
        static let chart5 = Color(red: 0.769, green: 0.188, blue: 0.08)
        
        // Sidebar colors
        static let sidebar = Color(red: 0.985, green: 0.985, blue: 0.985)
        static let sidebarForeground = Color(red: 0.145, green: 0.145, blue: 0.145)
        static let sidebarPrimary = Color(red: 0.012, green: 0.008, blue: 0.075)
        static let sidebarPrimaryForeground = Color(red: 0.985, green: 0.985, blue: 0.985)
        static let sidebarAccent = Color(red: 0.97, green: 0.97, blue: 0.97)
        static let sidebarAccentForeground = Color(red: 0.205, green: 0.205, blue: 0.205)
        static let sidebarBorder = Color(red: 0.922, green: 0.922, blue: 0.922)
    }
    
    // MARK: - Typography
    struct Typography {
        static let h1 = Font.system(size: 24, weight: .medium)
        static let h2 = Font.system(size: 20, weight: .medium)
        static let h3 = Font.system(size: 18, weight: .medium)
        static let h4 = Font.system(size: 16, weight: .medium)
        static let body = Font.system(size: 14, weight: .regular)
        static let label = Font.system(size: 14, weight: .medium)
        static let button = Font.system(size: 14, weight: .medium)
        static let caption = Font.system(size: 12, weight: .regular)
        static let small = Font.system(size: 11, weight: .regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 14
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let sm = Shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Custom Shadow Modifier
struct ShadowModifier: ViewModifier {
    let shadow: Shadow
    
    func body(content: Content) -> some View {
        content
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func customShadow(_ shadow: Shadow) -> some View {
        self.modifier(ShadowModifier(shadow: shadow))
    }
}