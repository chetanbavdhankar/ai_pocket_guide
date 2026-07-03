// SchedulerProtocol.swift — AI Pocket Arena
// Protocol for spaced repetition scheduling (SM-2 or FSRS)

import Foundation

/// Rating from user self-assessment (Flash Recall) or mapped from correctness
enum ReviewRating: Int, Sendable, CaseIterable {
    case again = 0     // Complete blackout, reset
    case hard = 1      // Recalled with serious difficulty
    case good = 2      // Recalled with some effort
    case easy = 3      // Recalled effortlessly

    /// Map a boolean correct/incorrect to a rating
    static func from(correct: Bool, responseTime: TimeInterval? = nil) -> ReviewRating {
        if !correct { return .again }
        if let time = responseTime, time < 3.0 { return .easy }
        return .good
    }
}

/// Result of scheduling computation
struct ScheduleResult: Sendable {
    let nextDueDate: Date
    let newInterval: Double        // In days
    let newEaseFactor: Double
}

/// Protocol for swappable spaced repetition algorithms
protocol Scheduler: Sendable {
    /// Compute the next review schedule for a concept based on rating
    func schedule(
        rating: ReviewRating,
        currentInterval: Double,
        currentEaseFactor: Double,
        reps: Int,
        lapses: Int
    ) -> ScheduleResult
}
