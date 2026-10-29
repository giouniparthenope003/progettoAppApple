import Foundation
import Combine

@MainActor
final class SpeechToTextViewModel: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let service: SpeechToTextServiceProtocol
    private var transcriptionTask: Task<Void, Never>?

    init(service: SpeechToTextServiceProtocol = SpeechToTextService()) {
        self.service = service
    }

    func startRecording(contextualStrings: [String] = []) {
        guard !isRecording else { return }

        transcript = ""
        errorMessage = nil
        isRecording = true

        transcriptionTask = Task {
            do {
                try await service.authorize()
                let stream = service.transcribe(contextualStrings: contextualStrings)
                for try await partial in stream {
                    transcript = partial
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            if !Task.isCancelled {
                isRecording = false
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        transcriptionTask?.cancel()
        transcriptionTask = nil
        service.stopTranscribing()
        isRecording = false
    }
}
