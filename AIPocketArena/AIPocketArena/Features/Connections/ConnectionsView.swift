// ConnectionsView.swift — AI Pocket Arena
// NYT Connections-style group sorting game mode.

import SwiftUI
import SwiftData

struct ConnectionsView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ConnectionsViewModel()
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.chips.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .connections,
                    difficulty: viewModel.difficulty,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.won ? 4 : viewModel.matchedGroups.count,
                    totalCount: 4,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header state (mistakes remaining)
                    headerView
                    
                    // Already matched groups list
                    matchedGroupsList
                    
                    // Grid of active chips
                    activeChipsGrid
                    
                    Spacer()
                    
                    // Action controls
                    actionControls
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
                Text("Connections")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .onAppear {
            viewModel.startSession(progressRecords: progressRecords, difficulty: .medium)
        }
    }
    
    // MARK: - Subviews
    
    private var emptySessionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.accent4)
            
            Text("Insufficent Concepts")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Text("To play Connections, at least 4 categories must have 4 concepts each.")
                .font(DesignTokens.body(14))
                .foregroundStyle(DesignTokens.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Find groups of 4 related concepts")
                .font(DesignTokens.body(13))
                .foregroundStyle(DesignTokens.text2)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("Mistakes:")
                    .font(DesignTokens.mono(11))
                    .foregroundStyle(DesignTokens.text3)
                
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < viewModel.mistakesRemaining ? DesignTokens.accent3 : DesignTokens.surface3)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var matchedGroupsList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.matchedGroups) { group in
                VStack(spacing: 4) {
                    Text(group.category.displayName)
                        .font(DesignTokens.display(13))
                        .foregroundStyle(.white)
                        .textCase(.uppercase)
                    
                    Text(group.concepts.map { $0.term }.joined(separator: ", "))
                        .font(DesignTokens.body(11))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(group.color.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius)
                        .stroke(group.color, lineWidth: 1.5)
                )
                .padding(.horizontal)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }
        }
    }
    
    private var activeChipsGrid: some View {
        let activeChips = viewModel.chips.filter { !$0.isMatched }
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(activeChips) { chip in
                Button {
                    viewModel.toggleSelection(of: chip.id)
                } label: {
                    Text(chip.concept.term)
                        .font(DesignTokens.mono(9))
                        .foregroundStyle(chip.isSelected ? .white : DesignTokens.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(chip.isSelected ? DesignTokens.accent : DesignTokens.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusSm)
                                .stroke(chip.isSelected ? DesignTokens.accent : DesignTokens.border, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var actionControls: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    viewModel.chips.shuffle()
                }
            } label: {
                Text("Shuffle")
                    .font(DesignTokens.display(14))
                    .foregroundStyle(DesignTokens.text)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radius)
                            .stroke(DesignTokens.border, lineWidth: 1)
                    )
            }
            
            Button {
                viewModel.submitGuess(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
            } label: {
                Text("Submit")
                    .font(DesignTokens.display(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedIDs.count == 4 ? DesignTokens.accentGradient : LinearGradient(colors: [DesignTokens.surface3], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
            }
            .disabled(viewModel.selectedIDs.count != 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    ConnectionsView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
