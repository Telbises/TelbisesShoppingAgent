import XCTest
@testable import TelbisesAIDealScout

final class OpenAILiveDealScoutServiceTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.responseHandler = nil
        super.tearDown()
    }

    func testFetchDealsParsesOutputTextAndRejectsDressForElectronicsQuery() async throws {
        let payload: [String: Any] = [
            "output_text": """
            {
              "deals": [
                {
                  "title": "Apple iPhone 15 Pro Max 256GB",
                  "price": 1099.99,
                  "currency": "USD",
                  "shipping": "Free shipping",
                  "source": "Best Buy",
                  "image_url": "https://example.com/iphone.jpg",
                  "deal_url": "https://www.bestbuy.com/site/searchpage.jsp?st=iphone+15+pro+max",
                  "is_sponsored": false
                },
                {
                  "title": "Everyday Midi Dress",
                  "price": 39.99,
                  "currency": "USD",
                  "shipping": "Free shipping",
                  "source": "StyleMart",
                  "image_url": "https://example.com/dress.jpg",
                  "deal_url": "https://www.macys.com/shop/womens-clothing?id=118",
                  "is_sponsored": false
                }
              ]
            }
            """
        ]
        let session = makeSession(statusCode: 200, jsonObject: payload)
        let fallback = SpyDealScoutService()
        fallback.deals = [TestFixtures.deal(title: "Fallback Dress")]
        let sut = OpenAILiveDealScoutService(
            apiKey: "test-key",
            model: "gpt-4o-search-preview",
            baseURL: "https://api.openai.com",
            session: session,
            fallback: fallback,
            allowFallback: false
        )

        let deals = try await sut.fetchDeals(for: ShoppingIntent(query: "iphone 15 pro max deals #liveweb", budget: nil, preferences: []))

        XCTAssertEqual(deals.count, 1)
        XCTAssertTrue(deals[0].title.lowercased().contains("iphone"))
        XCTAssertEqual(fallback.fetchCount, 0)
    }

    func testFetchDealsParsesNestedOutputContent() async throws {
        let payload: [String: Any] = [
            "output": [
                [
                    "type": "message",
                    "content": [
                        [
                            "type": "text",
                            "text": "{\"deals\":[{\"title\":\"Work Laptop RTX 4060\",\"price\":899.99,\"currency\":\"USD\",\"shipping\":\"Ships in 2 days\",\"source\":\"Best Buy\",\"image_url\":\"https://example.com/laptop.jpg\",\"deal_url\":\"https://www.bestbuy.com/site/searchpage.jsp?st=work+laptop\",\"is_sponsored\":false}]}"
                        ]
                    ]
                ]
            ]
        ]
        let session = makeSession(statusCode: 200, jsonObject: payload)
        let sut = OpenAILiveDealScoutService(
            apiKey: "test-key",
            model: "gpt-4o-search-preview",
            baseURL: "https://api.openai.com",
            session: session,
            fallback: SpyDealScoutService(),
            allowFallback: false
        )

        let deals = try await sut.fetchDeals(for: ShoppingIntent(query: "work laptop under 1000 #liveweb", budget: Decimal(1000), preferences: []))

        XCTAssertEqual(deals.count, 1)
        XCTAssertTrue(deals[0].title.lowercased().contains("laptop"))
        XCTAssertLessThanOrEqual((deals[0].price as NSDecimalNumber).doubleValue, 1000.0)
    }

    func testFetchDealsFiltersForUsedWhenPromptRequestsUsed() async throws {
        let payload: [String: Any] = [
            "output_text": """
            {
              "deals": [
                {
                  "title": "Used AirPods Pro (2nd Gen)",
                  "price": 129.00,
                  "currency": "USD",
                  "shipping": "Free shipping",
                  "source": "Back Market",
                  "image_url": "https://example.com/used-airpods.jpg",
                  "deal_url": "https://www.backmarket.com/en-us/p/used-airpods-pro",
                  "is_sponsored": false
                },
                {
                  "title": "Apple AirPods Pro New",
                  "price": 189.99,
                  "currency": "USD",
                  "shipping": "Free pickup",
                  "source": "Target",
                  "image_url": "https://example.com/new-airpods.jpg",
                  "deal_url": "https://www.target.com/s?searchTerm=airpods+pro",
                  "is_sponsored": false
                }
              ]
            }
            """
        ]
        let session = makeSession(statusCode: 200, jsonObject: payload)
        let sut = OpenAILiveDealScoutService(
            apiKey: "test-key",
            model: "gpt-4o-search-preview",
            baseURL: "https://api.openai.com",
            session: session,
            fallback: SpyDealScoutService(),
            allowFallback: false
        )

        let deals = try await sut.fetchDeals(for: ShoppingIntent(query: "used airpods deal #liveweb", budget: nil, preferences: ["used"]))

        XCTAssertEqual(deals.count, 1)
        XCTAssertTrue(deals[0].title.lowercased().contains("used"))
    }

    func testFetchDealsFallsBackWhenAllowedAndLiveRequestFails() async throws {
        let session = makeSession(statusCode: 500, rawBody: Data("server error".utf8))
        let fallback = SpyDealScoutService()
        fallback.deals = [TestFixtures.deal(title: "Fallback Laptop")]
        let sut = OpenAILiveDealScoutService(
            apiKey: "test-key",
            model: "gpt-4o-search-preview",
            baseURL: "https://api.openai.com",
            session: session,
            fallback: fallback,
            allowFallback: true
        )

        let deals = try await sut.fetchDeals(for: ShoppingIntent(query: "work laptop under 1000", budget: Decimal(1000), preferences: []))

        XCTAssertEqual(deals.count, 1)
        XCTAssertEqual(deals[0].title, "Fallback Laptop")
        XCTAssertEqual(fallback.fetchCount, 1)
    }

    func testFetchDealsThrowsWhenFallbackDisabledAndLiveRequestFails() async {
        let session = makeSession(statusCode: 500, rawBody: Data("server error".utf8))
        let fallback = SpyDealScoutService()
        fallback.deals = [TestFixtures.deal(title: "Fallback Laptop")]
        let sut = OpenAILiveDealScoutService(
            apiKey: "test-key",
            model: "gpt-4o-search-preview",
            baseURL: "https://api.openai.com",
            session: session,
            fallback: fallback,
            allowFallback: false
        )

        do {
            _ = try await sut.fetchDeals(for: ShoppingIntent(query: "work laptop under 1000", budget: Decimal(1000), preferences: []))
            XCTFail("Expected live deal error")
        } catch {
            XCTAssertEqual(fallback.fetchCount, 0)
        }
    }

    func testLivePromptBatchFiltersByCategoryBudgetAndCondition() async throws {
        let scenarios: [(query: String, json: String, expectedKeyword: String, maxPrice: Double?, requireUsed: Bool)] = [
            (
                query: "used iphone 15 pro max now #liveweb",
                json: """
                {"deals":[
                  {"title":"Used iPhone 15 Pro Max 256GB","price":899.0,"currency":"USD","shipping":"Free shipping","source":"Back Market","image_url":"https://example.com/u1.jpg","deal_url":"https://www.backmarket.com/en-us/p/used-iphone-15-pro-max","is_sponsored":false},
                  {"title":"Summer Midi Dress","price":29.0,"currency":"USD","shipping":"Free shipping","source":"StyleMart","image_url":"https://example.com/d1.jpg","deal_url":"https://example.com/dress","is_sponsored":false}
                ]}
                """,
                expectedKeyword: "iphone",
                maxPrice: nil,
                requireUsed: true
            ),
            (
                query: "best work laptop under 900 #liveweb",
                json: """
                {"deals":[
                  {"title":"Dell Latitude Work Laptop","price":849.0,"currency":"USD","shipping":"2-day shipping","source":"Best Buy","image_url":"https://example.com/l1.jpg","deal_url":"https://www.bestbuy.com/site/searchpage.jsp?st=dell+latitude","is_sponsored":false},
                  {"title":"Premium Gaming Laptop","price":1299.0,"currency":"USD","shipping":"Ships in 3 days","source":"Amazon","image_url":"https://example.com/l2.jpg","deal_url":"https://www.amazon.com/s?k=gaming+laptop","is_sponsored":false}
                ]}
                """,
                expectedKeyword: "laptop",
                maxPrice: 900,
                requireUsed: false
            ),
            (
                query: "used airpods pro deal #liveweb",
                json: """
                {"deals":[
                  {"title":"Refurbished AirPods Pro 2","price":139.0,"currency":"USD","shipping":"Free shipping","source":"Back Market","image_url":"https://example.com/a1.jpg","deal_url":"https://www.backmarket.com/en-us/p/used-airpods-pro","is_sponsored":false},
                  {"title":"New AirPods Pro 2","price":189.0,"currency":"USD","shipping":"Pickup today","source":"Target","image_url":"https://example.com/a2.jpg","deal_url":"https://www.target.com/s?searchTerm=airpods+pro","is_sponsored":false}
                ]}
                """,
                expectedKeyword: "airpods",
                maxPrice: nil,
                requireUsed: true
            )
        ]

        for scenario in scenarios {
            let payload: [String: Any] = ["output_text": scenario.json]
            let session = makeSession(statusCode: 200, jsonObject: payload)
            let sut = OpenAILiveDealScoutService(
                apiKey: "test-key",
                model: "gpt-4o-search-preview",
                baseURL: "https://api.openai.com",
                session: session,
                fallback: SpyDealScoutService(),
                allowFallback: false
            )

            let deals = try await sut.fetchDeals(for: ShoppingIntent(query: scenario.query, budget: nil, preferences: []))
            XCTAssertFalse(deals.isEmpty, "Expected deals for \(scenario.query)")
            XCTAssertTrue(deals.allSatisfy { $0.title.lowercased().contains(scenario.expectedKeyword) }, "Unexpected category for \(scenario.query)")

            if let maxPrice = scenario.maxPrice {
                XCTAssertTrue(deals.allSatisfy { (NSDecimalNumber(decimal: $0.price).doubleValue) <= maxPrice * 1.15 }, "Price overflow for \(scenario.query)")
            }

            if scenario.requireUsed {
                XCTAssertTrue(deals.allSatisfy { $0.title.lowercased().contains("used") || $0.title.lowercased().contains("refurbished") || $0.dealURL.absoluteString.lowercased().contains("used") }, "Used filter missed for \(scenario.query)")
            }
        }
    }

    private func makeSession(statusCode: Int, jsonObject: [String: Any]) -> URLSession {
        let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: [])) ?? Data()
        return makeSession(statusCode: statusCode, rawBody: data)
    }

    private func makeSession(statusCode: Int, rawBody: Data) -> URLSession {
        URLProtocolStub.responseHandler = { request in
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://api.openai.com/v1/responses")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, rawBody)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}

private final class SpyDealScoutService: DealScoutService {
    var deals: [Deal] = []
    private(set) var fetchCount = 0

    func fetchDeals(for intent: ShoppingIntent) async throws -> [Deal] {
        fetchCount += 1
        return deals
    }
}

private final class URLProtocolStub: URLProtocol {
    static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = URLProtocolStub.responseHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "URLProtocolStub", code: 0))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
