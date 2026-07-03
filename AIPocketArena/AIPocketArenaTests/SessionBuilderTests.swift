// SessionBuilderTests.swift — AI Pocket Arena

import XCTest
@testable import AIPocketArena

final class SessionBuilderTests: XCTestCase {
    let contentStore = ContentStore.shared
    let sessionBuilder = SessionBuilder()
    
    func testSessionWeights() {
        // Prepare some mock progress records (e.g. all fully mastered)
        let records = contentStore.concepts.map { concept -> ConceptProgress in
            let prog = ConceptProgress(conceptID: concept.id)
            prog.reps = 5
            prog.easeFactor = 2.5
            prog.interval = 30.0
            prog.dueDate = Date().addingTimeInterval(86400 * 10) // Not due
            prog.recentResults = [true, true, true, true, true]
            return prog
        }
        
        let session = sessionBuilder.buildSession(
            mode: .rapidFire,
            difficulty: .medium,
            progressRecords: records,
            count: 5
        )
        
        XCTAssertEqual(session.count, 5)
    }
}
