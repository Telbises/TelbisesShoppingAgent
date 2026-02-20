import Foundation

@MainActor
final class HomeChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var latestPayload: ResultsPayload?
    @Published var errorMessage: String?

    private let agent: ShoppingAgent

    init(agent: ShoppingAgent) {
        self.agent = agent
    }

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        errorMessage = nil

        messages.append(ChatMessage(role: .user, text: trimmed))
        isLoading = true
        do {
            let payload = try await agent.run(intentText: trimmed)
            latestPayload = payload
            messages.append(ChatMessage(role: .assistant, text: payload.response.summary))
        } catch {
            errorMessage = "Sorry, I couldn't fetch deals right now."
            messages.append(ChatMessage(role: .assistant, text: errorMessage ?? ""))
        }
        isLoading = false
    }
}
