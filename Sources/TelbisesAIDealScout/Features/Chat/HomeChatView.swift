import SwiftUI
import PhotosUI
import AVFoundation
import Speech
import UIKit
import Vision

struct HomeChatView: View {
    @ObservedObject var viewModel: HomeChatViewModel
    @StateObject private var voiceController = VoiceSearchController()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAnalyzingImage = false
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

            if let voiceError = voiceController.errorMessage {
                Text(voiceError)
                    .font(BrandTheme.font(14, weight: .medium, relativeTo: .subheadline))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .accessibilityLabel("Voice error, \(voiceError)")
            }

            Text("Telbises products may be promoted when they are contextually relevant.")
                .font(BrandTheme.font(12, relativeTo: .caption))
                .foregroundStyle(BrandTheme.mutedInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .accessibilityLabel("Disclosure: Telbises products may be promoted when relevant.")

            if !AppConfig.hasAIKey {
                Text("Live web deals are OFF. Add `AI_API_KEY` in Scheme environment variables.")
                    .font(BrandTheme.font(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(BrandTheme.accentWarm)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .accessibilityLabel("Live web deals are off. Add AI API key in scheme environment variables.")
            }

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

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(BrandTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(BrandTheme.border, lineWidth: 1)
                            )
                    }
                    .disabled(isAnalyzingImage || viewModel.isLoading)
                    .accessibilityLabel("Search using image")

                    Button {
                        Task {
                            await voiceController.toggleRecording { transcript in
                                viewModel.applyVoiceTranscript(transcript)
                            }
                        }
                    } label: {
                        Image(systemName: voiceController.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(voiceController.isRecording ? BrandTheme.accentBubble.opacity(0.28) : BrandTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(BrandTheme.border, lineWidth: 1)
                            )
                    }
                    .disabled(viewModel.isLoading || isAnalyzingImage)
                    .accessibilityLabel(voiceController.isRecording ? "Stop voice search" : "Start voice search")

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

                if AppConfig.hasAIKey {
                    Button("Search Live Web") {
                        Task { await viewModel.sendMessage(liveOnly: true) }
                    }
                    .buttonStyle(BrandSecondaryButtonStyle())
                    .accessibilityLabel("Search live web")
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
        .onDisappear {
            voiceController.stopRecording()
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                isAnalyzingImage = true
                defer {
                    isAnalyzingImage = false
                    selectedPhoto = nil
                }

                guard let imageData = try? await item.loadTransferable(type: Data.self) else {
                    viewModel.errorMessage = "Couldn't read the selected image."
                    return
                }

                await viewModel.searchUsingImage(imageData, liveOnly: AppConfig.hasAIKey)
            }
        }
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

@MainActor
final class VoiceSearchController: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func toggleRecording(onTranscript: @escaping (String) -> Void) async {
        if isRecording {
            stopRecording()
            return
        }

        let permissionsGranted = await requestPermissions()
        guard permissionsGranted else {
            errorMessage = "Voice permissions are required. Enable Speech Recognition and Microphone access."
            return
        }

        do {
            try startRecording(onTranscript: onTranscript)
        } catch {
            stopRecording()
            errorMessage = "Couldn't start voice search. Please try again."
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }

    private func requestPermissions() async -> Bool {
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAuthorized else { return false }

        let micAuthorized = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return micAuthorized
    }

    private func startRecording(onTranscript: @escaping (String) -> Void) throws {
        errorMessage = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        guard let speechRecognizer else {
            throw NSError(domain: "VoiceSearchController", code: 1)
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                Task { @MainActor in
                    onTranscript(result.bestTranscription.formattedString)
                    if result.isFinal {
                        self.stopRecording()
                    }
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stopRecording()
                    self.errorMessage = "Voice search failed. Please try again."
                }
            }
        }
    }
}

enum ImageQueryAnalyzer {
    static func query(from imageData: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let request = VNClassifyImageRequest()
            let handler = try makeHandler(from: imageData)
            try handler.perform([request])

            let labels = (request.results ?? [])
                .filter { $0.confidence >= 0.18 }
                .prefix(4)
                .map { normalizeIdentifier($0.identifier) }
                .filter { !$0.isEmpty }

            guard !labels.isEmpty else {
                return "find similar product deals online"
            }

            return "find best deals for \(labels.joined(separator: ", "))"
        }.value
    }

    private static func makeHandler(from imageData: Data) throws -> VNImageRequestHandler {
        if let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage {
            return VNImageRequestHandler(cgImage: cgImage, options: [:])
        }

        if let ciImage = CIImage(data: imageData) {
            return VNImageRequestHandler(ciImage: ciImage, options: [:])
        }

        throw NSError(domain: "ImageQueryAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported image data"])
    }

    private static func normalizeIdentifier(_ identifier: String) -> String {
        identifier
            .components(separatedBy: ",")
            .first?
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}
