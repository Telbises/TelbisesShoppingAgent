import Foundation

@MainActor
final class ResultsViewModel: ObservableObject {
    let payload: ResultsPayload
    @Published var selectedURL: URL?
    @Published var isComparePresented = false
    @Published private(set) var favoriteDealIDs: Set<String> = []
    @Published private(set) var comparedDealIDs: Set<String> = []
    private let coordinator: AppCoordinator
    private let favoritesKey = "favorite.deal.ids.v1"

    init(payload: ResultsPayload, coordinator: AppCoordinator) {
        self.payload = payload
        self.coordinator = coordinator
        self.favoriteDealIDs = Self.loadIDSet(for: favoritesKey)
    }

    func openDeal(_ deal: Deal) {
        selectedURL = deal.dealURL
    }

    func openTelbises(_ product: TelbisesProduct) -> AppRoute {
        AppRoute.telbisesDetail(product)
    }

    func makeTelbisesDetailViewModel(product: TelbisesProduct) -> TelbisesDetailViewModel {
        TelbisesDetailViewModel(product: product, coordinator: coordinator)
    }

    func isFavorite(_ deal: Deal) -> Bool {
        favoriteDealIDs.contains(deal.id)
    }

    func toggleFavorite(_ deal: Deal) {
        if favoriteDealIDs.contains(deal.id) {
            favoriteDealIDs.remove(deal.id)
        } else {
            favoriteDealIDs.insert(deal.id)
        }
        Self.saveIDSet(favoriteDealIDs, for: favoritesKey)
    }

    func isCompared(_ deal: Deal) -> Bool {
        comparedDealIDs.contains(deal.id)
    }

    func toggleCompare(_ deal: Deal) {
        if comparedDealIDs.contains(deal.id) {
            comparedDealIDs.remove(deal.id)
            return
        }
        guard comparedDealIDs.count < 3 else { return }
        comparedDealIDs.insert(deal.id)
    }

    var comparedRecommendations: [Recommendation] {
        payload.response.recommendations.filter { comparedDealIDs.contains($0.deal.id) }
    }

    private static func loadIDSet(for key: String) -> Set<String> {
        let values = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return Set(values)
    }

    private static func saveIDSet(_ values: Set<String>, for key: String) {
        UserDefaults.standard.set(Array(values), forKey: key)
    }
}
