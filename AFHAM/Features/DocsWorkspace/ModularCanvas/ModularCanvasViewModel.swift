//
//  ModularCanvasViewModel.swift
//  AFHAM
//
//  ViewModel for managing the modular canvas workspace
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ModularCanvasViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var panels: [DocumentPanel] = []
    @Published var activePipelines: [TransformationPipeline] = []
    @Published var selectedPanel: DocumentPanel?
    @Published var canvasSize: CGSize = .zero
    @Published var zoomLevel: CGFloat = 1.0
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?

    // Grid layout
    @Published var gridColumns: Int = 2
    @Published var panelSpacing: CGFloat = 16

    // MARK: - Dependencies

    private let fileSearchManager: GeminiFileSearchManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(fileSearchManager: GeminiFileSearchManager) {
        self.fileSearchManager = fileSearchManager
        setupObservers()
    }

    private func setupObservers() {
        // Monitor document changes from file search manager
        fileSearchManager.$documents
            .sink { [weak self] documents in
                self?.syncPanelsWithDocuments(documents)
            }
            .store(in: &cancellables)
    }

    // MARK: - Panel Management

    func addPanel(for document: DocumentMetadata) {
        let position = calculateNextPanelPosition()
        let panel = DocumentPanel(
            documentMetadata: document,
            position: position
        )
        panels.append(panel)
    }

    func removePanel(_ panel: DocumentPanel) {
        panels.removeAll { $0.id == panel.id }
        if selectedPanel?.id == panel.id {
            selectedPanel = nil
        }
    }

    func updatePanel(_ panel: DocumentPanel) {
        if let index = panels.firstIndex(where: { $0.id == panel.id }) {
            panels[index] = panel
        }
    }

    func selectPanel(_ panel: DocumentPanel) {
        selectedPanel = panel
    }

    private func syncPanelsWithDocuments(_ documents: [DocumentMetadata]) {
        // Add panels for new documents
        for document in documents {
            if !panels.contains(where: { $0.documentMetadata.id == document.id }) {
                addPanel(for: document)
            }
        }

        // Remove panels for deleted documents
        panels.removeAll { panel in
            !documents.contains(where: { $0.id == panel.documentMetadata.id })
        }
    }

    private func calculateNextPanelPosition() -> CGPoint {
        let rows = (panels.count / gridColumns) + 1
        let cols = panels.count % gridColumns
        let x = CGFloat(cols) * (400 + panelSpacing)
        let y = CGFloat(rows - 1) * (600 + panelSpacing)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Quick Actions

    func executeQuickAction(_ action: QuickAction, on panel: DocumentPanel) async {
        isProcessing = true
        errorMessage = nil

        do {
            switch action {
            case .summarize:
                try await executeSummarize(on: panel)
            case .translate:
                try await executeTranslate(on: panel)
            case .convertToSlides:
                try await executeConvertToSlides(on: panel)
            case .generateScript:
                try await executeGenerateScript(on: panel)
            case .socialPost:
                try await executeSocialPost(on: panel)
            case .extractAssets:
                try await executeExtractAssets(on: panel)
            case .chatbotSnippet:
                try await executeChatbotSnippet(on: panel)
            case .voiceover:
                try await executeVoiceover(on: panel)
            }
        } catch {
            errorMessage = "Failed to execute \(action.rawValue): \(error.localizedDescription)"
        }

        isProcessing = false
    }

    private func executeSummarize(on panel: DocumentPanel) async throws {
        let prompt = """
        قم بتلخيص المستند التالي بشكل شامل ومفصل:

        Please provide a comprehensive summary of the following document:

        Document: \(panel.documentMetadata.fileName)
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .summarize, parameters: [:])
        var pipeline = TransformationPipeline(name: "Summary", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .text,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeTranslate(on panel: DocumentPanel) async throws {
        let sourceLanguage = panel.documentMetadata.language
        let targetLanguage = sourceLanguage == "ar" ? "en" : "ar"

        let prompt = """
        Translate the following document from \(sourceLanguage) to \(targetLanguage):

        Document: \(panel.documentMetadata.fileName)

        Maintain the original tone and formatting.
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .translate, parameters: ["targetLanguage": targetLanguage])
        var pipeline = TransformationPipeline(name: "Translation", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .text,
            metadata: ["sourceLanguage": sourceLanguage, "targetLanguage": targetLanguage],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeConvertToSlides(on panel: DocumentPanel) async throws {
        let prompt = """
        Convert the following document into a presentation outline with slides:

        Document: \(panel.documentMetadata.fileName)

        Format:
        - Title slide
        - 5-8 content slides with title and bullet points
        - Summary slide

        Each slide should be clearly marked with [SLIDE: Title] followed by content.
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .convertToSlides, parameters: [:])
        var pipeline = TransformationPipeline(name: "Slides", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .slides,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeGenerateScript(on panel: DocumentPanel) async throws {
        let prompt = """
        Generate a presentation script based on the following document:

        Document: \(panel.documentMetadata.fileName)

        The script should:
        - Be conversational and engaging
        - Include speaker notes and timing suggestions
        - Have clear sections with headings
        - Be suitable for a 10-15 minute presentation
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .generateScript, parameters: [:])
        var pipeline = TransformationPipeline(name: "Script", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .script,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeSocialPost(on panel: DocumentPanel) async throws {
        let prompt = """
        Create engaging social media posts based on the following document:

        Document: \(panel.documentMetadata.fileName)

        Generate:
        1. LinkedIn post (professional, 1300 characters max)
        2. Twitter/X thread (3-5 tweets)
        3. Instagram caption (with hashtags)

        Include relevant hashtags and call-to-actions.
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .socialPost, parameters: [:])
        var pipeline = TransformationPipeline(name: "Social Media", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .text,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeExtractAssets(on panel: DocumentPanel) async throws {
        let prompt = """
        Extract and describe all visual assets, tables, figures, and quotes from the following document:

        Document: \(panel.documentMetadata.fileName)

        For each asset provide:
        - Type (figure/table/quote/chart)
        - Description
        - Context and relevance
        - Suggestions for visual representation
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .extractAssets, parameters: [:])
        var pipeline = TransformationPipeline(name: "Asset Extraction", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .json,
            metadata: [:],
            assets: parseExtractedAssets(from: result.0),
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeChatbotSnippet(on panel: DocumentPanel) async throws {
        let prompt = """
        Convert the following document into structured chatbot knowledge snippets:

        Document: \(panel.documentMetadata.fileName)

        For each snippet provide:
        - Intent (user question/query)
        - Response (clear, concise answer)
        - Alternative responses (2-3 variations)
        - Citations (source references)
        - Metadata (category, tags, confidence)

        Format as JSON.
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .chatbotSnippet, parameters: [:])
        var pipeline = TransformationPipeline(name: "Chatbot Snippets", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .json,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func executeVoiceover(on panel: DocumentPanel) async throws {
        let prompt = """
        Create a voiceover script optimized for audio recording based on the following document:

        Document: \(panel.documentMetadata.fileName)

        The script should:
        - Be conversational and natural for speaking
        - Include pronunciation guides for technical terms
        - Mark pauses and emphasis points
        - Estimate timing (words per minute: 150)
        - Include intro and outro sections
        """

        let result = try await fileSearchManager.queryDocuments(
            query: prompt,
            fileIDs: [panel.documentMetadata.geminiFileID].compactMap { $0 },
            storeID: panel.documentMetadata.fileSearchStoreID
        )

        var updatedPanel = panel
        let stage = TransformationStage(type: .voiceover, parameters: [:])
        var pipeline = TransformationPipeline(name: "Voiceover Script", stages: [stage])
        pipeline.output = TransformationOutput(
            content: result.0,
            format: .script,
            metadata: [:],
            assets: [],
            validationResults: ValidationResults(),
            generatedAt: Date()
        )
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    private func parseExtractedAssets(from content: String) -> [ExtractedAsset] {
        // Simple parsing - in production, use structured JSON parsing
        var assets: [ExtractedAsset] = []

        let lines = content.components(separatedBy: "\n")
        var currentAsset: ExtractedAsset?

        for line in lines {
            if line.contains("Figure") || line.contains("Table") || line.contains("Quote") || line.contains("Chart") {
                if let asset = currentAsset {
                    assets.append(asset)
                }

                let type: ExtractedAsset.AssetType
                if line.contains("Figure") {
                    type = .figure
                } else if line.contains("Table") {
                    type = .table
                } else if line.contains("Quote") {
                    type = .quote
                } else {
                    type = .chart
                }

                currentAsset = ExtractedAsset(
                    type: type,
                    sourceReference: line,
                    content: ""
                )
            } else if var asset = currentAsset {
                asset.content += line + "\n"
                currentAsset = asset
            }
        }

        if let asset = currentAsset {
            assets.append(asset)
        }

        return assets
    }

    // MARK: - Pipeline Management

    func createPipeline(preset: PipelinePreset, for panel: DocumentPanel) {
        let pipeline = TransformationPipeline(
            name: preset.rawValue,
            stages: preset.stages,
            preset: preset
        )

        var updatedPanel = panel
        updatedPanel.activeTransformations.append(pipeline)
        updatePanel(updatedPanel)
    }

    func executePipeline(_ pipeline: TransformationPipeline, for panel: DocumentPanel) async {
        isProcessing = true
        errorMessage = nil

        var updatedPipeline = pipeline

        for (index, stage) in pipeline.stages.enumerated() {
            updatedPipeline.currentStageIndex = index
            updatedPipeline.stages[index].status = .processing

            // Update UI
            if var updatedPanel = panels.first(where: { $0.id == panel.id }) {
                if let pipelineIndex = updatedPanel.activeTransformations.firstIndex(where: { $0.id == pipeline.id }) {
                    updatedPanel.activeTransformations[pipelineIndex] = updatedPipeline
                    updatePanel(updatedPanel)
                }
            }

            // Execute stage based on type
            await executeQuickAction(stage.type, on: panel)
            
            // Check if there was an error during execution
            if let error = errorMessage {
                updatedPipeline.stages[index].status = .error
                errorMessage = "Pipeline failed at stage \(index + 1): \(error)"
                break
            } else {
                updatedPipeline.stages[index].status = .completed
            }

            // Brief pause between stages
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        isProcessing = false
    }

    func updatePipelineStage(_ pipeline: TransformationPipeline, stageIndex: Int, newOutput: String, for panel: DocumentPanel) {
        var updatedPipeline = pipeline
        updatedPipeline.stages[stageIndex].output = newOutput
        updatedPipeline.updatedAt = Date()

        if var updatedPanel = panels.first(where: { $0.id == panel.id }) {
            if let pipelineIndex = updatedPanel.activeTransformations.firstIndex(where: { $0.id == pipeline.id }) {
                updatedPanel.activeTransformations[pipelineIndex] = updatedPipeline
                updatePanel(updatedPanel)
            }
        }
    }

    // MARK: - Layout Management

    func arrangeInGrid() {
        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 600

        for (index, panel) in panels.enumerated() {
            let row = index / gridColumns
            let col = index % gridColumns

            var updatedPanel = panel
            updatedPanel.position = CGPoint(
                x: CGFloat(col) * (panelWidth + panelSpacing),
                y: CGFloat(row) * (panelHeight + panelSpacing)
            )
            updatePanel(updatedPanel)
        }
    }

    func resetZoom() {
        zoomLevel = 1.0
    }

    func zoomIn() {
        zoomLevel = min(zoomLevel + 0.25, 2.0)
    }

    func zoomOut() {
        zoomLevel = max(zoomLevel - 0.25, 0.5)
    }

    // MARK: - Export Management

    func exportPipeline(_ pipeline: TransformationPipeline, as template: ExportTemplate) async -> URL? {
        guard let output = pipeline.output else { return nil }

        let fileName = "\(pipeline.name)_\(template.platform.rawValue)_\(Date().timeIntervalSince1970).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var exportContent = """
        # \(pipeline.name)
        Platform: \(template.platform.rawValue)
        Generated: \(output.generatedAt.formatted())

        ---

        \(output.content)

        ---

        """

        if template.configuration.includeMetadata {
            exportContent += "\n## Metadata\n"
            for (key, value) in output.metadata {
                exportContent += "- \(key): \(value)\n"
            }
        }

        if template.configuration.includeFooter {
            exportContent += "\n## Compliance\n"
            for footer in template.metadata.complianceFooters {
                exportContent += "\(footer)\n"
            }
        }

        do {
            try exportContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            return nil
        }
    }

    func generateExportSummary(for panel: DocumentPanel) -> ExportSummary {
        var summary = ExportSummary()

        // Collect channels from active transformations
        for pipeline in panel.activeTransformations {
            if let output = pipeline.output {
                switch output.format {
                case .slides:
                    summary.channels.append(.pdf)
                case .script:
                    summary.channels.append(.html)
                case .json:
                    summary.channels.append(.cms)
                default:
                    summary.channels.append(.pdf)
                }
            }
        }

        // Check languages
        summary.languages = [.english, .arabic]

        // Validate
        for pipeline in panel.activeTransformations {
            if let output = pipeline.output {
                summary.validationStatus = output.validationResults
            }
        }

        // Determine readiness
        summary.readyForDeployment = !summary.validationStatus.errors.isEmpty &&
                                     summary.validationStatus.localizationComplete &&
                                     summary.validationStatus.toneCompliance

        return summary
    }
}
