// MatchPairsView.swift — AI Pocket Arena
// Term ↔ Definition matching grid game mode.

import SwiftUI
import SwiftData

struct MatchPairsView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = MatchPairsViewModel()
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.sessionConcepts.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .matchPairs,
                    difficulty: viewModel.difficulty,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.sessionConcepts.count - viewModel.mistakes,
                    totalCount: viewModel.sessionConcepts.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header info
                    headerView
                    
                    // Grid content
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(viewModel.items) { item in
                                MatchCard(
                                    item: item,
                                    isSelected: viewModel.selectedItem1?.id == item.id || viewModel.selectedItem2?.id == item.id,
                                    isMatched: viewModel.matchedIDs.contains(item.conceptID),
                                    isWrong: isWrongSelection(item)
                                ) {
                                    viewModel.selectItem(item, progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(DesignTokens.text2)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Match Pairs")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .onAppear {
            viewModel.startSession(progressRecords: progressRecords, difficulty: .medium)
        }
    }
    
    // MARK: - Helpers
    
    private func isWrongSelection(_ item: MatchItem) -> Bool {
        guard let s1 = viewModel.selectedItem1, let s2 = viewModel.selectedItem2 else { return false }
        guard item.id == s1.id || item.id == s2.id else { return false }
        // If s2 is selected, we know it's not a match (otherwise they would have been matched and cleared immediately)
        return s1.conceptID != s2.conceptID || s1.isTerm == s2.isTerm
    }
    
    // MARK: - Subviews
    
    private var emptySessionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.accent4)
            
            Text("No Concepts Found")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match all pairs")
                    .font(DesignTokens.body(13))
                    .foregroundStyle(DesignTokens.text2)
                Text("Matched: \(viewModel.matchedIDs.count) / \(viewModel.sessionConcepts.count)")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Mistakes")
                    .font(DesignTokens.body(13))
                    .foregroundStyle(DesignTokens.text2)
                Text("\(viewModel.mistakes)")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(viewModel.mistakes > 0 ? DesignTokens.accent3 : DesignTokens.text)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Match Card
struct MatchCard: View {
    let item: MatchItem
    let isSelected: Bool
    let isMatched: Bool
    let isWrong: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(item.text)
                .font(item.isTerm ? DesignTokens.display(14) : DesignTokens.body(12))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius)
                        .stroke(borderColor, lineWidth: isSelected || isMatched ? 2 : 1)
                )
                .opacity(isMatched ? 0.35 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: isMatched)
        }
        .disabled(isMatched)
    }
    
    // MARK: - Card Styling
    
    private var textColor: Color {
        if isMatched {
            return DesignTokens.text3
        }
        if isWrong {
            return .white
        }
        if isSelected {
            return .white
        }
        return DesignTokens.text
    }
    
    private var backgroundColor: Color {
        if isMatched {
            return DesignTokens.surface3.opacity(0.2)
        }
        if isWrong {
            return DesignTokens.accent3.opacity(0.2)
        }
        if isSelected {
            return DesignTokens.accent.opacity(0.2)
        }
        return DesignTokens.surface
    }
    
    private var borderColor: Color {
        if isMatched {
            return DesignTokens.border.opacity(0.3)
        }
        if isWrong {
            return DesignTokens.accent3
        }
        if isSelected {
            return DesignTokens.accent
        }
        return DesignTokens.border
    }
}

#Preview {
    MatchPairsView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
