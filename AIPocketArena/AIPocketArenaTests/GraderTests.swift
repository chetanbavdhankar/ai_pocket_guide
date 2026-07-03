// GraderTests.swift — AI Pocket Arena

import XCTest
@testable import AIPocketArena

final class GraderTests: XCTestCase {
    let grader = DeterministicGrader()
    
    // Create a dummy concept for testing
    let dummyConcept = Concept(
        id: "test-concept",
        term: "RoPE",
        category: .embeddingsPositional,
        difficulty: 2,
        oneLiner: "Encodes position by rotating query/key vectors, enabling relative position via dot-product decay.",
        explanation: "RoPE applies a rotation matrix to query and key vectors based on their position.",
        interviewQuestion: "What is RoPE?",
        modelAnswer: "RoPE rotates Q and K vectors by position-dependent angles. When computing Q·Kᵀ, the rotation angles subtract, making the dot product depend only on relative distance.",
        distractors: ["D1", "D2", "D3"],
        cloze: nil,
        tradeoff: nil,
        tags: [],
        related: ["alibi", "sinusoidal-pe"]
    )
    
    func testEmptyAnswer() {
        let result = grader.grade(answer: "", modelAnswer: dummyConcept.modelAnswer, concept: dummyConcept)
        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.score, 0)
    }
    
    func testExactMatch() {
        let result = grader.grade(answer: dummyConcept.modelAnswer, modelAnswer: dummyConcept.modelAnswer, concept: dummyConcept)
        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.score, 1.0)
    }
    
    func testKeywordMatch() {
        let answer = "It rotates query and key vectors using rotation matrix angles to get relative distance in dot product."
        let result = grader.grade(answer: answer, modelAnswer: dummyConcept.modelAnswer, concept: dummyConcept)
        XCTAssertTrue(result.isCorrect)
        XCTAssertGreaterThanOrEqual(result.score, 0.4) // passing threshold
    }
}
