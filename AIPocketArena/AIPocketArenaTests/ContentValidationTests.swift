// ContentValidationTests.swift — AI Pocket Arena

import XCTest
@testable import AIPocketArena

final class ContentValidationTests: XCTestCase {
    let contentStore = ContentStore.shared
    
    func testConceptBankValidation() {
        XCTAssertTrue(contentStore.isLoaded, "ContentStore failed to load concepts.json")
        XCTAssertGreaterThan(contentStore.concepts.count, 0, "No concepts loaded in bank")
        
        // Assert no validation errors
        XCTAssertTrue(contentStore.validationErrors.isEmpty, "Concept validation errors found: \(contentStore.validationErrors)")
    }
}
