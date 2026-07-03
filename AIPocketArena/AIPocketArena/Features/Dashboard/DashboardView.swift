// DashboardView.swift — AI Pocket Arena
// Home screen: due count, streak, mastery rings, mode picker, weakest concepts

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = DashboardViewModel()
    @State private var showModeSelect = false

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                headerSection

                // MARK: - Due & Streak Cards
                HStack(spacing: 12) {
                    dueCard
                    streakCard
                }
                .padding(.horizontal)

                // MARK: - XP Progress
                XPProgressBar(
                    progress: profile.xpProgress,
                    level: viewModel.level,
                    xp: viewModel.xp
                )
                .padding(.horizontal)

                // MARK: - Quick Play
                quickPlaySection

                // MARK: - Mastery Overview
                masterySection

                // MARK: - Game Modes Grid
                modeGridSection

                // MARK: - Weakest Concepts
                weakestSection
            }
            .padding(.vertical)
        }
        .background(DesignTokens.bg)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI Pocket Arena")
                    .font(DesignTokens.display(20))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .onAppear {
            profile.updateStreak()
            viewModel.refresh(progressRecords: progressRecords, profile: profile)
        }
        .sheet(isPresented: $showModeSelect) {
            ModeSelectView()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(DesignTokens.body(14))
                    .foregroundStyle(DesignTokens.text2)
                Text("Ready to train?")
                    .font(DesignTokens.display(24))
                    .foregroundStyle(DesignTokens.text)
            }
            Spacer()
            StreakBadge(streak: viewModel.streak)
        }
        .padding(.horizontal)
    }

    // MARK: - Due Card
    private var dueCard: some View {
        NavigationLink {
            FlashRecallView()
        } label: {
            VStack(spacing: 8) {
                Text("\(viewModel.dueCount)")
                    .font(DesignTokens.display(36))
                    .foregroundStyle(DesignTokens.accent)

                Text("Due Today")
                    .font(DesignTokens.body(13))
                    .foregroundStyle(DesignTokens.text2)

                Text("Tap to review")
                    .font(DesignTokens.mono(10))
                    .foregroundStyle(DesignTokens.accent.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                    .stroke(DesignTokens.accent.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        VStack(spacing: 8) {
            Text("\(Int(viewModel.overallMastery * 100))%")
                .font(DesignTokens.display(36))
                .foregroundStyle(DesignTokens.accent2)

            Text("Mastery")
                .font(DesignTokens.body(13))
                .foregroundStyle(DesignTokens.text2)

            Text("\(ContentStore.shared.concepts.count) concepts")
                .font(DesignTokens.mono(10))
                .foregroundStyle(DesignTokens.accent2.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
    }

    // MARK: - Quick Play
    private var quickPlaySection: some View {
        Button {
            showModeSelect = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                Text("Start Training")
                    .font(DesignTokens.display(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DesignTokens.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
        }
        .padding(.horizontal)
    }

    // MARK: - Mastery Rings
    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Mastery")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.categoryMasteries, id: \.category) { item in
                        MasteryRingView(
                            category: item.category,
                            mastery: item.mastery,
                            size: 55
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Mode Grid
    private var modeGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Modes")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(GameMode.allCases) { mode in
                    NavigationLink {
                        modeDestination(for: mode)
                    } label: {
                        ModeCard(mode: mode)
                    }
                }
            }
            .padding(.horizontal)
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

    // MARK: - Weakest Concepts
    private var weakestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weakest Concepts")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(viewModel.weakestConcepts) { concept in
                    NavigationLink {
                        ConceptDetailView(concept: concept)
                    } label: {
                        WeakConceptRow(concept: concept)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Mode Card
struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.accent)

            Text(mode.displayName)
                .font(DesignTokens.body(13, weight: .semibold))
                .foregroundStyle(DesignTokens.text)

            Text(mode.subtitle)
                .font(DesignTokens.mono(9))
                .foregroundStyle(DesignTokens.text3)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Weak Concept Row
struct WeakConceptRow: View {
    let concept: Concept

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DesignTokens.accent3.opacity(0.2))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(concept.term)
                    .font(DesignTokens.body(14, weight: .semibold))
                    .foregroundStyle(DesignTokens.text)

                Text(concept.oneLiner)
                    .font(DesignTokens.body(12))
                    .foregroundStyle(DesignTokens.text2)
                    .lineLimit(1)
            }

            Spacer()

            CategoryBadge(category: concept.category)
        }
        .padding(12)
        .surfaceCard()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
