import SwiftUI

struct HomeChatView: View {
    @ObservedObject var viewModel: HomeChatViewModel
    private let logoURL = URL(string: "https://telbises.com/cdn/shop/files/New_Telbises_Logo_Black_199d58a5-862f-453f-aa49-5d572feb8077.png?v=1658806606")
    private let starterPrompts = [
        "gaming laptop under $1200",
        "viral sneakers for everyday wear",
        "best travel carry-on for Europe"
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            promptChips

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BrandTheme.font(14, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .accessibilityLabel("Error, \(error)")
            }

            Text("Telbises products may be promoted when they are contextually relevant.")
                .font(BrandTheme.font(12, relativeTo: .caption))
                .foregroundStyle(BrandTheme.mutedInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .accessibilityLabel("Disclosure: Telbises products may be promoted when relevant.")

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        if viewModel.isLoading {
                            ProgressView("Finding deals...")
                                .font(BrandTheme.font(13, relativeTo: .caption))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(BrandTheme.mutedInk)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack(spacing: 12) {
                TextField("Ask what to buy...", text: $viewModel.inputText, axis: .vertical)
                    .font(BrandTheme.font(17, relativeTo: .body))
                    .lineLimit(1...3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BrandTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BrandTheme.border, lineWidth: 1)
                    )
                    .accessibilityLabel("Shopping intent")

                Button("Send") {
                    Task { await viewModel.sendMessage() }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Send message")
                .frame(width: 104)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(BrandTheme.surface.opacity(0.98))

            if let payload = viewModel.latestPayload {
                NavigationLink("View Results", value: AppRoute.results(payload))
                    .buttonStyle(BrandSecondaryButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .accessibilityLabel("View results")
            }
        }
        .navigationTitle("Telbises AI")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            ZStack {
                BrandTheme.heroGradient.ignoresSafeArea()
                Circle()
                    .fill(BrandTheme.accentMint.opacity(0.20))
                    .frame(width: 320, height: 320)
                    .offset(x: -120, y: -260)
                Circle()
                    .fill(BrandTheme.accentBubble.opacity(0.18))
                    .frame(width: 260, height: 260)
                    .offset(x: 150, y: -190)
                LinearGradient(
                    colors: [BrandTheme.background.opacity(0.05), BrandTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            AsyncImage(url: logoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(BrandTheme.backgroundSoft)
                        .overlay(Image(systemName: "bag").foregroundStyle(BrandTheme.ink))
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Telbises AI")
                    .font(BrandTheme.font(24, weight: .heavy, relativeTo: .title2))
                    .foregroundStyle(BrandTheme.ink)
                Text("Find what to buy, instantly.")
                    .font(BrandTheme.font(12, relativeTo: .caption))
                    .foregroundStyle(BrandTheme.mutedInk)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var promptChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(starterPrompts, id: \.self) { prompt in
                    Button(prompt) {
                        viewModel.inputText = prompt
                    }
                    .font(BrandTheme.font(12, weight: .semibold, relativeTo: .caption))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(BrandTheme.surface.opacity(0.95))
                    )
                    .overlay(
                        Capsule()
                            .stroke(BrandTheme.accentSky.opacity(0.34), lineWidth: 1)
                    )
                    .foregroundStyle(BrandTheme.ink)
                    .accessibilityLabel("Quick prompt \(prompt)")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 4)
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer() }
            Text(message.text)
                .font(BrandTheme.font(14, relativeTo: .body))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(message.role == .assistant ? BrandTheme.accentSky.opacity(0.96) : BrandTheme.surface)
                .foregroundStyle(message.role == .assistant ? Color.white : BrandTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(message.role == .assistant ? Color.clear : BrandTheme.border, lineWidth: 1)
                )
                .accessibilityLabel("\(message.role == .assistant ? "Assistant" : "User") message, \(message.text)")
            if message.role == .user { Spacer() }
        }
    }
}
