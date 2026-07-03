// SchedulerTests.swift — AI Pocket Arena

import XCTest
@testable import AIPocketArena

final class SchedulerTests: XCTestCase {
    let scheduler = SM2Scheduler()
    
    func testAgainReset() {
        let result = scheduler.schedule(
            rating: .again,
            currentInterval: 5.0,
            currentEaseFactor: 2.5,
            reps: 2,
            lapses: 0
        )
        
        XCTAssertEqual(result.newInterval, 0)
        XCTAssertLessThan(result.newEaseFactor, 2.5)
        XCTAssertLessThan(result.nextDueDate.timeIntervalSinceNow, 120) // Due in ~1 minute
    }
    
    func testGoodGraduation() {
        // First good response gets 1 day
        let res1 = scheduler.schedule(
            rating: .good,
            currentInterval: 0,
            currentEaseFactor: 2.5,
            reps: 0,
            lapses: 0
        )
        XCTAssertEqual(res1.newInterval, 1.0)
        
        // Second good response gets 6 days
        let res2 = scheduler.schedule(
            rating: .good,
            currentInterval: 1.0,
            currentEaseFactor: 2.5,
            reps: 1,
            lapses: 0
        )
        XCTAssertEqual(res2.newInterval, 6.0)
        
        // Subsequent good response scales with EF
        let res3 = scheduler.schedule(
            rating: .good,
            currentInterval: 6.0,
            currentEaseFactor: 2.5,
            reps: 2,
            lapses: 0
        )
        XCTAssertEqual(res3.newInterval, 15.0) // 6 * 2.5
    }
    
    func testEasyMultiplier() {
        let result = scheduler.schedule(
            rating: .easy,
            currentInterval: 10.0,
            currentEaseFactor: 2.5,
            reps: 3,
            lapses: 0
        )
        
        XCTAssertGreaterThan(result.newEaseFactor, 2.5)
        XCTAssertEqual(result.newInterval, 10.0 * 2.5 * 1.3) // 32.5
    }
}
