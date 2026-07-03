// ConnectionsViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

struct ConnectionChip: Identifiable, Sendable, Hashable {
    let id = UUID()
    let concept: Concept
    var isSelected: Bool = false
    var isMatched: Bool = false
}

struct ConnectionGroup: Identifiable, Sendable, Hashable {
    let id = UUID()
    let category: Category
    let concepts: [Concept]
    let color: Color
}

@Observable
final class ConnectionsViewModel {
    var chips: [ConnectionChip] = []
    var matchedGroups: [ConnectionGroup] = []
    
    var selectedIDs: Set<UUID> = [] // set of chip IDs
    var mistakesRemaining: Int = 4
    
    // End states
    var completed: Bool = false
    var won: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    
    var difficulty: GameDifficulty = .medium
    private let contentStore = ContentStore.shared
    private let scheduler: any Scheduler = SM2Scheduler()
    
    func startSession(progressRecords: [ConceptProgress], difficulty: GameDifficulty) {
        self.difficulty = difficulty
        mistakesRemaining = 4
        completed = false
        won = false
        matchedGroups = []
        selectedIDs = []
        reviewedItems = []
        xpEarned = 0
        
        setupBoard()
    }
    
    func setupBoard() {
        // Select 4 categories that have at least 4 concepts
        var validCategories: [Category] = []
        for category in Category.allCases {
            if contentStore.concepts(for: category).count >= 4 {
                validCategories.append(category)
            }
        }
        
        guard validCategories.count >= 4 else {
            // Fallback: relax constraints or duplicate if term bank is too small,
            // but our seed has 4+ for tokenization (4), embeddings (4), attention (5), inference (6), efficiency (6).
            // So we definitely have at least 4 valid categories.
            chips = []
            return
        }
        
        let selectedCategories = Array(validCategories.shuffled().prefix(4))
        var boardChips: [ConnectionChip] = []
        
        for category in selectedCategories {
            let concepts = Array(contentStore.concepts(for: category).shuffled().prefix(4))
            for concept in concepts {
                boardChips.append(ConnectionChip(concept: concept))
            }
        }
        
        chips = boardChips.shuffled()
    }
    
    @MainActor
    func toggleSelection(of chipID: UUID) {
        guard let index = chips.firstIndex(where: { $0.id == chipID }) else { return }
        guard !chips[index].isMatched else { return }
        
        if chips[index].isSelected {
            chips[index].isSelected = false
            selectedIDs.remove(chipID)
            HapticsManager.shared.tap()
        } else {
            // Max 4 selected
            guard selectedIDs.count < 4 else { return }
            chips[index].isSelected = true
            selectedIDs.insert(chipID)
            HapticsManager.shared.tap()
        }
    }
    
    @MainActor
    func submitGuess(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard selectedIDs.count == 4 else { return }
        
        let selectedChips = chips.filter { selectedIDs.contains($0.id) }
        let selectedConcepts = selectedChips.map { $0.concept }
        
        // Check if all selected have the same category
        let categories = Set(selectedConcepts.map { $0.category })
        
        if categories.count == 1, let matchedCategory = categories.first {
            // Correct match!
            for id in selectedIDs {
                if let index = chips.firstIndex(where: { $0.id == id }) {
                    chips[index].isMatched = true
                    chips[index].isSelected = false
                }
            }
            
            let group = ConnectionGroup(
                category: matchedCategory,
                concepts: selectedConcepts,
                color: matchedCategory.accentColor
            )
            matchedGroups.append(group)
            
            // Adjust XP
            let earned = 20
            xpEarned += earned
            profile?.addXP(earned)
            
            // Log spaced repetition updates as correct
            for concept in selectedConcepts {
                updateScheduler(conceptID: concept.id, correct: true, progressRecords: progressRecords, modelContext: modelContext)
                reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: true))
            }
            
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
            selectedIDs.removeAll()
            
            // Check win
            if matchedGroups.count == 4 {
                won = true
                endGame(profile: profile)
            }
        } else {
            // Incorrect guess
            mistakesRemaining -= 1
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
            
            // Log spaced repetition updates as incorrect
            for concept in selectedConcepts {
                if !reviewedItems.contains(where: { $0.concept.id == concept.id }) {
                    updateScheduler(conceptID: concept.id, correct: false, progressRecords: progressRecords, modelContext: modelContext)
                    reviewedItems.append(SessionDetailItem(concept: concept, isCorrect: false))
                }
            }
            
            // Shake/Desort selection
            for id in selectedIDs {
                if let index = chips.firstIndex(where: { $0.id == id }) {
                    chips[index].isSelected = false
                }
            }
            selectedIDs.removeAll()
            
            // Check lose
            if mistakesRemaining == 0 {
                won = false
                // Match remaining automatically
                revealRemainingGroups()
                endGame(profile: profile)
            }
        }
    }
    
    @MainActor
    private func revealRemainingGroups() {
        let unmatchedChips = chips.filter { !$0.isMatched }
        let grouped = Dictionary(grouping: unmatchedChips, by: { $0.concept.category })
        
        for (category, cList) in grouped {
            let group = ConnectionGroup(
                category: category,
                concepts: cList.map { $0.concept },
                color: category.accentColor
            )
            matchedGroups.append(group)
        }
        
        for index in chips.indices {
            chips[index].isMatched = true
        }
    }
    
    @MainActor
    private func endGame(profile: UserProfile?) {
        if let profile {
            profile.totalSessionsPlayed += 1
            profile.totalCorrectAnswers += matchedGroups.count
            profile.totalQuestionsAnswered += 4
            profile.updateStreak()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completed = true
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
