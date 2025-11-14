// AFHAM - أفهم (Understand)
// Advanced Multimodal RAG System for iOS
// Combining Google Gemini File Search + Apple Intelligence

// MARK: - Info.plist Configuration Required
/*
Add the following to your Info.plist to fix document opening warnings:

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UISupportsDocumentBrowser</key>
<true/>
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.pdf</string>
            <string>public.text</string>
            <string>public.rtf</string>
        </array>
    </dict>
</array>
*/

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import AVFAudio
import Speech
import AudioToolbox
import Vision
import NaturalLanguage
// Translation framework is iOS 18+ only, commented out for iOS 17 compatibility
// TODO: Add @available(iOS 18.0, *) check when using translation features
// import Translation

// MARK: - BRAINSAIT: Core Configuration
struct AFHAMConfig {
    // Import from AFHAMConstants for better organization
    static let midnightBlue = AFHAMColors.midnightBlue
    static let medicalBlue = AFHAMColors.medicalBlue
    static let signalTeal = AFHAMColors.signalTeal
    static let deepOrange = AFHAMColors.deepOrange
    static let professionalGray = AFHAMColors.professionalGray
    
    static let supportedFileTypes = AFHAMConstants.Files.supportedUTTypes

    // API Configuration - Secure key management
    // SECURITY: API key stored securely in Keychain
    static var geminiAPIKey: String {
        return SecureAPIKeyManager.shared.getGeminiAPIKey() ?? ""
    }
    static let geminiModel = AFHAMConstants.API.geminiModel

    // Check if API key is configured
    static var isConfigured: Bool {
        return SecureAPIKeyManager.shared.isGeminiKeyConfigured
    }
}

// MARK: - MEDICAL: Data Models
struct DocumentMetadata: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let fileSize: Int64
    let uploadDate: Date
    let language: String // Arabic or English
    let documentType: String
    var geminiFileID: String?
    var fileSearchStoreID: String?
    var processingStatus: ProcessingStatus
    
    enum ProcessingStatus: String, Codable {
        case uploading
        case processing
        case indexed
        case ready
        case error
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let language: String
    var citations: [Citation]?
    var audioURL: URL?
}

struct Citation: Codable {
    let source: String
    let pageNumber: Int?
    let excerpt: String
}

// MARK: - AGENT: Gemini File Search Manager
@MainActor
class GeminiFileSearchManager: ObservableObject {
    @Published var documents: [DocumentMetadata] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var fileSearchStoreID: String?

    // MARK: - Retry Logic with Exponential Backoff

    /// Performs a network request with automatic retry and exponential backoff
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - operation: The async operation to perform
    /// - Returns: The result of the operation
    private func performRequestWithRetry<T>(
        maxRetries: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0

        while attempt < maxRetries {
            do {
                let result = try await operation()
                if attempt > 0 {
                    AppLogger.shared.log("Request succeeded after \(attempt) retries", level: .success)
                }
                return result
            } catch {
                lastError = error
                attempt += 1

                // Don't retry on client errors (4xx)
                if let urlError = error as? URLError {
                    let statusCode = urlError.errorCode
                    if statusCode >= 400 && statusCode < 500 {
                        AppLogger.shared.log("Client error (\(statusCode)), not retrying", level: .error)
                        throw error
                    }
                }

                // Don't retry on the last attempt
                if attempt < maxRetries {
                    // Exponential backoff: 2^attempt seconds, capped at 10 seconds
                    let delay = min(pow(2.0, Double(attempt)), 10.0)
                    AppLogger.shared.log("Request failed, retrying in \(delay)s (attempt \(attempt)/\(maxRetries))", level: .warning)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    AppLogger.shared.log("Max retries exceeded", level: .error)
                }
            }
        }

        throw lastError ?? AFHAMError.networkError("Max retries exceeded")
    }

    // BRAINSAIT: Create file search store with audit logging
    func createFileSearchStore(displayName: String) async throws -> String {
        let endpoint = "\(baseURL)/fileSearchStores?key=\(AFHAMConfig.geminiAPIKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "displayName": displayName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiAPI", code: -1)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let storeID = json["name"] as! String
        
        self.fileSearchStoreID = storeID
        return storeID
    }
    
    // MEDICAL: Upload and import file to File Search Store
    func uploadAndIndexDocument(fileURL: URL) async throws -> DocumentMetadata {
        // Check if API key is configured
        guard AFHAMConfig.isConfigured else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Gemini API key not configured. Please set GEMINI_API_KEY environment variable."
            ])
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Ensure we have a file search store
        if fileSearchStoreID == nil {
            fileSearchStoreID = try await createFileSearchStore(displayName: "AFHAM-Store-\(UUID().uuidString)")
        }
        
        // Read file data
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        
        // BILINGUAL: Detect language
        let language = detectLanguage(from: fileURL)
        
        // Upload to Gemini Files API first
        let fileID = try await uploadFileToGemini(fileData: fileData, fileName: fileName)
        
        // Import to File Search Store
        try await importFileToStore(fileID: fileID, fileName: fileName)
        
        // Create metadata
        let metadata = DocumentMetadata(
            id: UUID(),
            fileName: fileName,
            fileSize: Int64(fileData.count),
            uploadDate: Date(),
            language: language,
            documentType: fileURL.pathExtension,
            geminiFileID: fileID,
            fileSearchStoreID: fileSearchStoreID,
            processingStatus: .ready
        )
        
        documents.append(metadata)
        return metadata
    }
    
    // Upload file to Gemini Files API
    private func uploadFileToGemini(fileData: Data, fileName: String) async throws -> String {
        let endpoint = "\(baseURL)/files?key=\(AFHAMConfig.geminiAPIKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        let metadata = ["name": "files/\(fileName)"]
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        body.append("\r\n".data(using: .utf8)!)
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        return json["name"] as! String
    }
    
    // Import file to File Search Store
    private func importFileToStore(fileID: String, fileName: String) async throws {
        guard let storeID = fileSearchStoreID else {
            throw NSError(domain: "NoStore", code: -1)
        }

        let endpoint = "\(baseURL)/\(storeID):importFile?key=\(AFHAMConfig.geminiAPIKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "fileName": fileID,
            "customMetadata": [
                ["key": "originalName", "stringValue": fileName],
                ["key": "importDate", "stringValue": ISO8601DateFormatter().string(from: Date())]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ImportFailed", code: -1)
        }
    }
    
    // BILINGUAL: Detect language using NaturalLanguage framework
    private func detectLanguage(from url: URL) -> String {
        guard let text = try? String(contentsOf: url) else { return "en" }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(1000)))
        
        if let language = recognizer.dominantLanguage?.rawValue {
            return language.starts(with: "ar") ? "ar" : "en"
        }
        
        return "en"
    }
    
    // AGENT: Query with File Search (with retry logic)
    func queryDocuments(question: String, language: String) async throws -> (answer: String, citations: [Citation]) {
        // Check if API key is configured
        guard AFHAMConfig.isConfigured else {
            throw AFHAMError.apiKeyMissing
        }

        guard let storeID = fileSearchStoreID else {
            throw AFHAMError.queryFailed("No file search store available. Please upload documents first.")
        }

        // Use retry logic for the query
        return try await performRequestWithRetry {
            try await self.executeQuery(question: question, storeID: storeID)
        }
    }

    // Internal method to execute the actual query
    private func executeQuery(question: String, storeID: String) async throws -> (answer: String, citations: [Citation]) {
        let endpoint = "\(baseURL)/models/\(AFHAMConfig.geminiModel):generateContent?key=\(AFHAMConfig.geminiAPIKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AFHAMConstants.API.timeout

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": question]
                    ]
                ]
            ],
            "tools": [
                [
                    "fileSearch": [
                        "fileSearchStoreNames": [storeID]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AFHAMError.networkError("Invalid response from server")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AFHAMError.networkError("Server returned error: \(httpResponse.statusCode)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Extract answer and citations with better error handling
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let answer = firstPart["text"] as? String else {
            throw AFHAMError.queryFailed("Failed to parse response from Gemini API")
        }

        var citations: [Citation] = []
        if let groundingMetadata = firstCandidate["groundingMetadata"] as? [String: Any],
           let groundingSupports = groundingMetadata["groundingSupports"] as? [[String: Any]] {
            for support in groundingSupports {
                if let segment = support["segment"] as? [String: Any],
                   let text = segment["text"] as? String {
                    citations.append(Citation(
                        source: "Document",
                        pageNumber: nil,
                        excerpt: text
                    ))
                }
            }
        }

        return (answer, citations)
    }
}

// MARK: - AGENT: Voice Assistant Manager
@MainActor
class VoiceAssistantManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var currentLanguage: String = "ar-SA" // Default to Arabic
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    deinit {
        // Perform cleanup synchronously without calling main actor methods
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove tap safely
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End audio recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up references
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore errors during cleanup in deinit
        }
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        speechRecognizer?.delegate = self
    }
    
    // BILINGUAL: Switch language
    func switchLanguage(to language: String) {
        currentLanguage = language
        setupSpeechRecognizer()
    }
    
    // Start listening
    func startListening() async throws {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { 
            throw NSError(domain: "VoiceAssistant", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }
        
        // Request microphone permission
        let microphoneStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard microphoneStatus else {
            throw NSError(domain: "VoiceAssistant", code: 2, userInfo: [NSLocalizedDescriptionKey: "Microphone access not granted"])
        }
        
        // Stop any ongoing recognition
        await MainActor.run {
            stopListening()
        }
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw NSError(domain: "VoiceAssistant", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to configure audio session: \(error.localizedDescription)"])
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { 
            throw NSError(domain: "VoiceAssistant", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        let inputNode = audioEngine.inputNode
        
        // Remove any existing taps
        inputNode.removeTap(onBus: 0)
        
        // Get the recording format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0 else {
            throw NSError(domain: "VoiceAssistant", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
        }
        
        // Install tap on the input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            // Clean up on failure
            inputNode.removeTap(onBus: 0)
            throw NSError(domain: "VoiceAssistant", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to start audio engine: \(error.localizedDescription)"])
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    print("Speech recognition error: \(error.localizedDescription)")
                    self.stopListening()
                } else if result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
        
        await MainActor.run {
            isListening = true
        }
    }
    
    func stopListening() {
        // Stop audio engine if running
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove tap safely
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End audio recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        
        // Deactivate audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Warning: Could not deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    // BILINGUAL: Speak text
    func speak(text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
}



// MARK: - Enhanced Voice Features (Appended)
// Note: Keep old VoiceAssistantManager above for backward compatibility

// MARK: - Voice Activity Detection
class VoiceActivityDetector: ObservableObject {
    @Published var isSpeaking = false
    @Published var audioLevel: Float = 0.0

    private let threshold: Float = -50.0 // dB threshold
    private let silenceThreshold: Float = -55.0
    private var silenceDuration: TimeInterval = 0
    private let maxSilenceDuration: TimeInterval = 2.0

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelDataValue[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(rms)

        DispatchQueue.main.async {
            self.audioLevel = max(0, min(1, (db + 60) / 60))

            if db > self.threshold {
                self.isSpeaking = true
                self.silenceDuration = 0
            } else if db < self.silenceThreshold {
                self.silenceDuration += 0.02
                if self.silenceDuration > self.maxSilenceDuration {
                    self.isSpeaking = false
                }
            }
        }
    }
}

// MARK: - Voice Command Enum
enum VoiceCommand: String, CaseIterable {
    case openDocument = "افتح المستند", closeDocument = "أغلق المستند"
    case search = "ابحث", readText = "اقرأ", stopReading = "توقف"
    case nextPage = "الصفحة التالية", previousPage = "الصفحة السابقة"
    case summary = "ملخص", translate = "ترجم"
    case openDocumentEN = "open document", closeDocumentEN = "close document"
    case searchEN = "search", readTextEN = "read", stopReadingEN = "stop"
    case nextPageEN = "next page", previousPageEN = "previous page"
    case summaryEN = "summary", translateEN = "translate"

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

enum VoiceError: LocalizedError {
    case speechNotAuthorized, microphoneNotAuthorized, requestCreationFailed, invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized: return "Speech recognition not authorized"
        case .microphoneNotAuthorized: return "Microphone access not granted"
        case .requestCreationFailed: return "Could not create recognition request"
        case .invalidAudioFormat: return "Invalid audio format"
        }
    }
}

enum AudioFeedbackType {
    case begin, end, success, error
}

// Type alias for seamless migration
typealias EnhancedVoiceAssistantManager = VoiceAssistantManager
