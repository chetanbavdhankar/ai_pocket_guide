// ScenarioViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

@Observable
final class ScenarioViewModel {
    var sessionConcepts: [Concept] = []
    var currentIndex: Int = 0
    
    // MCQ Option
    var selectedOption: String? = nil
    
    // Free Text Option
    var textInput: String = ""
    var textFeedback: GradeResult? = nil
    
    // End states
    var completed: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    var correctCount: Int = 0
    
    var difficulty: GameDifficulty = .medium
    private let contentStore = ContentStore.shared
    private let sessionBuilder = SessionBuilder()
    private let scheduler: any Scheduler = SM2Scheduler()
    private let grader: any Grader = DeterministicGrader()
    
    var currentConcept: Concept? {
        guard currentIndex >= 0 && currentIndex < sessionConcepts.count else { return nil }
        return sessionConcepts[currentIndex]
    }
    
    var progress: Double {
        guard !sessionConcepts.isEmpty else { return 0 }
        return Double(currentIndex) / Double(sessionConcepts.count)
    }
    
    func startSession(progressRecords: [ConceptProgress], difficulty: GameDifficulty) {
        self.difficulty = difficulty
        sessionConcepts = sessionBuilder.buildSession(
            mode: .scenario,
            difficulty: difficulty,
            progressRecords: progressRecords,
            count: 6 // Scenarios take longer, so we play 6 instead of 10
        )
        currentIndex = 0
        completed = false
        reviewedItems = []
        xpEarned = 0
        correctCount = 0
        
        setupQuestion()
    }
    
    func setupQuestion() {
        selectedOption = nil
        textInput = ""
        textFeedback = nil
    }
    
    @MainActor
    func submitChoice(_ choice: String, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let concept = currentConcept, let tradeoff = concept.tradeoff else { return }
        guard selectedOption == nil else { return }
        selectedOption = choice
        
        let wasCorrect = choice == tradeoff.answer
        evaluateAnswer(correct: wasCorrect, concept: concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    func submitFreeText(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let concept = currentConcept, let tradeoff = concept.tradeoff else { return }
        
        let gradeResult = grader.grade(answer: textInput, modelAnswer: tradeoff.answer, concept: concept)
        textFeedback = gradeResult
        
        evaluateAnswer(correct: gradeResult.isCorrect, concept: concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    private func evaluateAnswer(correct: Bool, concept: Concept, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        if correct {
            correctCount += 1
            let baseXP = difficulty == .hard ? 20 : 15
            let earned = baseXP * concept.difficulty
            xpEarned += earned
            profile?.addXP(earned)
            
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
        } else {
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
        }
        
        updateScheduler(conceptID: concept.id, correct: correct, progressRecords: progressRecords, modelContext: modelContext)
        reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: correct))
    }
    
    @MainActor
    private func updateScheduler(conceptID: String, correct: Bool, progressRecords: [ConceptProgress], modelContext: ModelContext) {
        let progress: ConceptProgress
        if let existing = progressRecords.first(where: { $0.conceptID == conceptID }) {
            progress = existing
        } else {
            progress = ConceptProgress(conceptID: conceptID)
            modelContext.insert(progress)
        }
        
        progress.recordResult(correct)
        
        let rating = ReviewRating.from(correct: correct)
        let sched = scheduler.schedule(
            rating: rating,
            currentInterval: progress.interval,
            currentEaseFactor: progress.easeFactor,
            reps: progress.reps,
            lapses: progress.lapses
        )
        
        progress.dueDate = sched.nextDueDate
        progress.interval = sched.newInterval
        progress.easeFactor = sched.newEaseFactor
    }
    
    @MainActor
    private func advanceQuestion(profile: UserProfile?) {
        if currentIndex + 1 < sessionConcepts.count {
            currentIndex += 1
            setupQuestion()
        } else {
            if let profile {
                profile.totalSessionsPlayed += 1
                profile.totalCorrectAnswers += correctCount
                profile.totalQuestionsAnswered += sessionConcepts.count
                profile.updateStreak()
            }
            completed = true
        }
    }
}
