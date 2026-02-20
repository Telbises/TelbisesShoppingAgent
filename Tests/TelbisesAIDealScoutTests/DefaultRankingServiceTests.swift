import XCTest
@testable import TelbisesAIDealScout

final class DefaultRankingServiceTests: XCTestCase {

    var sut: DefaultRankingService!

    override func setUp() {
        super.setUp()
        sut = DefaultRankingService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRankSortsDealsByBestScoreForNeutralQuery() {
        let deals = [
            TestFixtures.deal(id: "d1", price: 99),
            TestFixtures.deal(id: "d2", price: 19),
            TestFixtures.deal(id: "d3", price: 49)
        ]
        let intent = TestFixtures.intent(query: "test")

        let result = sut.rank(deals: deals, telbises: nil, intent: intent)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].deal.price, 19)
        XCTAssertEqual(result[1].deal.price, 49)
        XCTAssertEqual(result[2].deal.price, 99)
    }

    func testRankReturnsEmptyWhenNoDeals() {
        let intent = TestFixtures.intent(query: "test")

        let result = sut.rank(deals: [], telbises: nil, intent: intent)

        XCTAssertTrue(result.isEmpty)
    }

    func testRankPreservesDealIdentity() {
        let deals = [
            TestFixtures.deal(id: "a", title: "First", price: 10),
            TestFixtures.deal(id: "b", title: "Second", price: 5)
        ]
        let intent = TestFixtures.intent(query: "test")

        let result = sut.rank(deals: deals, telbises: nil, intent: intent)

        XCTAssertEqual(result[0].id, "b")
        XCTAssertEqual(result[0].deal.title, "Second")
        XCTAssertEqual(result[1].id, "a")
        XCTAssertEqual(result[1].deal.title, "First")
    }
}
