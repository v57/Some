import XCTest
@testable import Some

final class SomeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Some().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
