import XCTest
@testable import TelbisesAIDealScout

final class DefaultShoppingAgentTests: XCTestCase {

    func testRunReturnsPayloadWithIntentAndSummary() async throws {
        let intentParser = StubIntentParserService()
        intentParser.fixedIntent = TestFixtures.intent(query: "blue hoodie")
        let dealScout = StubDealScoutService()
        dealScout.deals = [TestFixtures.deal(id: "d1", title: "Hoodie")]
        let catalog = StubTelbisesCatalogService()
        catalog.product = nil
        let agent = DefaultShoppingAgent(
            intentParser: intentParser,
            dealScout: dealScout,
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        let payload = try await agent.run(intentText: "blue hoodie")

        XCTAssertEqual(payload.intent.query, "blue hoodie")
        XCTAssertEqual(payload.response.summary, "Stub summary")
        XCTAssertEqual(payload.response.recommendations.count, 1)
        XCTAssertNil(payload.response.telbisesRecommendation)
    }

    func testRunIncludesTelbisesRecommendationWhenQueryContainsTelbises() async throws {
        let catalog = StubTelbisesCatalogService()
        catalog.product = TestFixtures.telbisesProduct(title: "Hoodie", description: "Soft")
        let explanation = StubExplanationService()
        explanation.summarizeResult = "Summary with Telbises"
        let agent = DefaultShoppingAgent(
            intentParser: StubIntentParserService(),
            dealScout: StubDealScoutService(),
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: explanation
        )

        let payload = try await agent.run(intentText: "telbises hoodie")

        XCTAssertNotNil(payload.response.telbisesRecommendation)
        XCTAssertEqual(payload.response.telbisesRecommendation?.product.title, "Hoodie")
        XCTAssertTrue(payload.response.telbisesRecommendation?.disclosure.lowercased().contains("promoted") ?? false)
    }

    func testRunOmitsTelbisesRecommendationWhenCatalogReturnsNil() async throws {
        let catalog = StubTelbisesCatalogService()
        catalog.product = nil
        let agent = DefaultShoppingAgent(
            intentParser: StubIntentParserService(),
            dealScout: StubDealScoutService(),
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        let payload = try await agent.run(intentText: "anything")

        XCTAssertNil(payload.response.telbisesRecommendation)
    }

    func testRunOmitsTelbisesWhenQueryDoesNotMatchAndNoPremiumIntent() async throws {
        let catalog = StubTelbisesCatalogService()
        catalog.product = TestFixtures.telbisesProduct(title: "Hoodie", description: "Cotton")
        let agent = DefaultShoppingAgent(
            intentParser: StubIntentParserService(),
            dealScout: StubDealScoutService(),
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        let payload = try await agent.run(intentText: "random xyz widget")

        XCTAssertNil(payload.response.telbisesRecommendation)
    }

    func testRunIncludesTelbisesWhenQueryMatchesProductAndNoDeals() async throws {
        let catalog = StubTelbisesCatalogService()
        catalog.product = TestFixtures.telbisesProduct(title: "Hoodie", description: "Soft hoodie")
        let dealScout = StubDealScoutService()
        dealScout.deals = []
        let agent = DefaultShoppingAgent(
            intentParser: StubIntentParserService(),
            dealScout: dealScout,
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        let payload = try await agent.run(intentText: "hoodie")

        XCTAssertNotNil(payload.response.telbisesRecommendation)
    }

    func testRunIncludesTelbisesWhenPremiumKeywordInQuery() async throws {
        let catalog = StubTelbisesCatalogService()
        catalog.product = TestFixtures.telbisesProduct(title: "Shirt", description: "Cotton")
        let dealScout = StubDealScoutService()
        dealScout.deals = [TestFixtures.deal(price: 10)]
        let agent = DefaultShoppingAgent(
            intentParser: StubIntentParserService(),
            dealScout: dealScout,
            telbisesCatalog: catalog,
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        let payload = try await agent.run(intentText: "premium shirt")

        XCTAssertNotNil(payload.response.telbisesRecommendation)
    }

    func testRunPropagatesIntentParserError() async {
        let agent = DefaultShoppingAgent(
            intentParser: ThrowingIntentParserService(),
            dealScout: StubDealScoutService(),
            telbisesCatalog: StubTelbisesCatalogService(),
            ranking: StubRankingService(),
            explanation: StubExplanationService()
        )

        do {
            _ = try await agent.run(intentText: "test")
            XCTFail("Expected throw")
        } catch is TestError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private enum TestError: Error { case fail }

private final class ThrowingIntentParserService: IntentParserService {
    func parseIntent(from text: String) async throws -> ShoppingIntent {
        throw TestError.fail
    }
}
