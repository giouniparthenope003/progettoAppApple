import Foundation
import Speech
import AVFoundation

// MARK: - Errori

enum RecognizerError: Error, LocalizedError {
    case recognizerUnavailable
    case notAuthorizedToRecognize
    case notPermittedToRecord

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            "Il riconoscimento vocale non è disponibile in questo momento."
        case .notAuthorizedToRecognize:
            "Serve il permesso per il riconoscimento vocale (Impostazioni > Privacy)."
        case .notPermittedToRecord:
            "Serve il permesso per usare il microfono (Impostazioni > Privacy)."
        }
    }
}

// MARK: - Protocollo

nonisolated protocol SpeechToTextServiceProtocol: AnyObject {
    func authorize() async throws
    func transcribe(contextualStrings: [String]) -> AsyncThrowingStream<String, Error>
    func stopTranscribing()
}

// MARK: - Servizio (basato sull'articolo di legin098)

nonisolated final class SpeechToTextService: SpeechToTextServiceProtocol {
    private let recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    init(localeIdentifier: String = "it-IT") {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }

    // MARK: Permessi

    func authorize() async throws {
        guard recognizer != nil else { throw RecognizerError.recognizerUnavailable }

        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { throw RecognizerError.notAuthorizedToRecognize }

        let micOK = await AVAudioApplication.requestRecordPermission()
        guard micOK else { throw RecognizerError.notPermittedToRecord }
    }

    // MARK: Trascrizione in tempo reale

    func transcribe(contextualStrings: [String] = []) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.reset()
            }

            do {
                guard let recognizer, recognizer.isAvailable else {
                    throw RecognizerError.recognizerUnavailable
                }

                let (engine, request) = try Self.prepareEngine()
                request.contextualStrings = contextualStrings
                request.taskHint = .confirmation          // parole singole / risposte brevi
                if recognizer.supportsOnDeviceRecognition {
                    request.requiresOnDeviceRecognition = true   // privacy: audio dei bambini sul dispositivo
                }

                self.audioEngine = engine
                self.request = request

                self.task = recognizer.recognitionTask(with: request) { @Sendable result, error in
                    if let result {
                        continuation.yield(result.bestTranscription.formattedString)
                        if result.isFinal { continuation.finish() }
                    }
                    if let error {
                        continuation.finish(throwing: error)
                    }
                }
            } catch {
                continuation.finish(throwing: error)
                reset()
            }
        }
    }

    func stopTranscribing() {
        reset()
    }

    // MARK: Utility

    func reset() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        audioEngine = nil
    }

    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        return (audioEngine, request)
    }
}
