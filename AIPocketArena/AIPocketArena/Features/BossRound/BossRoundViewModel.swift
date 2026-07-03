// BossRoundViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

enum BossQuestionType: String, Sendable, Codable {
    case mcq
    case cloze
    case scenario
}

struct BossQuestion: Identifiable, Sendable, Hashable {
    let id = UUID()
    let concept: Concept
    let type: BossQuestionType
    let questionText: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
}

@Observable
final class BossRoundViewModel {
    var questions: [BossQuestion] = []
    var currentIndex: Int = 0
    var selectedOption: String? = nil
    
    // Status
    var livesRemaining: Int = 3
    var timerActive: Bool = false
    var timeRemaining: TimeInterval = 15.0
    
    // End states
    var completed: Bool = false
    var won: Bool = false
    var reviewedItems: [SessionDetailItem] = []
    var xpEarned: Int = 0
    var correctCount: Int = 0
    
    private let contentStore = ContentStore.shared
    private let sessionBuilder = SessionBuilder()
    private let scheduler: any Scheduler = SM2Scheduler()
    
    var currentQuestion: BossQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }
    
    func startSession(progressRecords: [ConceptProgress]) {
        // Boss round selects the user's 10 weakest concepts
        let selectedConcepts = sessionBuilder.buildBossSession(progressRecords: progressRecords, count: 10)
        
        livesRemaining = 3
        completed = false
        won = false
        currentIndex = 0
        correctCount = 0
        xpEarned = 0
        reviewedItems = []
        
        setupBossQuestions(concepts: selectedConcepts)
        setupQuestion()
    }
    
    private func setupBossQuestions(concepts: [Concept]) {
        var bossQs: [BossQuestion] = []
        
        for (index, concept) in concepts.enumerated() {
            // Alternate type dynamically based on index and available fields
            let type: BossQuestionType
            if index % 3 == 0 && concept.tradeoff != nil {
                type = .scenario
            } else if index % 3 == 1 && concept.cloze != nil {
                type = .cloze
            } else {
                type = .mcq
            }
            
            let qText: String
            var opts: [String] = []
            let correct: String
            let expl: String
            
            switch type {
            case .scenario:
                let tradeoff = concept.tradeoff!
                qText = "Scenario: \(tradeoff.scenario)"
                opts = tradeoff.options.shuffled()
                correct = tradeoff.answer
                expl = tradeoff.why
                
            case .cloze:
                let cloze = concept.cloze!
                qText = "Fill in the blank: \(cloze.prompt)"
                
                // Select general distractors for cloze
                var optionsPool = contentStore.concepts(for: concept.category)
                    .compactMap { $0.cloze?.answer }
                    .filter { $0 != cloze.answer }
                if optionsPool.count < 3 {
                    optionsPool.append(contentsOf: ["tokens", "attention", "embeddings", "parameters", "weights"].filter { $0 != cloze.answer })
                }
                var clozeOpts = Array(Set(optionsPool)).shuffled().prefix(3).map { $0 }
                clozeOpts.append(cloze.answer)
                
                opts = clozeOpts.shuffled()
                correct = cloze.answer
                expl = concept.oneLiner
                
            case .mcq:
                qText = "Define \(concept.term):"
                let distractors = contentStore.getDistractors(for: concept, source: .relatedConcepts, count: 3)
                var mcqOpts = distractors
                mcqOpts.append(concept.oneLiner)
                
                opts = mcqOpts.shuffled()
                correct = concept.oneLiner
                expl = concept.explanation
            }
            
            bossQs.append(
                BossQuestion(
                    concept: concept,
                    type: type,
                    questionText: qText,
                    options: opts,
                    correctAnswer: correct,
                    explanation: expl
                )
            )
        }
        
        questions = bossQs
    }
    
    func setupQuestion() {
        guard currentQuestion != nil else { return }
        selectedOption = nil
        timeRemaining = 15.0
        timerActive = true
    }
    
    @MainActor
    func submitChoice(_ option: String, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let question = currentQuestion else { return }
        guard selectedOption == nil else { return }
        selectedOption = option
        timerActive = false
        
        let wasCorrect = option == question.correctAnswer
        evaluateAnswer(correct: wasCorrect, concept: question.concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    func handleTimeout(progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        guard let question = currentQuestion else { return }
        guard selectedOption == nil else { return }
        timerActive = false
        
        // Reveal correct
        selectedOption = question.correctAnswer
        evaluateAnswer(correct: false, concept: question.concept, progressRecords: progressRecords, modelContext: modelContext, profile: profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.advanceQuestion(profile: profile)
        }
    }
    
    @MainActor
    private func evaluateAnswer(correct: Bool, concept: Concept, progressRecords: [ConceptProgress], modelContext: ModelContext, profile: UserProfile?) {
        if correct {
            correctCount += 1
            // Boss round yields double XP!
            let earned = 30 * concept.difficulty
            xpEarned += earned
            profile?.addXP(earned)
            
            HapticsManager.shared.correct()
            SFXManager.shared.correct()
        } else {
            livesRemaining -= 1
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
        if livesRemaining <= 0 {
            won = false
            completed = true
            updateProfileEndState(profile: profile)
        } else if currentIndex + 1 < questions.count {
            currentIndex += 1
            setupQuestion()
        } else {
            won = true
            completed = true
            // Grant "Boss Slayer" badge if won!
            if let profile, !profile.unlockedBadges.contains(Badge.bossSlayer.rawValue) {
                profile.unlockedBadges.append(Badge.bossSlayer.rawValue)
            }
            updateProfileEndState(profile: profile)
        }
    }
    
    @MainActor
    private func updateProfileEndState(profile: UserProfile?) {
        if let profile {
            profile.totalSessionsPlayed += 1
            profile.totalCorrectAnswers += correctCount
            profile.totalQuestionsAnswered += reviewedItems.count
            profile.updateStreak()
        }
    }
}
