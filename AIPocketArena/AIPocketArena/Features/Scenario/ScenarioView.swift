// ScenarioView.swift — AI Pocket Arena
// Scenario tradeoff decisions game mode.

import SwiftUI
import SwiftData

struct ScenarioView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ScenarioViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.sessionConcepts.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .scenario,
                    difficulty: viewModel.difficulty,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.sessionConcepts.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Header progress
                    headerView
                    
                    // Tradeoff Scenario Box
                    scenarioBox
                    
                    // Controls
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
                Text("Scenario Tradeoffs")
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
            
            Text("No Scenarios Available")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Text("Currently, there are no concepts with tradeoff scenarios loaded in the bank.")
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
            Text("Scenario \(viewModel.currentIndex + 1) / \(viewModel.sessionConcepts.count)")
                .font(DesignTokens.mono(12))
                .foregroundStyle(DesignTokens.text2)
            Spacer()
            DifficultyBadge(difficulty: viewModel.difficulty == .easy ? 1 : (viewModel.difficulty == .medium ? 2 : 3))
        }
        .padding(.horizontal)
    }
    
    private var scenarioBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let concept = viewModel.currentConcept, let tradeoff = concept.tradeoff {
                HStack {
                    CategoryBadge(category: concept.category)
                    Spacer()
                }
                
                Text(tradeoff.scenario)
                    .font(DesignTokens.body(15, weight: .medium))
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
            if let tradeoff = viewModel.currentConcept?.tradeoff {
                ForEach(tradeoff.options, id: \.self) { option in
                    Button {
                        viewModel.submitChoice(option, progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                    } label: {
                        HStack {
                            Text(option)
                                .font(DesignTokens.body(13, weight: .semibold))
                                .foregroundStyle(choiceTextColor(for: option))
                            
                            Spacer()
                            
                            if let selected = viewModel.selectedOption {
                                if option == tradeoff.answer {
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
                        .background(choiceBackgroundColor(for: option))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radius)
                                .stroke(choiceBorderColor(for: option), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.selectedOption != nil)
                }
                
                if viewModel.selectedOption != nil {
                    // Show explanation explanation box
                    Text(tradeoff.why)
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
        .padding(.horizontal)
    }
    
    private var freeTextInputField: some View {
        VStack(spacing: 16) {
            TextField("Explain your architecture choice...", text: $viewModel.textInput)
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
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                        Text(feedback.isCorrect ? "Pass" : "Retry")
                            .font(DesignTokens.display(14))
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                    }
                    
                    Text(feedback.feedback)
                        .font(DesignTokens.body(13))
                        .foregroundStyle(DesignTokens.text2)
                    
                    if let tradeoff = viewModel.currentConcept?.tradeoff {
                        Divider().overlay(DesignTokens.border)
                        Text("Model Answer: \(tradeoff.answer)")
                            .font(DesignTokens.mono(11))
                            .foregroundStyle(DesignTokens.accent2)
                        Text(tradeoff.why)
                            .font(DesignTokens.body(12))
                            .foregroundStyle(DesignTokens.text2)
                    }
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
                    Text("Submit Explanation")
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
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.text
        }
        if choice == viewModel.currentConcept?.tradeoff?.answer {
            return .white
        } else if selected == choice {
            return .white
        }
        return DesignTokens.text2
    }
    
    private func choiceBackgroundColor(for choice: String) -> Color {
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.surface
        }
        if choice == viewModel.currentConcept?.tradeoff?.answer {
            return DesignTokens.accent2.opacity(0.2)
        } else if selected == choice {
            return DesignTokens.accent3.opacity(0.2)
        }
        return DesignTokens.surface.opacity(0.5)
    }
    
    private func choiceBorderColor(for choice: String) -> Color {
        guard let selected = viewModel.selectedOption else {
            return DesignTokens.border
        }
        if choice == viewModel.currentConcept?.tradeoff?.answer {
            return DesignTokens.accent2
        } else if selected == choice {
            return DesignTokens.accent3
        }
        return DesignTokens.border.opacity(0.3)
    }
}

#Preview {
    ScenarioView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
