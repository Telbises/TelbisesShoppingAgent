import Foundation

@MainActor
final class HomeChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var latestPayload: ResultsPayload?
    @Published var errorMessage: String?

    private let agent: ShoppingAgent
    private let imageQueryBuilder: (Data) async throws -> String

    init(
        agent: ShoppingAgent,
        imageQueryBuilder: @escaping (Data) async throws -> String = { data in
            try await ImageQueryAnalyzer.query(from: data)
        }
    ) {
        self.agent = agent
        self.imageQueryBuilder = imageQueryBuilder
    }

    func applyVoiceTranscript(_ transcript: String) {
        inputText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func searchUsingImage(_ imageData: Data, liveOnly: Bool = true) async {
        errorMessage = nil
        do {
            let generatedQuery = try await imageQueryBuilder(imageData)
            inputText = generatedQuery
            await sendMessage(liveOnly: liveOnly)
        } catch {
            errorMessage = "Couldn't analyze the image. Please try another photo."
        }
    }

    func sendMessage(liveOnly: Bool = false) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        errorMessage = nil

        messages.append(ChatMessage(role: .user, text: trimmed))
        isLoading = true
        do {
            let agentInput = liveOnly ? "\(trimmed) \(AppConfig.liveWebMarker)" : trimmed
            let payload = try await agent.run(intentText: agentInput)
            latestPayload = payload
            messages.append(ChatMessage(role: .assistant, text: payload.response.summary))
        } catch {
            errorMessage = liveOnly
                ? "Live web results are unavailable right now. Check API key/model/network and try again."
                : "Sorry, I couldn't fetch deals right now."
            messages.append(ChatMessage(role: .assistant, text: errorMessage ?? ""))
        }
        isLoading = false
    }
}
