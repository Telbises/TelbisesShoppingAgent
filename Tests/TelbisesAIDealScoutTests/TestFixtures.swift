import Foundation
@testable import TelbisesAIDealScout

enum TestFixtures {
    static let baseURL = URL(string: "https://example.com")!

    static func deal(
        id: String = "d1",
        title: String = "Test Deal",
        price: Decimal = 29.99,
        currency: String = "USD",
        shipping: String = "Free shipping",
        source: String = "TestStore",
        imageURL: URL? = nil,
        dealURL: URL? = nil,
        isSponsored: Bool = false
    ) -> Deal {
        Deal(
            id: id,
            title: title,
            price: price,
            currency: currency,
            shipping: shipping,
            source: source,
            imageURL: imageURL ?? baseURL.appendingPathComponent("img/\(id).jpg"),
            dealURL: dealURL ?? baseURL.appendingPathComponent("deal/\(id)"),
            isSponsored: isSponsored
        )
    }

    static func telbisesVariant(
        id: String = "v1",
        title: String = "Default",
        price: Decimal = 49.99,
        inStock: Bool = true
    ) -> TelbisesVariant {
        TelbisesVariant(id: id, title: title, price: price, inStock: inStock)
    }

    static func telbisesProduct(
        id: String = "tp1",
        title: String = "Premium Hoodie",
        description: String = "Soft cotton hoodie",
        price: Decimal = 49.99,
        currency: String = "USD",
        imageURL: URL? = nil,
        variants: [TelbisesVariant]? = nil,
        shopifyCheckoutURL: URL? = nil
    ) -> TelbisesProduct {
        TelbisesProduct(
            id: id,
            title: title,
            description: description,
            price: price,
            currency: currency,
            imageURL: imageURL ?? baseURL.appendingPathComponent("product/\(id).jpg"),
            variants: variants ?? [telbisesVariant(price: price)],
            shopifyCheckoutURL: shopifyCheckoutURL ?? baseURL.appendingPathComponent("checkout")
        )
    }

    static func intent(query: String, budget: Decimal? = nil, preferences: [String] = []) -> ShoppingIntent {
        ShoppingIntent(query: query, budget: budget, preferences: preferences)
    }

    static func resultsPayload(
        query: String = "test",
        summary: String = "Test summary",
        recommendations: [Recommendation] = [],
        telbisesRecommendation: TelbisesRecommendation? = nil
    ) -> ResultsPayload {
        let intent = ShoppingIntent(query: query, budget: nil, preferences: [])
        let response = AgentResponse(
            recommendations: recommendations,
            telbisesRecommendation: telbisesRecommendation,
            summary: summary,
            citations: []
        )
        return ResultsPayload(intent: intent, response: response)
    }
}
