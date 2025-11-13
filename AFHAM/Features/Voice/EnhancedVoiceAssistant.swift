// AFHAM - Enhanced Voice Assistant
// Advanced voice features with VAD, commands, and better Arabic support

import SwiftUI
import AVFoundation
import Speech
import AudioToolbox

// MARK: - Voice Activity Detection
class VoiceActivityDetector: ObservableObject {
    @Published var isSpeaking = false
    @Published var audioLevel: Float = 0.0

    private let threshold: Float = -50.0 // dB threshold
    private let silenceThreshold: Float = -55.0
    private var silenceDuration: TimeInterval = 0
    private let maxSilenceDuration: TimeInterval = 2.0 // 2 seconds of silence

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS (Root Mean Square) for audio level
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelDataValue[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(rms)

        DispatchQueue.main.async {
            self.audioLevel = max(0, min(1, (db + 60) / 60)) // Normalize to 0-1

            // Detect voice activity
            if db > self.threshold {
                self.isSpeaking = true
                self.silenceDuration = 0
            } else if db < self.silenceThreshold {
                self.silenceDuration += 0.02 // Approximate buffer duration
                if self.silenceDuration > self.maxSilenceDuration {
                    self.isSpeaking = false
                }
            }
        }
    }
}

// MARK: - Voice Command Recognition
enum VoiceCommand: String, CaseIterable {
    // Arabic commands
    case openDocument = "افتح المستند"
    case closeDocument = "أغلق المستند"
    case search = "ابحث"
    case readText = "اقرأ"
    case stopReading = "توقف"
    case nextPage = "الصفحة التالية"
    case previousPage = "الصفحة السابقة"
    case summary = "ملخص"
    case translate = "ترجم"

    // English commands
    case openDocumentEN = "open document"
    case closeDocumentEN = "close document"
    case searchEN = "search"
    case readTextEN = "read"
    case stopReadingEN = "stop"
    case nextPageEN = "next page"
    case previousPageEN = "previous page"
    case summaryEN = "summary"
    case translateEN = "translate"

    var action: String {
        switch self {
        case .openDocument, .openDocumentEN: return "open"
        case .closeDocument, .closeDocumentEN: return "close"
        case .search, .searchEN: return "search"
        case .readText, .readTextEN: return "read"
        case .stopReading, .stopReadingEN: return "stop"
        case .nextPage, .nextPageEN: return "next"
        case .previousPage, .previousPageEN: return "previous"
        case .summary, .summaryEN: return "summary"
        case .translate, .translateEN: return "translate"
        }
    }
}

// MARK: - Enhanced Voice Assistant Manager
@MainActor
class EnhancedVoiceAssistantManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var recognizedText = ""
    @Published var currentLanguage: String = "ar-SA"
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    @Published var detectedCommand: VoiceCommand?
    @Published var continuousMode = false
    @Published var autoSpeak = true
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var speechVolume: Float = 1.0

    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private let vadDetector = VoiceActivityDetector()
    private var isProcessingCommand = false
    private var lastRecognitionTime: Date?
    private let minTimeBetweenRecognitions: TimeInterval = 1.0

    // MARK: - Initialization
    override init() {
        super.init()
        setupSpeechRecognizer()
        synthesizer.delegate = self

        // Configure audio session for voice
        configureAudioSession()
    }

    deinit {
        stopListening()
    }

    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Speech Recognizer Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        speechRecognizer?.delegate = self

        // Enable on-device recognition if available
        if #available(iOS 13.0, *) {
            speechRecognizer?.supportsOnDeviceRecognition
        }
    }

    // MARK: - Language Switching
    func switchLanguage(to language: String) {
        currentLanguage = language
        setupSpeechRecognizer()

        // Play audio feedback
        playAudioFeedback(.success)

        // Announce language switch
        let message = language.starts(with: "ar") ? "تم تغيير اللغة إلى العربية" : "Language switched to English"
        if autoSpeak {
            speak(text: message, language: language)
        }
    }

    // MARK: - Start Listening
    func startListening() async throws {
        // Check permissions
        try await checkPermissions()

        // Stop any ongoing recognition
        stopListening()

        // Clear previous text
        recognizedText = ""
        errorMessage = nil

        // Play start sound
        playAudioFeedback(.begin)

        // Configure audio session for recording
        try configureRecordingSession()

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Add context for better recognition
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }

        // Setup audio engine
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0 else {
            throw VoiceError.invalidAudioFormat
        }

        // Install tap with VAD
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Process for voice activity detection
            Task { @MainActor in
                self.vadDetector.processAudioBuffer(buffer)
                self.audioLevel = self.vadDetector.audioLevel
            }

            // Send to recognition
            self.recognitionRequest?.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self.recognizedText = transcription

                    // Check for voice commands
                    self.detectVoiceCommand(in: transcription)

                    // In continuous mode, process final results automatically
                    if result.isFinal && self.continuousMode {
                        self.lastRecognitionTime = Date()
                        // Auto-restart after brief pause
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        if self.continuousMode && !self.isListening {
                            try? await self.startListening()
                        }
                    }
                }

                if let error = error {
                    self.handleRecognitionError(error)
                } else if result?.isFinal == true && !self.continuousMode {
                    self.playAudioFeedback(.success)
                    self.stopListening()
                }
            }
        }

        isListening = true
    }

    // MARK: - Stop Listening
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isListening = false

        // Play stop sound
        if !continuousMode {
            playAudioFeedback(.end)
        }
    }

    // MARK: - Voice Command Detection
    private func detectVoiceCommand(in text: String) {
        let lowercasedText = text.lowercased()

        for command in VoiceCommand.allCases {
            if lowercasedText.contains(command.rawValue.lowercased()) {
                detectedCommand = command
                executeVoiceCommand(command)
                break
            }
        }
    }

    private func executeVoiceCommand(_ command: VoiceCommand) {
        guard !isProcessingCommand else { return }
        isProcessingCommand = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Announce command recognition
        let message = currentLanguage.starts(with: "ar") ?
            "تم تنفيذ أمر: \(command.rawValue)" :
            "Executing command: \(command.rawValue)"

        if autoSpeak {
            speak(text: message, language: currentLanguage)
        }

        // Reset flag after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                isProcessingCommand = false
            }
        }
    }

    // MARK: - Text-to-Speech
    func speak(text: String, language: String, rate: Float? = nil, pitch: Float? = nil, volume: Float? = nil) {
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Select best voice for language
        if let voice = selectBestVoice(for: language) {
            utterance.voice = voice
        }

        // Apply settings
        utterance.rate = rate ?? speechRate
        utterance.pitchMultiplier = pitch ?? speechPitch
        utterance.volume = volume ?? speechVolume

        // Add pauses for natural speech
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    private func selectBestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        // Prefer enhanced/premium quality voices
        let enhancedVoice = voices.first { voice in
            voice.language.starts(with: language.prefix(2)) &&
            voice.quality == .enhanced
        }

        if let enhanced = enhancedVoice {
            return enhanced
        }

        // Fallback to default voice
        return AVSpeechSynthesisVoice(language: language)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }

    // MARK: - Permission Checking
    private func checkPermissions() async throws {
        // Check speech recognition
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            throw VoiceError.speechNotAuthorized
        }

        // Check microphone
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard micStatus else {
            throw VoiceError.microphoneNotAuthorized
        }
    }

    // MARK: - Audio Session Configuration
    private func configureRecordingSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio Feedback
    private func playAudioFeedback(_ type: AudioFeedbackType) {
        let soundID: SystemSoundID
        switch type {
        case .begin:
            soundID = 1113 // Begin recording
        case .end:
            soundID = 1114 // End recording
        case .success:
            soundID = 1057 // Success
        case .error:
            soundID = 1053 // Error
        }
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Error Handling
    private func handleRecognitionError(_ error: Error) {
        let message: String
        if currentLanguage.starts(with: "ar") {
            message = "خطأ في التعرف على الصوت: \(error.localizedDescription)"
        } else {
            message = "Speech recognition error: \(error.localizedDescription)"
        }

        errorMessage = message
        playAudioFeedback(.error)
        stopListening()
    }

    // MARK: - SFSpeechRecognizerDelegate
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                errorMessage = "Speech recognition not available"
                stopListening()
            }
        }
    }
}

// MARK: - Supporting Types
enum VoiceError: LocalizedError {
    case speechNotAuthorized
    case microphoneNotAuthorized
    case requestCreationFailed
    case invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized:
            return "Speech recognition not authorized"
        case .microphoneNotAuthorized:
            return "Microphone access not granted"
        case .requestCreationFailed:
            return "Could not create recognition request"
        case .invalidAudioFormat:
            return "Invalid audio format"
        }
    }
}

enum AudioFeedbackType {
    case begin
    case end
    case success
    case error
}

// MARK: - Voice Settings View
struct VoiceSettingsView: View {
    @ObservedObject var voiceManager: EnhancedVoiceAssistantManager
    @Environment(\.locale) var locale

    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }

    var body: some View {
        Form {
            Section(header: Text(isArabic ? "الإعدادات العامة" : "General Settings")) {
                Toggle(isArabic ? "التحدث التلقائي" : "Auto Speak", isOn: $voiceManager.autoSpeak)
                Toggle(isArabic ? "الوضع المستمر" : "Continuous Mode", isOn: $voiceManager.continuousMode)
            }

            Section(header: Text(isArabic ? "إعدادات الصوت" : "Voice Settings")) {
                VStack(alignment: .leading) {
                    Text(isArabic ? "سرعة الكلام" : "Speech Rate")
                        .font(.caption)
                    Slider(value: $voiceManager.speechRate, in: 0.0...1.0)
                }

                VStack(alignment: .leading) {
                    Text(isArabic ? "نبرة الصوت" : "Speech Pitch")
                        .font(.caption)
                    Slider(value: $voiceManager.speechPitch, in: 0.5...2.0)
                }

                VStack(alignment: .leading) {
                    Text(isArabic ? "مستوى الصوت" : "Volume")
                        .font(.caption)
                    Slider(value: $voiceManager.speechVolume, in: 0.0...1.0)
                }
            }

            Section(header: Text(isArabic ? "اختبار" : "Test")) {
                Button(action: {
                    let testText = isArabic ? "مرحباً، أنا مساعدك الصوتي" : "Hello, I am your voice assistant"
                    voiceManager.speak(text: testText, language: voiceManager.currentLanguage)
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(isArabic ? "اختبار الصوت" : "Test Voice")
                    }
                }
            }
        }
        .navigationTitle(isArabic ? "إعدادات الصوت" : "Voice Settings")
    }
}
