// ContentStore.swift — AI Pocket Arena
// Loads, validates, and serves the bundled concepts.json

import Foundation
import SwiftUI

@Observable
final class ContentStore: @unchecked Sendable {
    private(set) var concepts: [Concept] = []
    private(set) var conceptsByID: [String: Concept] = [:]
    private(set) var conceptsByCategory: [Category: [Concept]] = [:]
    private(set) var validationErrors: [Concept.ValidationError] = []
    private(set) var isLoaded = false

    // Content lint warnings (debug only)
    private(set) var lintWarnings: [String] = []

    static let shared = ContentStore()

    private init() {
        loadConcepts()
    }

    private func loadConcepts() {
        guard let url = Bundle.main.url(forResource: "concepts", withExtension: "json") else {
            #if DEBUG
            assertionFailure("concepts.json not found in bundle")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let bank = try decoder.decode(ConceptBank.self, from: data)
            self.concepts = bank.concepts

            // Build lookup indices
            let allIDs = Set(concepts.map(\.id))
            conceptsByID = Dictionary(uniqueKeysWithValues: concepts.map { ($0.id, $0) })
            conceptsByCategory = Dictionary(grouping: concepts, by: \.category)

            // Validate all concepts
            var errors: [Concept.ValidationError] = []
            for concept in concepts {
                errors.append(contentsOf: concept.validate(allIDs: allIDs))
            }
            self.validationErrors = errors

            // Content lint (debug only)
            #if DEBUG
            runContentLint()
            if !errors.isEmpty {
                print("⚠️ Concept validation errors:")
                for error in errors {
                    print("  \(error)")
                }
            }
            #endif

            isLoaded = true
        } catch {
            #if DEBUG
            assertionFailure("Failed to decode concepts.json: \(error)")
            #endif
        }
    }

    // MARK: - Queries

    func concepts(for category: Category) -> [Concept] {
        conceptsByCategory[category] ?? []
    }

    func concepts(forDifficulty difficulty: Int) -> [Concept] {
        concepts.filter { $0.difficulty == difficulty }
    }

    func concepts(matching search: String) -> [Concept] {
        guard !search.isEmpty else { return concepts }
        let lowered = search.lowercased()
        return concepts.filter {
            $0.term.lowercased().contains(lowered) ||
            $0.oneLiner.lowercased().contains(lowered) ||
            $0.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
    }

    func concept(byID id: String) -> Concept? {
        conceptsByID[id]
    }

    func relatedConcepts(for concept: Concept) -> [Concept] {
        concept.related.compactMap { conceptsByID[$0] }
    }

    /// Get concepts with tradeoff scenarios (for Scenario mode)
    func conceptsWithTradeoff() -> [Concept] {
        concepts.filter { $0.tradeoff != nil }
    }

    /// Get concepts with cloze items (for Cloze mode)
    func conceptsWithCloze() -> [Concept] {
        concepts.filter { $0.cloze != nil }
    }

    /// Get distractors for a concept based on difficulty
    func getDistractors(for concept: Concept, source: ModeConfig.DistractorSource, count: Int = 3) -> [String] {
        switch source {
        case .relatedConcepts:
            // Hardest: pull from related concepts' one-liners
            var distractors = concept.related.compactMap { conceptsByID[$0]?.oneLiner }
            if distractors.count < count {
                // Fall back to same category
                let sameCat = conceptsByCategory[concept.category]?
                    .filter { $0.id != concept.id }
                    .map(\.oneLiner) ?? []
                distractors.append(contentsOf: sameCat)
            }
            return Array(distractors.shuffled().prefix(count))

        case .sameCategory:
            // Medium: pull from same category
            let sameCat = conceptsByCategory[concept.category]?
                .filter { $0.id != concept.id }
                .map(\.oneLiner) ?? []
            if sameCat.count >= count {
                return Array(sameCat.shuffled().prefix(count))
            }
            // Fall back to stored distractors
            return Array((sameCat + concept.distractors).shuffled().prefix(count))

        case .randomCategory:
            // Easiest: use stored distractors (pre-authored)
            return Array(concept.distractors.shuffled().prefix(count))
        }
    }

    // MARK: - Content Lint

    private func runContentLint() {
        var warnings: [String] = []

        for concept in concepts {
            if concept.cloze == nil {
                warnings.append("[\(concept.id)] missing cloze item")
            }
            if concept.tradeoff == nil {
                warnings.append("[\(concept.id)] missing tradeoff scenario")
            }
            if concept.related.isEmpty {
                warnings.append("[\(concept.id)] no related concepts")
            }
            if concept.tags.isEmpty {
                warnings.append("[\(concept.id)] no tags")
            }
        }

        // Check category coverage
        for category in Category.allCases {
            let count = conceptsByCategory[category]?.count ?? 0
            if count == 0 {
                warnings.append("[COVERAGE] category '\(category.rawValue)' has 0 concepts")
            } else if count < 3 {
                warnings.append("[COVERAGE] category '\(category.rawValue)' has only \(count) concepts")
            }
        }

        self.lintWarnings = warnings

        if !warnings.isEmpty {
            print("📋 Content lint warnings (\(warnings.count)):")
            for w in warnings.prefix(10) {
                print("  \(w)")
            }
            if warnings.count > 10 {
                print("  ... and \(warnings.count - 10) more")
            }
        }
    }
}
