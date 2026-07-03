// ClozeViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

@Observable
final class ClozeViewModel {
    var sessionConcepts: [Concept] = []
    var currentIndex: Int = 0
    
    // Multiple Choice options (for Easy/Medium)
    var choices: [String] = []
    var selectedChoice: String? = nil
    
    // Free text input (for Hard)
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
            mode: .cloze,
            difficulty: difficulty,
            progressRecords: progressRecords,
            count: 10
        )
        currentIndex = 0
        completed = false
        reviewedItems = []
        xpEarned = 0
        correctCount = 0
        
        setupQuestion()
    }
    
    func setupQuestion() {
        guard let concept = currentConcept, let cloze = concept.cloze else { return }
        
        selectedChoice = nil
        textInput = ""
        textFeedback = nil
        
        let config = GameMode.cloze.config(for: difficulty)
        
        if config.inputMethod == .multipleChoice {
            // Generate multiple choices
            // Let's generate choices from other concept cloze answers in the same category, or fallback to general terms.
            var optionsPool = contentStore.concepts(for: concept.category)
                .compactMap { $0.cloze?.answer }
                .filter { $0 != cloze.answer }
            
            if optionsPool.count < 3 {
                optionsPool.append(contentsOf: ["tokens", "attention", "embeddings", "parameters", "weights"].filter { $0 != cloze.answer })
            }
            
            var allChoices = Array(Set(optionsPool)).shuffled().prefix(3).map { $0 }
            allChoices.append(cloze.answer)
            choices = allChoices.shuffled()
        }
    }
    
    @MainActor
    func submitChoice(_ choice: String, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard selectedChoice == nil else { return }
        selectedChoice = choice
        
        guard let concept = currentConcept, let cloze = concept.cloze else { return }
        let wasCorrect = choice == cloze.answer
        
        evaluateAnswer(correct: wasCorrect, concept: concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    func submitFreeText(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let concept = currentConcept, let cloze = concept.cloze else { return }
        
        let gradeResult = grader.grade(answer: textInput, modelAnswer: cloze.answer, concept: concept)
        textFeedback = gradeResult
        
        evaluateAnswer(correct: gradeResult.isCorrect, concept: concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    private func evaluateAnswer(correct: Bool, concept: Concept, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        if correct {
            correctCount += 1
            let baseXP = difficulty == .hard ? 15 : 10
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
