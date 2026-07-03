// MasteryRingView.swift — AI Pocket Arena
// Circular progress indicator for category mastery

import SwiftUI

struct MasteryRingView: View {
    let category: Category
    let mastery: Double
    var size: CGFloat = 60

    @State private var animatedMastery: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(DesignTokens.surface3, lineWidth: 4)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedMastery)
                    .stroke(
                        category.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: animatedMastery)

                // Percentage
                Text("\(Int(mastery * 100))")
                    .font(DesignTokens.mono(size * 0.22))
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.text)
            }
            .frame(width: size, height: size)

            // Category icon
            Image(systemName: category.icon)
                .font(.system(size: size * 0.2))
                .foregroundStyle(category.accentColor)

            Text(category.displayName)
                .font(DesignTokens.mono(8))
                .foregroundStyle(DesignTokens.text2)
                .lineLimit(1)
                .frame(width: size + 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedMastery = mastery
            }
        }
        .onChange(of: mastery) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedMastery = newValue
            }
        }
    }
}

// MARK: - XP Progress Bar
struct XPProgressBar: View {
    let progress: Double
    let level: Int
    let xp: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Level \(level)")
                    .font(DesignTokens.display(14))
                    .foregroundStyle(DesignTokens.accent)
                Spacer()
                Text("\(xp) XP")
                    .font(DesignTokens.mono(12))
                    .foregroundStyle(DesignTokens.text2)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.surface3)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.accentGradient)
                        .frame(width: geo.size.width * min(1, max(0, progress)))
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Streak Display
struct StreakBadge: View {
    let streak: Int
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 20))
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)

            Text("\(streak)")
                .font(DesignTokens.display(18))
                .foregroundStyle(DesignTokens.accent4)

            Text("day streak")
                .font(DesignTokens.body(12))
                .foregroundStyle(DesignTokens.text2)
        }
        .onAppear { isPulsing = streak > 0 }
    }
}

#Preview {
    VStack(spacing: 20) {
        MasteryRingView(category: .attention, mastery: 0.72)
        XPProgressBar(progress: 0.45, level: 5, xp: 450)
            .padding(.horizontal)
        StreakBadge(streak: 7)
    }
    .padding()
    .background(DesignTokens.bg)
}
