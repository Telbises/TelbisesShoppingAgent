import Foundation

@MainActor
final class TelbisesDetailViewModel: ObservableObject {
    let product: TelbisesProduct
    @Published var selectedVariant: TelbisesVariant
    @Published var quantity: Int = 1
    @Published var showCheckout = false

    private let coordinator: AppCoordinator

    var availableVariants: [TelbisesVariant] { product.variants }

    init(product: TelbisesProduct, coordinator: AppCoordinator) {
        self.product = product
        let firstAvailable = product.variants.first(where: { $0.inStock }) ?? product.variants.first
        self.selectedVariant = firstAvailable ?? TelbisesVariant(id: "", title: "Default", price: product.price, inStock: true)
        self.coordinator = coordinator
    }

    func addToCart() {
        coordinator.cartViewModel.add(product: product, variant: selectedVariant, quantity: quantity)
    }

    func checkoutURL() -> URL {
        product.shopifyCheckoutURL
    }
}
