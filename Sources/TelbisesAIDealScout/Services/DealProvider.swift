import Foundation

protocol DealProvider {
    func loadDeals() async throws -> [Deal]
}

final class RemoteDealProvider: DealProvider {
    private let feedURL: URL
    private let session: URLSession

    init(feedURL: URL, session: URLSession = .shared) {
        self.feedURL = feedURL
        self.session = session
    }

    func loadDeals() async throws -> [Deal] {
        var request = URLRequest(url: feedURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "RemoteDealProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid deal feed response"])
        }
        return try JSONDecoder().decode([Deal].self, from: data)
    }
}

final class MockDealProvider: DealProvider {
    func loadDeals() async throws -> [Deal] {
        let data = try MockDataLoader.loadJSON(named: "MockDeals")
        return try JSONDecoder().decode([Deal].self, from: data)
    }
}
