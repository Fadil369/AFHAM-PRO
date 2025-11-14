//
//  AppleVisionProcessor.swift
//  AFHAM - Apple Vision Preprocessing Pipeline
//
//  On-device text recognition, document classification, and PHI detection
//  using Apple's Vision framework for offline/low-latency processing
//

import Foundation
import SwiftUI
@preconcurrency import Vision
import CoreML
import NaturalLanguage

// MARK: - Apple Vision Processor

/// Performs on-device OCR and document analysis using Apple Vision
@MainActor
class AppleVisionProcessor: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?

    // MARK: - Properties

    private let processingQueue = DispatchQueue(label: "com.afham.vision", qos: .userInitiated)

    // MARK: - Text Recognition

    /// Perform on-device OCR using Apple Vision
    func recognizeText(from image: UIImage, languageHints: [String] = ["en-US", "ar-SA"]) async throws -> AppleVisionResult {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let startTime = Date()

        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }

        defer {
            Task { @MainActor in
                isProcessing = false
                progress = 1.0
            }
        }

        // Create text recognition request
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: VisionError.noTextRecognized)
                    return
                }

                // Extract text and build result
                var fullText = ""
                var textBlocks: [TextBlock] = []
                var totalConfidence = 0.0

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }

                    let text = topCandidate.string
                    let confidence = Double(topCandidate.confidence)

                    fullText += text + "\n"
                    totalConfidence += confidence

                    // Convert bounding box
                    let boundingBox = BoundingBox(
                        x: Double(observation.boundingBox.origin.x),
                        y: Double(observation.boundingBox.origin.y),
                        width: Double(observation.boundingBox.size.width),
                        height: Double(observation.boundingBox.size.height)
                    )

                    // Classify text block type
                    let blockType = self.classifyTextBlock(text)

                    let textBlock = TextBlock(
                        id: UUID(),
                        text: text,
                        boundingBox: boundingBox,
                        confidence: confidence,
                        language: nil,
                        type: blockType
                    )

                    textBlocks.append(textBlock)
                }

                let avgConfidence = observations.isEmpty ? 0.0 : totalConfidence / Double(observations.count)

                // Detect primary language
                let detectedLanguage = self.detectLanguage(fullText)

                let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

                let result = AppleVisionResult(
                    id: UUID(),
                    documentId: UUID(), // Will be set by caller
                    timestamp: Date(),
                    recognizedText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                    textBlocks: textBlocks,
                    confidence: avgConfidence,
                    languageDetected: detectedLanguage,
                    processingTimeMs: processingTime
                )

                continuation.resume(returning: result)
            }

            // Configure request for optimal accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languageHints

            // Enable automatic language detection
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            self.processingQueue.async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Recognize text from multiple images (batch processing)
    func recognizeTextBatch(from images: [UIImage], languageHints: [String] = ["en-US", "ar-SA"]) async throws -> [AppleVisionResult] {
        var results: [AppleVisionResult] = []

        for (index, image) in images.enumerated() {
            await MainActor.run {
                progress = Double(index) / Double(images.count)
            }

            let result = try await recognizeText(from: image, languageHints: languageHints)
            results.append(result)
        }

        return results
    }

    // MARK: - Document Classification

    /// Classify document type using on-device CoreML model
    func classifyDocumentType(from image: UIImage, text: String) async throws -> DocumentType {
        // Use text-based heuristics for classification
        let keywords = extractKeywords(from: text)

        // Medical Report
        if keywords.contains(where: { ["diagnosis", "patient", "medical", "hospital", "clinic"].contains($0.lowercased()) }) {
            return .medicalReport
        }

        // Prescription
        if keywords.contains(where: { ["medication", "prescription", "dose", "pharmacy", "rx"].contains($0.lowercased()) }) {
            return .prescription
        }

        // Lab Report
        if keywords.contains(where: { ["test", "result", "lab", "laboratory", "analysis"].contains($0.lowercased()) }) {
            return .labReport
        }

        // Insurance Claim
        if keywords.contains(where: { ["insurance", "claim", "policy", "coverage", "premium"].contains($0.lowercased()) }) {
            return .insuranceClaim
        }

        // Food Label
        if keywords.contains(where: { ["nutrition", "calories", "ingredients", "serving", "fat"].contains($0.lowercased()) }) {
            return .foodLabel
        }

        // Contract
        if keywords.contains(where: { ["agreement", "contract", "terms", "conditions", "party"].contains($0.lowercased()) }) {
            return .contract
        }

        // Spreadsheet (table detection)
        if text.contains("\t") || detectTabularStructure(text) {
            return .spreadsheet
        }

        return .generic
    }

    // MARK: - PHI Detection

    /// Detect Protected Health Information (PHI) for PDPL compliance
    func detectPHI(in text: String) async throws -> [DetectedPHI] {
        var phiElements: [DetectedPHI] = []

        // Use NaturalLanguage framework for entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        let tags: [NLTag] = [.personalName, .organizationName, .placeName]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            guard let tag = tag, tags.contains(tag) else { return true }

            let value = String(text[range])

            let phiType: PHIType
            switch tag {
            case .personalName:
                phiType = .name
            case .organizationName:
                phiType = .organization
            case .placeName:
                phiType = .location
            default:
                return true
            }

            let phi = DetectedPHI(
                id: UUID(),
                type: phiType,
                value: value,
                range: range,
                confidence: 0.8
            )

            phiElements.append(phi)
            return true
        }

        // Detect dates
        let dateDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let dateMatches = dateDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in dateMatches {
            if let range = Range(match.range, in: text) {
                let value = String(text[range])
                let phi = DetectedPHI(
                    id: UUID(),
                    type: .date,
                    value: value,
                    range: range,
                    confidence: 0.9
                )
                phiElements.append(phi)
            }
        }

        // Detect phone numbers
        let phoneDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let phoneMatches = phoneDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in phoneMatches {
            if let range = Range(match.range, in: text) {
                let value = String(text[range])
                let phi = DetectedPHI(
                    id: UUID(),
                    type: .phoneNumber,
                    value: value,
                    range: range,
                    confidence: 0.95
                )
                phiElements.append(phi)
            }
        }

        // Detect medical record numbers (pattern-based)
        let mrnPattern = "\\b(MRN|Patient ID)[:\\s]?([A-Z0-9]{6,12})\\b"
        if let mrnRegex = try? NSRegularExpression(pattern: mrnPattern, options: .caseInsensitive) {
            let mrnMatches = mrnRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in mrnMatches {
                if let range = Range(match.range, in: text) {
                    let value = String(text[range])
                    let phi = DetectedPHI(
                        id: UUID(),
                        type: .medicalRecordNumber,
                        value: value,
                        range: range,
                        confidence: 0.85
                    )
                    phiElements.append(phi)
                }
            }
        }

        // Detect national IDs (Saudi Arabia format: 10 digits)
        let idPattern = "\\b[1-2][0-9]{9}\\b"
        if let idRegex = try? NSRegularExpression(pattern: idPattern) {
            let idMatches = idRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in idMatches {
                if let range = Range(match.range, in: text) {
                    let value = String(text[range])
                    let phi = DetectedPHI(
                        id: UUID(),
                        type: .nationalId,
                        value: value,
                        range: range,
                        confidence: 0.75
                    )
                    phiElements.append(phi)
                }
            }
        }

        return phiElements
    }

    /// Redact PHI from text
    func redactPHI(in text: String, phi: [DetectedPHI]) -> String {
        var redactedText = text

        // Sort by range in reverse to maintain string indices
        let sortedPHI = phi.sorted { $0.range.lowerBound > $1.range.lowerBound }

        for element in sortedPHI {
            let redactionMask = String(repeating: "*", count: element.value.count)
            redactedText.replaceSubrange(element.range, with: redactionMask)
        }

        return redactedText
    }

    // MARK: - Helper Methods

    /// Classify text block type based on content
    private func classifyTextBlock(_ text: String) -> TextBlockType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Heading: short, may end with colon
        if trimmed.count < 50 && (trimmed.hasSuffix(":") || trimmed.uppercased() == trimmed) {
            return .heading
        }

        // List item: starts with bullet, number, or dash
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
            return .list
        }

        // Check for numeric prefix (1., 2., etc.)
        if let firstChar = trimmed.first, firstChar.isNumber {
            let components = trimmed.components(separatedBy: ".")
            if components.count >= 2, components[0].allSatisfy({ $0.isNumber }) {
                return .list
            }
        }

        return .paragraph
    }

    /// Detect primary language of text
    private func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }

        return "unknown"
    }

    /// Extract keywords from text
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var keywords: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if tag == .noun || tag == .verb {
                let keyword = String(text[range])
                keywords.append(keyword)
            }
            return true
        }

        return keywords
    }

    /// Detect tabular structure in text
    private func detectTabularStructure(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)

        // Check if multiple lines have similar number of delimiters
        let tabCounts = lines.map { $0.components(separatedBy: "\t").count }
        let avgTabCount = tabCounts.reduce(0, +) / max(tabCounts.count, 1)

        // If most lines have similar tab counts > 1, likely a table
        let similarLines = tabCounts.filter { abs($0 - avgTabCount) <= 1 }.count
        return avgTabCount > 1 && Double(similarLines) / Double(max(lines.count, 1)) > 0.7
    }

    // MARK: - Barcode Detection

    /// Detect and decode barcodes/QR codes in image
    func detectBarcodes(in image: UIImage) async throws -> [DetectedBarcode] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let barcodes = observations.compactMap { observation -> DetectedBarcode? in
                    guard let payload = observation.payloadStringValue else { return nil }

                    return DetectedBarcode(
                        id: UUID(),
                        type: observation.symbology.rawValue,
                        payload: payload,
                        boundingBox: BoundingBox(
                            x: Double(observation.boundingBox.origin.x),
                            y: Double(observation.boundingBox.origin.y),
                            width: Double(observation.boundingBox.size.width),
                            height: Double(observation.boundingBox.size.height)
                        ),
                        confidence: Double(observation.confidence)
                    )
                }

                continuation.resume(returning: barcodes)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            self.processingQueue.async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct DetectedPHI: Identifiable {
    let id: UUID
    let type: PHIType
    let value: String
    let range: Range<String.Index>
    let confidence: Double
}

enum PHIType: String {
    case name
    case nationalId
    case medicalRecordNumber
    case phoneNumber
    case email
    case address
    case date
    case organization
    case location
}

struct DetectedBarcode: Identifiable {
    let id: UUID
    let type: String
    let payload: String
    let boundingBox: BoundingBox
    let confidence: Double
}

enum VisionError: LocalizedError {
    case invalidImage
    case noTextRecognized
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextRecognized:
            return "No text recognized in image"
        case .processingFailed:
            return "Vision processing failed"
        }
    }
}
