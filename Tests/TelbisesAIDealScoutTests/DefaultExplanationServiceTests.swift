import XCTest
@testable import TelbisesAIDealScout

final class DefaultExplanationServiceTests: XCTestCase {

    var sut: DefaultExplanationService!

    override func setUp() {
        super.setUp()
        sut = DefaultExplanationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testExplainIncludesDealPriceSourceAndShipping() async {
        let deal = TestFixtures.deal(
            title: "Test Deal",
            price: 19.99,
            currency: "USD",
            shipping: "Free shipping",
            source: "StoreX"
        )
        let intent = TestFixtures.intent(query: "hoodie")

        let result = await sut.explain(deal: deal, intent: intent)

        XCTAssertTrue(result.contains("hoodie"))
        XCTAssertTrue(result.contains("StoreX"))
        XCTAssertTrue(result.contains("Free shipping"))
        XCTAssertTrue(result.contains("19.99") || result.contains("$19.99") || result.contains("20"))
    }

    func testExplainTelbisesIncludesProductTitleAndPrice() async {
        let product = TestFixtures.telbisesProduct(title: "Premium Hoodie", price: 49.99, currency: "USD")
        let intent = TestFixtures.intent(query: "hoodie")

        let result = await sut.explainTelbises(product: product, intent: intent)

        XCTAssertTrue(result.contains("Premium Hoodie"))
        XCTAssertTrue(result.contains("hoodie"))
        XCTAssertTrue(result.contains("49.99") || result.contains("$49.99") || result.contains("50"))
    }

    func testSummarizeIncludesIntentQuery() async {
        let intent = TestFixtures.intent(query: "blue jacket")
        let deals = [TestFixtures.deal()]

        let result = await sut.summarize(intent: intent, deals: deals, telbises: nil)

        XCTAssertTrue(result.contains("blue jacket"))
        XCTAssertTrue(result.contains("top deals"))
    }

    func testSummarizeAppendsTelbisesSentenceWhenTelbisesPresent() async {
        let intent = TestFixtures.intent(query: "shirt")
        let product = TestFixtures.telbisesProduct()

        let result = await sut.summarize(intent: intent, deals: [], telbises: product)

        XCTAssertTrue(result.contains("Telbises"))
        XCTAssertTrue(result.contains("matches your request"))
    }

    func testSummarizeNoTelbisesSentenceWhenTelbisesNil() async {
        let intent = TestFixtures.intent(query: "shirt")

        let result = await sut.summarize(intent: intent, deals: [], telbises: nil)

        XCTAssertFalse(result.contains("Telbises pick"))
    }
}
