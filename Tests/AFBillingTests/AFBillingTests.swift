import XCTest
@testable import AFBilling

final class AFBillingTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AFBilling().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}