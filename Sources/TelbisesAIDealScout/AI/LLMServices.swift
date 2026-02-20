import Foundation

protocol LLMProvider {
    func complete(system: String, user: String) async throws -> String
}

final class OpenAIProvider: LLMProvider {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession

    init(apiKey: String = AppConfig.aiApiKey, model: String = AppConfig.aiModel, baseURL: String = AppConfig.aiBaseURL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = URL(string: baseURL) ?? URL(string: "https://api.openai.com")!
        self.session = session
    }

    func complete(system: String, user: String) async throws -> String {
        let endpoint = baseURL.appendingPathComponent("/v1/chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "OpenAIProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "LLM request failed"])
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "OpenAIProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty LLM response"])
        }
        return content
    }
}

final class LLMIntentParserService: IntentParserService {
    private let llm: LLMProvider
    private let fallback: IntentParserService

    init(llm: LLMProvider, fallback: IntentParserService = MockIntentParserService()) {
        self.llm = llm
        self.fallback = fallback
    }

    func parseIntent(from text: String) async throws -> ShoppingIntent {
        let cleanedInput = text.replacingOccurrences(of: AppConfig.liveWebMarker, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let system = "You extract shopping intent. Return strict JSON with keys: query (string), budget (number|null), preferences (string array). No markdown."
        let user = "Input: \(cleanedInput)"

        do {
            let raw = try await llm.complete(system: system, user: user)
            let json = Self.extractJSON(from: raw)
            let parsed = try JSONDecoder().decode(IntentPayload.self, from: Data(json.utf8))
            let budgetDecimal = parsed.budget.map { Decimal($0) }
            let cleanedQuery = parsed.query.replacingOccurrences(of: AppConfig.liveWebMarker, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return ShoppingIntent(query: cleanedQuery, budget: budgetDecimal, preferences: parsed.preferences)
        } catch {
            return try await fallback.parseIntent(from: cleanedInput)
        }
    }

    private static func extractJSON(from value: String) -> String {
        guard let start = value.firstIndex(of: "{"), let end = value.lastIndex(of: "}") else {
            return value
        }
        return String(value[start...end])
    }

    private struct IntentPayload: Codable {
        let query: String
        let budget: Double?
        let preferences: [String]
    }
}

final class LLMExplanationService: ExplanationService {
    private let llm: LLMProvider
    private let fallback: ExplanationService

    init(llm: LLMProvider, fallback: ExplanationService = DefaultExplanationService()) {
        self.llm = llm
        self.fallback = fallback
    }

    func explain(deal: Deal, intent: ShoppingIntent) async -> String {
        let prompt = "Intent: \(intent.query). Deal: \(deal.title), \(deal.price) \(deal.currency), shipping \(deal.shipping), source \(deal.source). Return one short sentence and stay factual."
        do {
            let text = try await llm.complete(system: "You are a transparent shopping assistant.", user: prompt)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return await fallback.explain(deal: deal, intent: intent)
        }
    }

    func explainTelbises(product: TelbisesProduct, intent: ShoppingIntent) async -> String {
        let prompt = "Intent: \(intent.query). Telbises product: \(product.title), \(product.price) \(product.currency). Explain in one short sentence why it is relevant as a premium option. Do not claim it is cheapest."
        do {
            let text = try await llm.complete(system: "You are a transparent shopping assistant.", user: prompt)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return await fallback.explainTelbises(product: product, intent: intent)
        }
    }

    func summarize(intent: ShoppingIntent, deals: [Deal], telbises: TelbisesProduct?) async -> String {
        let topDeals = deals.prefix(3).map { "\($0.title) (\($0.price) \($0.currency))" }.joined(separator: ", ")
        let telbisesText = telbises?.title ?? "none"
        let prompt = "Intent: \(intent.query). Deals: \(topDeals). Telbises: \(telbisesText). Return 1-2 concise sentences with transparent wording."
        do {
            let text = try await llm.complete(system: "You are a transparent shopping assistant.", user: prompt)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return await fallback.summarize(intent: intent, deals: deals, telbises: telbises)
        }
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}
