// UserProfile.swift — AI Pocket Arena
// SwiftData model for user state (XP, streaks, badges, settings)

import Foundation
import SwiftData

@Model
final class UserProfile {
    var xp: Int
    var level: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var streakFreezeAvailable: Bool
    var totalSessionsPlayed: Int
    var totalCorrectAnswers: Int
    var totalQuestionsAnswered: Int

    // Badge IDs that have been unlocked
    var unlockedBadges: [String]

    // Settings
    var hapticsEnabled: Bool
    var sfxEnabled: Bool
    var freePlayMode: Bool          // Disables difficulty gating
    var defaultDifficulty: String   // "easy", "medium", "hard"

    // Daily challenge tracking
    var lastDailyChallengeDate: Date?
    var dailyChallengeHighScore: Int

    init() {
        self.xp = 0
        self.level = 1
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.streakFreezeAvailable = false
        self.totalSessionsPlayed = 0
        self.totalCorrectAnswers = 0
        self.totalQuestionsAnswered = 0
        self.unlockedBadges = []
        self.hapticsEnabled = true
        self.sfxEnabled = true
        self.freePlayMode = false
        self.defaultDifficulty = "medium"
        self.lastDailyChallengeDate = nil
        self.dailyChallengeHighScore = 0
    }

    // MARK: - XP & Leveling

    /// XP required for a given level (exponential curve)
    static func xpForLevel(_ level: Int) -> Int {
        Int(100 * pow(1.5, Double(level - 1)))
    }

    var xpForNextLevel: Int {
        Self.xpForLevel(level + 1)
    }

    var xpProgress: Double {
        let currentLevelXP = Self.xpForLevel(level)
        let nextLevelXP = Self.xpForLevel(level + 1)
        let range = nextLevelXP - currentLevelXP
        guard range > 0 else { return 1.0 }
        return Double(xp - currentLevelXP) / Double(range)
    }

    func addXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel {
            level += 1
        }
    }

    // MARK: - Streak Management

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastActive = lastActiveDate else {
            // First time playing
            currentStreak = 1
            lastActiveDate = today
            return
        }

        let lastDay = calendar.startOfDay(for: lastActive)

        if lastDay == today {
            // Already played today
            return
        }

        let daysSinceActive = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysSinceActive == 1 {
            // Consecutive day
            currentStreak += 1
        } else if daysSinceActive == 2 && streakFreezeAvailable {
            // Use streak freeze
            currentStreak += 1
            streakFreezeAvailable = false
        } else {
            // Streak broken
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastActiveDate = today

        // Earn a freeze every 7 days
        if currentStreak > 0 && currentStreak % 7 == 0 {
            streakFreezeAvailable = true
        }
    }

    // MARK: - Accuracy

    var overallAccuracy: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)
    }
}

// MARK: - Badge Definitions
enum Badge: String, CaseIterable, Identifiable, Sendable {
    // Category mastery
    case tokenizationMaster = "tokenization-master"
    case embeddingsMaster = "embeddings-master"
    case attentionMaster = "attention-master"
    case transformerMaster = "transformer-master"
    case architecturesMaster = "architectures-master"
    case pretrainingMaster = "pretraining-master"
    case finetuningMaster = "finetuning-master"
    case inferenceMaster = "inference-master"
    case efficiencyMaster = "efficiency-master"
    case scalingMaster = "scaling-master"
    case ragMaster = "rag-master"
    case agentsMaster = "agents-master"
    case evaluationMaster = "evaluation-master"

    // Milestones
    case firstSession = "first-session"
    case streak7 = "streak-7"
    case streak30 = "streak-30"
    case streak100 = "streak-100"
    case bossSlayer = "boss-slayer"
    case perfectRound = "perfect-round"
    case centurion = "centurion"              // 100 concepts mastered
    case speedDemon = "speed-demon"           // 10 Rapid Fire streak

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tokenizationMaster: "Token Sage"
        case .embeddingsMaster: "Embedding Architect"
        case .attentionMaster: "Attention Master"
        case .transformerMaster: "Transformer Guru"
        case .architecturesMaster: "Architecture Expert"
        case .pretrainingMaster: "Pretraining Pro"
        case .finetuningMaster: "Fine-tuning Wizard"
        case .inferenceMaster: "Inference Optimizer"
        case .efficiencyMaster: "Efficiency Expert"
        case .scalingMaster: "Scaling Scientist"
        case .ragMaster: "RAG Specialist"
        case .agentsMaster: "Agent Orchestrator"
        case .evaluationMaster: "Eval Maestro"
        case .firstSession: "First Steps"
        case .streak7: "Weekly Warrior"
        case .streak30: "Monthly Master"
        case .streak100: "Century Sentinel"
        case .bossSlayer: "Boss Slayer"
        case .perfectRound: "Flawless"
        case .centurion: "Centurion"
        case .speedDemon: "Speed Demon"
        }
    }

    var icon: String {
        switch self {
        case .attentionMaster: "👁️"
        case .transformerMaster: "🧊"
        case .finetuningMaster: "🧙"
        case .inferenceMaster: "⚡"
        case .scalingMaster: "📈"
        case .ragMaster: "🔍"
        case .agentsMaster: "🤖"
        case .firstSession: "🌟"
        case .streak7: "🔥"
        case .streak30: "💎"
        case .streak100: "👑"
        case .bossSlayer: "⚔️"
        case .perfectRound: "✨"
        case .centurion: "💯"
        case .speedDemon: "🏎️"
        default: "🏆"
        }
    }
}
