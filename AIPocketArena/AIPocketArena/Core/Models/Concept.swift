// Concept.swift — AI Pocket Arena
// Codable model matching §2.2 schema exactly

import Foundation

struct ClozeItem: Codable, Sendable, Hashable {
    let prompt: String
    let answer: String
}

struct TradeoffItem: Codable, Sendable, Hashable {
    let scenario: String
    let options: [String]
    let answer: String
    let why: String
}

struct Concept: Codable, Identifiable, Sendable, Hashable {
    let id: String                          // kebab-case, stable, unique
    let term: String
    let category: Category
    let difficulty: Int                     // 1=foundational, 2=intermediate, 3=frontier
    let oneLiner: String                    // <=140 chars
    let explanation: String                 // 2-4 sentence architectural explanation
    let interviewQuestion: String
    let modelAnswer: String
    let distractors: [String]              // >=3 plausible-but-wrong one-liners
    let cloze: ClozeItem?
    let tradeoff: TradeoffItem?            // Present for ~40% of concepts
    let tags: [String]
    let related: [String]                  // ids of related concepts

    // MARK: - Validation
    struct ValidationError: Error, CustomStringConvertible {
        let conceptID: String
        let message: String
        var description: String { "[\(conceptID)] \(message)" }
    }

    func validate(allIDs: Set<String>) -> [ValidationError] {
        var errors: [ValidationError] = []

        if oneLiner.count > 140 {
            errors.append(ValidationError(conceptID: id, message: "oneLiner exceeds 140 chars (\(oneLiner.count))"))
        }

        if distractors.count < 3 {
            errors.append(ValidationError(conceptID: id, message: "needs ≥3 distractors, has \(distractors.count)"))
        }

        for relatedID in related {
            if !allIDs.contains(relatedID) {
                errors.append(ValidationError(conceptID: id, message: "dangling related ID: '\(relatedID)'"))
            }
        }

        if difficulty < 1 || difficulty > 3 {
            errors.append(ValidationError(conceptID: id, message: "difficulty must be 1-3, got \(difficulty)"))
        }

        if explanation.isEmpty {
            errors.append(ValidationError(conceptID: id, message: "explanation is empty"))
        }

        return errors
    }
}

// MARK: - Concept Bank (top-level JSON wrapper)
struct ConceptBank: Codable, Sendable {
    let concepts: [Concept]
}
