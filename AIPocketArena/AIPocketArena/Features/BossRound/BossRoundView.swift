// BossRoundView.swift — AI Pocket Arena
// High-stakes mixed gauntlet mode with 3 lives and 15s timer.

import SwiftUI
import SwiftData

struct BossRoundView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = BossRoundViewModel()
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.questions.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .bossRound,
                    difficulty: .hard,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.questions.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header progress + lives
                    headerView
                    
                    // Question text box
                    questionBox
                    
                    // MCQ Options
                    optionsList
                    
                    // Explanation after answering
                    explanationBox
                    
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
                Text("BOSS ROUND")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.accent3)
            }
        }
        .onAppear {
            viewModel.startSession(progressRecords: progressRecords)
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
            Image(systemName: "shield.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.text3)
            
            Text("No Weak Concepts")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Text("Boss Round targets your weakest concepts. Play other modes first to populate progress records!")
                .font(DesignTokens.body(14))
                .foregroundStyle(DesignTokens.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Boss Round: \(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
                    .font(DesignTokens.mono(12))
                    .foregroundStyle(DesignTokens.text2)
                
                Spacer()
                
                // Lives display
                HStack(spacing: 4) {
                    ForEach(0..<3) { idx in
                        Image(systemName: idx < viewModel.livesRemaining ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.accent3)
                    }
                }
            }
            .padding(.horizontal)
            
            // 15-second countdown progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.surface3)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.accent3)
                        .frame(width: geo.size.width * max(0, viewModel.timeRemaining / 15.0))
                        .animation(.linear(duration: 0.1), value: viewModel.timeRemaining)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
        }
    }
    
    private var questionBox: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let question = viewModel.currentQuestion {
                HStack {
                    CategoryBadge(category: question.concept.category)
                    Spacer()
                    Text(question.type.rawValue.uppercased())
                        .font(DesignTokens.mono(9))
                        .foregroundStyle(DesignTokens.text3)
                }
                
                Text(question.questionText)
                    .font(DesignTokens.body(15, weight: .semibold))
                    .foregroundStyle(DesignTokens.text)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                .stroke(DesignTokens.accent3.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var optionsList: some View {
        VStack(spacing: 10) {
            if let question = viewModel.currentQuestion {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        viewModel.submitChoice(option, progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                    } label: {
                        HStack {
                            Text(option)
                                .font(DesignTokens.body(13, weight: .medium))
                                .foregroundStyle(optionTextColor(for: option, correct: question.correctAnswer))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            if let selected = viewModel.selectedOption {
                                if option == question.correctAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(DesignTokens.accent2)
                                } else if selected == option {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(DesignTokens.accent3)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(optionBackgroundColor(for: option, correct: question.correctAnswer))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radius)
                                .stroke(optionBorderColor(for: option, correct: question.correctAnswer), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.selectedOption != nil)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var explanationBox: some View {
        VStack {
            if viewModel.selectedOption != nil, let question = viewModel.currentQuestion {
                Text(question.explanation)
                    .font(DesignTokens.body(13))
                    .foregroundStyle(DesignTokens.text2)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radius)
                            .stroke(DesignTokens.border, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Option Styling Helpers
    
    private func optionTextColor(for option: String, correct: String) -> Color {
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.text
        }
        if option == correct {
            return .white
        } else if selected == option {
            return .white
        }
        return DesignTokens.text2
    }
    
    private func optionBackgroundColor(for option: String, correct: String) -> Color {
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.surface
        }
        if option == correct {
            return DesignTokens.accent2.opacity(0.2)
        } else if selected == option {
            return DesignTokens.accent3.opacity(0.2)
        }
        return DesignTokens.surface.opacity(0.5)
    }
    
    private func optionBorderColor(for option: String, correct: String) -> Color {
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.border
        }
        if option == correct {
            return DesignTokens.accent2
        } else if selected == option {
            return DesignTokens.accent3
        }
        return DesignTokens.border.opacity(0.3)
    }
}

#Preview {
    BossRoundView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
