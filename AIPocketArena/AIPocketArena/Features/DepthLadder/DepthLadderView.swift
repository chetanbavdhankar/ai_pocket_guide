// DepthLadderView.swift — AI Pocket Arena
// Depth Ladder interview simulation mode.

import SwiftUI
import SwiftData

struct DepthLadderView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = DepthLadderViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.concept == nil {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .depthLadder,
                    difficulty: .hard,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.feedBacks.filter { $0.isCorrect }.count,
                    totalCount: 4,
                    reviewedItems: [SessionDetailItem(concept: viewModel.concept!, isCorrect: viewModel.totalScore / 4.0 >= 0.5)]
                )
            } else {
                VStack(spacing: 20) {
                    // Header progress
                    headerView
                    
                    // Ladder Sidebar + Active Rung Content
                    HStack(alignment: .top, spacing: 16) {
                        ladderSidebar
                        
                        VStack(alignment: .leading, spacing: 16) {
                            activeRungPrompt
                            
                            answerInputField
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
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
                Text("Depth Ladder")
                    .font(DesignTokens.display(16))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .onAppear {
            viewModel.startSession(progressRecords: progressRecords)
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
            if let concept = viewModel.concept {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interview Prep")
                        .font(DesignTokens.body(13))
                        .foregroundStyle(DesignTokens.text2)
                    Text(concept.term)
                        .font(DesignTokens.display(16))
                        .foregroundStyle(DesignTokens.text)
                }
            }
            Spacer()
            CategoryBadge(category: viewModel.concept?.category ?? .attention)
        }
        .padding(.horizontal)
    }
    
    private var ladderSidebar: some View {
        VStack(spacing: 12) {
            ForEach((1...4).reversed(), id: \.self) { level in
                let isCompleted = level < viewModel.currentRungIndex + 1
                let isActive = level == viewModel.currentRungIndex + 1
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(isActive ? DesignTokens.accent : (isCompleted ? DesignTokens.accent2 : DesignTokens.surface3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(level)")
                                .font(DesignTokens.mono(10))
                                .fontWeight(.bold)
                                .foregroundStyle(isActive || isCompleted ? .white : DesignTokens.text2)
                        )
                    
                    if level > 1 {
                        Rectangle()
                            .fill(isCompleted ? DesignTokens.accent2 : DesignTokens.surface3)
                            .frame(width: 2, height: 24)
                    }
                }
            }
        }
        .frame(width: 40)
    }
    
    private var activeRungPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let rung = viewModel.currentRung {
                Text(rung.question.uppercased())
                    .font(DesignTokens.mono(11))
                    .foregroundStyle(DesignTokens.accent)
                    .tracking(1)
                
                Text(rung.prompt)
                    .font(DesignTokens.body(15, weight: .medium))
                    .foregroundStyle(DesignTokens.text)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radius)
                .stroke(DesignTokens.border, lineWidth: 1)
        )
    }
    
    private var answerInputField: some View {
        VStack(spacing: 12) {
            TextField("Type your response here...", text: $viewModel.textInput, axis: .vertical)
                .font(DesignTokens.body(14))
                .lineLimit(3...6)
                .padding()
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius)
                        .stroke(isFieldFocused ? DesignTokens.accent : DesignTokens.border, lineWidth: 1)
                )
                .focused($isFieldFocused)
                .disabled(viewModel.currentFeedback != nil)
            
            if let feedback = viewModel.currentFeedback {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                        Text(feedback.isCorrect ? "Rung Completed (\(Int(feedback.score * 100))%)" : "Needs Detail (\(Int(feedback.score * 100))%)")
                            .font(DesignTokens.display(13))
                            .foregroundStyle(feedback.isCorrect ? DesignTokens.accent2 : DesignTokens.accent3)
                    }
                    
                    Text(feedback.feedback)
                        .font(DesignTokens.body(12))
                        .foregroundStyle(DesignTokens.text2)
                    
                    if let rung = viewModel.currentRung {
                        Divider().overlay(DesignTokens.border)
                        Text("Model Suggestion:")
                            .font(DesignTokens.mono(10))
                            .foregroundStyle(DesignTokens.accent2)
                        Text(rung.modelAnswer)
                            .font(DesignTokens.body(12))
                            .foregroundStyle(DesignTokens.text2)
                            .lineSpacing(2)
                    }
                    
                    Button {
                        viewModel.advanceRung(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
                    } label: {
                        Text(viewModel.currentRungIndex == 3 ? "Complete Ladder" : "Ascend to Next Rung")
                            .font(DesignTokens.display(14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    }
                }
                .padding()
                .background(feedback.isCorrect ? DesignTokens.accent2.opacity(0.08) : DesignTokens.accent3.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radius)
                        .stroke(feedback.isCorrect ? DesignTokens.accent2.opacity(0.3) : DesignTokens.accent3.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    isFieldFocused = false
                    viewModel.submitRung(progressRecords: progressRecords, modelContext: modelContext, profile: profiles.first)
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
    }
}

#Preview {
    DepthLadderView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
