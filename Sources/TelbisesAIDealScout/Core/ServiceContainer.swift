import Foundation

final class ServiceContainer {
    let intentParser: IntentParserService
    let dealScout: DealScoutService
    let telbisesCatalog: TelbisesCatalogService
    let ranking: RankingService
    let explanation: ExplanationService
    let shoppingAgent: ShoppingAgent
    let cartService: CartService

    init() {
        let mockIntent = MockIntentParserService()
        let llmProvider = AppConfig.hasAIKey ? OpenAIProvider() : nil
        self.intentParser = llmProvider.map { LLMIntentParserService(llm: $0, fallback: mockIntent) } ?? mockIntent

        let fallbackDealProvider: DealProvider
        if let url = URL(string: AppConfig.dealsFeedURL), !AppConfig.dealsFeedURL.isEmpty {
            fallbackDealProvider = RemoteDealProvider(feedURL: url)
        } else {
            fallbackDealProvider = MockDealProvider()
        }
        let fallbackDealScout = MockDealScoutService(provider: fallbackDealProvider)
        if AppConfig.hasAIKey && AppConfig.liveDealsEnabled {
            self.dealScout = OpenAILiveDealScoutService(fallback: fallbackDealScout)
        } else {
            self.dealScout = fallbackDealScout
        }

        let mockCatalog = MockTelbisesCatalogService()
        if AppConfig.hasShopifyConfig {
            let liveCatalog = ShopifyStorefrontService(domain: AppConfig.shopifyDomain, token: AppConfig.storefrontToken)
            self.telbisesCatalog = FallbackTelbisesCatalogService(primary: liveCatalog, fallback: mockCatalog)
        } else {
            self.telbisesCatalog = mockCatalog
        }

        self.ranking = DefaultRankingService()
        self.explanation = llmProvider.map { LLMExplanationService(llm: $0) } ?? DefaultExplanationService()
        self.cartService = DefaultCartService()
        self.shoppingAgent = DefaultShoppingAgent(
            intentParser: intentParser,
            dealScout: dealScout,
            telbisesCatalog: telbisesCatalog,
            ranking: ranking,
            explanation: explanation
        )
    }
}
