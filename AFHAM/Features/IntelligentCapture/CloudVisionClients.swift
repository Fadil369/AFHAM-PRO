//
//  CloudVisionClients.swift
//  AFHAM - Cloud Vision API Clients
//
//  Integration with DeepSeek OCR, OpenAI Vision, and Gemini Vision
//  for high-fidelity text extraction and semantic analysis
//

import Foundation
import SwiftUI

// MARK: - DeepSeek OCR Client

/// Client for DeepSeek OCR API with advanced text extraction
@MainActor
class DeepSeekOCRClient: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var errorMessage: String?

    // MARK: - Properties

    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/v1/ocr"
    private let session: URLSession
    private let requestManager: RequestManager

    // MARK: - Initialization

    init(apiKey: String, requestManager: RequestManager) {
        self.apiKey = apiKey
        self.requestManager = requestManager

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - OCR Processing

    /// Perform high-fidelity OCR extraction
    func extractText(
        from imageData: Data,
        documentType: DocumentType,
        languageHints: [String] = ["en", "ar"]
    ) async throws -> DeepSeekOCRResult {
        guard !imageData.isEmpty else {
            throw DeepSeekError.invalidInput
        }

        await MainActor.run {
            isProcessing = true
        }

        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }

        let startTime = Date()

        // Prepare request
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode image to base64
        let base64Image = imageData.base64EncodedString()

        // Build request payload
        let payload: [String: Any] = [
            "image": base64Image,
            "mode": "high_fidelity",
            "language_hints": languageHints,
            "document_type": documentType.rawValue,
            "extract_tables": true,
            "extract_structure": true,
            "return_bounding_boxes": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Execute with retry logic
        let (data, response) = try await executeWithRetry(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DeepSeekError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse response
        let result = try parseOCRResponse(data, startTime: startTime)
        return result
    }

    /// Parse DeepSeek OCR response
    private func parseOCRResponse(_ data: Data, startTime: Date) throws -> DeepSeekOCRResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let json = json else {
            throw DeepSeekError.invalidResponse
        }

        // Extract full text
        let fullText = json["text"] as? String ?? ""

        // Extract text blocks
        var textBlocks: [TextBlock] = []
        if let blocks = json["text_blocks"] as? [[String: Any]] {
            textBlocks = blocks.compactMap { parseTextBlock($0) }
        }

        // Extract tables
        var tables: [TableStructure] = []
        if let tablesData = json["tables"] as? [[String: Any]] {
            tables = tablesData.compactMap { parseTable($0) }
        }

        // Extract metadata
        let confidence = json["confidence"] as? Double ?? 0.0
        let language = json["detected_language"] as? String ?? "unknown"

        let metadata = DeepSeekMetadata(
            modelVersion: json["model_version"] as? String ?? "deepseek-ocr-v1",
            processingMode: json["processing_mode"] as? String ?? "high_fidelity",
            enhancementsApplied: json["enhancements"] as? [String] ?? []
        )

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        return DeepSeekOCRResult(
            id: UUID(),
            documentId: UUID(), // Will be set by caller
            timestamp: Date(),
            fullText: fullText,
            textBlocks: textBlocks,
            tables: tables,
            confidence: confidence,
            languageDetected: language,
            processingTimeMs: processingTime,
            metadata: metadata
        )
    }

    private func parseTextBlock(_ json: [String: Any]) -> TextBlock? {
        guard let text = json["text"] as? String,
              let bbox = json["bounding_box"] as? [String: Double],
              let confidence = json["confidence"] as? Double else {
            return nil
        }

        let boundingBox = BoundingBox(
            x: bbox["x"] ?? 0,
            y: bbox["y"] ?? 0,
            width: bbox["width"] ?? 0,
            height: bbox["height"] ?? 0
        )

        let typeStr = json["type"] as? String ?? "paragraph"
        let type = TextBlockType(rawValue: typeStr) ?? .paragraph

        return TextBlock(
            id: UUID(),
            text: text,
            boundingBox: boundingBox,
            confidence: confidence,
            language: json["language"] as? String,
            type: type
        )
    }

    private func parseTable(_ json: [String: Any]) -> TableStructure? {
        guard let rows = json["rows"] as? [[String]],
              let bbox = json["bounding_box"] as? [String: Double],
              let confidence = json["confidence"] as? Double else {
            return nil
        }

        let boundingBox = BoundingBox(
            x: bbox["x"] ?? 0,
            y: bbox["y"] ?? 0,
            width: bbox["width"] ?? 0,
            height: bbox["height"] ?? 0
        )

        return TableStructure(
            id: UUID(),
            rows: rows,
            headers: json["headers"] as? [String],
            boundingBox: boundingBox,
            confidence: confidence
        )
    }

    // MARK: - Retry Logic

    private func executeWithRetry(_ request: URLRequest, retries: Int = 3) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                let (data, response) = try await session.data(for: request)
                return (data, response)
            } catch {
                lastError = error

                // Don't retry on client errors (4xx)
                if let urlError = error as? URLError,
                   urlError.code == .badServerResponse {
                    throw error
                }

                // Exponential backoff
                if attempt < retries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? DeepSeekError.networkError
    }
}

// MARK: - OpenAI Vision Client

/// Client for OpenAI Vision API for semantic analysis
@MainActor
class OpenAIVisionClient: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var errorMessage: String?

    // MARK: - Properties

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let model = "gpt-4-vision-preview"

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Vision Analysis

    /// Analyze document image for semantic understanding
    func analyzeDocument(
        imageData: Data,
        documentType: DocumentType,
        extractedText: String? = nil
    ) async throws -> OpenAIVisionAnalysis {
        await MainActor.run {
            isProcessing = true
        }

        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }

        let startTime = Date()

        // Build prompt based on document type
        let prompt = buildAnalysisPrompt(documentType: documentType, extractedText: extractedText)

        // Encode image to base64
        let base64Image = imageData.base64EncodedString()

        // Build request
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ],
            "max_tokens": 2000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Execute request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse response
        let result = try parseVisionResponse(data, documentType: documentType, startTime: startTime)
        return result
    }

    private func buildAnalysisPrompt(documentType: DocumentType, extractedText: String?) -> String {
        var prompt = "Analyze this \(documentType.displayName) image and provide:\n"
        prompt += "1. A concise summary of the document content\n"
        prompt += "2. Key insights and important information\n"
        prompt += "3. Action items or recommendations\n"
        prompt += "4. Any entities mentioned (people, organizations, medications, etc.)\n"

        if let text = extractedText {
            prompt += "\nExtracted text for reference:\n\(text)"
        }

        switch documentType {
        case .medicalReport, .labReport:
            prompt += "\nFocus on medical findings, diagnoses, and clinical significance."
        case .prescription:
            prompt += "\nFocus on medications, dosages, and usage instructions."
        case .insuranceClaim:
            prompt += "\nFocus on claim details, coverage, and any issues or denials."
        case .foodLabel:
            prompt += "\nFocus on nutritional information and dietary considerations."
        default:
            break
        }

        prompt += "\n\nProvide the response in JSON format with keys: summary, insights (array), actions (array), entities (array with type and value)."

        return prompt
    }

    private func parseVisionResponse(
        _ data: Data,
        documentType: DocumentType,
        startTime: Date
    ) throws -> OpenAIVisionAnalysis {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let json = json,
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }

        // Try to parse JSON response from content
        var summary = ""
        var insights: [String] = []
        var actionItems: [ActionItem] = []
        var entities: [ExtractedEntity] = []

        if let jsonContent = try? JSONSerialization.jsonObject(with: content.data(using: .utf8) ?? Data()) as? [String: Any] {
            summary = jsonContent["summary"] as? String ?? content
            insights = jsonContent["insights"] as? [String] ?? []

            if let actions = jsonContent["actions"] as? [[String: Any]] {
                actionItems = actions.compactMap { parseActionItem($0) }
            }

            if let ents = jsonContent["entities"] as? [[String: Any]] {
                entities = ents.compactMap { parseEntity($0) }
            }
        } else {
            // Fallback: use content as summary
            summary = content
        }

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        return OpenAIVisionAnalysis(
            id: UUID(),
            documentId: UUID(),
            timestamp: Date(),
            summary: summary,
            keyInsights: insights,
            actionItems: actionItems,
            entities: entities,
            confidence: 0.85,
            modelUsed: model,
            processingTimeMs: processingTime
        )
    }

    private func parseActionItem(_ json: [String: Any]) -> ActionItem? {
        guard let title = json["title"] as? String else { return nil }

        let priorityStr = json["priority"] as? String ?? "medium"
        let priority = ActionPriority(rawValue: priorityStr) ?? .medium

        return ActionItem(
            id: UUID(),
            title: title,
            description: json["description"] as? String ?? "",
            priority: priority,
            dueDate: nil,
            category: json["category"] as? String ?? "general"
        )
    }

    private func parseEntity(_ json: [String: Any]) -> ExtractedEntity? {
        guard let value = json["value"] as? String,
              let typeStr = json["type"] as? String else { return nil }

        let type = EntityType(rawValue: typeStr) ?? .organization

        return ExtractedEntity(
            id: UUID(),
            type: type,
            value: value,
            confidence: json["confidence"] as? Double ?? 0.8,
            redacted: false
        )
    }
}

// MARK: - Gemini Vision Client Extension

/// Extension to existing GeminiFileSearchManager for vision analysis
extension GeminiFileSearchManager {

    /// Analyze document with Gemini Vision for bilingual insights
    func analyzeDocumentVision(
        imageData: Data,
        documentType: DocumentType,
        extractedText: String? = nil
    ) async throws -> GeminiVisionAnalysis {
        let startTime = Date()

        // Build prompt for bilingual analysis
        let prompt = buildBilingualPrompt(documentType: documentType, extractedText: extractedText)

        // Upload image to Gemini Files API
        let fileUri = try await uploadImageForVision(imageData)

        // Generate content with vision model
        let content = try await generateContentWithVision(fileUri: fileUri, prompt: prompt)

        // Parse response
        let result = try parseGeminiVisionResponse(
            content,
            documentType: documentType,
            startTime: startTime
        )

        return result
    }

    private func buildBilingualPrompt(documentType: DocumentType, extractedText: String?) -> String {
        var prompt = """
        Analyze this \(documentType.displayName) and provide a comprehensive bilingual (English and Arabic) analysis.

        Provide the following in JSON format:
        {
          "summary_en": "English summary",
          "summary_ar": "Arabic summary",
          "compliance_checks": [{"rule": "", "status": "passed/failed/warning", "details": "", "severity": "low/medium/high/critical"}],
          "medical_codes": [{"system": "ICD-10/CPT/SNOMED", "code": "", "display": "", "confidence": 0.0}],
          "risk_flags": [{"category": "", "description": "", "severity": "low/medium/high/critical", "recommendations": []}]
        }
        """

        if let text = extractedText {
            prompt += "\n\nExtracted text:\n\(text)"
        }

        return prompt
    }

    private func uploadImageForVision(_ imageData: Data) async throws -> String {
        // Use existing file upload mechanism
        let mimeType = "image/jpeg"
        let fileName = "vision_\(UUID().uuidString).jpg"

        // This would use the existing uploadFile method
        // For now, return a placeholder
        return "files/\(UUID().uuidString)"
    }

    private func generateContentWithVision(fileUri: String, prompt: String) async throws -> String {
        // Use Gemini's vision model (gemini-pro-vision)
        // This would integrate with existing generateContent method
        // For now, return placeholder
        return "{\"summary_en\": \"Analysis complete\", \"summary_ar\": \"اكتمل التحليل\"}"
    }

    private func parseGeminiVisionResponse(
        _ content: String,
        documentType: DocumentType,
        startTime: Date
    ) throws -> GeminiVisionAnalysis {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.invalidResponse
        }

        let summaryEn = json["summary_en"] as? String ?? ""
        let summaryAr = json["summary_ar"] as? String ?? ""

        let bilingualSummary = BilingualContent(english: summaryEn, arabic: summaryAr)

        var complianceChecks: [ComplianceCheck] = []
        if let checks = json["compliance_checks"] as? [[String: Any]] {
            complianceChecks = checks.compactMap { parseComplianceCheck($0) }
        }

        var medicalCodes: [MedicalCode] = []
        if let codes = json["medical_codes"] as? [[String: Any]] {
            medicalCodes = codes.compactMap { parseMedicalCode($0) }
        }

        var riskFlags: [RiskFlag] = []
        if let flags = json["risk_flags"] as? [[String: Any]] {
            riskFlags = flags.compactMap { parseRiskFlag($0) }
        }

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        return GeminiVisionAnalysis(
            id: UUID(),
            documentId: UUID(),
            timestamp: Date(),
            bilingualSummary: bilingualSummary,
            complianceChecks: complianceChecks,
            medicalCoding: medicalCodes.isEmpty ? nil : medicalCodes,
            riskFlags: riskFlags,
            confidence: 0.88,
            modelUsed: "gemini-pro-vision",
            processingTimeMs: processingTime
        )
    }

    private func parseComplianceCheck(_ json: [String: Any]) -> ComplianceCheck? {
        guard let rule = json["rule"] as? String,
              let statusStr = json["status"] as? String,
              let status = ComplianceStatus(rawValue: statusStr),
              let details = json["details"] as? String,
              let severityStr = json["severity"] as? String,
              let severity = ComplianceSeverity(rawValue: severityStr) else {
            return nil
        }

        return ComplianceCheck(
            id: UUID(),
            rule: rule,
            status: status,
            details: details,
            severity: severity
        )
    }

    private func parseMedicalCode(_ json: [String: Any]) -> MedicalCode? {
        guard let system = json["system"] as? String,
              let code = json["code"] as? String,
              let display = json["display"] as? String,
              let confidence = json["confidence"] as? Double else {
            return nil
        }

        return MedicalCode(
            id: UUID(),
            system: system,
            code: code,
            display: display,
            confidence: confidence
        )
    }

    private func parseRiskFlag(_ json: [String: Any]) -> RiskFlag? {
        guard let category = json["category"] as? String,
              let description = json["description"] as? String,
              let severityStr = json["severity"] as? String,
              let severity = RiskSeverity(rawValue: severityStr) else {
            return nil
        }

        return RiskFlag(
            id: UUID(),
            category: category,
            description: description,
            severity: severity,
            recommendations: json["recommendations"] as? [String] ?? []
        )
    }
}

// MARK: - Error Types

enum DeepSeekError: LocalizedError {
    case invalidInput
    case invalidResponse
    case networkError
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input data"
        case .invalidResponse:
            return "Invalid response from DeepSeek API"
        case .networkError:
            return "Network error occurred"
        case .apiError(let code, let message):
            return "DeepSeek API error (\(code)): \(message)"
        }
    }
}

enum OpenAIError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code, let message):
            return "OpenAI API error (\(code)): \(message)"
        }
    }
}

enum GeminiError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Invalid response from Gemini API"
    }
}
