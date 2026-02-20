import Foundation

final class ShopifyStorefrontService: TelbisesCatalogService {
    private let domain: String
    private let token: String
    private let session: URLSession

    init(domain: String = AppConfig.shopifyDomain, token: String = AppConfig.storefrontToken, session: URLSession = .shared) {
        self.domain = domain
        self.token = token
        self.session = session
    }

    func fetchRelevantProduct(for intent: ShoppingIntent) async throws -> TelbisesProduct? {
        let normalizedDomain = domain.hasPrefix("http") ? domain : "https://\(domain)"
        guard let endpoint = URL(string: normalizedDomain)?.appendingPathComponent("/api/2024-10/graphql.json") else {
            throw NSError(domain: "ShopifyStorefrontService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid SHOPIFY_DOMAIN"])
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: buildQuery(for: intent)))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "ShopifyStorefrontService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Shopify API request failed"])
        }

        let decoded = try JSONDecoder().decode(StorefrontResponse.self, from: data)
        let nodes = decoded.data.products.edges.map(\.node)
        guard !nodes.isEmpty else { return nil }

        let bestNode = pickBestNode(nodes: nodes, query: intent.query) ?? nodes.first
        guard let node = bestNode else { return nil }
        return mapProduct(node: node)
    }

    private func buildQuery(for intent: ShoppingIntent) -> String {
        let sanitized = intent.query.replacingOccurrences(of: "\"", with: "")
        let escaped = sanitized.replacingOccurrences(of: "\\", with: "\\\\")
        return """
        {
          products(first: 8, query: "title:*\(escaped)* OR tag:*\(escaped)*") {
            edges {
              node {
                id
                title
                description
                onlineStoreUrl
                variants(first: 5) {
                  edges {
                    node {
                      id
                      title
                      price {
                        amount
                        currencyCode
                      }
                      availableForSale
                    }
                  }
                }
                images(first: 1) {
                  edges {
                    node { url }
                  }
                }
              }
            }
          }
        }
        """
    }

    private func pickBestNode(nodes: [StorefrontResponse.ProductNode], query: String) -> StorefrontResponse.ProductNode? {
        let tokens = query.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        guard !tokens.isEmpty else { return nodes.first }
        return nodes.max { lhs, rhs in
            let lhsHaystack = "\(lhs.title.lowercased()) \(lhs.description.lowercased())"
            let rhsHaystack = "\(rhs.title.lowercased()) \(rhs.description.lowercased())"
            let lhsScore = tokens.filter { lhsHaystack.contains($0) }.count
            let rhsScore = tokens.filter { rhsHaystack.contains($0) }.count
            return lhsScore < rhsScore
        }
    }

    private func mapProduct(node: StorefrontResponse.ProductNode) -> TelbisesProduct {
        let variants = node.variants.edges.map { edge in
            TelbisesVariant(
                id: edge.node.id,
                title: edge.node.title,
                price: Decimal(string: edge.node.price.amount) ?? 0,
                inStock: edge.node.availableForSale
            )
        }
        let firstVariantPrice = variants.first?.price ?? 0
        let currency = node.variants.edges.first?.node.price.currencyCode ?? "USD"
        let imageURL = node.images.edges.first.flatMap { URL(string: $0.node.url) }
        let fallbackStoreURL = "https://\(domain.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""))"
        let checkoutURL = URL(string: node.onlineStoreURL ?? fallbackStoreURL) ?? URL(string: "https://shopify.com")!

        return TelbisesProduct(
            id: node.id,
            title: node.title,
            description: node.description,
            price: firstVariantPrice,
            currency: currency,
            imageURL: imageURL,
            variants: variants,
            shopifyCheckoutURL: checkoutURL
        )
    }
}

private struct GraphQLRequest: Encodable {
    let query: String
}

private struct StorefrontResponse: Decodable {
    let data: DataContainer

    struct DataContainer: Decodable {
        let products: ProductConnection
    }

    struct ProductConnection: Decodable {
        let edges: [ProductEdge]
    }

    struct ProductEdge: Decodable {
        let node: ProductNode
    }

    struct ProductNode: Decodable {
        let id: String
        let title: String
        let description: String
        let onlineStoreURL: String?
        let variants: VariantConnection
        let images: ImageConnection

        enum CodingKeys: String, CodingKey {
            case id, title, description, variants, images
            case onlineStoreURL = "onlineStoreUrl"
        }
    }

    struct VariantConnection: Decodable {
        let edges: [VariantEdge]
    }

    struct VariantEdge: Decodable {
        let node: VariantNode
    }

    struct VariantNode: Decodable {
        let id: String
        let title: String
        let availableForSale: Bool
        let price: MoneyV2
    }

    struct ImageConnection: Decodable {
        let edges: [ImageEdge]
    }

    struct ImageEdge: Decodable {
        let node: ImageNode
    }

    struct ImageNode: Decodable {
        let url: String
    }

    struct MoneyV2: Decodable {
        let amount: String
        let currencyCode: String
    }
}
