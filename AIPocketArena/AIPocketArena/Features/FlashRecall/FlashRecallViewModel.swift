// FlashRecallViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

@Observable
final class FlashRecallViewModel {
    var sessionConcepts: [Concept] = []
    var currentIndex: Int = 0
    var isFlipped: Bool = false
    var showExplanationDetail: Bool = false
    
    var completed: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    var correctCount: Int = 0
    
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
    
    func startSession(progressRecords: [ConceptProgress]) {
        // Flash recall shows due concepts or random ones if none due
        sessionConcepts = sessionBuilder.buildSession(
            mode: .flashRecall,
            difficulty: .medium,
            progressRecords: progressRecords,
            count: 10
        )
        currentIndex = 0
        isFlipped = false
        showExplanationDetail = false
        completed = false
        reviewedItems = []
        xpEarned = 0
        correctCount = 0
    }
    
    @MainActor
    func submitRating(_ rating: ReviewRating, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let concept = currentConcept else { return }
        
        // Find or create progress record
        let progress: ConceptProgress
        if let existing = progressRecords.first(where: { $0.conceptID == concept.id }) {
            progress = existing
        } else {
            progress = ConceptProgress(conceptID: concept.id)
            modelContext.insert(progress)
        }
        
        let wasCorrect = rating != .again
        progress.recordResult(wasCorrect)
        
        // Schedule next review
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
        
        // Record details for recap
        reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: wasCorrect))
        if wasCorrect {
            correctCount += 1
            // Earn XP
            let baseXP = 15
            let mult = concept.difficulty
            let earned = baseXP * mult
            xpEarned += earned
            profile?.addXP(earned)
        }
        
        // Play haptics/audio
        if wasCorrect {
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
        } else {
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
        }
        
        // Move to next card or complete
        if currentIndex + 1 < sessionConcepts.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isFlipped = false
                showExplanationDetail = false
                currentIndex += 1
            }
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
