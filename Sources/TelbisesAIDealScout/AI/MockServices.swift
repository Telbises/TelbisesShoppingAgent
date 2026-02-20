import Foundation

final class MockIntentParserService: IntentParserService {
    func parseIntent(from text: String) async throws -> ShoppingIntent {
        ShoppingIntent(query: text, budget: nil, preferences: [])
    }
}

final class MockDealScoutService: DealScoutService {
    private let provider: DealProvider

    init(provider: DealProvider = MockDealProvider()) {
        self.provider = provider
    }

    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        do {
            let deals = try await provider.loadDeals()
            if deals.isEmpty { return FallbackData.deals }
            return deals
        } catch {
            return FallbackData.deals
        }
    }
}

final class MockTelbisesCatalogService: TelbisesCatalogService {
    func fetchRelevantProduct(for intent: ShoppingIntent) async throws -> TelbisesProduct? {
        let products: [TelbisesProduct]
        do {
            let data = try MockDataLoader.loadJSON(named: "MockTelbisesCatalog")
            products = try JSONDecoder().decode([TelbisesProduct].self, from: data)
        } catch {
            products = FallbackData.telbisesProducts
        }
        let tokens = intent.query.lowercased().split(separator: " ").map(String.init)
        let match = products.first { product in
            let haystack = "\(product.title.lowercased()) \(product.description.lowercased())"
            return tokens.contains { haystack.contains($0) }
        }
        return match
    }
}

final class DefaultRankingService: RankingService {
    func rank(deals: [Deal], telbises: TelbisesProduct?, intent: ShoppingIntent) -> [RankedDeal] {
        guard !deals.isEmpty else { return [] }
        let minPrice = deals.map { decimalToDouble($0.price) }.min() ?? 0
        let maxPrice = deals.map { decimalToDouble($0.price) }.max() ?? 1
        let queryTokens = tokenize(intent.query)

        return deals.map { deal in
            let price = decimalToDouble(deal.price)
            let priceRange = max(maxPrice - minPrice, 0.01)
            let normalizedPrice = (maxPrice - price) / priceRange
            let priceScore = clamp(normalizedPrice)

            let shippingLower = deal.shipping.lowercased()
            let shippingScore: Double
            if shippingLower.contains("free") {
                shippingScore = 1.0
            } else if shippingLower.contains("flat") || shippingLower.contains("2-3") || shippingLower.contains("3-5") {
                shippingScore = 0.68
            } else {
                shippingScore = 0.42
            }

            let haystack = "\(deal.title.lowercased()) \(deal.source.lowercased())"
            let overlapCount = queryTokens.filter { haystack.contains($0) }.count
            let relevanceScore = queryTokens.isEmpty ? 0.5 : clamp(Double(overlapCount) / Double(queryTokens.count))

            let trustedSources: Set<String> = ["nordstrom", "macys", "target", "amazon", "best buy", "walmart"]
            let trustScore = trustedSources.contains(where: { deal.source.lowercased().contains($0) }) ? 0.8 : 0.6

            let totalScore = clamp((relevanceScore * 0.35) + (priceScore * 0.3) + (shippingScore * 0.2) + (trustScore * 0.15))
            let reasons = [
                "Relevance \(percentage(relevanceScore))",
                "Price value \(percentage(priceScore))",
                "Shipping convenience \(percentage(shippingScore))",
                "Source confidence \(percentage(trustScore))"
            ]

            return RankedDeal(
                id: deal.id,
                deal: deal,
                breakdown: RankingBreakdown(
                    totalScore: totalScore,
                    relevanceScore: relevanceScore,
                    priceScore: priceScore,
                    shippingScore: shippingScore,
                    trustScore: trustScore,
                    reasons: reasons
                )
            )
        }.sorted { $0.breakdown.totalScore > $1.breakdown.totalScore }
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 }
    }

    private func decimalToDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    private func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}

final class DefaultExplanationService: ExplanationService {
    func explain(deal: Deal, intent: ShoppingIntent) async -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = deal.currency
        let priceStr = formatter.string(from: deal.price as NSDecimalNumber) ?? "$\(deal.price)"
        return "Matches \"\(intent.query)\": \(priceStr) at \(deal.source), \(deal.shipping)."
    }

    func explainTelbises(product: TelbisesProduct, intent: ShoppingIntent) async -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.currency
        let priceStr = formatter.string(from: product.price as NSDecimalNumber) ?? "$\(product.price)"
        return "Premium option for \"\(intent.query)\": \(product.title) at \(priceStr)."
    }

    func summarize(intent: ShoppingIntent, deals: [Deal], telbises: TelbisesProduct?) async -> String {
        var message = "Here are top deals for \"\(intent.query)\"."
        if telbises != nil {
            message += " I included a Telbises pick because it matches your request."
        }
        return message
    }
}

final class DefaultCartService: CartService, ObservableObject {
    @Published private(set) var items: [CartItem] = []

    func add(product: TelbisesProduct, variant: TelbisesVariant, quantity: Int) {
        let item = CartItem(id: UUID().uuidString, product: product, variant: variant, quantity: quantity)
        items.append(item)
    }

    func clear() {
        items.removeAll()
    }
}

enum MockDataLoader {
    static func loadJSON(named name: String) throws -> Data {
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            return try Data(contentsOf: url)
        }
        let fallbackBundle = Bundle(for: BundleMarker.self)
        if let url = fallbackBundle.url(forResource: name, withExtension: "json") {
            return try Data(contentsOf: url)
        }
        guard let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("Sources/TelbisesAIDealScout/Resources/\(name).json"),
              FileManager.default.fileExists(atPath: resourceURL.path) else {
            throw NSError(domain: "MockDataLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing mock JSON: \(name)"])
        }
        return try Data(contentsOf: resourceURL)
    }
}

private final class BundleMarker {}

private enum FallbackData {
    static let deals: [Deal] = [
        Deal(
            id: "deal-fallback-1",
            title: "Everyday Midi Dress",
            price: Decimal(string: "39.99") ?? 39.99,
            currency: "USD",
            shipping: "Free shipping over $50",
            source: "StyleMart",
            imageURL: URL(string: "https://images.pexels.com/photos/985635/pexels-photo-985635.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop"),
            dealURL: URL(string: "https://www.macys.com/shop/womens-clothing?id=118")!,
            isSponsored: false
        ),
        Deal(
            id: "deal-fallback-2",
            title: "Linen Summer Dress",
            price: Decimal(string: "54.00") ?? 54.00,
            currency: "USD",
            shipping: "$4.99 flat rate",
            source: "Urban Wardrobe",
            imageURL: URL(string: "https://images.pexels.com/photos/6311392/pexels-photo-6311392.jpeg?auto=compress&cs=tinysrgb&w=640&h=640&fit=crop"),
            dealURL: URL(string: "https://www.nordstrom.com/browse/women/clothing/dresses")!,
            isSponsored: false
        )
    ]

    static let telbisesProducts: [TelbisesProduct] = [
        TelbisesProduct(
            id: "telbises-fallback-1",
            title: "Telbises Signature Satin Dress",
            description: "A premium satin dress with limited drop sizing and artisan stitching.",
            price: Decimal(string: "129.00") ?? 129.00,
            currency: "USD",
            imageURL: URL(string: "https://cdn.shopify.com/s/files/1/0512/8195/2940/products/b521aac55ca8f58c72c7f68a0a70a8bf_10a84a1c-956b-42cc-bfee-8e4fc1a2c599_140x140.jpg?v=1661308979"),
            variants: [
                TelbisesVariant(id: "telbises-fallback-1-s", title: "Small", price: Decimal(string: "129.00") ?? 129.00, inStock: true),
                TelbisesVariant(id: "telbises-fallback-1-m", title: "Medium", price: Decimal(string: "129.00") ?? 129.00, inStock: true)
            ],
            shopifyCheckoutURL: URL(string: "https://telbises.com")!
        )
    ]
}
