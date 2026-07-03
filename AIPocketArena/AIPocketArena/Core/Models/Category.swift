// Category.swift — AI Pocket Arena
// Fixed taxonomy from §2.1

import SwiftUI

enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
    case tokenization = "tokenization"
    case embeddingsPositional = "embeddings-positional"
    case attention = "attention"
    case transformerBlock = "transformer-block"
    case architectures = "architectures"
    case pretrainingOptimization = "pretraining-optimization"
    case finetuningAlignment = "finetuning-alignment"
    case inferenceDecoding = "inference-decoding"
    case efficiencySystems = "efficiency-systems"
    case scalingReasoning = "scaling-reasoning"
    case ragRetrieval = "rag-retrieval"
    case agentsTools = "agents-tools"
    case evaluation = "evaluation"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tokenization: "Tokenization"
        case .embeddingsPositional: "Embeddings & Positional"
        case .attention: "Attention"
        case .transformerBlock: "Transformer Block"
        case .architectures: "Architectures"
        case .pretrainingOptimization: "Pretraining & Optimization"
        case .finetuningAlignment: "Fine-tuning & Alignment"
        case .inferenceDecoding: "Inference & Decoding"
        case .efficiencySystems: "Efficiency & Systems"
        case .scalingReasoning: "Scaling & Reasoning"
        case .ragRetrieval: "RAG & Retrieval"
        case .agentsTools: "Agents & Tools"
        case .evaluation: "Evaluation"
        }
    }

    var icon: String {
        switch self {
        case .tokenization: "textformat.abc"
        case .embeddingsPositional: "arrow.up.right.and.arrow.down.left.rectangle"
        case .attention: "eye"
        case .transformerBlock: "cube.transparent"
        case .architectures: "building.columns"
        case .pretrainingOptimization: "graduationcap"
        case .finetuningAlignment: "slider.horizontal.3"
        case .inferenceDecoding: "wand.and.rays"
        case .efficiencySystems: "bolt"
        case .scalingReasoning: "chart.line.uptrend.xyaxis"
        case .ragRetrieval: "magnifyingglass"
        case .agentsTools: "wrench.and.screwdriver"
        case .evaluation: "checkmark.seal"
        }
    }

    var accentColor: Color {
        switch self {
        case .tokenization: DesignTokens.accent
        case .embeddingsPositional: DesignTokens.accent2
        case .attention: DesignTokens.accent4
        case .transformerBlock: DesignTokens.accent3
        case .architectures: DesignTokens.accent
        case .pretrainingOptimization: DesignTokens.accent2
        case .finetuningAlignment: DesignTokens.accent4
        case .inferenceDecoding: DesignTokens.accent3
        case .efficiencySystems: DesignTokens.accent2
        case .scalingReasoning: DesignTokens.accent
        case .ragRetrieval: DesignTokens.accent4
        case .agentsTools: DesignTokens.accent3
        case .evaluation: DesignTokens.accent2
        }
    }
}
