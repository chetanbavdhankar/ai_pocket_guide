// RapidFireView.swift — AI Pocket Arena
// Timed MCQ with dynamic countdown bar, streak indicators, and instant feedback.

import SwiftUI
import SwiftData

struct RapidFireView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = RapidFireViewModel()
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.sessionConcepts.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .rapidFire,
                    difficulty: viewModel.difficulty,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.sessionConcepts.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header progress and streak
                    headerView
                    
                    // Question box
                    questionBox
                    
                    // Options list
                    optionsList
                    
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
                Text("Rapid Fire")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .onAppear {
            viewModel.startSession(progressRecords: progressRecords, difficulty: .medium)
        }
        .onReceive(timer) { _ in
            guard viewModel.timerActive else { return }
            if viewModel.timeRemaining > 0 {
                viewModel.timeRemaining -= 0.1
            } else {
                viewModel.handleTimeout(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
            }
        }
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
            
            Text("Go back and read some study guides first!")
                .font(DesignTokens.body(14))
                .foregroundStyle(DesignTokens.text2)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Question \(viewModel.currentIndex + 1) / \(viewModel.sessionConcepts.count)")
                    .font(DesignTokens.mono(12))
                    .foregroundStyle(DesignTokens.text2)
                
                Spacer()
                
                if viewModel.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(viewModel.currentStreak)")
                            .font(DesignTokens.mono(12))
                            .foregroundStyle(DesignTokens.accent4)
                        if viewModel.streakMultiplier > 1 {
                            Text("(x\(viewModel.streakMultiplier))")
                                .font(DesignTokens.mono(11))
                                .foregroundStyle(DesignTokens.accent2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Timer progress bar
            let limit = GameMode.rapidFire.config(for: viewModel.difficulty).timePerQuestion ?? 1
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.surface3)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.timeRemaining < 3 ? DesignTokens.accent3 : DesignTokens.accent)
                        .frame(width: geo.size.width * max(0, viewModel.timeRemaining / limit))
                        .animation(.linear(duration: 0.1), value: viewModel.timeRemaining)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
        }
    }
    
    private var questionBox: some View {
        VStack(spacing: 12) {
            if let concept = viewModel.currentConcept {
                Text(concept.term)
                    .font(DesignTokens.display(20))
                    .foregroundStyle(DesignTokens.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                CategoryBadge(category: concept.category)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                .stroke(DesignTokens.border, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.options) { option in
                Button {
                    viewModel.selectOption(option, progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                } label: {
                    HStack {
                        Text(option.oneLiner)
                            .font(DesignTokens.body(13, weight: .medium))
                            .foregroundStyle(optionTextColor(for: option))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if let selectedID = viewModel.selectedOptionID {
                            if option.isCorrect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DesignTokens.accent2)
                            } else if selectedID == option.id {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DesignTokens.accent3)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(optionBackgroundColor(for: option))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radius)
                            .stroke(optionBorderColor(for: option), lineWidth: 1)
                    )
                }
                .disabled(viewModel.selectedOptionID != nil)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Option Styling Helpers
    
    private func optionTextColor(for option: MCQOption) -> Color {
        guard let selectedID = viewModel.selectedOptionID else {
            return DesignTokens.text
        }
        if option.isCorrect {
            return .white
        } else if selectedID == option.id {
            return .white
        }
        return DesignTokens.text2
    }
    
    private func optionBackgroundColor(for option: MCQOption) -> Color {
        guard let selectedID = viewModel.selectedOptionID else {
            return DesignTokens.surface
        }
        if option.isCorrect {
            return DesignTokens.accent2.opacity(0.2)
        } else if selectedID == option.id {
            return DesignTokens.accent3.opacity(0.2)
        }
        return DesignTokens.surface.opacity(0.5)
    }
    
    private func optionBorderColor(for option: MCQOption) -> Color {
        guard let selectedID = viewModel.selectedOptionID else {
            return DesignTokens.border
        }
        if option.isCorrect {
            return DesignTokens.accent2
        } else if selectedID == option.id {
            return DesignTokens.accent3
        }
        return DesignTokens.border.opacity(0.3)
    }
}

#Preview {
    NavigationStack {
        RapidFireView()
    }
    .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
