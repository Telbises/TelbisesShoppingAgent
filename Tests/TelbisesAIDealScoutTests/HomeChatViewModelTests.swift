import XCTest
@testable import TelbisesAIDealScout

@MainActor
final class HomeChatViewModelTests: XCTestCase {

    func testSendMessageAppendsUserAndAssistantMessagesOnSuccess() async {
        let payload = TestFixtures.resultsPayload(summary: "Here are 3 deals.")
        let agent = MockShoppingAgent(payload: payload, error: nil)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "hoodie"
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[0].role, ChatMessage.Role.user)
        XCTAssertEqual(viewModel.messages[0].text, "hoodie")
        XCTAssertEqual(viewModel.messages[1].role, ChatMessage.Role.assistant)
        XCTAssertEqual(viewModel.messages[1].text, "Here are 3 deals.")
        XCTAssertEqual(viewModel.latestPayload?.response.summary, "Here are 3 deals.")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSendMessageClearsInputAfterSend() async {
        let agent = MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "test query"
        await viewModel.sendMessage()

        XCTAssertTrue(viewModel.inputText.isEmpty)
    }

    func testSendMessageLiveOnlyAppendsLiveWebMarker() async {
        let agent = MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "iphone 15 pro max deals"
        await viewModel.sendMessage(liveOnly: true)

        XCTAssertEqual(agent.lastIntentText, "iphone 15 pro max deals \(AppConfig.liveWebMarker)")
    }

    func testSendMessageDefaultDoesNotAppendLiveWebMarker() async {
        let agent = MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "iphone 15 pro max deals"
        await viewModel.sendMessage()

        XCTAssertEqual(agent.lastIntentText, "iphone 15 pro max deals")
    }

    func testSendMessageSetsErrorMessageOnAgentFailure() async {
        let agent = MockShoppingAgent(payload: nil, error: TestAgentError.fail)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "hoodie"
        await viewModel.sendMessage()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Sorry, I couldn't fetch deals right now.")
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages[1].text, viewModel.errorMessage)
    }

    func testSendMessageDoesNothingWhenInputEmpty() async {
        let agent = MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil)
        let viewModel = HomeChatViewModel(agent: agent)

        viewModel.inputText = "   "
        await viewModel.sendMessage()

        XCTAssertEqual(viewModel.messages.count, 0)
    }

    func testApplyVoiceTranscriptUpdatesInputText() {
        let viewModel = HomeChatViewModel(agent: MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil))

        viewModel.applyVoiceTranscript("find used airpods pro")

        XCTAssertEqual(viewModel.inputText, "find used airpods pro")
    }

    func testSearchUsingImageBuildsQueryAndSendsLiveMessage() async {
        let payload = TestFixtures.resultsPayload(summary: "Image search results")
        let agent = MockShoppingAgent(payload: payload, error: nil)
        let viewModel = HomeChatViewModel(
            agent: agent,
            imageQueryBuilder: { _ in "used iphone 15 pro max deals" }
        )

        await viewModel.searchUsingImage(Data([0x01, 0x02]), liveOnly: true)

        XCTAssertEqual(agent.lastIntentText, "used iphone 15 pro max deals \(AppConfig.liveWebMarker)")
        XCTAssertEqual(viewModel.messages.first?.text, "used iphone 15 pro max deals")
        XCTAssertEqual(viewModel.messages.last?.text, "Image search results")
        XCTAssertTrue(viewModel.inputText.isEmpty)
    }

    func testSearchUsingImageSetsErrorWhenImageParsingFails() async {
        let agent = MockShoppingAgent(payload: TestFixtures.resultsPayload(summary: "Done"), error: nil)
        let viewModel = HomeChatViewModel(
            agent: agent,
            imageQueryBuilder: { _ in throw TestAgentError.fail }
        )

        await viewModel.searchUsingImage(Data([0x01]), liveOnly: true)

        XCTAssertEqual(viewModel.errorMessage, "Couldn't analyze the image. Please try another photo.")
        XCTAssertEqual(viewModel.messages.count, 0)
    }
}

private enum TestAgentError: Error { case fail }

private final class MockShoppingAgent: ShoppingAgent {
    let payload: ResultsPayload?
    let error: Error?
    private(set) var lastIntentText: String?

    init(payload: ResultsPayload?, error: Error?) {
        self.payload = payload
        self.error = error
    }

    func run(intentText: String) async throws -> ResultsPayload {
        lastIntentText = intentText
        if let e = error { throw e }
        guard let p = payload else { throw TestAgentError.fail }
        return p
    }
}
