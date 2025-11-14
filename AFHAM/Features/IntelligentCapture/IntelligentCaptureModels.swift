//
//  IntelligentCaptureModels.swift
//  AFHAM - Intelligent Capture Data Models
//
//  Core data models for multimodal document capture, OCR, and vision analysis
//  Supports DeepSeek OCR, Apple Vision, OpenAI Vision, and Gemini Vision
//

import Foundation
import SwiftUI
import CoreML
import Vision

// MARK: - Document Types

/// Types of documents that can be captured and analyzed
enum DocumentType: String, Codable, CaseIterable {
    case medicalReport = "medical_report"
    case prescription = "prescription"
    case insuranceClaim = "insurance_claim"
    case labReport = "lab_report"
    case pharmacyLabel = "pharmacy_label"
    case foodLabel = "food_label"
    case spreadsheet = "spreadsheet"
    case contract = "contract"
    case generic = "generic"

    var displayName: String {
        switch self {
        case .medicalReport: return LocalizationKey.icDocTypeMedicalReport.localized
        case .prescription: return LocalizationKey.icDocTypePrescription.localized
        case .insuranceClaim: return LocalizationKey.icDocTypeInsuranceClaim.localized
        case .labReport: return LocalizationKey.icDocTypeLabReport.localized
        case .pharmacyLabel: return LocalizationKey.icDocTypePharmacyLabel.localized
        case .foodLabel: return LocalizationKey.icDocTypeFoodLabel.localized
        case .spreadsheet: return LocalizationKey.icDocTypeSpreadsheet.localized
        case .contract: return LocalizationKey.icDocTypeContract.localized
        case .generic: return LocalizationKey.icDocTypeGeneric.localized
        }
    }

    var icon: String {
        switch self {
        case .medicalReport: return "doc.text.fill"
        case .prescription: return "pills.fill"
        case .insuranceClaim: return "doc.plaintext.fill"
        case .labReport: return "chart.bar.doc.horizontal.fill"
        case .pharmacyLabel: return "cross.case.fill"
        case .foodLabel: return "leaf.fill"
        case .spreadsheet: return "tablecells.fill"
        case .contract: return "doc.text.magnifyingglass"
        case .generic: return "doc.fill"
        }
    }
}

// MARK: - Captured Document

/// Represents a captured physical document with metadata
struct CapturedDocument: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let imageData: Data
    let documentType: DocumentType
    let language: String // "ar", "en", or "mixed"
    let pages: Int
    let metadata: DocumentMetadataInfo

    // Processing status
    var processingStage: ProcessingStage
    var offlineMode: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        imageData: Data,
        documentType: DocumentType = .generic,
        language: String = "en",
        pages: Int = 1,
        metadata: DocumentMetadataInfo = DocumentMetadataInfo(),
        processingStage: ProcessingStage = .captured,
        offlineMode: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.imageData = imageData
        self.documentType = documentType
        self.language = language
        self.pages = pages
        self.metadata = metadata
        self.processingStage = processingStage
        self.offlineMode = offlineMode
    }
}

/// Processing stages for a captured document
enum ProcessingStage: String, Codable {
    case captured = "captured"
    case appleVisionProcessing = "apple_vision"
    case deepseekOCR = "deepseek_ocr"
    case multimodalAnalysis = "multimodal"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .captured: return LocalizationKey.icStageCaptured.localized
        case .appleVisionProcessing: return LocalizationKey.icStageAppleVision.localized
        case .deepseekOCR: return LocalizationKey.icStageDeepSeek.localized
        case .multimodalAnalysis: return LocalizationKey.icStageMultimodal.localized
        case .completed: return LocalizationKey.icStageCompleted.localized
        case .failed: return LocalizationKey.icStageFailed.localized
        }
    }
}

/// Additional metadata for captured documents
struct DocumentMetadataInfo: Codable {
    var captureMode: String = "auto"
    var imageQuality: Double = 1.0
    var fileSize: Int = 0
    var resolution: CGSize = .zero
    var perspectiveCorrected: Bool = false
    var blurScore: Double = 1.0
}

// MARK: - OCR Results

/// Result from Apple Vision on-device OCR
struct AppleVisionResult: Codable {
    let id: UUID
    let documentId: UUID
    let timestamp: Date
    let recognizedText: String
    let textBlocks: [TextBlock]
    let confidence: Double
    let languageDetected: String
    let processingTimeMs: Int

    init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        recognizedText: String,
        textBlocks: [TextBlock] = [],
        confidence: Double,
        languageDetected: String,
        processingTimeMs: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.recognizedText = recognizedText
        self.textBlocks = textBlocks
        self.confidence = confidence
        self.languageDetected = languageDetected
        self.processingTimeMs = processingTimeMs
    }
}

/// Result from DeepSeek OCR API
struct DeepSeekOCRResult: Codable {
    let id: UUID
    let documentId: UUID
    let timestamp: Date
    let fullText: String
    let textBlocks: [TextBlock]
    let tables: [TableStructure]
    let confidence: Double
    let languageDetected: String
    let processingTimeMs: Int
    let metadata: DeepSeekMetadata

    init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        fullText: String,
        textBlocks: [TextBlock] = [],
        tables: [TableStructure] = [],
        confidence: Double,
        languageDetected: String,
        processingTimeMs: Int,
        metadata: DeepSeekMetadata = DeepSeekMetadata()
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.fullText = fullText
        self.textBlocks = textBlocks
        self.tables = tables
        self.confidence = confidence
        self.languageDetected = languageDetected
        self.processingTimeMs = processingTimeMs
        self.metadata = metadata
    }
}

struct DeepSeekMetadata: Codable {
    var modelVersion: String = "deepseek-ocr-v1"
    var processingMode: String = "high_fidelity"
    var enhancementsApplied: [String] = []
}

/// Text block with position and metadata
struct TextBlock: Codable, Identifiable {
    let id: UUID
    let text: String
    let boundingBox: BoundingBox
    let confidence: Double
    let language: String?
    let type: TextBlockType

    init(
        id: UUID = UUID(),
        text: String,
        boundingBox: BoundingBox,
        confidence: Double,
        language: String? = nil,
        type: TextBlockType = .paragraph
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.language = language
        self.type = type
    }
}

enum TextBlockType: String, Codable {
    case heading
    case paragraph
    case list
    case table
    case signature
    case stamp
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

/// Table structure extracted from documents
struct TableStructure: Codable, Identifiable {
    let id: UUID
    let rows: [[String]]
    let headers: [String]?
    let boundingBox: BoundingBox
    let confidence: Double

    init(
        id: UUID = UUID(),
        rows: [[String]],
        headers: [String]? = nil,
        boundingBox: BoundingBox,
        confidence: Double
    ) {
        self.id = id
        self.rows = rows
        self.headers = headers
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

// MARK: - Vision Analysis Results

/// Result from OpenAI Vision analysis
struct OpenAIVisionAnalysis: Codable {
    let id: UUID
    let documentId: UUID
    let timestamp: Date
    let summary: String
    let keyInsights: [String]
    let actionItems: [ActionItem]
    let entities: [ExtractedEntity]
    let confidence: Double
    let modelUsed: String
    let processingTimeMs: Int

    init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        summary: String,
        keyInsights: [String],
        actionItems: [ActionItem] = [],
        entities: [ExtractedEntity] = [],
        confidence: Double,
        modelUsed: String = "gpt-4-vision-preview",
        processingTimeMs: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.summary = summary
        self.keyInsights = keyInsights
        self.actionItems = actionItems
        self.entities = entities
        self.confidence = confidence
        self.modelUsed = modelUsed
        self.processingTimeMs = processingTimeMs
    }
}

/// Result from Gemini Vision analysis
struct GeminiVisionAnalysis: Codable {
    let id: UUID
    let documentId: UUID
    let timestamp: Date
    let bilingualSummary: BilingualContent
    let complianceChecks: [ComplianceCheck]
    let medicalCoding: [MedicalCode]?
    let riskFlags: [RiskFlag]
    let confidence: Double
    let modelUsed: String
    let processingTimeMs: Int

    init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        bilingualSummary: BilingualContent,
        complianceChecks: [ComplianceCheck] = [],
        medicalCoding: [MedicalCode]? = nil,
        riskFlags: [RiskFlag] = [],
        confidence: Double,
        modelUsed: String = "gemini-pro-vision",
        processingTimeMs: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.bilingualSummary = bilingualSummary
        self.complianceChecks = complianceChecks
        self.medicalCoding = medicalCoding
        self.riskFlags = riskFlags
        self.confidence = confidence
        self.modelUsed = modelUsed
        self.processingTimeMs = processingTimeMs
    }
}

struct BilingualContent: Codable {
    let english: String
    let arabic: String
}

struct ComplianceCheck: Codable, Identifiable {
    let id: UUID
    let rule: String
    let status: ComplianceStatus
    let details: String
    let severity: ComplianceSeverity

    init(
        id: UUID = UUID(),
        rule: String,
        status: ComplianceStatus,
        details: String,
        severity: ComplianceSeverity
    ) {
        self.id = id
        self.rule = rule
        self.status = status
        self.details = details
        self.severity = severity
    }
}

enum ComplianceStatus: String, Codable {
    case passed
    case failed
    case warning
    case notApplicable
}

enum ComplianceSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

struct MedicalCode: Codable, Identifiable {
    let id: UUID
    let system: String // "ICD-10", "CPT", "SNOMED"
    let code: String
    let display: String
    let confidence: Double

    init(
        id: UUID = UUID(),
        system: String,
        code: String,
        display: String,
        confidence: Double
    ) {
        self.id = id
        self.system = system
        self.code = code
        self.display = display
        self.confidence = confidence
    }
}

struct RiskFlag: Codable, Identifiable {
    let id: UUID
    let category: String
    let description: String
    let severity: RiskSeverity
    let recommendations: [String]

    init(
        id: UUID = UUID(),
        category: String,
        description: String,
        severity: RiskSeverity,
        recommendations: [String] = []
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.severity = severity
        self.recommendations = recommendations
    }
}

enum RiskSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

struct ActionItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let priority: ActionPriority
    let dueDate: Date?
    let category: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        priority: ActionPriority,
        dueDate: Date? = nil,
        category: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.category = category
    }
}

enum ActionPriority: String, Codable {
    case low
    case medium
    case high
    case urgent
}

struct ExtractedEntity: Codable, Identifiable {
    let id: UUID
    let type: EntityType
    let value: String
    let confidence: Double
    let redacted: Bool

    init(
        id: UUID = UUID(),
        type: EntityType,
        value: String,
        confidence: Double,
        redacted: Bool = false
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.confidence = confidence
        self.redacted = redacted
    }
}

enum EntityType: String, Codable {
    case patientName
    case patientId
    case dateOfBirth
    case medication
    case diagnosis
    case procedure
    case labValue
    case doctorName
    case facilityName
    case phoneNumber
    case email
    case address
    case insuranceId
    case amount
    case date
    case organization
}

// MARK: - Unified Captured Insight

/// Unified result aggregating all OCR and vision analysis
struct CapturedInsight: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let capturedDocument: CapturedDocument
    let timestamp: Date

    // OCR Results
    var appleVisionResult: AppleVisionResult?
    var deepSeekResult: DeepSeekOCRResult?

    // Vision Analysis Results
    var openAIAnalysis: OpenAIVisionAnalysis?
    var geminiAnalysis: GeminiVisionAnalysis?

    // Unified outputs
    var unifiedText: String
    var unifiedSummary: String
    var allActionItems: [ActionItem]
    var allEntities: [ExtractedEntity]
    var overallConfidence: Double

    // Medical template results
    var templateAnalysis: TemplateAnalysisResult?

    // Compliance and security
    var phiRedacted: Bool
    var complianceStatus: ComplianceStatus
    var auditLogId: String?

    // Offline processing status
    var deferredCloudAnalysis: Bool

    init(
        id: UUID = UUID(),
        documentId: UUID,
        capturedDocument: CapturedDocument,
        timestamp: Date = Date(),
        appleVisionResult: AppleVisionResult? = nil,
        deepSeekResult: DeepSeekOCRResult? = nil,
        openAIAnalysis: OpenAIVisionAnalysis? = nil,
        geminiAnalysis: GeminiVisionAnalysis? = nil,
        unifiedText: String = "",
        unifiedSummary: String = "",
        allActionItems: [ActionItem] = [],
        allEntities: [ExtractedEntity] = [],
        overallConfidence: Double = 0.0,
        templateAnalysis: TemplateAnalysisResult? = nil,
        phiRedacted: Bool = false,
        complianceStatus: ComplianceStatus = .notApplicable,
        auditLogId: String? = nil,
        deferredCloudAnalysis: Bool = false
    ) {
        self.id = id
        self.documentId = documentId
        self.capturedDocument = capturedDocument
        self.timestamp = timestamp
        self.appleVisionResult = appleVisionResult
        self.deepSeekResult = deepSeekResult
        self.openAIAnalysis = openAIAnalysis
        self.geminiAnalysis = geminiAnalysis
        self.unifiedText = unifiedText
        self.unifiedSummary = unifiedSummary
        self.allActionItems = allActionItems
        self.allEntities = allEntities
        self.overallConfidence = overallConfidence
        self.templateAnalysis = templateAnalysis
        self.phiRedacted = phiRedacted
        self.complianceStatus = complianceStatus
        self.auditLogId = auditLogId
        self.deferredCloudAnalysis = deferredCloudAnalysis
    }
}

// MARK: - Template Analysis

/// Medical template-specific analysis
struct TemplateAnalysisResult: Codable {
    let templateType: DocumentType
    let specificFindings: [TemplateFinding]
    let interpretations: [Interpretation]
    let recommendations: [String]
    let visualizations: [VisualizationData]?

    init(
        templateType: DocumentType,
        specificFindings: [TemplateFinding] = [],
        interpretations: [Interpretation] = [],
        recommendations: [String] = [],
        visualizations: [VisualizationData]? = nil
    ) {
        self.templateType = templateType
        self.specificFindings = specificFindings
        self.interpretations = interpretations
        self.recommendations = recommendations
        self.visualizations = visualizations
    }
}

struct TemplateFinding: Codable, Identifiable {
    let id: UUID
    let category: String
    let key: String
    let value: String
    let unit: String?
    let normalRange: String?
    let status: FindingStatus
    let citations: [String]

    init(
        id: UUID = UUID(),
        category: String,
        key: String,
        value: String,
        unit: String? = nil,
        normalRange: String? = nil,
        status: FindingStatus = .normal,
        citations: [String] = []
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.unit = unit
        self.normalRange = normalRange
        self.status = status
        self.citations = citations
    }
}

enum FindingStatus: String, Codable {
    case normal
    case abnormalLow
    case abnormalHigh
    case critical
    case unknown

    var color: Color {
        switch self {
        case .normal: return .green
        case .abnormalLow, .abnormalHigh: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

struct Interpretation: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let confidence: Double
    let sources: [String]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        confidence: Double,
        sources: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.confidence = confidence
        self.sources = sources
    }
}

struct VisualizationData: Codable, Identifiable {
    let id: UUID
    let type: VisualizationType
    let title: String
    let data: [String: Double]

    init(
        id: UUID = UUID(),
        type: VisualizationType,
        title: String,
        data: [String: Double]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.data = data
    }
}

enum VisualizationType: String, Codable {
    case barChart
    case lineChart
    case pieChart
    case gauge
}

// MARK: - Offline Queue

/// Job for deferred cloud analysis when offline
struct OfflineCaptureJob: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let jobType: CaptureJobType
    let payload: Data
    let priority: Int
    let createdAt: Date
    var retryCount: Int
    var lastRetryAt: Date?
    var status: JobStatus

    init(
        id: UUID = UUID(),
        documentId: UUID,
        jobType: CaptureJobType,
        payload: Data,
        priority: Int = 5,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        lastRetryAt: Date? = nil,
        status: JobStatus = .pending
    ) {
        self.id = id
        self.documentId = documentId
        self.jobType = jobType
        self.payload = payload
        self.priority = priority
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastRetryAt = lastRetryAt
        self.status = status
    }
}

enum CaptureJobType: String, Codable {
    case deepSeekOCR
    case openAIVision
    case geminiVision
    case templateAnalysis
}

enum JobStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - Export Formats

/// Export format options
enum ExportFormat: String, CaseIterable {
    case fhir = "FHIR Observation"
    case pdf = "PDF Report"
    case csv = "CSV Data"
    case json = "JSON"
    case whatsapp = "WhatsApp Summary"
    case text = "Plain Text"

    var displayName: String {
        self.rawValue
    }

    var icon: String {
        switch self {
        case .fhir: return "heart.text.square.fill"
        case .pdf: return "doc.fill"
        case .csv: return "tablecells.fill"
        case .json: return "curlybraces"
        case .whatsapp: return "message.fill"
        case .text: return "text.alignleft"
        }
    }
}

// MARK: - Localization Keys Extension

extension LocalizationKey {
    // Document Types
    static let icDocTypeMedicalReport = LocalizationKey.customKey("ic.doctype.medical_report")
    static let icDocTypePrescription = LocalizationKey.customKey("ic.doctype.prescription")
    static let icDocTypeInsuranceClaim = LocalizationKey.customKey("ic.doctype.insurance_claim")
    static let icDocTypeLabReport = LocalizationKey.customKey("ic.doctype.lab_report")
    static let icDocTypePharmacyLabel = LocalizationKey.customKey("ic.doctype.pharmacy_label")
    static let icDocTypeFoodLabel = LocalizationKey.customKey("ic.doctype.food_label")
    static let icDocTypeSpreadsheet = LocalizationKey.customKey("ic.doctype.spreadsheet")
    static let icDocTypeContract = LocalizationKey.customKey("ic.doctype.contract")
    static let icDocTypeGeneric = LocalizationKey.customKey("ic.doctype.generic")

    // Processing Stages
    static let icStageCaptured = LocalizationKey.customKey("ic.stage.captured")
    static let icStageAppleVision = LocalizationKey.customKey("ic.stage.apple_vision")
    static let icStageDeepSeek = LocalizationKey.customKey("ic.stage.deepseek")
    static let icStageMultimodal = LocalizationKey.customKey("ic.stage.multimodal")
    static let icStageCompleted = LocalizationKey.customKey("ic.stage.completed")
    static let icStageFailed = LocalizationKey.customKey("ic.stage.failed")
}
