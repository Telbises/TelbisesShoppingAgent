import Foundation

protocol ShoppingAgent {
    func run(intentText: String) async throws -> ResultsPayload
}

final class DefaultShoppingAgent: ShoppingAgent {
    private let intentParser: IntentParserService
    private let dealScout: DealScoutService
    private let telbisesCatalog: TelbisesCatalogService
    private let ranking: RankingService
    private let explanation: ExplanationService

    init(
        intentParser: IntentParserService,
        dealScout: DealScoutService,
        telbisesCatalog: TelbisesCatalogService,
        ranking: RankingService,
        explanation: ExplanationService
    ) {
        self.intentParser = intentParser
        self.dealScout = dealScout
        self.telbisesCatalog = telbisesCatalog
        self.ranking = ranking
        self.explanation = explanation
    }

    func run(intentText: String) async throws -> ResultsPayload {
        let intent = try await intentParser.parseIntent(from: intentText)
        async let dealsTask = dealScout.fetchDeals(for: intent)
        async let telbisesTask = telbisesCatalog.fetchRelevantProduct(for: intent)

        let deals = try await dealsTask
        let telbises = try await telbisesTask

        let rankedDeals = ranking.rank(deals: deals, telbises: telbises, intent: intent)
        let recommendations = await buildRecommendations(deals: rankedDeals, intent: intent)
        let telbisesRecommendation = await buildTelbisesRecommendation(product: telbises, intent: intent, deals: rankedDeals.map(\.deal))
        let summary = await explanation.summarize(intent: intent, deals: rankedDeals.map(\.deal), telbises: telbises)
        let citations = buildCitations(rankedDeals: rankedDeals, telbises: telbises)

        return ResultsPayload(
            intent: intent,
            response: AgentResponse(
                recommendations: recommendations,
                telbisesRecommendation: telbisesRecommendation,
                summary: summary,
                citations: citations
            )
        )
    }

    private func buildRecommendations(deals: [RankedDeal], intent: ShoppingIntent) async -> [Recommendation] {
        var results: [Recommendation] = []
        for rankedDeal in deals {
            let deal = rankedDeal.deal
            let reasoning = await explanation.explain(deal: deal, intent: intent)
            let citation = SourceCitation(id: "src-\(deal.id)", title: deal.title, source: deal.source, url: deal.dealURL)
            results.append(Recommendation(
                id: UUID().uuidString,
                deal: deal,
                reasoning: reasoning,
                score: rankedDeal.breakdown,
                citations: [citation]
            ))
        }
        return results
    }

    private func buildTelbisesRecommendation(product: TelbisesProduct?, intent: ShoppingIntent, deals: [Deal]) async -> TelbisesRecommendation? {
        guard let product else { return nil }
        guard shouldShowTelbises(product: product, intent: intent, deals: deals) else { return nil }
        let reasoning = await explanation.explainTelbises(product: product, intent: intent)
        return TelbisesRecommendation(
            product: product,
            reasoning: reasoning,
            disclosure: "Promoted: Telbises is shown as a premium option only when it fits your request.",
            citations: [
                SourceCitation(
                    id: "src-telbises-\(product.id)",
                    title: product.title,
                    source: "Telbises",
                    url: product.shopifyCheckoutURL
                )
            ]
        )
    }

    private func buildCitations(rankedDeals: [RankedDeal], telbises: TelbisesProduct?) -> [SourceCitation] {
        var citations = rankedDeals.prefix(5).map { ranked in
            SourceCitation(id: "src-\(ranked.deal.id)", title: ranked.deal.title, source: ranked.deal.source, url: ranked.deal.dealURL)
        }
        if let telbises {
            citations.append(
                SourceCitation(
                    id: "src-telbises-\(telbises.id)",
                    title: telbises.title,
                    source: "Telbises",
                    url: telbises.shopifyCheckoutURL
                )
            )
        }
        return citations
    }

    private func shouldShowTelbises(product: TelbisesProduct, intent: ShoppingIntent, deals: [Deal]) -> Bool {
        let query = intent.query.lowercased()
        if query.contains("telbises") { return true }

        let premiumKeywords: [String] = ["premium", "quality", "luxury", "best", "durable", "gift", "designer"]
        let wantsPremium = premiumKeywords.contains { query.contains($0) }

        let tokens = query
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }

        let stopwords: Set<String> = ["the", "a", "an", "and", "or", "for", "to", "of", "in", "on", "with", "under", "over", "near", "me", "i", "my", "looking", "buy", "need", "want"]
        let meaningfulTokens = tokens.filter { $0.count >= 3 && !stopwords.contains($0) }

        let haystack = "\(product.title.lowercased()) \(product.description.lowercased())"
        let overlap = meaningfulTokens.filter { haystack.contains($0) }.count

        // Keep the promo contextual: require at least some match, or explicit premium intent.
        if deals.isEmpty {
            return overlap >= 1 || wantsPremium
        }

        let cheapestDealPrice = deals.map { $0.price }.min() ?? 0
        let productPrice = product.price
        let priceRatio = decimalToDouble(productPrice) / max(decimalToDouble(cheapestDealPrice), 0.01)

        // If it's much more expensive, only show it when user signals premium intent.
        if priceRatio >= 2.5 {
            return wantsPremium && overlap >= 1
        }

        // Otherwise, show when it actually matches the query reasonably well.
        return overlap >= 2 || (overlap >= 1 && wantsPremium)
    }

    private func decimalToDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
