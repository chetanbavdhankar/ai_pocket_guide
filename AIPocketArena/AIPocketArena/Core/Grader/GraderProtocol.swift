// GraderProtocol.swift — AI Pocket Arena
// Protocol for grading free-text answers (deterministic or LLM-based)

import Foundation

struct GradeResult: Sendable {
    let isCorrect: Bool
    let score: Double        // 0.0 - 1.0
    let feedback: String
    let matchedKeywords: [String]
}

/// Protocol for swappable grading strategies
protocol Grader: Sendable {
    func grade(answer: String, modelAnswer: String, concept: Concept) -> GradeResult
}
