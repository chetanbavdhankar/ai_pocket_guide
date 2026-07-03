// MatchPairsViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

struct MatchItem: Identifiable, Sendable, Hashable {
    let id = UUID()
    let conceptID: String
    let text: String
    let isTerm: Bool // true = term, false = one-liner/definition
}

@Observable
final class MatchPairsViewModel {
    var sessionConcepts: [Concept] = []
    var items: [MatchItem] = []
    
    var selectedItem1: MatchItem? = nil
    var selectedItem2: MatchItem? = nil
    var matchedIDs: Set<String> = [] // set of conceptIDs
    
    var mistakes: Int = 0
    var completed: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    
    var difficulty: GameDifficulty = .medium
    private let contentStore = ContentStore.shared
    private let sessionBuilder = SessionBuilder()
    private let scheduler: any Scheduler = SM2Scheduler()
    
    func startSession(progressRecords: [ConceptProgress], difficulty: GameDifficulty) {
        self.difficulty = difficulty
        let config = GameMode.matchPairs.config(for: difficulty)
        let pairsCount = config.gridSize ?? 6
        
        sessionConcepts = sessionBuilder.buildSession(
            mode: .matchPairs,
            difficulty: difficulty,
            progressRecords: progressRecords,
            count: pairsCount
        )
        
        mistakes = 0
        completed = false
        reviewedItems = []
        xpEarned = 0
        matchedIDs = []
        selectedItem1 = nil
        selectedItem2 = nil
        
        setupGrid()
    }
    
    func setupGrid() {
        var gridItems: [MatchItem] = []
        for concept in sessionConcepts {
            gridItems.append(MatchItem(conceptID: concept.id, text: concept.term, isTerm: true))
            gridItems.append(MatchItem(conceptID: concept.id, text: concept.oneLiner, isTerm: false))
        }
        items = gridItems.shuffled()
    }
    
    @MainActor
    func selectItem(_ item: MatchItem, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        // Prevent tapping already matched items
        guard !matchedIDs.contains(item.conceptID) else { return }
        
        if selectedItem1 == nil {
            selectedItem1 = item
            HapticsManager.shared.tap()
        } else if selectedItem2 == nil {
            // Prevent tapping same item twice
            guard item.id != selectedItem1?.id else { return }
            
            selectedItem2 = item
            HapticsManager.shared.tap()
            
            // Check match
            evaluateMatch(progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        }
    }
    
    @MainActor
    private func evaluateMatch(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let s1 = selectedItem1, let s2 = selectedItem2 else { return }
        
        let isMatch = s1.conceptID == s2.conceptID && s1.isTerm != s2.isTerm
        
        if isMatch {
            matchedIDs.insert(s1.conceptID)
            
            // Give XP
            if let concept = sessionConcepts.first(where: { $0.id == s1.conceptID }) {
                let baseXP = 8
                let earned = baseXP * concept.difficulty
                xpEarned += earned
                profile?.addXP(earned)
                
                // Spaced repetition write back
                updateScheduler(conceptID: concept.id, correct: true, progressRecords: progressRecords, modelContext: modelContext)
                reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: true))
            }
            
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
            
            selectedItem1 = nil
            selectedItem2 = nil
            
            // Check complete
            if matchedIDs.count == sessionConcepts.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let profile {
                        profile.totalSessionsPlayed += 1
                        profile.totalCorrectAnswers += self.sessionConcepts.count
                        profile.totalQuestionsAnswered += self.sessionConcepts.count
                        profile.updateStreak()
                    }
                    self.completed = true
                }
            }
        } else {
            mistakes += 1
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
            
            // Mark both as incorrect for spaced repetition scheduling if not already recorded
            if let concept1 = sessionConcepts.first(where: { $0.id == s1.conceptID }),
               !reviewedItems.contains(where: { $0.concept.id == concept1.id }) {
                updateScheduler(conceptID: concept1.id, correct: false, progressRecords: progressRecords, modelContext: modelContext)
                reviewedItems.append(SessionDetailItem(concept: concept1, isCorrect: false))
            }
            if let concept2 = sessionConcepts.first(where: { $0.id == s2.conceptID }),
               !reviewedItems.contains(where: { $0.concept.id == concept2.id }) {
                updateScheduler(conceptID: concept2.id, correct: false, progressRecords: progressRecords, modelContext: modelContext)
                reviewedItems.append(SessionDetailItem(concept: concept2, isCorrect: false))
            }
            
            // Clear selections after short delay so user sees they were wrong
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.selectedItem1 = nil
                self.selectedItem2 = nil
            }
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
}
