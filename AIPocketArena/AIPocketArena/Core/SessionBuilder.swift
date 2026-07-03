// SessionBuilder.swift — AI Pocket Arena
// Selects concepts for a session: 60% weak/due, 30% category, 10% random

import Foundation
import SwiftData

@Observable
final class SessionBuilder: @unchecked Sendable {
    private let contentStore: ContentStore
    private let scheduler: any Scheduler

    init(contentStore: ContentStore = .shared, scheduler: any Scheduler = SM2Scheduler()) {
        self.contentStore = contentStore
        self.scheduler = scheduler
    }

    /// Build a session of concepts for a game mode
    func buildSession(
        mode: GameMode,
        difficulty: GameDifficulty,
        categoryFilter: Category? = nil,
        progressRecords: [ConceptProgress],
        count: Int = 10
    ) -> [Concept] {
        let progressMap = Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.conceptID, $0) })

        // Filter available concepts
        var pool = contentStore.concepts

        // Apply category filter if set
        if let category = categoryFilter {
            pool = pool.filter { $0.category == category }
        }

        // Filter by mode requirements
        switch mode {
        case .cloze:
            pool = pool.filter { $0.cloze != nil }
        case .scenario:
            pool = pool.filter { $0.tradeoff != nil }
        default:
            break
        }

        guard !pool.isEmpty else { return [] }

        // Score each concept for selection priority
        struct ScoredConcept {
            let concept: Concept
            let score: Double // Higher = more likely to be selected
        }

        let scored = pool.map { concept -> ScoredConcept in
            let progress = progressMap[concept.id]

            var score: Double = 0

            // Due concepts get highest priority
            if progress == nil || (progress?.isDue ?? true) {
                score += 100
            }

            // Low mastery = high priority
            if let p = progress {
                score += (1.0 - p.mastery) * 80
                // Recent failures add priority
                let recentMisses = p.recentResults.suffix(5).filter { !$0 }.count
                score += Double(recentMisses) * 15
                // Low ease factor means struggle
                score += max(0, (2.5 - p.easeFactor) * 20)
            } else {
                // Never seen = high priority
                score += 60
            }

            // Small random factor for interleaving
            score += Double.random(in: 0...10)

            return ScoredConcept(concept: concept, score: score)
        }

        // Sort by score (highest first)
        let sorted = scored.sorted { $0.score > $1.score }

        // Apply the 60/30/10 split
        let targetCount = min(count, pool.count)
        let weakDueCount = Int(ceil(Double(targetCount) * 0.6))
        let categoryCount = Int(ceil(Double(targetCount) * 0.3))
        let randomCount = targetCount - weakDueCount - categoryCount

        var selected: [Concept] = []
        var usedIDs = Set<String>()

        // 60%: Weakest/due concepts (already sorted by priority)
        for item in sorted {
            if selected.count >= weakDueCount { break }
            if !usedIDs.contains(item.concept.id) {
                selected.append(item.concept)
                usedIDs.insert(item.concept.id)
            }
        }

        // 30%: Category-focused (different category from weak set if no filter)
        if let category = categoryFilter {
            let catConcepts = pool.filter { $0.category == category && !usedIDs.contains($0.id) }
            for concept in catConcepts.shuffled().prefix(categoryCount) {
                selected.append(concept)
                usedIDs.insert(concept.id)
            }
        } else {
            // Pick from underrepresented categories
            let categories = Category.allCases.shuffled()
            for category in categories {
                if selected.count >= weakDueCount + categoryCount { break }
                if let concept = pool.filter({ $0.category == category && !usedIDs.contains($0.id) }).randomElement() {
                    selected.append(concept)
                    usedIDs.insert(concept.id)
                }
            }
        }

        // 10%: Random interleaving
        let remaining = pool.filter { !usedIDs.contains($0.id) }
        for concept in remaining.shuffled().prefix(max(0, randomCount)) {
            selected.append(concept)
        }

        // Shuffle final selection for interleaving
        return Array(selected.shuffled().prefix(targetCount))
    }

    /// Build a Boss Round session — pulls weakest concepts across all categories
    func buildBossSession(progressRecords: [ConceptProgress], count: Int = 15) -> [Concept] {
        let progressMap = Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.conceptID, $0) })

        let sorted = contentStore.concepts.sorted { a, b in
            let masteryA = progressMap[a.id]?.mastery ?? 0
            let masteryB = progressMap[b.id]?.mastery ?? 0
            return masteryA < masteryB
        }

        return Array(sorted.prefix(count).shuffled())
    }

    /// Build a Daily Challenge — deterministic based on date
    func buildDailyChallenge(date: Date = Date()) -> [Concept] {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = UInt64(year * 1000 + dayOfYear)

        var rng = SeededRandomNumberGenerator(seed: seed)
        let shuffled = contentStore.concepts.shuffled(using: &rng)
        return Array(shuffled.prefix(10))
    }
}

// MARK: - Seeded RNG for deterministic daily challenges
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
