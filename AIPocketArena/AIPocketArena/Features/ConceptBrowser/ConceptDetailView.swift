// ConceptDetailView.swift — AI Pocket Arena
// Full concept detail: explanation, interview Q, related concepts

import SwiftUI

struct ConceptDetailView: View {
    let concept: Concept
    @State private var showModelAnswer = false
    private let contentStore = ContentStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CategoryBadge(category: concept.category)
                        DifficultyBadge(difficulty: concept.difficulty)
                    }

                    Text(concept.term)
                        .font(DesignTokens.display(24))
                        .foregroundStyle(DesignTokens.text)

                    Text(concept.oneLiner)
                        .font(DesignTokens.body(15))
                        .foregroundStyle(DesignTokens.accent2)
                }

                Divider().overlay(DesignTokens.border)

                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Explanation")
                    Text(concept.explanation)
                        .font(DesignTokens.body(14))
                        .foregroundStyle(DesignTokens.text)
                        .lineSpacing(4)
                }

                Divider().overlay(DesignTokens.border)

                // Interview Question
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Interview Question", icon: "questionmark.bubble")

                    Text(concept.interviewQuestion)
                        .font(DesignTokens.body(14, weight: .medium))
                        .foregroundStyle(DesignTokens.accent4)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.accent4.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showModelAnswer.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showModelAnswer ? "eye.slash" : "eye")
                            Text(showModelAnswer ? "Hide Answer" : "Reveal Model Answer")
                        }
                    }
                    .buttonStyle(OutlineButtonStyle(color: DesignTokens.accent2))

                    if showModelAnswer {
                        Text(concept.modelAnswer)
                            .font(DesignTokens.body(14))
                            .foregroundStyle(DesignTokens.text)
                            .lineSpacing(4)
                            .padding(12)
                            .background(DesignTokens.accent2.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }
                }

                // Cloze
                if let cloze = concept.cloze {
                    Divider().overlay(DesignTokens.border)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Cloze", icon: "text.insert")
                        Text(cloze.prompt)
                            .font(DesignTokens.mono(13))
                            .foregroundStyle(DesignTokens.text)
                            .padding(12)
                            .surfaceCard()

                        Text("Answer: \(cloze.answer)")
                            .font(DesignTokens.mono(12))
                            .foregroundStyle(DesignTokens.accent2)
                    }
                }

                // Tradeoff
                if let tradeoff = concept.tradeoff {
                    Divider().overlay(DesignTokens.border)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tradeoff Scenario", icon: "theatermasks")

                        Text(tradeoff.scenario)
                            .font(DesignTokens.body(14))
                            .foregroundStyle(DesignTokens.text)
                            .padding(12)
                            .surfaceCard()

                        ForEach(tradeoff.options, id: \.self) { option in
                            HStack {
                                Circle()
                                    .fill(option == tradeoff.answer ? DesignTokens.accent2 : DesignTokens.surface3)
                                    .frame(width: 8, height: 8)
                                Text(option)
                                    .font(DesignTokens.body(13))
                                    .foregroundStyle(option == tradeoff.answer ? DesignTokens.accent2 : DesignTokens.text2)
                            }
                        }

                        Text(tradeoff.why)
                            .font(DesignTokens.body(13))
                            .foregroundStyle(DesignTokens.text2)
                            .padding(12)
                            .background(DesignTokens.accent2.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSm))
                    }
                }

                // Tags
                if !concept.tags.isEmpty {
                    Divider().overlay(DesignTokens.border)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Tags", icon: "tag")
                        FlowLayout(spacing: 6) {
                            ForEach(concept.tags, id: \.self) { tag in
                                Text(tag)
                                    .chipStyle()
                            }
                        }
                    }
                }

                // Related Concepts
                if !concept.related.isEmpty {
                    Divider().overlay(DesignTokens.border)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Related Concepts", icon: "link")

                        ForEach(contentStore.relatedConcepts(for: concept)) { related in
                            NavigationLink {
                                ConceptDetailView(concept: related)
                            } label: {
                                HStack {
                                    Text(related.term)
                                        .font(DesignTokens.body(13, weight: .medium))
                                        .foregroundStyle(DesignTokens.accent)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DesignTokens.text3)
                                }
                                .padding(10)
                                .surfaceCard()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(DesignTokens.bg)
        .navigationTitle(concept.term)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.accent)
            }
            Text(title)
                .font(DesignTokens.display(14))
                .foregroundStyle(DesignTokens.text)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
