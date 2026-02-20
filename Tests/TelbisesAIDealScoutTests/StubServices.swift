import Foundation
@testable import TelbisesAIDealScout

/// Returns a fixed intent (optional custom query).
final class StubIntentParserService: IntentParserService {
    var fixedIntent: ShoppingIntent?

    func parseIntent(from text: String) async throws -> ShoppingIntent {
        if let fixed = fixedIntent { return fixed }
        return ShoppingIntent(query: text, budget: nil, preferences: [])
    }
}

/// Returns a fixed list of deals.
final class StubDealScoutService: DealScoutService {
    var deals: [Deal] = []
    var throwError: Error?

    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        if let e = throwError { throw e }
        return deals
    }
}

/// Returns a fixed product or nil.
final class StubTelbisesCatalogService: TelbisesCatalogService {
    var product: TelbisesProduct?
    var throwError: Error?

    func fetchRelevantProduct(for intent: ShoppingIntent) async throws -> TelbisesProduct? {
        if let e = throwError { throw e }
        return product
    }
}

/// Returns deals in the order given (no re-sort).
final class StubRankingService: RankingService {
    func rank(deals: [Deal], telbises: TelbisesProduct?, intent: ShoppingIntent) -> [RankedDeal] {
        deals.map { deal in
            RankedDeal(
                id: deal.id,
                deal: deal,
                breakdown: RankingBreakdown(
                    totalScore: 0.5,
                    relevanceScore: 0.5,
                    priceScore: 0.5,
                    shippingScore: 0.5,
                    trustScore: 0.5,
                    reasons: ["Stub ranking"]
                )
            )
        }
    }
}

/// Returns fixed strings for explanation/summary.
final class StubExplanationService: ExplanationService {
    var explainResult = "Stub reasoning"
    var explainTelbisesResult = "Stub Telbises reasoning"
    var summarizeResult = "Stub summary"

    func explain(deal: Deal, intent: ShoppingIntent) async -> String { explainResult }
    func explainTelbises(product: TelbisesProduct, intent: ShoppingIntent) async -> String { explainTelbisesResult }
    func summarize(intent: ShoppingIntent, deals: [Deal], telbises: TelbisesProduct?) async -> String { summarizeResult }
}

/// CartService stub for ViewModel tests.
final class StubCartService: CartService {
    private(set) var items: [CartItem] = []
    func add(product: TelbisesProduct, variant: TelbisesVariant, quantity: Int) {
        items.append(CartItem(id: UUID().uuidString, product: product, variant: variant, quantity: quantity))
    }
    func clear() { items.removeAll() }
}
