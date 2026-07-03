// ConceptBrowserView.swift — AI Pocket Arena
// Searchable, filterable list of all concepts

import SwiftUI

struct ConceptBrowserView: View {
    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil
    @State private var selectedDifficulty: Int? = nil

    private let contentStore = ContentStore.shared

    private var filteredConcepts: [Concept] {
        var results = contentStore.concepts

        if !searchText.isEmpty {
            results = contentStore.concepts(matching: searchText)
        }

        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }

        if let diff = selectedDifficulty {
            results = results.filter { $0.difficulty == diff }
        }

        return results
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(Category.allCases) { category in
                            FilterChip(
                                label: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.accentColor
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Difficulty filter
                HStack(spacing: 8) {
                    ForEach([1, 2, 3], id: \.self) { diff in
                        DifficultyFilterChip(
                            difficulty: diff,
                            isSelected: selectedDifficulty == diff
                        ) {
                            selectedDifficulty = selectedDifficulty == diff ? nil : diff
                        }
                    }
                    Spacer()
                    Text("\(filteredConcepts.count) concepts")
                        .font(DesignTokens.mono(11))
                        .foregroundStyle(DesignTokens.text3)
                }
                .padding(.horizontal)

                // Concept list
                LazyVStack(spacing: 8) {
                    ForEach(filteredConcepts) { concept in
                        NavigationLink {
                            ConceptDetailView(concept: concept)
                        } label: {
                            ConceptRow(concept: concept)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Concept Browser")
        .searchable(text: $searchText, prompt: "Search terms...")
    }
}

// MARK: - Concept Row
struct ConceptRow: View {
    let concept: Concept

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(concept.term)
                        .font(DesignTokens.body(14, weight: .semibold))
                        .foregroundStyle(DesignTokens.text)
                        .lineLimit(1)

                    DifficultyBadge(difficulty: concept.difficulty)
                }

                Text(concept.oneLiner)
                    .font(DesignTokens.body(12))
                    .foregroundStyle(DesignTokens.text2)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            CategoryBadge(category: concept.category)
        }
        .padding(12)
        .surfaceCard()
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = DesignTokens.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignTokens.mono(11))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

// MARK: - Difficulty Filter Chip
struct DifficultyFilterChip: View {
    let difficulty: Int
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        switch difficulty {
        case 1: "① Foundational"
        case 2: "② Intermediate"
        case 3: "③ Frontier"
        default: ""
        }
    }

    private var color: Color {
        switch difficulty {
        case 1: DesignTokens.accent2
        case 2: DesignTokens.accent4
        case 3: DesignTokens.accent3
        default: DesignTokens.text3
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignTokens.mono(10))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
}
