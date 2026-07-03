// ConceptProgress.swift — AI Pocket Arena
// SwiftData model for per-concept user progress (keyed by stable concept.id)

import Foundation
import SwiftData

@Model
final class ConceptProgress {
    @Attribute(.unique) var conceptID: String

    // SM-2 / FSRS state
    var easeFactor: Double       // SM-2 ease factor (default 2.5)
    var interval: Double         // Days until next review
    var lastReviewed: Date?
    var dueDate: Date
    var lapses: Int              // Times the user got it wrong after learning
    var reps: Int                // Total successful repetitions
    var consecutiveCorrect: Int  // Current streak of correct answers

    // Accuracy tracking (ring buffer of last 10)
    var recentResults: [Bool]    // Last 10 answer results

    // Computed mastery (0-1)
    var mastery: Double {
        guard reps > 0 else { return 0 }
        let accuracyScore: Double
        if recentResults.isEmpty {
            accuracyScore = 0
        } else {
            accuracyScore = Double(recentResults.filter { $0 }.count) / Double(recentResults.count)
        }
        let stabilityScore = min(1.0, interval / 30.0) // Normalize to 30 days max
        let easeScore = min(1.0, (easeFactor - 1.3) / (2.5 - 1.3)) // Normalize EF range
        return (accuracyScore * 0.5 + stabilityScore * 0.3 + easeScore * 0.2)
    }

    var isDue: Bool {
        Date() >= dueDate
    }

    init(conceptID: String) {
        self.conceptID = conceptID
        self.easeFactor = 2.5
        self.interval = 0
        self.lastReviewed = nil
        self.dueDate = Date.distantPast // Due immediately
        self.lapses = 0
        self.reps = 0
        self.consecutiveCorrect = 0
        self.recentResults = []
    }

    func recordResult(_ correct: Bool) {
        recentResults.append(correct)
        if recentResults.count > 10 {
            recentResults.removeFirst()
        }
        if correct {
            consecutiveCorrect += 1
        } else {
            consecutiveCorrect = 0
            lapses += 1
        }
        reps += 1
        lastReviewed = Date()
    }
}
