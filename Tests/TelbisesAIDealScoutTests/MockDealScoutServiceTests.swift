import XCTest
@testable import TelbisesAIDealScout

final class MockDealScoutServiceTests: XCTestCase {

    func testElectronicsPromptDoesNotReturnDressDeals() async throws {
        let sut = MockDealScoutService()
        let intent = ShoppingIntent(query: "iphone 15 pro max deals", budget: nil, preferences: [])

        let deals = try await sut.fetchDeals(for: intent)

        XCTAssertFalse(deals.isEmpty)
        XCTAssertFalse(deals.contains(where: { $0.title.lowercased().contains("dress") }))
        XCTAssertTrue(deals.contains(where: { $0.title.lowercased().contains("iphone") }))
    }

    func testWorkLaptopUnder1000ReturnsLaptopFirst() async throws {
        let sut = MockDealScoutService()
        let intent = ShoppingIntent(query: "work laptop under 1000", budget: Decimal(1000), preferences: [])

        let deals = try await sut.fetchDeals(for: intent)

        XCTAssertFalse(deals.isEmpty)
        XCTAssertTrue(deals.first?.title.lowercased().contains("laptop") == true)
        XCTAssertLessThanOrEqual((deals.first?.price as NSDecimalNumber?)?.doubleValue ?? 0, 1000.0)
    }

    func testUsedAirpodsPromptReturnsAirpodsDeal() async throws {
        let sut = MockDealScoutService()
        let intent = ShoppingIntent(query: "used airpods deal", budget: nil, preferences: ["used"])

        let deals = try await sut.fetchDeals(for: intent)

        XCTAssertFalse(deals.isEmpty)
        XCTAssertTrue(deals.first?.title.lowercased().contains("airpods") == true)
    }

    func testElectronicsPromptBatchNeverFallsBackToDressOnlyResults() async throws {
        let sut = MockDealScoutService()
        let prompts = [
            "used iphone 15 pro max now",
            "best work laptop under 900",
            "gaming laptop deal today",
            "used airpods pro deal"
        ]

        for prompt in prompts {
            let deals = try await sut.fetchDeals(for: ShoppingIntent(query: prompt, budget: nil, preferences: []))
            XCTAssertFalse(deals.isEmpty, "Expected non-empty deals for prompt: \(prompt)")
            XCTAssertFalse(deals.allSatisfy { $0.title.lowercased().contains("dress") }, "Dress-only results for prompt: \(prompt)")
        }
    }
}
