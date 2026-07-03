// DeterministicGrader.swift — AI Pocket Arena
// Normalized string + keyword/related-term coverage grader

import Foundation

struct DeterministicGrader: Grader, Sendable {
    /// Minimum score to count as correct
    private let passingThreshold: Double = 0.4

    func grade(answer: String, modelAnswer: String, concept: Concept) -> GradeResult {
        let normalizedAnswer = normalize(answer)

        // Empty answer is always wrong
        guard !normalizedAnswer.isEmpty else {
            return GradeResult(
                isCorrect: false,
                score: 0,
                feedback: "No answer provided.",
                matchedKeywords: []
            )
        }

        // Extract keywords from model answer
        let keywords = extractKeywords(from: modelAnswer)
        let relatedTerms = concept.related

        // Check keyword coverage
        var matchedKeywords: [String] = []
        for keyword in keywords {
            if normalizedAnswer.contains(normalize(keyword)) {
                matchedKeywords.append(keyword)
            }
        }

        // Check related term mentions
        for term in relatedTerms {
            let normalizedTerm = normalize(term.replacingOccurrences(of: "-", with: " "))
            if normalizedAnswer.contains(normalizedTerm) {
                matchedKeywords.append(term)
            }
        }

        // Check for exact/near match of the one-liner
        let oneLineScore = fuzzyMatch(normalizedAnswer, normalize(concept.oneLiner))

        // Compute composite score
        let keywordScore: Double
        if keywords.isEmpty {
            keywordScore = 0
        } else {
            keywordScore = Double(matchedKeywords.count) / Double(keywords.count)
        }

        // Weight: 60% keyword coverage, 40% fuzzy one-liner match
        let score = min(1.0, keywordScore * 0.6 + oneLineScore * 0.4)
        let isCorrect = score >= passingThreshold

        // Generate feedback
        let feedback: String
        if isCorrect && score > 0.7 {
            feedback = "Excellent! You covered the key concepts."
        } else if isCorrect {
            feedback = "Good answer. Consider mentioning: \(keywords.filter { !matchedKeywords.contains($0) }.prefix(2).joined(separator: ", "))"
        } else {
            let missed = keywords.filter { !matchedKeywords.contains($0) }.prefix(3).joined(separator: ", ")
            feedback = "Key concepts missed: \(missed)"
        }

        return GradeResult(
            isCorrect: isCorrect,
            score: score,
            feedback: feedback,
            matchedKeywords: matchedKeywords
        )
    }

    // MARK: - Private Helpers

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func extractKeywords(from text: String) -> [String] {
        let stopWords: Set<String> = [
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "can", "shall", "to", "of", "in", "for",
            "on", "with", "at", "by", "from", "as", "into", "through", "during",
            "before", "after", "above", "below", "between", "under", "again",
            "further", "then", "once", "here", "there", "when", "where", "why",
            "how", "all", "each", "every", "both", "few", "more", "most", "other",
            "some", "such", "no", "not", "only", "own", "same", "so", "than",
            "too", "very", "just", "because", "but", "and", "or", "if", "while",
            "that", "this", "it", "its", "which", "what", "who", "whom", "their",
            "them", "they", "we", "our", "your", "he", "she", "him", "her",
            "i", "me", "my", "you", "us"
        ]

        let words = text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.count > 2 }

        // Deduplicate while preserving order
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    private func fuzzyMatch(_ a: String, _ b: String) -> Double {
        guard !a.isEmpty && !b.isEmpty else { return 0 }

        let wordsA = Set(a.components(separatedBy: " "))
        let wordsB = Set(b.components(separatedBy: " "))

        guard !wordsB.isEmpty else { return 0 }

        let intersection = wordsA.intersection(wordsB)
        return Double(intersection.count) / Double(wordsB.count)
    }
}
