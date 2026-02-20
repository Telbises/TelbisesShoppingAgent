import Foundation

final class OpenAILiveDealScoutService: DealScoutService {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession
    private let fallback: DealScoutService
    private let allowFallback: Bool

    init(
        apiKey: String = AppConfig.aiApiKey,
        model: String = AppConfig.liveDealsModel,
        baseURL: String = AppConfig.aiBaseURL,
        session: URLSession = .shared,
        fallback: DealScoutService,
        allowFallback: Bool = AppConfig.liveDealsFallbackEnabled
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = URL(string: baseURL) ?? URL(string: "https://api.openai.com")!
        self.session = session
        self.fallback = fallback
        self.allowFallback = allowFallback
    }

    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        let liveOnly = intent.query.lowercased().contains(AppConfig.liveWebMarker)
        let mustUseLive = liveOnly || !allowFallback
        let sanitizedIntent = sanitized(intent)

        do {
            let liveDeals = try await fetchLiveDeals(for: sanitizedIntent)
            let filteredDeals = filterDealsByIntent(liveDeals, intent: sanitizedIntent)
            guard !filteredDeals.isEmpty else {
                throw NSError(
                    domain: "OpenAILiveDealScoutService",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "No relevant live results available for this query right now."]
                )
            }
            return filteredDeals
        } catch {
            if mustUseLive {
                throw error
            }
            return try await fallback.fetchDeals(for: sanitizedIntent)
        }
    }

    private func fetchLiveDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        let endpoint = baseURL.appendingPathComponent("v1/responses")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = buildPrompt(for: intent)
        let payload = LiveSearchRequest(
            model: model,
            input: prompt,
            tools: [.init(type: "web_search_preview")],
            toolChoice: "auto",
            temperature: 0.1,
            maxOutputTokens: 1100
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(
                domain: "OpenAILiveDealScoutService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI response."]
            )
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "OpenAILiveDealScoutService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI live search failed (\(http.statusCode)): \(body.prefix(240))"]
            )
        }

        return try parseDeals(from: data)
    }

    private func buildPrompt(for intent: ShoppingIntent) -> String {
        let budgetLine: String
        if let budget = intent.budget {
            budgetLine = "Budget cap: \(budget) USD."
        } else {
            budgetLine = "No strict budget cap unless the query states one."
        }

        return """
        Find current shopping deals for: "\(intent.query)".
        \(budgetLine)
        Return strict JSON only with this exact shape:
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
        - Return 4 to 8 real, currently available listings.
        - Use reputable US retailers/marketplaces.
        - Use valid product listing URLs only (no homepages).
        - Match product category strictly.
        - If query asks for used/refurbished, include used/refurbished listings.
        - Do not include clothing for electronics queries.
        - Do not output markdown or comments.
        """
    }

    private func parseDeals(from data: Data) throws -> [Deal] {
        if let directEnvelope = try? JSONDecoder().decode(DealEnvelope.self, from: data) {
            return mapDeals(from: directEnvelope)
        }

        guard let rootObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            throw NSError(
                domain: "OpenAILiveDealScoutService",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Unable to parse OpenAI response JSON."]
            )
        }

        if let payloadObject = Self.findDealsPayload(in: rootObject),
           let payloadData = try? JSONSerialization.data(withJSONObject: payloadObject, options: []),
           let payloadEnvelope = try? JSONDecoder().decode(DealEnvelope.self, from: payloadData) {
            return mapDeals(from: payloadEnvelope)
        }

        let rawText = Self.extractOutputText(from: rootObject)
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(
                domain: "OpenAILiveDealScoutService",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI returned empty output text."]
            )
        }

        let json = Self.extractJSON(from: rawText)
        let envelope = try JSONDecoder().decode(DealEnvelope.self, from: Data(json.utf8))
        return mapDeals(from: envelope)
    }

    private func mapDeals(from envelope: DealEnvelope) -> [Deal] {
        envelope.deals.compactMap { item in
            guard let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
            guard let dealURLText = item.dealURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let dealURL = URL(string: dealURLText),
                  let scheme = dealURL.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https") else { return nil }

            let source = item.source?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? inferredSource(from: dealURL)
            let shipping = item.shipping?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Shipping varies"
            let currency = item.currency?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "USD"

            let imageURL: URL?
            if let rawImageURL = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
               let parsedImageURL = URL(string: rawImageURL),
               let scheme = parsedImageURL.scheme?.lowercased(),
               (scheme == "http" || scheme == "https") {
                imageURL = parsedImageURL
            } else {
                imageURL = nil
            }

            return Deal(
                id: UUID().uuidString,
                title: title,
                price: item.decimalPrice ?? 0,
                currency: currency.uppercased(),
                shipping: shipping,
                source: source,
                imageURL: imageURL,
                dealURL: dealURL,
                isSponsored: item.isSponsored ?? false
            )
        }
    }

    private func inferredSource(from url: URL) -> String {
        let host = (url.host ?? "Unknown").lowercased()
        let trimmed = host.replacingOccurrences(of: "www.", with: "")
        return trimmed.isEmpty ? "Unknown" : trimmed.capitalized
    }

    private func filterDealsByIntent(_ deals: [Deal], intent: ShoppingIntent) -> [Deal] {
        var filtered = deals.filter { isRelevant($0, for: intent.query) }
        if filtered.isEmpty {
            filtered = deals
        }

        if let budget = intent.budget {
            let budgetAmount = decimalToDouble(budget)
            let budgeted = filtered.filter { decimalToDouble($0.price) <= (budgetAmount * 1.15) }
            if !budgeted.isEmpty {
                filtered = budgeted
            }
        }

        if requiresUsedInventory(intent.query) {
            let usedOnly = filtered.filter { isUsedLike($0) }
            if !usedOnly.isEmpty {
                filtered = usedOnly
            }
        }

        return Array(filtered.prefix(8))
    }

    private func isRelevant(_ deal: Deal, for query: String) -> Bool {
        let tokens = tokenize(query)
        guard !tokens.isEmpty else { return true }

        let haystack = "\(deal.title.lowercased()) \(deal.source.lowercased()) \(deal.dealURL.absoluteString.lowercased())"
        let overlap = tokens.filter { haystack.contains($0) }.count
        if overlap == 0 { return false }

        let queryCategory = category(for: query)
        if queryCategory == .electronics, looksLikeFashion(text: haystack) && !looksLikeElectronics(text: haystack) {
            return false
        }
        if queryCategory == .fashion, looksLikeElectronics(text: haystack) && !looksLikeFashion(text: haystack) {
            return false
        }

        return true
    }

    private func requiresUsedInventory(_ query: String) -> Bool {
        let text = query.lowercased()
        return text.contains("used") || text.contains("refurbished") || text.contains("preowned") || text.contains("renewed")
    }

    private func isUsedLike(_ deal: Deal) -> Bool {
        let text = "\(deal.title.lowercased()) \(deal.source.lowercased()) \(deal.dealURL.absoluteString.lowercased())"
        return text.contains("used") || text.contains("refurbished") || text.contains("renewed") || text.contains("preowned")
    }

    private func tokenize(_ text: String) -> [String] {
        let stopwords: Set<String> = [
            "the", "for", "with", "and", "buy", "deal", "deals", "under", "over", "best", "work", "what", "to"
        ]
        return text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }

    private enum QueryCategory {
        case electronics
        case fashion
        case generic
    }

    private func category(for query: String) -> QueryCategory {
        let text = query.lowercased()
        if looksLikeElectronics(text: text) { return .electronics }
        if looksLikeFashion(text: text) { return .fashion }
        return .generic
    }

    private func looksLikeElectronics(text: String) -> Bool {
        let keywords = [
            "iphone", "airpods", "macbook", "laptop", "gaming", "headphone", "headset", "tablet", "phone", "monitor", "gpu", "cpu", "camera", "tv"
        ]
        return keywords.contains { text.contains($0) }
    }

    private func looksLikeFashion(text: String) -> Bool {
        let keywords = [
            "dress", "fashion", "outfit", "hoodie", "shirt", "sneaker", "jacket", "jeans", "linen", "wrap"
        ]
        return keywords.contains { text.contains($0) }
    }

    private func decimalToDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private func sanitized(_ intent: ShoppingIntent) -> ShoppingIntent {
        ShoppingIntent(
            query: intent.query.replacingOccurrences(of: AppConfig.liveWebMarker, with: "").trimmingCharacters(in: .whitespacesAndNewlines),
            budget: intent.budget,
            preferences: intent.preferences
        )
    }

    private static func findDealsPayload(in value: Any) -> [String: Any]? {
        if let dictionary = value as? [String: Any] {
            if dictionary["deals"] != nil {
                return dictionary
            }
            for nested in dictionary.values {
                if let found = findDealsPayload(in: nested) {
                    return found
                }
            }
        }
        if let array = value as? [Any] {
            for item in array {
                if let found = findDealsPayload(in: item) {
                    return found
                }
            }
        }
        return nil
    }

    private static func extractOutputText(from value: Any) -> String {
        guard let root = value as? [String: Any] else { return "" }
        var chunks: [String] = []

        if let outputText = root["output_text"] {
            chunks.append(contentsOf: extractTextFragments(from: outputText))
        }

        if let outputItems = root["output"] as? [Any] {
            for item in outputItems {
                guard let itemDict = item as? [String: Any] else { continue }
                if let content = itemDict["content"] {
                    chunks.append(contentsOf: extractTextFragments(from: content))
                }
            }
        }

        return chunks.joined(separator: "\n")
    }

    private static func extractTextFragments(from value: Any) -> [String] {
        if let text = value as? String {
            return [text]
        }
        if let dictionary = value as? [String: Any] {
            if let text = dictionary["text"] as? String {
                return [text]
            }
            if let textValue = (dictionary["text"] as? [String: Any])?["value"] as? String {
                return [textValue]
            }
            var nested: [String] = []
            for item in dictionary.values {
                nested.append(contentsOf: extractTextFragments(from: item))
            }
            return nested
        }
        if let array = value as? [Any] {
            return array.flatMap { extractTextFragments(from: $0) }
        }
        return []
    }

    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = balancedJSONObjectCandidates(in: trimmed)
        if let dealsCandidate = candidates.first(where: { $0.contains("\"deals\"") }) {
            return dealsCandidate
        }

        guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") else {
            return trimmed
        }
        return String(trimmed[start...end])
    }

    private static func balancedJSONObjectCandidates(in text: String) -> [String] {
        var depth = 0
        var startIndex: String.Index?
        var results: [String] = []

        for index in text.indices {
            let character = text[index]
            if character == "{" {
                if depth == 0 {
                    startIndex = index
                }
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0, let startIndex {
                    results.append(String(text[startIndex...index]))
                }
            }
        }

        return results
    }
}

private struct LiveSearchRequest: Encodable {
    let model: String
    let input: String
    let tools: [SearchTool]
    let toolChoice: String
    let temperature: Double
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, input, tools, temperature
        case toolChoice = "tool_choice"
        case maxOutputTokens = "max_output_tokens"
    }
}

private struct SearchTool: Encodable {
    let type: String
}

private struct DealEnvelope: Decodable {
    let deals: [LiveDeal]
}

private struct LiveDeal: Decodable {
    let title: String?
    let price: PriceValue?
    let currency: String?
    let shipping: String?
    let source: String?
    let imageURL: String?
    let dealURL: String?
    let isSponsored: Bool?
    let priceText: String?

    enum CodingKeys: String, CodingKey {
        case title, price, currency, shipping, source
        case imageURL = "image_url"
        case dealURL = "deal_url"
        case isSponsored = "is_sponsored"
        case priceText = "price_text"
    }

    var decimalPrice: Decimal? {
        if let price {
            return price.decimalValue
        }
        guard let priceText else { return nil }
        let digits = priceText.filter { $0.isNumber || $0 == "." }
        return Decimal(string: digits)
    }
}

private enum PriceValue: Decodable {
    case double(Double)
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        self = .string(try container.decode(String.self))
    }

    var decimalValue: Decimal? {
        switch self {
        case .double(let value):
            return Decimal(value)
        case .int(let value):
            return Decimal(value)
        case .string(let value):
            let digits = value.filter { $0.isNumber || $0 == "." }
            return Decimal(string: digits)
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
