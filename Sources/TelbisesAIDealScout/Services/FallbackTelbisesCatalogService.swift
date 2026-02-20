import Foundation

final class FallbackTelbisesCatalogService: TelbisesCatalogService {
    private let primary: TelbisesCatalogService
    private let fallback: TelbisesCatalogService

    init(primary: TelbisesCatalogService, fallback: TelbisesCatalogService) {
        self.primary = primary
        self.fallback = fallback
    }

    func fetchRelevantProduct(for intent: ShoppingIntent) async throws -> TelbisesProduct? {
        do {
            let result = try await primary.fetchRelevantProduct(for: intent)
            if result != nil { return result }
        } catch {
            // Fall through to local catalog when network/API is unavailable.
        }
        return try await fallback.fetchRelevantProduct(for: intent)
    }
}
