// ClozeView.swift — AI Pocket Arena
// Fill-in-the-blank game mode supporting MCQ and keyboard input.

import SwiftUI
import SwiftData

struct ClozeView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ClozeViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.sessionConcepts.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .cloze,
                    difficulty: viewModel.difficulty,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.sessionConcepts.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Question Prompt Box
                    promptBox
                    
                    // Input options based on difficulty
                    if viewModel.difficulty == .hard {
                        freeTextInputField
                    } else {
                        multipleChoiceButtons
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
                Text("Cloze Recall")
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
            
            Text("No Concepts Found")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Question \(viewModel.currentIndex + 1) / \(viewModel.sessionConcepts.count)")
                .font(DesignTokens.mono(12))
                .foregroundStyle(DesignTokens.text2)
            Spacer()
            DifficultyBadge(difficulty: viewModel.difficulty == .easy ? 1 : (viewModel.difficulty == .medium ? 2 : 3))
        }
        .padding(.horizontal)
    }
    
    private var promptBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let concept = viewModel.currentConcept, let cloze = concept.cloze {
                HStack {
                    CategoryBadge(category: concept.category)
                    Spacer()
                }
                
                Text(cloze.prompt)
                    .font(DesignTokens.body(16, weight: .medium))
                    .foregroundStyle(DesignTokens.text)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                .stroke(DesignTokens.border, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var multipleChoiceButtons: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.choices, id: \.self) { choice in
                Button {
                    viewModel.submitChoice(choice, progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                } label: {
                    HStack {
                        Text(choice)
                            .font(DesignTokens.mono(13))
                            .foregroundStyle(choiceTextColor(for: choice))
                        
                        Spacer()
                        
                        if let selected = viewModel.selectedChoice {
                            if choice == viewModel.currentConcept?.cloze?.answer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DesignTokens.accent2)
                            } else if selected == choice {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DesignTokens.accent3)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(choiceBackgroundColor(for: choice))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radius)
                            .stroke(choiceBorderColor(for: choice), lineWidth: 1)
                    )
                }
                .disabled(viewModel.selectedChoice != nil)
            }
        }
        .padding(.horizontal)
    }
    
    private var freeTextInputField: some View {
        VStack(spacing: 16) {
            TextField("Type the missing phrase...", text: $viewModel.textInput)
                .font(DesignTokens.body(14))
                .padding()
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius)
                        .stroke(isFieldFocused ? DesignTokens.accent : DesignTokens.border, lineWidth: 1)
                )
                .focused($isFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.submitFreeText(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                }
                .disabled(viewModel.textFeedback != nil)
            
            if let feedback = viewModel.textFeedback {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                        Text(feedback.isCorrect ? "Correct" : "Incorrect")
                            .font(DesignTokens.display(14))
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                    }
                    
                    Text(feedback.feedback)
                        .font(DesignTokens.body(13))
                        .foregroundStyle(DesignTokens.text2)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(feedback.isCorrect ? DesignTokens.accent2.opacity(0.1) : DesignTokens.accent3.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .transition(.opacity)
            } else {
                Button {
                    isFieldFocused = false
                    viewModel.submitFreeText(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                } label: {
                    Text("Submit Answer")
                        .font(DesignTokens.display(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                }
                .disabled(viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Choice Styling Helpers
    
    private func choiceTextColor(for choice: String) -> Color {
        guard let selected = viewModel.selectedChoice else {
            return DesignTokens.text
        }
        if choice == viewModel.currentConcept?.cloze?.answer {
            return .white
        } else if selected == choice {
            return .white
        }
        return DesignTokens.text2
    }
    
    private func choiceBackgroundColor(for choice: String) -> Color {
        guard let selected = viewModel.selectedChoice else {
            return DesignTokens.surface
        }
        if choice == viewModel.currentConcept?.cloze?.answer {
            return DesignTokens.accent2.opacity(0.2)
        } else if selected == choice {
            return DesignTokens.accent3.opacity(0.2)
        }
        return DesignTokens.surface.opacity(0.5)
    }
    
    private func choiceBorderColor(for choice: String) -> Color {
        guard let selected = viewModel.selectedChoice else {
            return DesignTokens.border
        }
        if choice == viewModel.currentConcept?.cloze?.answer {
            return DesignTokens.accent2
        } else if selected == choice {
            return DesignTokens.accent3
        }
        return DesignTokens.border.opacity(0.3)
    }
}

#Preview {
    ClozeView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
