// DepthLadderViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

struct LadderRung: Identifiable, Sendable, Hashable {
    let id = UUID()
    let level: Int // 1 to 4
    let question: String
    let prompt: String
    let modelAnswer: String
}

@Observable
final class DepthLadderViewModel {
    var concept: Concept? = nil
    var rungs: [LadderRung] = []
    var currentRungIndex: Int = 0
    
    // Inputs & Feedback
    var textInput: String = ""
    var feedBacks: [GradeResult] = []
    var currentFeedback: GradeResult? = nil
    
    // End states
    var completed: Bool = false
    var totalScore: Double = 0.0
    var xpEarned: Int = 0
    
    private let contentStore = ContentStore.shared
    private let sessionBuilder = SessionBuilder()
    private let scheduler: any Scheduler = SM2Scheduler()
    private let grader: any Grader = DeterministicGrader()
    
    var currentRung: LadderRung? {
        guard currentRungIndex >= 0 && currentRungIndex < rungs.count else { return nil }
        return rungs[currentRungIndex]
    }
    
    var progress: Double {
        guard !rungs.isEmpty else { return 0 }
        return Double(currentRungIndex) / Double(rungs.count)
    }
    
    func startSession(progressRecords: [ConceptProgress]) {
        // Choose one concept for the ladder session
        let session = sessionBuilder.buildSession(
            mode: .depthLadder,
            difficulty: .hard,
            progressRecords: progressRecords,
            count: 1
        )
        
        guard let selectedConcept = session.first else { return }
        self.concept = selectedConcept
        
        currentRungIndex = 0
        textInput = ""
        feedBacks = []
        currentFeedback = nil
        completed = false
        totalScore = 0.0
        xpEarned = 0
        
        setupLadder(for: selectedConcept)
    }
    
    private func setupLadder(for concept: Concept) {
        let relatedTerm = concept.related.first ?? "similar techniques"
        
        rungs = [
            LadderRung(
                level: 1,
                question: "Define the term",
                prompt: "What is the primary architectural purpose or definition of \(concept.term)?",
                modelAnswer: concept.oneLiner
            ),
            LadderRung(
                level: 2,
                question: "Compare it",
                prompt: "How does \(concept.term) compare or contrast with \(relatedTerm.replacingOccurrences(of: "-", with: " "))?",
                modelAnswer: concept.explanation
            ),
            LadderRung(
                level: 3,
                question: "State a tradeoff",
                prompt: "What is a primary engineering or computational tradeoff associated with \(concept.term)?",
                modelAnswer: concept.tradeoff?.why ?? "It exchanges computational complexity/memory foot-print (like KV cache scale or parameter counts) to optimize model perplexity, generation speed, or GPU hardware alignment."
            ),
            LadderRung(
                level: 4,
                question: "Select application scenario",
                prompt: "Describe a specific design scenario or architecture choice where you would select \(concept.term) over alternatives.",
                modelAnswer: concept.modelAnswer
            )
        ]
    }
    
    @MainActor
    func submitRung(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let rung = currentRung, let concept = concept else { return }
        
        let result = grader.grade(answer: textInput, modelAnswer: rung.modelAnswer, concept: concept)
        currentFeedback = result
        feedBacks.append(result)
        totalScore += result.score
        
        // Give partial XP based on accuracy
        let earned = Int(10.0 * result.score)
        xpEarned += earned
        profile?.addXP(earned)
        
        if result.isCorrect {
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
        } else {
            HapticsManager.shared.incorrect()
            SFXManager.shared.incorrect()
        }
    }
    
    @MainActor
    func advanceRung(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let concept = concept else { return }
        currentFeedback = nil
        textInput = ""
        
        if currentRungIndex + 1 < rungs.count {
            currentRungIndex += 1
        } else {
            // End session
            let averageScore = totalScore / Double(rungs.count)
            let passed = averageScore >= 0.5
            
            // Log spaced repetition result
            updateScheduler(conceptID: concept.id, correct: passed, progressRecords: progressRecords, modelContext: modelContext)
            
            if let profile {
                profile.totalSessionsPlayed += 1
                profile.totalCorrectAnswers += passed ? 1 : 0
                profile.totalQuestionsAnswered += 1
                profile.updateStreak()
            }
            
            completed = true
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
