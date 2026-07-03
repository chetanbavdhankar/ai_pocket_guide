// RapidFireViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

struct MCQOption: Identifiable, Sendable, Hashable {
    let id = UUID()
    let oneLiner: String
    let isCorrect: Bool
}

@Observable
final class RapidFireViewModel {
    var sessionConcepts: [Concept] = []
    var currentIndex: Int = 0
    var selectedOptionID: UUID? = nil
    var options: [MCQOption] = []
    
    // Timer state
    var timeRemaining: TimeInterval = 0
    var timerActive: Bool = false
    
    // Streaks / Multipliers
    var currentStreak: Int = 0
    var streakMultiplier: Int = 1
    
    // End states
    var completed: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    var correctCount: Int = 0
    
    let difficulty: GameDifficulty = .medium
    private let contentStore = ContentStore.shared
    private let sessionBuilder = SessionBuilder()
    private let scheduler: any Scheduler = SM2Scheduler()
    
    var currentConcept: Concept? {
        guard currentIndex >= 0 && currentIndex < sessionConcepts.count else { return nil }
        return sessionConcepts[currentIndex]
    }
    
    var progress: Double {
        guard !sessionConcepts.isEmpty else { return 0 }
        return Double(currentIndex) / Double(sessionConcepts.count)
    }
    
    func startSession(progressRecords: [ConceptProgress], difficulty: GameDifficulty) {
        sessionConcepts = sessionBuilder.buildSession(
            mode: .rapidFire,
            difficulty: difficulty,
            progressRecords: progressRecords,
            count: 10
        )
        currentIndex = 0
        currentStreak = 0
        streakMultiplier = 1
        completed = false
        reviewedItems = []
        xpEarned = 0
        correctCount = 0
        
        setupQuestion()
    }
    
    func setupQuestion() {
        guard let concept = currentConcept else { return }
        selectedOptionID = nil
        
        // Setup timer
        let config = GameMode.rapidFire.config(for: difficulty)
        if let timeLimit = config.timePerQuestion {
            timeRemaining = timeLimit
            timerActive = true
        } else {
            timeRemaining = 0
            timerActive = false
        }
        
        // Generate distractors based on difficulty-specific rules
        let distractors = contentStore.getDistractors(for: concept, source: config.distractorSource, count: 3)
        var allOptions = distractors.map { MCQOption(oneLiner: $0, isCorrect: false) }
        allOptions.append(MCQOption(oneLiner: concept.oneLiner, isCorrect: true))
        options = allOptions.shuffled()
    }
    
    @MainActor
    func selectOption(_ option: MCQOption, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard selectedOptionID == nil else { return }
        selectedOptionID = option.id
        timerActive = false
        
        guard let concept = currentConcept else { return }
        
        // Evaluate correctness
        let wasCorrect = option.isCorrect
        
        if wasCorrect {
            currentStreak += 1
            correctCount += 1
            // Streak multiplier: ×2 at 3, ×3 at 5, ×5 at 10
            if currentStreak >= 10 {
                streakMultiplier = 5
                HapticsManager.shared.streak()
            } else if currentStreak >= 5 {
                streakMultiplier = 3
                HapticsManager.shared.streak()
            } else if currentStreak >= 3 {
                streakMultiplier = 2
                HapticsManager.shared.streak()
            } else {
                streakMultiplier = 1
            }
            
            // Compute and add XP
            let baseXP = 10
            let diffMult = concept.difficulty
            let earned = baseXP * diffMult * streakMultiplier
            xpEarned += earned
            profile?.addXP(earned)
            
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
        } else {
            currentStreak = 0
            streakMultiplier = 1
            
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
        }
        
        // Update spaced repetition schedule
        updateScheduler(conceptID: concept.id, correct: wasCorrect, progressRecords: progressRecords, modelContext: modelContext)
        
        // Add to review details
        reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: wasCorrect))
        
        // Auto advance after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    func handleTimeout(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard selectedOptionID == nil else { return }
        timerActive = false
        currentStreak = 0
        streakMultiplier = 1
        
        HapticsManager.shared.incorrect()
        SFXManager.shared.incorrect()
        
        if let concept = currentConcept {
            updateScheduler(conceptID: concept.id, correct: false, progressRecords: progressRecords, modelContext: modelContext)
            reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: false))
        }
        
        // Reveal correct answer (setting selectedOptionID to some non-matching value so it highlights correct option)
        selectedOptionID = UUID()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.advanceQuestion(profile: profile)
        }
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
