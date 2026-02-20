import XCTest
@testable import TelbisesAIDealScout

@MainActor
final class CartViewModelTests: XCTestCase {

    func testAddIncreasesItems() {
        let cartService = DefaultCartService()
        let viewModel = CartViewModel(cartService: cartService)
        let product = TestFixtures.telbisesProduct()
        let variant = product.variants[0]

        viewModel.add(product: product, variant: variant, quantity: 2)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items[0].quantity, 2)
        XCTAssertEqual(viewModel.items[0].product.title, product.title)
    }

    func testClearEmptiesItems() {
        let cartService = DefaultCartService()
        let viewModel = CartViewModel(cartService: cartService)
        let product = TestFixtures.telbisesProduct()
        let variant = product.variants[0]

        viewModel.add(product: product, variant: variant, quantity: 1)
        XCTAssertEqual(viewModel.items.count, 1)

        viewModel.clear()
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testMultipleAddsAppendItems() {
        let cartService = DefaultCartService()
        let viewModel = CartViewModel(cartService: cartService)
        let p1 = TestFixtures.telbisesProduct(id: "p1", title: "First")
        let p2 = TestFixtures.telbisesProduct(id: "p2", title: "Second")

        viewModel.add(product: p1, variant: p1.variants[0], quantity: 1)
        viewModel.add(product: p2, variant: p2.variants[0], quantity: 1)

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.items[0].product.title, "First")
        XCTAssertEqual(viewModel.items[1].product.title, "Second")
    }
}
