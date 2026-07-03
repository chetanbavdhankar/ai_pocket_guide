// ModeSelectView.swift — AI Pocket Arena
// Full mode selection sheet with difficulty picker and category filter

import SwiftUI

struct ModeSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDifficulty: GameDifficulty = .medium
    @State private var selectedCategory: Category? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Difficulty picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(DesignTokens.display(14))
                            .foregroundStyle(DesignTokens.text)

                        HStack(spacing: 8) {
                            ForEach(GameDifficulty.allCases) { diff in
                                Button {
                                    selectedDifficulty = diff
                                } label: {
                                    Text("\(diff.icon) \(diff.displayName)")
                                        .font(DesignTokens.body(13, weight: .semibold))
                                        .foregroundStyle(selectedDifficulty == diff ? .white : DesignTokens.text2)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedDifficulty == diff ? DesignTokens.accent : DesignTokens.surface2)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Category filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Category")
                            .font(DesignTokens.display(14))
                            .foregroundStyle(DesignTokens.text)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    selectedCategory = nil
                                } label: {
                                    Text("All")
                                        .font(DesignTokens.mono(11))
                                        .foregroundStyle(selectedCategory == nil ? .white : DesignTokens.text2)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == nil ? DesignTokens.accent : DesignTokens.surface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }

                                ForEach(Category.allCases) { category in
                                    Button {
                                        selectedCategory = category
                                    } label: {
                                        Text(category.displayName)
                                            .font(DesignTokens.mono(11))
                                            .foregroundStyle(selectedCategory == category ? .white : category.accentColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedCategory == category ? category.accentColor : category.accentColor.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Modes list
                    VStack(spacing: 12) {
                        ForEach(GameMode.allCases) { mode in
                            NavigationLink {
                                modeDestination(for: mode)
                            } label: {
                                ModeDetailCard(mode: mode, difficulty: selectedDifficulty)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(DesignTokens.bg)
            .navigationTitle("Choose Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DesignTokens.text2)
                }
            }
        }
    }

    @ViewBuilder
    private func modeDestination(for mode: GameMode) -> some View {
        switch mode {
        case .flashRecall: FlashRecallView()
        case .rapidFire: RapidFireView()
        case .matchPairs: MatchPairsView()
        case .cloze: ClozeView()
        case .connections: ConnectionsView()
        case .scenario: ScenarioView()
        case .depthLadder: DepthLadderView()
        case .bossRound: BossRoundView()
        }
    }
}

// MARK: - Mode Detail Card
struct ModeDetailCard: View {
    let mode: GameMode
    let difficulty: GameDifficulty

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: mode.icon)
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.accent)
                .frame(width: 44, height: 44)
                .background(DesignTokens.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(mode.displayName)
                    .font(DesignTokens.body(15, weight: .semibold))
                    .foregroundStyle(DesignTokens.text)

                Text(mode.learningType)
                    .font(DesignTokens.mono(11))
                    .foregroundStyle(DesignTokens.text2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.text3)
        }
        .padding(14)
        .cardStyle()
    }
}
