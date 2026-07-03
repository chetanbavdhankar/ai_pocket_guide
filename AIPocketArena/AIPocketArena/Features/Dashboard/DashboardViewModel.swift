// DashboardViewModel.swift — AI Pocket Arena

import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    var dueCount: Int = 0
    var overallMastery: Double = 0
    var weakestConcepts: [Concept] = []
    var categoryMasteries: [(category: Category, mastery: Double)] = []
    var streak: Int = 0
    var xp: Int = 0
    var level: Int = 1

    private let contentStore = ContentStore.shared

    func refresh(progressRecords: [ConceptProgress], profile: UserProfile?) {
        let progressMap = Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.conceptID, $0) })

        // Due count
        dueCount = contentStore.concepts.filter { concept in
            guard let progress = progressMap[concept.id] else { return true }
            return progress.isDue
        }.count

        // Overall mastery
        if progressRecords.isEmpty {
            overallMastery = 0
        } else {
            overallMastery = progressRecords.reduce(0.0) { $0 + $1.mastery } / Double(contentStore.concepts.count)
        }

        // Category masteries
        categoryMasteries = Category.allCases.compactMap { category in
            let concepts = contentStore.concepts(for: category)
            guard !concepts.isEmpty else { return nil }
            let mastery = concepts.reduce(0.0) { sum, concept in
                sum + (progressMap[concept.id]?.mastery ?? 0)
            } / Double(concepts.count)
            return (category: category, mastery: mastery)
        }

        // Weakest concepts
        weakestConcepts = contentStore.concepts.sorted { a, b in
            let mA = progressMap[a.id]?.mastery ?? 0
            let mB = progressMap[b.id]?.mastery ?? 0
            return mA < mB
        }.prefix(3).map { $0 }

        // Profile stats
        if let profile {
            streak = profile.currentStreak
            xp = profile.xp
            level = profile.level
        }
    }
}
