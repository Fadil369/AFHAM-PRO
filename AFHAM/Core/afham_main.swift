// AFHAM - أفهم (Understand)
// Advanced Multimodal RAG System for iOS
// Combining Google Gemini File Search + Apple Intelligence

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Speech
import Vision
import NaturalLanguage
import Translation

// MARK: - BRAINSAIT: Core Configuration
struct AFHAMConfig {
    // Import from AFHAMConstants for better organization
    static let midnightBlue = AFHAMColors.midnightBlue
    static let medicalBlue = AFHAMColors.medicalBlue
    static let signalTeal = AFHAMColors.signalTeal
    static let deepOrange = AFHAMColors.deepOrange
    static let professionalGray = AFHAMColors.professionalGray
    
    static let supportedFileTypes = AFHAMConstants.Files.supportedUTTypes
    
    // API Configuration - Store securely in production
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY" // TODO: Move to secure storage
    static let geminiModel = AFHAMConstants.API.geminiModel
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
    
    // BRAINSAIT: Create file search store with audit logging
    func createFileSearchStore(displayName: String) async throws -> String {
        let endpoint = "\(baseURL)/fileSearchStores"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(AFHAMConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        
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
        let endpoint = "\(baseURL)/files"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue(AFHAMConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        
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
        
        let endpoint = "\(baseURL)/\(storeID):importFile"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(AFHAMConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        
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
    
    // AGENT: Query with File Search
    func queryDocuments(question: String, language: String) async throws -> (answer: String, citations: [Citation]) {
        guard let storeID = fileSearchStoreID else {
            throw NSError(domain: "NoStore", code: -1)
        }
        
        let endpoint = "\(baseURL)/models/\(AFHAMConfig.geminiModel):generateContent"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(AFHAMConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        // Extract answer and citations
        let candidates = json["candidates"] as! [[String: Any]]
        let content = candidates[0]["content"] as! [String: Any]
        let parts = content["parts"] as! [[String: Any]]
        let answer = parts[0]["text"] as! String
        
        var citations: [Citation] = []
        if let groundingMetadata = candidates[0]["groundingMetadata"] as? [String: Any],
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
        // Request authorization
        let status = await SFSpeechRecognizer.requestAuthorization()
        guard status == .authorized else { return }
        
        // Stop any ongoing recognition
        stopListening()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopListening()
            }
        }
        
        isListening = true
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    // BILINGUAL: Speak text
    func speak(text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
}

// MARK: - Helper: Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
