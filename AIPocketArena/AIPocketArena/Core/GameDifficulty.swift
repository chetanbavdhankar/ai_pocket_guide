// GameDifficulty.swift — AI Pocket Arena
// Two orthogonal difficulty axes: content difficulty and game difficulty

import Foundation
import SwiftUI

/// Game difficulty controls time pressure, distractor subtlety, input method, hints
enum GameDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    var icon: String {
        switch self {
        case .easy: "🟢"
        case .medium: "🟡"
        case .hard: "🔴"
        }
    }
}

/// Mode-specific difficulty configuration
struct ModeConfig: Sendable {
    let timePerQuestion: TimeInterval?  // nil = no timer
    let distractorSource: DistractorSource
    let inputMethod: InputMethod
    let hintsAvailable: Bool
    let gridSize: Int?                  // For Match Pairs
    let livesCount: Int?                // For Boss Round

    enum DistractorSource: Sendable {
        case randomCategory     // Easy: distractors from random categories
        case sameCategory       // Medium: distractors from same category
        case relatedConcepts    // Hard: distractors from `related` concepts
    }

    enum InputMethod: Sendable {
        case multipleChoice
        case freeText
    }
}

/// Game mode definitions
enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case flashRecall
    case rapidFire
    case matchPairs
    case cloze
    case connections
    case scenario
    case depthLadder
    case bossRound

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flashRecall: "Flash Recall"
        case .rapidFire: "Rapid Fire"
        case .matchPairs: "Match Pairs"
        case .cloze: "Cloze"
        case .connections: "Connections"
        case .scenario: "Scenario"
        case .depthLadder: "Depth Ladder"
        case .bossRound: "Boss Round"
        }
    }

    var subtitle: String {
        switch self {
        case .flashRecall: "Recall + Retention"
        case .rapidFire: "Timed MCQ"
        case .matchPairs: "Term ↔ Definition"
        case .cloze: "Fill the Blank"
        case .connections: "Group & Categorize"
        case .scenario: "Tradeoff Decisions"
        case .depthLadder: "Interview Simulation"
        case .bossRound: "Mixed Gauntlet"
        }
    }

    var icon: String {
        switch self {
        case .flashRecall: "rectangle.stack"
        case .rapidFire: "bolt.fill"
        case .matchPairs: "square.grid.2x2"
        case .cloze: "text.insert"
        case .connections: "circle.grid.cross"
        case .scenario: "theatermasks"
        case .depthLadder: "ladder"
        case .bossRound: "shield.checkered"
        }
    }

    var learningType: String {
        switch self {
        case .flashRecall: "Recall + Retention"
        case .rapidFire: "Recognition"
        case .matchPairs: "Discrimination"
        case .cloze: "Productive Recall"
        case .connections: "Categorical Mastery"
        case .scenario: "Application"
        case .depthLadder: "Application + Articulation"
        case .bossRound: "Mixed Gauntlet"
        }
    }

    var accentColor: (any ShapeStyle) {
        switch self {
        case .flashRecall: DesignTokens.accent
        case .rapidFire: DesignTokens.accent3
        case .matchPairs: DesignTokens.accent2
        case .cloze: DesignTokens.accent4
        case .connections: DesignTokens.accent
        case .scenario: DesignTokens.accent4
        case .depthLadder: DesignTokens.accent2
        case .bossRound: DesignTokens.accent3
        }
    }

    /// Get mode configuration for a given difficulty
    func config(for difficulty: GameDifficulty) -> ModeConfig {
        switch self {
        case .flashRecall:
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: .randomCategory,
                inputMethod: .multipleChoice,
                hintsAvailable: true,
                gridSize: nil,
                livesCount: nil
            )

        case .rapidFire:
            let time: TimeInterval = switch difficulty {
            case .easy: 20
            case .medium: 12
            case .hard: 8
            }
            let source: ModeConfig.DistractorSource = switch difficulty {
            case .easy: .randomCategory
            case .medium: .sameCategory
            case .hard: .relatedConcepts
            }
            return ModeConfig(
                timePerQuestion: time,
                distractorSource: source,
                inputMethod: .multipleChoice,
                hintsAvailable: difficulty == .easy,
                gridSize: nil,
                livesCount: nil
            )

        case .matchPairs:
            let grid = switch difficulty {
            case .easy: 4
            case .medium: 6
            case .hard: 8
            }
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: difficulty == .hard ? .sameCategory : .randomCategory,
                inputMethod: .multipleChoice,
                hintsAvailable: difficulty == .easy,
                gridSize: grid,
                livesCount: nil
            )

        case .cloze:
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: .sameCategory,
                inputMethod: difficulty == .hard ? .freeText : .multipleChoice,
                hintsAvailable: difficulty != .hard,
                gridSize: nil,
                livesCount: nil
            )

        case .connections:
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: difficulty == .hard ? .relatedConcepts : .sameCategory,
                inputMethod: .multipleChoice,
                hintsAvailable: difficulty == .easy,
                gridSize: nil,
                livesCount: nil
            )

        case .scenario:
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: .relatedConcepts,
                inputMethod: difficulty == .hard ? .freeText : .multipleChoice,
                hintsAvailable: difficulty != .hard,
                gridSize: nil,
                livesCount: nil
            )

        case .depthLadder:
            return ModeConfig(
                timePerQuestion: nil,
                distractorSource: .relatedConcepts,
                inputMethod: .freeText,
                hintsAvailable: difficulty == .easy,
                gridSize: nil,
                livesCount: nil
            )

        case .bossRound:
            return ModeConfig(
                timePerQuestion: 15,
                distractorSource: .relatedConcepts,
                inputMethod: .multipleChoice,
                hintsAvailable: false,
                gridSize: nil,
                livesCount: 3
            )
        }
    }
}
