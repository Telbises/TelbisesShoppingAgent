import Foundation

struct ShoppingIntent: Hashable, Codable {
    let query: String
    let budget: Decimal?
    let preferences: [String]
}

struct Deal: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let price: Decimal
    let currency: String
    let shipping: String
    let source: String
    let imageURL: URL?
    let dealURL: URL
    let isSponsored: Bool
}

struct TelbisesProduct: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let price: Decimal
    let currency: String
    let imageURL: URL?
    let variants: [TelbisesVariant]
    let shopifyCheckoutURL: URL
}

struct TelbisesVariant: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let price: Decimal
    let inStock: Bool
}

struct Recommendation: Hashable, Identifiable {
    let id: String
    let deal: Deal
    let reasoning: String
    let score: RankingBreakdown
    let citations: [SourceCitation]
}

struct TelbisesRecommendation: Hashable {
    let product: TelbisesProduct
    let reasoning: String
    let disclosure: String
    let citations: [SourceCitation]
}

struct AgentResponse: Hashable {
    let recommendations: [Recommendation]
    let telbisesRecommendation: TelbisesRecommendation?
    let summary: String
    let citations: [SourceCitation]
}

struct ResultsPayload: Hashable {
    let intent: ShoppingIntent
    let response: AgentResponse
}

struct ChatMessage: Hashable, Identifiable {
    enum Role: String {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

struct CartItem: Hashable, Identifiable {
    let id: String
    let product: TelbisesProduct
    let variant: TelbisesVariant
    let quantity: Int
}

struct SourceCitation: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let source: String
    let url: URL
}

struct RankingBreakdown: Hashable {
    let totalScore: Double
    let relevanceScore: Double
    let priceScore: Double
    let shippingScore: Double
    let trustScore: Double
    let reasons: [String]
}

struct RankedDeal: Hashable, Identifiable {
    let id: String
    let deal: Deal
    let breakdown: RankingBreakdown
}
