import Foundation

protocol IntentParserService {
    func parseIntent(from text: String) async throws -> ShoppingIntent
}

protocol DealScoutService {
    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal]
}

protocol TelbisesCatalogService {
    func fetchRelevantProduct(for intent: ShoppingIntent) async throws -> TelbisesProduct?
}

protocol RankingService {
    func rank(deals: [Deal], telbises: TelbisesProduct?, intent: ShoppingIntent) -> [RankedDeal]
}

protocol ExplanationService {
    func explain(deal: Deal, intent: ShoppingIntent) async -> String
    func explainTelbises(product: TelbisesProduct, intent: ShoppingIntent) async -> String
    func summarize(intent: ShoppingIntent, deals: [Deal], telbises: TelbisesProduct?) async -> String
}

protocol CartService {
    var items: [CartItem] { get }
    func add(product: TelbisesProduct, variant: TelbisesVariant, quantity: Int)
    func clear()
}

// Agent naming aliases for architecture readability and provider swap clarity.
typealias QueryUnderstandingAgent = IntentParserService
typealias CommerceSearchAgent = DealScoutService
typealias RankingEngine = RankingService
typealias ExplanationAgent = ExplanationService
