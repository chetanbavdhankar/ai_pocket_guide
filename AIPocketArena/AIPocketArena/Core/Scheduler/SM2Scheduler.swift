// SM2Scheduler.swift — AI Pocket Arena
// SM-2 algorithm implementation (Anki-style spaced repetition)

import Foundation

struct SM2Scheduler: Scheduler, Sendable {
    // SM-2 constants
    private let minEaseFactor: Double = 1.3
    private let defaultEaseFactor: Double = 2.5

    // Learning steps (in minutes) before graduating to review
    private let learningSteps: [Double] = [1, 10] // 1 min, 10 min
    private let graduatingInterval: Double = 1.0    // 1 day
    private let easyInterval: Double = 4.0          // 4 days

    func schedule(
        rating: ReviewRating,
        currentInterval: Double,
        currentEaseFactor: Double,
        reps: Int,
        lapses: Int
    ) -> ScheduleResult {
        var newEF = currentEaseFactor
        var newInterval: Double
        var nextDue: Date

        switch rating {
        case .again:
            // Reset: back to learning phase
            newEF = max(minEaseFactor, currentEaseFactor - 0.2)
            newInterval = 0 // Will be reviewed again soon
            // Due in 1 minute (learning step 1)
            nextDue = Date().addingTimeInterval(60)

        case .hard:
            // Harder than expected
            newEF = max(minEaseFactor, currentEaseFactor - 0.15)
            if reps <= 1 {
                // Still learning: use 10-minute step
                newInterval = 0
                nextDue = Date().addingTimeInterval(600)
            } else {
                // Review: multiply by 1.2 (shorter than normal)
                newInterval = max(1, currentInterval * 1.2)
                nextDue = Date().addingTimeInterval(newInterval * 86400)
            }

        case .good:
            // As expected
            newEF = max(minEaseFactor, currentEaseFactor + 0.0)
            if reps == 0 {
                // First time: graduate to 1 day
                newInterval = graduatingInterval
            } else if reps == 1 {
                // Second time: 6 days
                newInterval = 6
            } else {
                // Subsequent: multiply by ease factor
                newInterval = currentInterval * currentEaseFactor
            }
            nextDue = Date().addingTimeInterval(newInterval * 86400)

        case .easy:
            // Effortless recall
            newEF = max(minEaseFactor, currentEaseFactor + 0.15)
            if reps == 0 {
                newInterval = easyInterval
            } else {
                newInterval = currentInterval * currentEaseFactor * 1.3
            }
            nextDue = Date().addingTimeInterval(newInterval * 86400)
        }

        return ScheduleResult(
            nextDueDate: nextDue,
            newInterval: max(0, newInterval),
            newEaseFactor: newEF
        )
    }
}
