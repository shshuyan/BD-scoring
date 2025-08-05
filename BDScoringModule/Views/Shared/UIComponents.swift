import SwiftUI

// MARK: - Button Component
struct BDButton: View {
    enum Variant {
        case `default`
        case destructive
        case outline
        case secondary
        case ghost
        case link
    }
    
    enum Size {
        case `default`
        case sm
        case lg
        case icon
    }
    
    let title: String
    let variant: Variant
    let size: Size
    let action: () -> Void
    let icon: String?
    
    init(
        _ title: String,
        variant: Variant = .default,
        size: Size = .default,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize))
                }
                if !title.isEmpty {
                    Text(title)
                        .font(DesignSystem.Typography.button)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: height)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.primary
        case .destructive:
            return DesignSystem.Colors.destructive
        case .outline:
            return DesignSystem.Colors.background
        case .secondary:
            return DesignSystem.Colors.secondary
        case .ghost:
            return Color.clear
        case .link:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.primaryForeground
        case .destructive:
            return DesignSystem.Colors.destructiveForeground
        case .outline:
            return DesignSystem.Colors.foreground
        case .secondary:
            return DesignSystem.Colors.secondaryForeground
        case .ghost:
            return DesignSystem.Colors.foreground
        case .link:
            return DesignSystem.Colors.primary
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline:
            return DesignSystem.Colors.border
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        variant == .outline ? 1 : 0
    }
    
    private var height: CGFloat {
        switch size {
        case .default:
            return 36
        case .sm:
            return 32
        case .lg:
            return 40
        case .icon:
            return 36
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .default:
            return DesignSystem.Spacing.md
        case .sm:
            return 12
        case .lg:
            return DesignSystem.Spacing.lg
        case .icon:
            return 0
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .default:
            return DesignSystem.Spacing.sm
        case .sm:
            return 6
        case .lg:
            return 10
        case .icon:
            return 0
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .default:
            return 16
        case .sm:
            return 14
        case .lg:
            return 18
        case .icon:
            return 16
        }
    }
}

// MARK: - Card Component
struct BDCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.card)
        .foregroundColor(DesignSystem.Colors.cardForeground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Card Header Component
struct BDCardHeader<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
    }
}

// MARK: - Card Title Component
struct BDCardTitle: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.h4)
            .foregroundColor(DesignSystem.Colors.cardForeground)
    }
}

// MARK: - Card Description Component
struct BDCardDescription: View {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
    
    var body: some View {
        Text(description)
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.mutedForeground)
    }
}

// MARK: - Card Content Component
struct BDCardContent<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

// MARK: - Badge Component
struct BDBadge: View {
    enum Variant {
        case `default`
        case secondary
        case destructive
        case outline
    }
    
    let text: String
    let variant: Variant
    
    init(_ text: String, variant: Variant = .default) {
        self.text = text
        self.variant = variant
    }
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.secondary
        case .destructive:
            return DesignSystem.Colors.destructive
        case .outline:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.primaryForeground
        case .secondary:
            return DesignSystem.Colors.secondaryForeground
        case .destructive:
            return DesignSystem.Colors.destructiveForeground
        case .outline:
            return DesignSystem.Colors.foreground
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline:
            return DesignSystem.Colors.border
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        variant == .outline ? 1 : 0
    }
}

// MARK: - Progress Component
struct BDProgress: View {
    let value: Double // 0.0 to 1.0
    let height: CGFloat
    
    init(value: Double, height: CGFloat = 8) {
        self.value = max(0, min(1, value))
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DesignSystem.Colors.secondary)
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: height / 2))
                
                Rectangle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: geometry.size.width * value, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: height / 2))
            }
        }
        .frame(height: height)
    }
}
/
/ MARK: - Input Component
struct BDInput: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(DesignSystem.Typography.body)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.inputBackground)
        .foregroundColor(DesignSystem.Colors.foreground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Label Component
struct BDLabel: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.label)
            .foregroundColor(DesignSystem.Colors.foreground)
    }
}

// MARK: - Separator Component
struct BDSeparator: View {
    let orientation: Orientation
    
    enum Orientation {
        case horizontal
        case vertical
    }
    
    init(orientation: Orientation = .horizontal) {
        self.orientation = orientation
    }
    
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.border)
            .frame(
                width: orientation == .horizontal ? nil : 1,
                height: orientation == .horizontal ? 1 : nil
            )
    }
}

// MARK: - Alert Component
struct BDAlert: View {
    enum Variant {
        case `default`
        case destructive
    }
    
    let title: String
    let description: String?
    let variant: Variant
    let icon: String?
    
    init(
        title: String,
        description: String? = nil,
        variant: Variant = .default,
        icon: String? = nil
    ) {
        self.title = title
        self.description = description
        self.variant = variant
        self.icon = icon
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.label)
                    .foregroundColor(titleColor)
                
                if let description = description {
                    Text(description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(descriptionColor)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.background
        case .destructive:
            return DesignSystem.Colors.destructive.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.border
        case .destructive:
            return DesignSystem.Colors.destructive.opacity(0.3)
        }
    }
    
    private var titleColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.foreground
        case .destructive:
            return DesignSystem.Colors.destructive
        }
    }
    
    private var descriptionColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.mutedForeground
        case .destructive:
            return DesignSystem.Colors.destructive.opacity(0.8)
        }
    }
    
    private var iconColor: Color {
        switch variant {
        case .default:
            return DesignSystem.Colors.mutedForeground
        case .destructive:
            return DesignSystem.Colors.destructive
        }
    }
}

// MARK: - Skeleton Component
struct BDSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.muted)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shimmer()
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Switch Component
struct BDSwitch: View {
    @Binding var isOn: Bool
    
    init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(BDSwitchStyle())
    }
}

struct BDSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? DesignSystem.Colors.primary : DesignSystem.Colors.muted)
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}