// DesignTokens.swift — AI Pocket Arena
// Visual design tokens from §8, matching the web guide palette

import SwiftUI

enum DesignTokens {
    // MARK: - Colors
    static let bg = Color(hex: 0x0A0A0F)
    static let surface = Color(hex: 0x111118)
    static let surface2 = Color(hex: 0x16161F)
    static let surface3 = Color(hex: 0x1C1C28)
    static let border = Color(hex: 0x2A2A3A)

    static let accent = Color(hex: 0x6C63FF)     // Purple
    static let accent2 = Color(hex: 0x00D4AA)    // Teal/Green
    static let accent3 = Color(hex: 0xFF6B6B)    // Red/Coral
    static let accent4 = Color(hex: 0xFFD166)    // Yellow/Gold

    static let text = Color(hex: 0xE8E8F0)
    static let text2 = Color(hex: 0x9898B0)
    static let text3 = Color(hex: 0x5A5A78)

    // MARK: - Radii
    static let radius: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusSm: CGFloat = 8

    // MARK: - Fonts
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Syne", size: size).weight(weight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DMMono-Regular", size: size).weight(weight)
    }

    static func monoMedium(_ size: CGFloat) -> Font {
        .custom("DMMono-Medium", size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, accent2],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let bgGradient = LinearGradient(
        colors: [bg, surface],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows
    static let glowAccent = Color(hex: 0x6C63FF).opacity(0.3)
    static let glowCorrect = Color(hex: 0x00D4AA).opacity(0.3)
    static let glowIncorrect = Color(hex: 0xFF6B6B).opacity(0.3)
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Styled View Modifiers
struct CardStyle: ViewModifier {
    var isHovered: Bool = false

    func body(content: Content) -> some View {
        content
            .background(DesignTokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                    .stroke(isHovered ? DesignTokens.accent.opacity(0.3) : DesignTokens.border, lineWidth: 1)
            )
    }
}

struct SurfaceCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignTokens.surface2)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radius)
                    .stroke(DesignTokens.border, lineWidth: 1)
            )
    }
}

struct ChipStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.mono(12))
            .foregroundStyle(DesignTokens.accent4)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignTokens.surface3)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignTokens.border, lineWidth: 1)
            )
    }
}

struct AccentButtonStyle: ButtonStyle {
    var color: Color = DesignTokens.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.body(14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var color: Color = DesignTokens.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.body(13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusSm)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle(isHovered: Bool = false) -> some View {
        modifier(CardStyle(isHovered: isHovered))
    }

    func surfaceCard() -> some View {
        modifier(SurfaceCardStyle())
    }

    func chipStyle() -> some View {
        modifier(ChipStyle())
    }
}

// MARK: - Badge View
struct CategoryBadge: View {
    let category: Category

    var body: some View {
        Text(category.displayName)
            .font(DesignTokens.mono(10))
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.3)
            .foregroundStyle(category.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(category.accentColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(category.accentColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: Int

    var label: String {
        switch difficulty {
        case 1: "Foundational"
        case 2: "Intermediate"
        case 3: "Frontier"
        default: "Unknown"
        }
    }

    var color: Color {
        switch difficulty {
        case 1: DesignTokens.accent2
        case 2: DesignTokens.accent4
        case 3: DesignTokens.accent3
        default: DesignTokens.text3
        }
    }

    var body: some View {
        Text(label)
            .font(DesignTokens.mono(10))
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .tracking(0.3)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}
