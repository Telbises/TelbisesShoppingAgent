import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    let services: ServiceContainer
    let cartViewModel: CartViewModel
    let chatViewModel: HomeChatViewModel

    init() {
        self.services = ServiceContainer()
        self.cartViewModel = CartViewModel(cartService: services.cartService)
        self.chatViewModel = HomeChatViewModel(agent: services.shoppingAgent)
    }
}

enum AppRoute: Hashable {
    case results(ResultsPayload)
    case telbisesDetail(TelbisesProduct)
    case cart
}
