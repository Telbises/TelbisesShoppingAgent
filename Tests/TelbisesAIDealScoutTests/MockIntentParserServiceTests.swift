import XCTest
@testable import TelbisesAIDealScout

final class MockIntentParserServiceTests: XCTestCase {

    var sut: MockIntentParserService!

    override func setUp() {
        super.setUp()
        sut = MockIntentParserService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testParseIntentReturnsIntentWithQuery() async throws {
        let result = try await sut.parseIntent(from: "blue hoodie under 50")

        XCTAssertEqual(result.query, "blue hoodie under 50")
        XCTAssertNil(result.budget)
        XCTAssertTrue(result.preferences.isEmpty)
    }

    func testParseIntentPreservesInputText() async throws {
        let input = "  premium cotton shirt  "
        let result = try await sut.parseIntent(from: input)

        XCTAssertEqual(result.query, input)
    }
}
