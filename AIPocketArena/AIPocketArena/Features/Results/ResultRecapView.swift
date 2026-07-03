// ResultRecapView.swift — AI Pocket Arena
// Post-session results screen showing accuracy, XP earned, level up, and concepts reviewed.

import SwiftUI

struct SessionDetailItem: Identifiable, Sendable {
    let id = UUID()
    let concept: Concept
    let isCorrect: Bool
}

struct ResultRecapView: View {
    @Environment(\.dismiss) private var dismiss
    
    let mode: GameMode
    let difficulty: GameDifficulty
    let xpEarned: Int
    let correctCount: Int
    let totalCount: Int
    let reviewedItems: [SessionDetailItem]
    
    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header / Mode badge
                VStack(spacing: 8) {
                    Text(mode.displayName)
                        .font(DesignTokens.mono(12))
                        .foregroundStyle(DesignTokens.accent)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignTokens.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text("Session Complete")
                        .font(DesignTokens.display(28))
                        .foregroundStyle(DesignTokens.text)
                }
                .padding(.top, 20)
                
                // Ring/Stat visualization
                ZStack {
                    Circle()
                        .stroke(DesignTokens.surface3, lineWidth: 10)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: accuracy)
                        .stroke(
                            accuracy >= 0.7 ? DesignTokens.accent2 : (accuracy >= 0.4 ? DesignTokens.accent4 : DesignTokens.accent3),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 150, height: 150)
                    
                    VStack(spacing: 4) {
                        Text("\(correctCount) / \(totalCount)")
                            .font(DesignTokens.display(24))
                            .foregroundStyle(DesignTokens.text)
                        
                        Text("\(Int(accuracy * 100))% Correct")
                            .font(DesignTokens.body(14, weight: .medium))
                            .foregroundStyle(DesignTokens.text2)
                    }
                }
                
                // Rewards / XP
                HStack(spacing: 20) {
                    VStack {
                        Text("+\(xpEarned)")
                            .font(DesignTokens.display(24))
                            .foregroundStyle(DesignTokens.accent4)
                        Text("XP Earned")
                            .font(DesignTokens.body(12))
                            .foregroundStyle(DesignTokens.text2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(DesignTokens.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    
                    VStack {
                        Text(difficulty.displayName)
                            .font(DesignTokens.display(20))
                            .foregroundStyle(DesignTokens.text)
                        Text("Difficulty")
                            .font(DesignTokens.body(12))
                            .foregroundStyle(DesignTokens.text2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(DesignTokens.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                }
                
                // Concepts reviewed list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Concepts Reviewed")
                        .font(DesignTokens.display(16))
                        .foregroundStyle(DesignTokens.text)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(reviewedItems) { item in
                            HStack {
                                Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(item.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                                
                                Text(item.concept.term)
                                    .font(DesignTokens.body(14, weight: .semibold))
                                    .foregroundStyle(DesignTokens.text)
                                
                                Spacer()
                                
                                CategoryBadge(category: item.concept.category)
                            }
                            .padding()
                            .background(DesignTokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radius)
                                    .stroke(DesignTokens.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Back to Dashboard")
                        .font(DesignTokens.display(16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.bottom, 40)
        }
        .background(DesignTokens.bg)
    }
}
