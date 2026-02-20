import XCTest
@testable import TelbisesAIDealScout

@MainActor
final class ResultsViewModelTests: XCTestCase {

    func testOpenDealSetsSelectedURL() {
        let payload = TestFixtures.resultsPayload()
        let coordinator = makeCoordinator()
        let viewModel = ResultsViewModel(payload: payload, coordinator: coordinator)
        let deal = TestFixtures.deal(dealURL: URL(string: "https://example.com/deal/1")!)

        viewModel.openDeal(deal)

        XCTAssertEqual(viewModel.selectedURL, deal.dealURL)
    }

    func testMakeTelbisesDetailViewModelReturnsViewModelWithProduct() {
        let product = TestFixtures.telbisesProduct(title: "Test Product")
        let payload = TestFixtures.resultsPayload(
            telbisesRecommendation: TelbisesRecommendation(
                product: product,
                reasoning: "Test",
                disclosure: "Promoted",
                citations: []
            )
        )
        let payloadWithTelbises = ResultsPayload(
            intent: payload.intent,
            response: AgentResponse(
                recommendations: payload.response.recommendations,
                telbisesRecommendation: payload.response.telbisesRecommendation,
                summary: payload.response.summary,
                citations: []
            )
        )
        let coordinator = makeCoordinator()
        let resultsVM = ResultsViewModel(payload: payloadWithTelbises, coordinator: coordinator)

        let detailVM = resultsVM.makeTelbisesDetailViewModel(product: product)

        XCTAssertEqual(detailVM.product.id, product.id)
        XCTAssertEqual(detailVM.product.title, "Test Product")
    }

    private func makeCoordinator() -> AppCoordinator {
        AppCoordinator()
    }
}
