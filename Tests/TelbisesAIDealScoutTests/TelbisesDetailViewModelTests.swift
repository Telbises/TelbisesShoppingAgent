import XCTest
@testable import TelbisesAIDealScout

@MainActor
final class TelbisesDetailViewModelTests: XCTestCase {

    func testAvailableVariantsReturnsProductVariants() {
        let v1 = TestFixtures.telbisesVariant(id: "v1", title: "S")
        let v2 = TestFixtures.telbisesVariant(id: "v2", title: "M")
        let product = TestFixtures.telbisesProduct(variants: [v1, v2])
        let coordinator = AppCoordinator()

        let viewModel = TelbisesDetailViewModel(product: product, coordinator: coordinator)

        XCTAssertEqual(viewModel.availableVariants.count, 2)
        XCTAssertEqual(viewModel.availableVariants[0].title, "S")
        XCTAssertEqual(viewModel.availableVariants[1].title, "M")
    }

    func testCheckoutURLReturnsProductShopifyURL() {
        let url = URL(string: "https://shop.example.com/checkout")!
        let product = TestFixtures.telbisesProduct(shopifyCheckoutURL: url)
        let coordinator = AppCoordinator()

        let viewModel = TelbisesDetailViewModel(product: product, coordinator: coordinator)

        XCTAssertEqual(viewModel.checkoutURL(), url)
    }

    func testInitialQuantityIsOne() {
        let product = TestFixtures.telbisesProduct()
        let coordinator = AppCoordinator()

        let viewModel = TelbisesDetailViewModel(product: product, coordinator: coordinator)

        XCTAssertEqual(viewModel.quantity, 1)
    }

    func testSelectedVariantDefaultsToFirstAvailable() {
        let v1 = TestFixtures.telbisesVariant(id: "v1", title: "S", inStock: false)
        let v2 = TestFixtures.telbisesVariant(id: "v2", title: "M", inStock: true)
        let product = TestFixtures.telbisesProduct(variants: [v1, v2])
        let coordinator = AppCoordinator()

        let viewModel = TelbisesDetailViewModel(product: product, coordinator: coordinator)

        XCTAssertEqual(viewModel.selectedVariant.title, "M")
    }
}
