import SwiftUI

struct AppRootView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack {
            HomeChatView(viewModel: coordinator.chatViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .results(let payload):
                        ResultsView(viewModel: ResultsViewModel(payload: payload, coordinator: coordinator))
                    case .telbisesDetail(let product):
                        TelbisesDetailView(viewModel: TelbisesDetailViewModel(product: product, coordinator: coordinator))
                    case .cart:
                        CartView(viewModel: coordinator.cartViewModel)
                    }
                }
        }
        .tint(BrandTheme.ink)
    }
}
