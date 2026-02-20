import Foundation

final class OpenAILiveDealScoutService: DealScoutService {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession
    private let fallback: DealScoutService

    init(
        apiKey: String = AppConfig.aiApiKey,
        model: String = AppConfig.aiModel,
        baseURL: String = AppConfig.aiBaseURL,
        session: URLSession = .shared,
        fallback: DealScoutService
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = URL(string: baseURL) ?? URL(string: "https://api.openai.com")!
        self.session = session
        self.fallback = fallback
    }

    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        do {
            let liveDeals = try await fetchLiveDeals(for: intent)
            if liveDeals.isEmpty {
                return try await fallback.fetchDeals(for: intent)
            }
            return liveDeals
        } catch {
            return try await fallback.fetchDeals(for: intent)
        }
    }

    private func fetchLiveDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        let endpoint = baseURL.appendingPathComponent("/v1/responses")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = """
        Find current shopping deals for: "\(intent.query)".
        Return strict JSON only with shape:
        {
          "deals": [
            {
              "title": "string",
              "price": number,
              "currency": "USD",
              "shipping": "string",
              "source": "string",
              "image_url": "https://...",
              "deal_url": "https://...",
              "is_sponsored": false
            }
          ]
        }
        Rules:
        - 3 to 6 deals max.
        - Prefer reputable US retailers.
        - Only real product listing URLs.
        - Do not output markdown.
        """

        let payload = LiveSearchRequest(
            model: model,
            input: prompt,
            tools: [.init(type: "web_search", externalWebAccess: true)],
            toolChoice: "auto",
            temperature: 0.2
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "OpenAILiveDealScoutService", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI live search request failed"])
        }

        let decoded = try JSONDecoder().decode(LiveSearchResponse.self, from: data)
        let rawText = decoded.outputText ?? decoded.firstOutputText ?? ""
        let json = Self.extractJSON(from: rawText)
        let parsed = try JSONDecoder().decode(DealEnvelope.self, from: Data(json.utf8))

        return parsed.deals.compactMap { item in
            guard let dealURL = URL(string: item.dealURL) else { return nil }
            return Deal(
                id: UUID().uuidString,
                title: item.title,
                price: Decimal(item.price),
                currency: item.currency,
                shipping: item.shipping,
                source: item.source,
                imageURL: URL(string: item.imageURL),
                dealURL: dealURL,
                isSponsored: item.isSponsored
            )
        }
    }

    private static func extractJSON(from value: String) -> String {
        guard let start = value.firstIndex(of: "{"), let end = value.lastIndex(of: "}") else {
            return value
        }
        return String(value[start...end])
    }
}

private struct LiveSearchRequest: Encodable {
    let model: String
    let input: String
    let tools: [SearchTool]
    let toolChoice: String
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model, input, tools, temperature
        case toolChoice = "tool_choice"
    }
}

private struct SearchTool: Encodable {
    let type: String
    let externalWebAccess: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case externalWebAccess = "external_web_access"
    }
}

private struct LiveSearchResponse: Decodable {
    let outputText: String?
    let output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case output
        case outputText = "output_text"
    }

    var firstOutputText: String? {
        output?
            .compactMap(\.content)
            .flatMap { $0 }
            .first(where: { $0.type == "output_text" })?
            .text
    }

    struct OutputItem: Decodable {
        let content: [ContentItem]?
    }

    struct ContentItem: Decodable {
        let type: String
        let text: String?
    }
}

private struct DealEnvelope: Decodable {
    let deals: [LiveDeal]
}

private struct LiveDeal: Decodable {
    let title: String
    let price: Double
    let currency: String
    let shipping: String
    let source: String
    let imageURL: String
    let dealURL: String
    let isSponsored: Bool

    enum CodingKeys: String, CodingKey {
        case title, price, currency, shipping, source
        case imageURL = "image_url"
        case dealURL = "deal_url"
        case isSponsored = "is_sponsored"
    }
}
