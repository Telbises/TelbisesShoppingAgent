import Foundation

struct AppConfig {
    private static func readEnv(_ key: String, fallback: String = "") -> String {
        let raw = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fallback
        return raw
    }

    static let shopifyDomain = readEnv("SHOPIFY_DOMAIN", fallback: "your-shop.myshopify.com")
    static let storefrontToken = readEnv("STOREFRONT_TOKEN", fallback: "STOREFRONT_TOKEN")
    static let aiApiKey = readEnv("AI_API_KEY", fallback: "AI_API_KEY")
    static let aiBaseURL = readEnv("AI_BASE_URL", fallback: "https://api.openai.com")
    static let aiModel = readEnv("AI_MODEL", fallback: "gpt-4o-mini")
    static let dealsFeedURL = readEnv("DEALS_FEED_URL")
    static let liveDealsEnabled = readEnv("LIVE_DEALS_ENABLED", fallback: "true").lowercased() != "false"

    static var hasAIKey: Bool {
        !aiApiKey.isEmpty && aiApiKey != "AI_API_KEY"
    }

    static var hasShopifyConfig: Bool {
        !shopifyDomain.isEmpty &&
        !storefrontToken.isEmpty &&
        shopifyDomain != "your-shop.myshopify.com" &&
        storefrontToken != "STOREFRONT_TOKEN"
    }
}
