//
//  IntelligentCaptureManager.swift
//  AFHAM - Intelligent Capture Orchestration
//
//  Main orchestrator for multimodal document capture and analysis
//  Coordinates camera, OCR, vision APIs, and compliance
//

import Foundation
import SwiftUI
import Combine

// MARK: - Intelligent Capture Manager

/// Main orchestrator for the intelligent capture flow
@MainActor
class IntelligentCaptureManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var currentStage: ProcessingStage = .captured
    @Published var progress: Double = 0.0
    @Published var capturedInsights: [CapturedInsight] = []
    @Published var errorMessage: String?
    @Published var offlineMode = false

    // MARK: - Dependencies

    private let cameraManager: CameraIntakeManager
    private let appleVisionProcessor: AppleVisionProcessor
    private let deepSeekClient: DeepSeekOCRClient?
    private let openAIClient: OpenAIVisionClient?
    private let geminiManager: GeminiFileSearchManager?
    nonisolated private let offlineQueue: OfflineCaptureQueue
    private let complianceLogger: ComplianceAuditLogger?
    private let templateEngine: MedicalTemplateEngine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        apiKeys: APIKeys,
        requestManager: RequestManager,
        complianceLogger: ComplianceAuditLogger? = nil
    ) {
        self.cameraManager = CameraIntakeManager()
        self.appleVisionProcessor = AppleVisionProcessor()

        // Initialize cloud clients (optional for offline mode)
        if let deepSeekKey = apiKeys.deepSeekKey {
            self.deepSeekClient = DeepSeekOCRClient(apiKey: deepSeekKey, requestManager: requestManager)
        } else {
            self.deepSeekClient = nil
        }

        if let openAIKey = apiKeys.openAIKey {
            self.openAIClient = OpenAIVisionClient(apiKey: openAIKey)
        } else {
            self.openAIClient = nil
        }

        self.geminiManager = apiKeys.geminiKey != nil ? GeminiFileSearchManager() : nil

        self.offlineQueue = OfflineCaptureQueue()
        self.complianceLogger = complianceLogger
        self.templateEngine = MedicalTemplateEngine()

        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Monitor network status
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                guard let self = self else { return }
                let isOnline = notification.object as? Bool ?? true
                self.offlineMode = !isOnline

                if isOnline {
                    Task {
                        await self.processOfflineQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Main Processing Flow

    /// Process captured document through complete intelligent capture pipeline
    func processDocument(
        image: UIImage,
        documentType: DocumentType = .generic,
        userConsent: Bool = false
    ) async throws -> CapturedInsight {

        isProcessing = true
        progress = 0.0
        errorMessage = nil

        defer {
            isProcessing = false
        }

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw CaptureError.invalidImage
        }

        // Create captured document
        let metadata = DocumentMetadataInfo(
            captureMode: "intelligent",
            imageQuality: 1.0,
            fileSize: imageData.count,
            resolution: image.size,
            perspectiveCorrected: true,
            blurScore: 1.0
        )

        var capturedDoc = CapturedDocument(
            imageData: imageData,
            documentType: documentType,
            metadata: metadata,
            offlineMode: offlineMode
        )

        // Stage 1: Apple Vision (on-device, always available)
        currentStage = .appleVisionProcessing
        progress = 0.2

        let appleVisionResult = try await appleVisionProcessor.recognizeText(from: image)
        capturedDoc.processingStage = .appleVisionProcessing

        // Classify document type if not specified
        if documentType == .generic {
            let detectedType = try await appleVisionProcessor.classifyDocumentType(
                from: image,
                text: appleVisionResult.recognizedText
            )
            capturedDoc.documentType = detectedType
        }

        // Detect and redact PHI
        let detectedPHI = try await appleVisionProcessor.detectPHI(in: appleVisionResult.recognizedText)
        let shouldRedact = !detectedPHI.isEmpty && !userConsent

        var redactedText = appleVisionResult.recognizedText
        if shouldRedact {
            redactedText = appleVisionProcessor.redactPHI(in: appleVisionResult.recognizedText, phi: detectedPHI)
        }

        progress = 0.4

        // Stage 2: DeepSeek OCR (cloud, high fidelity)
        var deepSeekResult: DeepSeekOCRResult?

        if !offlineMode, let deepSeekClient = deepSeekClient {
            currentStage = .deepseekOCR
            progress = 0.5

            do {
                deepSeekResult = try await deepSeekClient.extractText(
                    from: imageData,
                    documentType: capturedDoc.documentType,
                    languageHints: ["en", "ar"]
                )
                capturedDoc.processingStage = .deepseekOCR
            } catch {
                // Fall back to Apple Vision result, queue for later
                errorMessage = "DeepSeek OCR unavailable: \(error.localizedDescription)"
                queueForOfflineProcessing(documentId: capturedDoc.id, jobType: .deepSeekOCR, imageData: imageData)
            }
        } else {
            // Offline: queue job
            queueForOfflineProcessing(documentId: capturedDoc.id, jobType: .deepSeekOCR, imageData: imageData)
        }

        progress = 0.6

        // Stage 3: Multimodal Analysis (OpenAI + Gemini)
        currentStage = .multimodalAnalysis
        var openAIAnalysis: OpenAIVisionAnalysis?
        var geminiAnalysis: GeminiVisionAnalysis?

        let currentDocumentType = capturedDoc.documentType
        let currentDocumentId = capturedDoc.id
        let sanitizedText = redactedText

        if !offlineMode {
            // Fan-out to cloud vision APIs in parallel
            async let openAITask: OpenAIVisionAnalysis? = {
                guard let client = self.openAIClient else { return nil }
                do {
                    return try await client.analyzeDocument(
                        imageData: imageData,
                        documentType: currentDocumentType,
                        extractedText: sanitizedText
                    )
                } catch {
                    self.queueForOfflineProcessing(documentId: currentDocumentId, jobType: .openAIVision, imageData: imageData)
                    return nil
                }
            }()

            async let geminiTask: GeminiVisionAnalysis? = {
                guard let manager = self.geminiManager else { return nil }
                do {
                    return try await manager.analyzeDocumentVision(
                        imageData: imageData,
                        documentType: currentDocumentType,
                        extractedText: sanitizedText
                    )
                } catch {
                    self.queueForOfflineProcessing(documentId: currentDocumentId, jobType: .geminiVision, imageData: imageData)
                    return nil
                }
            }()

            (openAIAnalysis, geminiAnalysis) = await (openAITask, geminiTask)
        } else {
            // Offline: queue both jobs
            queueForOfflineProcessing(documentId: currentDocumentId, jobType: .openAIVision, imageData: imageData)
            queueForOfflineProcessing(documentId: currentDocumentId, jobType: .geminiVision, imageData: imageData)
        }

        progress = 0.8

        // Stage 4: Template Analysis
        let templateAnalysis = try await templateEngine.analyzeWithTemplate(
            documentType: capturedDoc.documentType,
            extractedText: deepSeekResult?.fullText ?? appleVisionResult.recognizedText,
            tables: deepSeekResult?.tables ?? [],
            entities: (openAIAnalysis?.entities ?? []) + extractEntitiesFromGemini(geminiAnalysis)
        )

        progress = 0.9

        // Stage 5: Aggregate results
        let insight = aggregateResults(
            capturedDocument: capturedDoc,
            appleVisionResult: appleVisionResult,
            deepSeekResult: deepSeekResult,
            openAIAnalysis: openAIAnalysis,
            geminiAnalysis: geminiAnalysis,
            templateAnalysis: templateAnalysis,
            phiRedacted: shouldRedact
        )

        // Log compliance event
        if let logger = complianceLogger {
            _ = logger.logDocumentAccess(
                documentId: insight.documentId.uuidString,
                accessType: "intelligent_capture",
                metadata: [
                    "document_type": capturedDoc.documentType.rawValue,
                    "phi_detected": !detectedPHI.isEmpty,
                    "phi_redacted": shouldRedact,
                    "offline_mode": offlineMode
                ]
            )
        }

        progress = 1.0
        currentStage = .completed

        // Store insight
        capturedInsights.append(insight)

        // Persist locally
        try await persistInsight(insight)

        return insight
    }

    // MARK: - Result Aggregation

    private func aggregateResults(
        capturedDocument: CapturedDocument,
        appleVisionResult: AppleVisionResult,
        deepSeekResult: DeepSeekOCRResult?,
        openAIAnalysis: OpenAIVisionAnalysis?,
        geminiAnalysis: GeminiVisionAnalysis?,
        templateAnalysis: TemplateAnalysisResult,
        phiRedacted: Bool
    ) -> CapturedInsight {

        // Unified text (prefer DeepSeek, fallback to Apple Vision)
        let unifiedText = deepSeekResult?.fullText ?? appleVisionResult.recognizedText

        // Unified summary
        var summaries: [String] = []
        if let openAISummary = openAIAnalysis?.summary {
            summaries.append(openAISummary)
        }
        if let geminiSummary = geminiAnalysis?.bilingualSummary.english {
            summaries.append(geminiSummary)
        }

        let unifiedSummary = summaries.isEmpty
            ? "Document captured and processed successfully."
            : summaries.joined(separator: "\n\n")

        // Aggregate action items
        let allActions = openAIAnalysis?.actionItems ?? []
        // Could extract actions from Gemini recommendations as well

        // Aggregate entities
        var allEntities = openAIAnalysis?.entities ?? []
        allEntities.append(contentsOf: extractEntitiesFromGemini(geminiAnalysis))

        // Calculate overall confidence
        var confidences: [Double] = [appleVisionResult.confidence]
        if let deepSeek = deepSeekResult { confidences.append(deepSeek.confidence) }
        if let openAI = openAIAnalysis { confidences.append(openAI.confidence) }
        if let gemini = geminiAnalysis { confidences.append(gemini.confidence) }

        let overallConfidence = confidences.reduce(0.0, +) / Double(confidences.count)

        // Determine compliance status
        let complianceStatus: ComplianceStatus = {
            if let checks = geminiAnalysis?.complianceChecks {
                if checks.contains(where: { $0.status == .failed }) {
                    return .failed
                }
                if checks.contains(where: { $0.status == .warning }) {
                    return .warning
                }
                return .passed
            }
            return .notApplicable
        }()

        // Check if cloud analysis was deferred
        let deferredCloud = offlineMode || deepSeekResult == nil || openAIAnalysis == nil || geminiAnalysis == nil

        return CapturedInsight(
            id: UUID(),
            documentId: capturedDocument.id,
            capturedDocument: capturedDocument,
            timestamp: Date(),
            appleVisionResult: appleVisionResult,
            deepSeekResult: deepSeekResult,
            openAIAnalysis: openAIAnalysis,
            geminiAnalysis: geminiAnalysis,
            unifiedText: unifiedText,
            unifiedSummary: unifiedSummary,
            allActionItems: allActions,
            allEntities: allEntities,
            overallConfidence: overallConfidence,
            templateAnalysis: templateAnalysis,
            phiRedacted: phiRedacted,
            complianceStatus: complianceStatus,
            deferredCloudAnalysis: deferredCloud
        )
    }

    private func extractEntitiesFromGemini(_ analysis: GeminiVisionAnalysis?) -> [ExtractedEntity] {
        // Extract medical codes as entities
        guard let codes = analysis?.medicalCoding else { return [] }

        return codes.map { code in
            ExtractedEntity(
                id: UUID(),
                type: code.system == "ICD-10" ? .diagnosis : .procedure,
                value: "\(code.code): \(code.display)",
                confidence: code.confidence,
                redacted: false
            )
        }
    }

    // MARK: - Offline Queue Management

    private nonisolated func queueForOfflineProcessing(documentId: UUID, jobType: CaptureJobType, imageData: Data) {
        let job = OfflineCaptureJob(
            documentId: documentId,
            jobType: jobType,
            payload: imageData,
            priority: 5
        )
        offlineQueue.enqueue(job)
    }

    private func processOfflineQueue() async {
        let jobs = offlineQueue.getPendingJobs()

        for job in jobs {
            do {
                switch job.jobType {
                case .deepSeekOCR:
                    if let client = deepSeekClient {
                        _ = try await client.extractText(from: job.payload, documentType: .generic)
                        offlineQueue.markCompleted(job.id)
                    }

                case .openAIVision:
                    if let client = openAIClient {
                        _ = try await client.analyzeDocument(imageData: job.payload, documentType: .generic)
                        offlineQueue.markCompleted(job.id)
                    }

                case .geminiVision:
                    if let manager = geminiManager {
                        _ = try await manager.analyzeDocumentVision(imageData: job.payload, documentType: .generic)
                        offlineQueue.markCompleted(job.id)
                    }

                case .templateAnalysis:
                    // Template analysis is local, shouldn't be queued
                    offlineQueue.markCompleted(job.id)
                }
            } catch {
                offlineQueue.markFailed(job.id, error: error)
            }
        }
    }

    // MARK: - Persistence

    private func persistInsight(_ insight: CapturedInsight) async throws {
        // Encode and encrypt
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)

        // Use existing OfflineModeManager encryption
        // For now, save to UserDefaults (in production, use encrypted file system)
        let key = "captured_insight_\(insight.id.uuidString)"
        UserDefaults.standard.set(data, forKey: key)

        // Save index
        var insightIds = UserDefaults.standard.stringArray(forKey: "captured_insight_ids") ?? []
        insightIds.append(insight.id.uuidString)
        UserDefaults.standard.set(insightIds, forKey: "captured_insight_ids")
    }

    /// Load previously captured insights
    func loadInsights() async {
        let insightIds = UserDefaults.standard.stringArray(forKey: "captured_insight_ids") ?? []

        var loadedInsights: [CapturedInsight] = []

        for idString in insightIds {
            let key = "captured_insight_\(idString)"
            if let data = UserDefaults.standard.data(forKey: key) {
                let decoder = JSONDecoder()
                if let insight = try? decoder.decode(CapturedInsight.self, from: data) {
                    loadedInsights.append(insight)
                }
            }
        }

        capturedInsights = loadedInsights.sorted { $0.timestamp > $1.timestamp }
    }

    /// Delete an insight
    func deleteInsight(_ insight: CapturedInsight) {
        // Remove from array
        capturedInsights.removeAll { $0.id == insight.id }

        // Remove from storage
        let key = "captured_insight_\(insight.id.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)

        // Update index
        var insightIds = UserDefaults.standard.stringArray(forKey: "captured_insight_ids") ?? []
        insightIds.removeAll { $0 == insight.id.uuidString }
        UserDefaults.standard.set(insightIds, forKey: "captured_insight_ids")
    }

    // MARK: - Batch Processing

    func processMultiPageDocument(images: [UIImage], documentType: DocumentType) async throws -> CapturedInsight {
        // For multi-page documents, combine all pages

        var allAppleVisionResults: [AppleVisionResult] = []
        var combinedText = ""

        for (index, image) in images.enumerated() {
            let result = try await appleVisionProcessor.recognizeText(from: image)
            allAppleVisionResults.append(result)
            combinedText += "--- Page \(index + 1) ---\n\(result.recognizedText)\n\n"
        }

        // Use the first image for vision analysis
        guard let firstImage = images.first else {
            throw CaptureError.invalidImage
        }

        return try await processDocument(image: firstImage, documentType: documentType)
    }

    // MARK: - Camera Access

    func getCameraManager() -> CameraIntakeManager {
        return cameraManager
    }
}

// MARK: - Offline Capture Queue

/// Manages offline job queue for deferred cloud processing
class OfflineCaptureQueue {

    private var jobs: [OfflineCaptureJob] = []
    private let queue = DispatchQueue(label: "com.afham.offline_queue", attributes: .concurrent)

    func enqueue(_ job: OfflineCaptureJob) {
        queue.async(flags: .barrier) {
            self.jobs.append(job)
            self.persistQueue()
        }
    }

    func getPendingJobs() -> [OfflineCaptureJob] {
        queue.sync {
            jobs.filter { $0.status == .pending }.sorted { $0.priority > $1.priority }
        }
    }

    func markCompleted(_ jobId: UUID) {
        queue.async(flags: .barrier) {
            if let index = self.jobs.firstIndex(where: { $0.id == jobId }) {
                self.jobs[index].status = .completed
                self.persistQueue()
            }
        }
    }

    func markFailed(_ jobId: UUID, error: Error) {
        queue.async(flags: .barrier) {
            if let index = self.jobs.firstIndex(where: { $0.id == jobId }) {
                self.jobs[index].status = .failed
                self.jobs[index].retryCount += 1
                self.jobs[index].lastRetryAt = Date()
                self.persistQueue()
            }
        }
    }

    private func persistQueue() {
        // Persist to UserDefaults (in production, use encrypted storage)
        if let data = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(data, forKey: "offline_capture_queue")
        }
    }

    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: "offline_capture_queue"),
           let loadedJobs = try? JSONDecoder().decode([OfflineCaptureJob].self, from: data) {
            jobs = loadedJobs
        }
    }

    init() {
        loadQueue()
    }
}

// MARK: - Supporting Types

struct APIKeys {
    let deepSeekKey: String?
    let openAIKey: String?
    let geminiKey: String?
}

enum CaptureError: LocalizedError {
    case invalidImage
    case processingFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .processingFailed:
            return "Document processing failed"
        case .networkUnavailable:
            return "Network unavailable for cloud processing"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
