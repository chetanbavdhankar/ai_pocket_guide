// FlashRecallView.swift — AI Pocket Arena
// Spaced repetition flashcards with interactive 3D rotation flip and self-rating.

import SwiftUI
import SwiftData

struct FlashRecallView: View {
    @Query private var progressRecords: [ConceptProgress]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = FlashRecallViewModel()
    @State private var dragOffset = CGSize.zero
    
    private var profile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            
            if viewModel.sessionConcepts.isEmpty {
                emptySessionView
            } else if viewModel.completed {
                ResultRecapView(
                    mode: .flashRecall,
                    difficulty: .medium,
                    xpEarned: viewModel.xpEarned,
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.sessionConcepts.count,
                    reviewedItems: viewModel.reviewedItems
                )
            } else {
                VStack(spacing: 20) {
                    // Progress Header
                    progressHeader
                    
                    Spacer()
                    
                    // Flash Card
                    ZStack {
                        if let concept = viewModel.currentConcept {
                            FlashCardContent(
                                concept: concept,
                                isFlipped: viewModel.isFlipped,
                                showExplanationDetail: viewModel.showExplanationDetail
                            )
                            .rotation3DEffect(
                                .degrees(viewModel.isFlipped ? 180 : 0),
                                axis: (x: 0.0, y: 1.0, z: 0.0),
                                perspective: 0.5
                            )
                            .offset(dragOffset)
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                            viewModel.isFlipped.toggle()
                                            HapticsManager.shared.tap()
                                        }
                                    }
                            )
                        }
                    }
                    .frame(height: 400)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Rating controls
                    if viewModel.isFlipped {
                        ratingButtons
                    } else {
                        tapToRevealPrompt
                    }
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
                Text("Flash Recall")
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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.accent2)
            
            Text("Fully Caught Up!")
                .font(DesignTokens.display(20))
                .foregroundStyle(DesignTokens.text)
            
            Text("No concepts are due for review. Play another mode to learn more!")
                .font(DesignTokens.body(14))
                .foregroundStyle(DesignTokens.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Back") { dismiss() }
                .buttonStyle(AccentButtonStyle())
        }
    }
    
    private var progressHeader: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.currentIndex + 1) / \(viewModel.sessionConcepts.count)")
                .font(DesignTokens.mono(12))
                .foregroundStyle(DesignTokens.text2)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.surface3)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.accent)
                        .frame(width: geo.size.width * viewModel.progress)
                }
            }
            .frame(height: 6)
            
            HStack(spacing: 4) {
                Text("🔥")
                Text("\(profile?.currentStreak ?? 0)")
                    .font(DesignTokens.mono(12))
                    .foregroundStyle(DesignTokens.text2)
            }
        }
        .padding(.horizontal)
    }
    
    private var tapToRevealPrompt: some View {
        Text("Tap Card to Flip")
            .font(DesignTokens.mono(12))
            .foregroundStyle(DesignTokens.text2)
            .padding(.bottom, 20)
            .opacity(0.8)
    }
    
    private var ratingButtons: some View {
        VStack(spacing: 12) {
            // Detailed toggle for interview Q
            Button {
                withAnimation {
                    viewModel.showExplanationDetail.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.showExplanationDetail ? "minus.circle" : "plus.circle")
                    Text(viewModel.showExplanationDetail ? "Hide Details" : "Show Interview & Tradeoffs")
                }
                .font(DesignTokens.body(13, weight: .semibold))
                .foregroundStyle(DesignTokens.accent4)
            }
            .padding(.bottom, 4)
            
            HStack(spacing: 8) {
                // Again
                RatingButton(label: "Again", desc: "<1m", color: DesignTokens.accent3) {
                    viewModel.submitRating(.again, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
                }
                // Hard
                RatingButton(label: "Hard", desc: "1.2x", color: DesignTokens.accent4) {
                    viewModel.submitRating(.hard, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
                }
                // Good
                RatingButton(label: "Good", desc: "EFx", color: DesignTokens.accent2) {
                    viewModel.submitRating(.good, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
                }
                // Easy
                RatingButton(label: "Easy", desc: "1.3x", color: DesignTokens.accent) {
                    viewModel.submitRating(.easy, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Rating Button Helper
struct RatingButton: View {
    let label: String
    let desc: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(DesignTokens.body(14, weight: .bold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(DesignTokens.mono(10))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
        }
    }
}

// MARK: - Flash Card Content View
struct FlashCardContent: View {
    let concept: Concept
    let isFlipped: Bool
    let showExplanationDetail: Bool
    
    var body: some View {
        ZStack {
            if !isFlipped {
                // Front Side
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignTokens.accent)
                    
                    Text(concept.term)
                        .font(DesignTokens.display(24))
                        .foregroundStyle(DesignTokens.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack {
                        CategoryBadge(category: concept.category)
                        DifficultyBadge(difficulty: concept.difficulty)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                        .stroke(DesignTokens.border, lineWidth: 1)
                )
            } else {
                // Back Side (flipped 180 degrees to read properly)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(concept.term)
                                .font(DesignTokens.display(18))
                                .foregroundStyle(DesignTokens.accent)
                            Spacer()
                            CategoryBadge(category: concept.category)
                        }
                        
                        Text(concept.oneLiner)
                            .font(DesignTokens.body(14, weight: .semibold))
                            .foregroundStyle(DesignTokens.accent2)
                        
                        Text(concept.explanation)
                            .font(DesignTokens.body(13))
                            .foregroundStyle(DesignTokens.text)
                            .lineSpacing(3)
                        
                        if showExplanationDetail {
                            VStack(alignment: .leading, spacing: 10) {
                                Divider().overlay(DesignTokens.border)
                                
                                Text("Interview Question")
                                    .font(DesignTokens.mono(10))
                                    .foregroundStyle(DesignTokens.accent4)
                                
                                Text(concept.interviewQuestion)
                                    .font(DesignTokens.body(12, weight: .medium))
                                    .foregroundStyle(DesignTokens.text)
                                
                                Text("Model Answer")
                                    .font(DesignTokens.mono(10))
                                    .foregroundStyle(DesignTokens.accent2)
                                
                                Text(concept.modelAnswer)
                                    .font(DesignTokens.body(12))
                                    .foregroundStyle(DesignTokens.text2)
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusLg)
                        .stroke(DesignTokens.accent.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
