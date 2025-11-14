//
//  ModularCanvasArchitecture.swift
//  AFHAM
//
//  Advanced modular canvas architecture for document workspace
//  Provides panel-based document management with transformation pipelines
//

import Foundation
import SwiftUI
import Combine

// MARK: - Core Data Models

/// Represents a document panel in the modular canvas
struct DocumentPanel: Identifiable, Codable {
    let id: UUID
    var documentMetadata: DocumentMetadata
    var position: CGPoint
    var size: CGSize
    var isExpanded: Bool
    var quickActions: [QuickAction]
    var activeTransformations: [TransformationPipeline]
    var previewMode: PreviewMode
    var comments: [Comment]
    var revisionHistory: [Revision]

    init(
        id: UUID = UUID(),
        documentMetadata: DocumentMetadata,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 400, height: 600),
        isExpanded: Bool = true
    ) {
        self.id = id
        self.documentMetadata = documentMetadata
        self.position = position
        self.size = size
        self.isExpanded = isExpanded
        self.quickActions = QuickAction.defaultActions
        self.activeTransformations = []
        self.previewMode = .source
        self.comments = []
        self.revisionHistory = []
    }
}

/// Quick actions available for each document panel
enum QuickAction: String, Codable, CaseIterable {
    case summarize = "Summarize"
    case translate = "Translate"
    case convertToSlides = "Convert to Slides"
    case generateScript = "Generate Script"
    case socialPost = "Social Post"
    case extractAssets = "Extract Assets"
    case chatbotSnippet = "Chatbot Snippet"
    case voiceover = "Voiceover"

    static var defaultActions: [QuickAction] {
        [.summarize, .translate, .convertToSlides, .generateScript]
    }

    var icon: String {
        switch self {
        case .summarize: return "doc.text.magnifyingglass"
        case .translate: return "globe"
        case .convertToSlides: return "rectangle.stack"
        case .generateScript: return "text.bubble"
        case .socialPost: return "megaphone"
        case .extractAssets: return "photo.on.rectangle.angled"
        case .chatbotSnippet: return "message.badge.waveform"
        case .voiceover: return "mic.and.signal.meter"
        }
    }
}

/// Preview modes for document output
enum PreviewMode: String, Codable {
    case source = "Source"
    case sideBySide = "Side by Side"
    case preview = "Preview Only"
    case splitVertical = "Split Vertical"
    case splitHorizontal = "Split Horizontal"
}

// MARK: - Transformation Pipeline

/// Represents a multi-stage transformation pipeline
struct TransformationPipeline: Identifiable, Codable {
    let id: UUID
    var name: String
    var stages: [TransformationStage]
    var currentStageIndex: Int
    var output: TransformationOutput?
    var preset: PipelinePreset?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        stages: [TransformationStage] = [],
        preset: PipelinePreset? = nil
    ) {
        self.id = id
        self.name = name
        self.stages = stages
        self.currentStageIndex = 0
        self.output = nil
        self.preset = preset
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    mutating func addStage(_ stage: TransformationStage) {
        stages.append(stage)
        updatedAt = Date()
    }

    mutating func moveToNextStage() {
        if currentStageIndex < stages.count - 1 {
            currentStageIndex += 1
            updatedAt = Date()
        }
    }

    var isComplete: Bool {
        currentStageIndex == stages.count - 1 && output != nil
    }
}

/// Individual transformation stage in a pipeline
struct TransformationStage: Identifiable, Codable {
    let id: UUID
    var type: QuickAction
    var parameters: [String: String]
    var output: String?
    var isEditable: Bool
    var status: StageStatus

    init(
        id: UUID = UUID(),
        type: QuickAction,
        parameters: [String: String] = [:],
        isEditable: Bool = true
    ) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.output = nil
        self.isEditable = isEditable
        self.status = .pending
    }

    enum StageStatus: String, Codable {
        case pending = "Pending"
        case processing = "Processing"
        case completed = "Completed"
        case error = "Error"
    }
}

/// Output from a transformation pipeline
struct TransformationOutput: Codable {
    let content: String
    let format: OutputFormat
    let metadata: [String: String]
    let assets: [ExtractedAsset]
    let validationResults: ValidationResults
    let generatedAt: Date
}

/// Available output formats
enum OutputFormat: String, Codable {
    case text = "Text"
    case markdown = "Markdown"
    case html = "HTML"
    case pdf = "PDF"
    case slides = "Slides"
    case script = "Script"
    case json = "JSON"
}

// MARK: - Pipeline Presets

/// Pre-configured transformation pipelines
enum PipelinePreset: String, Codable, CaseIterable {
    case investorBrief = "Investor Brief"
    case patientLeaflet = "Patient Leaflet"
    case trainingSlideDeck = "Training Slide Deck"
    case socialMediaCampaign = "Social Media Campaign"
    case multilingualFAQ = "Multilingual FAQ"
    case complianceReport = "Compliance Report"
    case podcastScript = "Podcast Script"
    case whatsappBrief = "WhatsApp Brief"

    var icon: String {
        switch self {
        case .investorBrief: return "chart.line.uptrend.xyaxis"
        case .patientLeaflet: return "cross.case"
        case .trainingSlideDeck: return "rectangle.stack.badge.person.crop"
        case .socialMediaCampaign: return "megaphone"
        case .multilingualFAQ: return "globe.badge.chevron.backward"
        case .complianceReport: return "checkmark.shield"
        case .podcastScript: return "waveform"
        case .whatsappBrief: return "message.badge.filled.fill"
        }
    }

    var stages: [TransformationStage] {
        switch self {
        case .investorBrief:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "executive"]),
                TransformationStage(type: .convertToSlides, parameters: ["theme": "professional"]),
                TransformationStage(type: .extractAssets, parameters: ["type": "charts"])
            ]
        case .patientLeaflet:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "simple"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "ar"]),
                TransformationStage(type: .extractAssets, parameters: ["type": "illustrations"])
            ]
        case .trainingSlideDeck:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "educational"]),
                TransformationStage(type: .convertToSlides, parameters: ["theme": "training"]),
                TransformationStage(type: .generateScript, parameters: ["type": "presenter"])
            ]
        case .socialMediaCampaign:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "engaging"]),
                TransformationStage(type: .socialPost, parameters: ["platform": "multiple"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "ar"})
            ]
        case .multilingualFAQ:
            return [
                TransformationStage(type: .chatbotSnippet, parameters: ["format": "faq"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "ar"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "en"])
            ]
        case .complianceReport:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "formal"]),
                TransformationStage(type: .extractAssets, parameters: ["type": "citations"]),
                TransformationStage(type: .chatbotSnippet, parameters: ["format": "structured"])
            ]
        case .podcastScript:
            return [
                TransformationStage(type: .generateScript, parameters: ["type": "podcast"]),
                TransformationStage(type: .voiceover, parameters: ["style": "conversational"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "ar"])
            ]
        case .whatsappBrief:
            return [
                TransformationStage(type: .summarize, parameters: ["style": "brief", "maxLength": "500"]),
                TransformationStage(type: .translate, parameters: ["targetLanguage": "ar"]),
                TransformationStage(type: .socialPost, parameters: ["platform": "whatsapp"])
            ]
        }
    }

    var description: String {
        switch self {
        case .investorBrief:
            return "Executive summary → Professional slides → Key charts"
        case .patientLeaflet:
            return "Simple summary → Arabic translation → Visual aids"
        case .trainingSlideDeck:
            return "Educational content → Training slides → Presenter script"
        case .socialMediaCampaign:
            return "Engaging summary → Social posts → Multilingual"
        case .multilingualFAQ:
            return "FAQ format → Arabic/English → Chatbot ready"
        case .complianceReport:
            return "Formal summary → Citations → Structured data"
        case .podcastScript:
            return "Podcast script → Voiceover → Multilingual"
        case .whatsappBrief:
            return "Brief summary → Arabic → WhatsApp format"
        }
    }
}

// MARK: - Modal-Specific Editors

/// Configuration for modal-specific editors
enum EditorMode: String, Codable {
    case slides = "Slides"
    case script = "Script"
    case chatbot = "Chatbot"
    case standard = "Standard"

    var icon: String {
        switch self {
        case .slides: return "rectangle.stack"
        case .script: return "text.alignleft"
        case .chatbot: return "message.badge.waveform"
        case .standard: return "doc.text"
        }
    }
}

/// Slide deck configuration
struct SlideConfiguration: Codable {
    var title: String
    var theme: SlideTheme
    var slides: [Slide]
    var layout: SlideLayout

    struct Slide: Identifiable, Codable {
        let id: UUID
        var title: String
        var body: String
        var notes: String
        var assets: [ExtractedAsset]
        var layout: SlideLayout

        init(id: UUID = UUID(), title: String = "", body: String = "") {
            self.id = id
            self.title = title
            self.body = body
            self.notes = ""
            self.assets = []
            self.layout = .titleAndBody
        }
    }

    enum SlideTheme: String, Codable {
        case professional = "Professional"
        case training = "Training"
        case medical = "Medical"
        case creative = "Creative"
    }

    enum SlideLayout: String, Codable {
        case title = "Title"
        case titleAndBody = "Title and Body"
        case twoColumn = "Two Column"
        case imageAndText = "Image and Text"
        case fullImage = "Full Image"
    }
}

/// Script configuration for teleprompter
struct ScriptConfiguration: Codable {
    var title: String
    var scriptType: ScriptType
    var sections: [ScriptSection]
    var timing: TimingConfiguration
    var formatting: FormattingOptions

    struct ScriptSection: Identifiable, Codable {
        let id: UUID
        var heading: String
        var content: String
        var duration: TimeInterval
        var speaker: String?

        init(id: UUID = UUID(), heading: String = "", content: String = "") {
            self.id = id
            self.heading = heading
            self.content = content
            self.duration = 0
            self.speaker = nil
        }
    }

    enum ScriptType: String, Codable {
        case podcast = "Podcast"
        case voiceover = "Voiceover"
        case presentation = "Presentation"
        case video = "Video"
    }

    struct TimingConfiguration: Codable {
        var wordsPerMinute: Int
        var pauseDuration: TimeInterval
        var showTimestamps: Bool

        init() {
            self.wordsPerMinute = 150
            self.pauseDuration = 1.0
            self.showTimestamps = true
        }
    }

    struct FormattingOptions: Codable {
        var fontSize: CGFloat
        var scrollSpeed: Double
        var highlightCurrentLine: Bool

        init() {
            self.fontSize = 24
            self.scrollSpeed = 1.0
            self.highlightCurrentLine = true
        }
    }
}

/// Chatbot snippet configuration
struct ChatbotConfiguration: Codable {
    var intent: String
    var response: String
    var alternativeResponses: [String]
    var citations: [Citation]
    var metadata: ChatbotMetadata
    var validationStatus: ValidationStatus

    struct ChatbotMetadata: Codable {
        var category: String
        var tags: [String]
        var language: String
        var confidenceScore: Double

        init() {
            self.category = ""
            self.tags = []
            self.language = "en"
            self.confidenceScore = 0.0
        }
    }

    enum ValidationStatus: String, Codable {
        case pending = "Pending"
        case approved = "Approved"
        case needsReview = "Needs Review"
        case rejected = "Rejected"
    }
}

// MARK: - Localization Layer

/// Localization configuration for side-by-side panels
struct LocalizationLayer: Codable {
    var sourceLanguage: SupportedLanguage
    var targetLanguage: SupportedLanguage
    var sourceContent: String
    var translatedContent: String
    var toneStyle: ToneStyle
    var terminologyGlossary: [GlossaryEntry]
    var syncScrolling: Bool
    var validationResults: ValidationResults

    enum SupportedLanguage: String, Codable {
        case english = "en"
        case arabic = "ar"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .arabic: return "Arabic"
            }
        }
    }

    enum ToneStyle: String, Codable, CaseIterable {
        case formal = "Formal"
        case friendly = "Friendly"
        case clinical = "Clinical"
        case conversational = "Conversational"

        var icon: String {
            switch self {
            case .formal: return "briefcase"
            case .friendly: return "hand.wave"
            case .clinical: return "stethoscope"
            case .conversational: return "bubble.left.and.bubble.right"
            }
        }
    }

    struct GlossaryEntry: Identifiable, Codable {
        let id: UUID
        var sourceTerm: String
        var targetTerm: String
        var context: String
        var isLocked: Bool

        init(id: UUID = UUID(), sourceTerm: String, targetTerm: String, context: String = "", isLocked: Bool = false) {
            self.id = id
            self.sourceTerm = sourceTerm
            self.targetTerm = targetTerm
            self.context = context
            self.isLocked = isLocked
        }
    }
}

// MARK: - Smart Assets

/// Extracted or generated assets from documents
struct ExtractedAsset: Identifiable, Codable {
    let id: UUID
    var type: AssetType
    var sourceReference: String
    var content: String
    var metadata: [String: String]
    var recommendations: [AssetRecommendation]

    enum AssetType: String, Codable {
        case figure = "Figure"
        case table = "Table"
        case quote = "Quote"
        case chart = "Chart"
        case infographic = "Infographic"
        case image = "Image"
    }

    init(id: UUID = UUID(), type: AssetType, sourceReference: String, content: String) {
        self.id = id
        self.type = type
        self.sourceReference = sourceReference
        self.content = content
        self.metadata = [:]
        self.recommendations = []
    }
}

/// Recommendations for asset transformation
struct AssetRecommendation: Identifiable, Codable {
    let id: UUID
    var targetFormat: String
    var description: String
    var confidence: Double
    var previewURL: String?

    init(id: UUID = UUID(), targetFormat: String, description: String, confidence: Double = 0.8) {
        self.id = id
        self.targetFormat = targetFormat
        self.description = description
        self.confidence = confidence
        self.previewURL = nil
    }
}

// MARK: - Collaborative Review

/// Comment on a document or transformation
struct Comment: Identifiable, Codable {
    let id: UUID
    var author: String
    var content: String
    var timestamp: Date
    var position: CommentPosition?
    var status: CommentStatus
    var tags: [String]
    var replies: [Comment]

    struct CommentPosition: Codable {
        var line: Int?
        var section: String?
        var coordinates: CGPoint?
    }

    enum CommentStatus: String, Codable {
        case open = "Open"
        case resolved = "Resolved"
        case inProgress = "In Progress"
    }

    init(
        id: UUID = UUID(),
        author: String,
        content: String,
        timestamp: Date = Date(),
        status: CommentStatus = .open
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.timestamp = timestamp
        self.position = nil
        self.status = status
        self.tags = []
        self.replies = []
    }
}

/// Document revision tracking
struct Revision: Identifiable, Codable {
    let id: UUID
    var version: Int
    var content: String
    var author: String
    var timestamp: Date
    var changeDescription: String
    var branchName: String?

    init(
        id: UUID = UUID(),
        version: Int,
        content: String,
        author: String,
        changeDescription: String
    ) {
        self.id = id
        self.version = version
        self.content = content
        self.author = author
        self.timestamp = Date()
        self.changeDescription = changeDescription
        self.branchName = nil
    }
}

// MARK: - Validation & Compliance

/// Validation results for content
struct ValidationResults: Codable {
    var localizationComplete: Bool
    var citationCoverage: Double
    var privacyRedaction: RedactionStatus
    var toneCompliance: Bool
    var errors: [ValidationError]
    var warnings: [ValidationWarning]

    struct ValidationError: Identifiable, Codable {
        let id: UUID
        var message: String
        var location: String
        var severity: Severity

        enum Severity: String, Codable {
            case critical = "Critical"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
        }

        init(id: UUID = UUID(), message: String, location: String, severity: Severity = .medium) {
            self.id = id
            self.message = message
            self.location = location
            self.severity = severity
        }
    }

    struct ValidationWarning: Identifiable, Codable {
        let id: UUID
        var message: String
        var suggestion: String

        init(id: UUID = UUID(), message: String, suggestion: String) {
            self.id = id
            self.message = message
            self.suggestion = suggestion
        }
    }

    enum RedactionStatus: String, Codable {
        case complete = "Complete"
        case partial = "Partial"
        case pending = "Pending"
        case notRequired = "Not Required"
    }

    init() {
        self.localizationComplete = false
        self.citationCoverage = 0.0
        self.privacyRedaction = .pending
        self.toneCompliance = false
        self.errors = []
        self.warnings = []
    }
}

// MARK: - Platform Exports

/// Export template configuration
struct ExportTemplate: Identifiable, Codable {
    let id: UUID
    var platform: ExportPlatform
    var configuration: ExportConfiguration
    var metadata: ExportMetadata

    enum ExportPlatform: String, Codable, CaseIterable {
        case linkedInCarousel = "LinkedIn Carousel"
        case whatsAppBrief = "WhatsApp Brief"
        case applePagesbrochure = "Apple Pages Brochure"
        case fhirPatientInstructions = "FHIR Patient Instructions"
        case pdf = "PDF Document"
        case html = "HTML Page"
        case cms = "CMS Push"
        case email = "Email"

        var icon: String {
            switch self {
            case .linkedInCarousel: return "link.circle"
            case .whatsAppBrief: return "message.fill"
            case .applePagesbrochure: return "doc.richtext"
            case .fhirPatientInstructions: return "cross.case.fill"
            case .pdf: return "doc.fill"
            case .html: return "globe"
            case .cms: return "server.rack"
            case .email: return "envelope.fill"
            }
        }
    }

    struct ExportConfiguration: Codable {
        var format: String
        var template: String
        var customCSS: String?
        var includeMetadata: Bool
        var includeFooter: Bool

        init() {
            self.format = "default"
            self.template = "standard"
            self.customCSS = nil
            self.includeMetadata = true
            self.includeFooter = true
        }
    }

    struct ExportMetadata: Codable {
        var title: String
        var tags: [String]
        var complianceFooters: [String]
        var author: String
        var createdAt: Date

        init(title: String = "", author: String = "") {
            self.title = title
            self.tags = []
            self.complianceFooters = []
            self.author = author
            self.createdAt = Date()
        }
    }

    init(id: UUID = UUID(), platform: ExportPlatform, configuration: ExportConfiguration = ExportConfiguration(), metadata: ExportMetadata = ExportMetadata()) {
        self.id = id
        self.platform = platform
        self.configuration = configuration
        self.metadata = metadata
    }
}

/// Export summary for stakeholder review
struct ExportSummary: Codable {
    var channels: [ExportTemplate.ExportPlatform]
    var languages: [LocalizationLayer.SupportedLanguage]
    var approvals: [Approval]
    var validationStatus: ValidationResults
    var readyForDeployment: Bool
    var generatedAt: Date

    struct Approval: Identifiable, Codable {
        let id: UUID
        var approver: String
        var status: ApprovalStatus
        var timestamp: Date
        var notes: String

        enum ApprovalStatus: String, Codable {
            case pending = "Pending"
            case approved = "Approved"
            case rejected = "Rejected"
            case changesRequested = "Changes Requested"
        }

        init(id: UUID = UUID(), approver: String, status: ApprovalStatus = .pending, notes: String = "") {
            self.id = id
            self.approver = approver
            self.status = status
            self.timestamp = Date()
            self.notes = notes
        }
    }

    init() {
        self.channels = []
        self.languages = []
        self.approvals = []
        self.validationStatus = ValidationResults()
        self.readyForDeployment = false
        self.generatedAt = Date()
    }
}
