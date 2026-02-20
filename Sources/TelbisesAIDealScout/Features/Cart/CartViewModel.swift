import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    private let cartService: DefaultCartService

    init(cartService: CartService) {
        guard let service = cartService as? DefaultCartService else {
            self.cartService = DefaultCartService()
            return
        }
        self.cartService = service
        self.items = service.items
    }

    func add(product: TelbisesProduct, variant: TelbisesVariant, quantity: Int) {
        cartService.add(product: product, variant: variant, quantity: quantity)
        items = cartService.items
    }

    func clear() {
        cartService.clear()
        items = cartService.items
    }
}
