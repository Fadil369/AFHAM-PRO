//
//  ModularCanvasView.swift
//  AFHAM
//
//  Main modular canvas view integrating all document workspace features
//

import SwiftUI

struct ModularCanvasView: View {
    @StateObject private var viewModel: ModularCanvasViewModel
    @State private var selectedView: CanvasView = .panels
    @State private var showRightPanel: Bool = true
    @State private var selectedRightPanelTab: RightPanelTab = .validation

    init(fileSearchManager: GeminiFileSearchManager) {
        _viewModel = StateObject(wrappedValue: ModularCanvasViewModel(fileSearchManager: fileSearchManager))
    }

    var body: some View {
        NavigationView {
            HSplitView {
                // Main Canvas Area
                mainCanvasArea
                    .frame(minWidth: 600)

                // Right Panel (Collapsible)
                if showRightPanel {
                    rightPanel
                        .frame(minWidth: 300, idealWidth: 400, maxWidth: 500)
                }
            }
            .navigationTitle("Docs Workspace")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    toolbarActions
                }
            }
        }
        .sheet(item: $selectedEditorMode) { mode in
            editorSheet(for: mode)
        }
    }

    @State private var selectedEditorMode: EditorMode?

    // MARK: - Main Canvas Area

    private var mainCanvasArea: some View {
        VStack(spacing: 0) {
            // View Selector
            viewSelectorBar

            Divider()

            // Content
            ZStack {
                switch selectedView {
                case .panels:
                    panelsGridView
                case .pipelines:
                    pipelinesView
                case .localization:
                    localizationView
                case .exports:
                    exportsView
                }
            }
        }
    }

    // MARK: - View Selector Bar

    private var viewSelectorBar: some View {
        HStack(spacing: 0) {
            ForEach(CanvasView.allCases, id: \.self) { view in
                Button(action: { selectedView = view }) {
                    VStack(spacing: 4) {
                        Image(systemName: view.icon)
                        Text(view.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedView == view ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedView == view ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Panels Grid View

    private var panelsGridView: some View {
        ScrollView {
            if viewModel.panels.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: viewModel.panelSpacing), count: viewModel.gridColumns),
                    spacing: viewModel.panelSpacing
                ) {
                    ForEach(viewModel.panels) { panel in
                        DocumentPanelView(
                            viewModel: viewModel,
                            panel: panel
                        )
                        .frame(height: 600)
                    }
                }
                .padding()
            }
        }
        .background(Color(.tertiarySystemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Documents")
                .font(.title2.bold())
                .foregroundColor(.secondary)

            Text("Upload documents to start transforming and repurposing content")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: {}) {
                Label("Upload Documents", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Pipelines View

    private var pipelinesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Pipeline Presets
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pipeline Presets")
                        .font(.title2.bold())

                    Text("Start with pre-configured transformation pipelines for common use cases")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 16) {
                        ForEach(PipelinePreset.allCases, id: \.self) { preset in
                            PresetCard(preset: preset, isSelected: false) {
                                // Create pipeline from preset
                                if let panel = viewModel.selectedPanel {
                                    viewModel.createPipeline(preset: preset, for: panel)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Active Pipelines
                if !viewModel.activePipelines.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Pipelines")
                            .font(.title2.bold())

                        ForEach(viewModel.activePipelines) { pipeline in
                            PipelineProgressView(pipeline: pipeline)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Localization View

    private var localizationView: some View {
        VStack {
            if let selectedPanel = viewModel.selectedPanel {
                LocalizationView(layer: .constant(LocalizationLayer(
                    sourceLanguage: .english,
                    targetLanguage: .arabic,
                    sourceContent: "Source content here...",
                    translatedContent: "",
                    toneStyle: .formal,
                    terminologyGlossary: [],
                    syncScrolling: true,
                    validationResults: ValidationResults()
                )))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Select a document panel to start localization")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Exports View

    private var exportsView: some View {
        VStack {
            if let selectedPanel = viewModel.selectedPanel,
               let firstPipeline = selectedPanel.activeTransformations.first {
                ExportTemplatesView(pipeline: firstPipeline)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No content to export")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Create a transformation first to export content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Tab Selector
            Picker("Panel", selection: $selectedRightPanelTab) {
                ForEach(RightPanelTab.allCases, id: \.self) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Tab Content
            ScrollView {
                if let selectedPanel = viewModel.selectedPanel {
                    switch selectedRightPanelTab {
                    case .validation:
                        ValidationChecklistView(panel: .constant(selectedPanel))
                    case .comments:
                        CollaborativeReviewView(panel: .constant(selectedPanel))
                    case .assets:
                        if let output = selectedPanel.activeTransformations.first?.output {
                            SmartAssetRecommendationsView(assets: output.assets)
                        } else {
                            emptyRightPanel(icon: "photo.on.rectangle.angled", message: "No assets detected")
                        }
                    }
                } else {
                    emptyRightPanel(icon: "sidebar.right", message: "Select a document panel")
                }
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    private func emptyRightPanel(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Toolbar Actions

    private var toolbarActions: some View {
        Group {
            // Grid Layout Controls
            Menu {
                Picker("Columns", selection: $viewModel.gridColumns) {
                    Text("1 Column").tag(1)
                    Text("2 Columns").tag(2)
                    Text("3 Columns").tag(3)
                    Text("4 Columns").tag(4)
                }

                Divider()

                Button(action: viewModel.arrangeInGrid) {
                    Label("Arrange in Grid", systemImage: "square.grid.2x2")
                }
            } label: {
                Label("Layout", systemImage: "rectangle.3.group")
            }

            // Zoom Controls
            Menu {
                Button(action: viewModel.zoomIn) {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }

                Button(action: viewModel.zoomOut) {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }

                Button(action: viewModel.resetZoom) {
                    Label("Reset Zoom", systemImage: "1.magnifyingglass")
                }
            } label: {
                Label("Zoom", systemImage: "magnifyingglass")
            }

            // Right Panel Toggle
            Button(action: { showRightPanel.toggle() }) {
                Label("Panel", systemImage: showRightPanel ? "sidebar.right" : "sidebar.left")
            }

            Divider()

            // Modal Editors
            Menu {
                Button(action: { selectedEditorMode = .slides }) {
                    Label("Slide Editor", systemImage: "rectangle.stack")
                }

                Button(action: { selectedEditorMode = .script }) {
                    Label("Script Editor", systemImage: "text.alignleft")
                }

                Button(action: { selectedEditorMode = .chatbot }) {
                    Label("Chatbot Editor", systemImage: "message.badge.waveform")
                }
            } label: {
                Label("Editors", systemImage: "pencil.and.list.clipboard")
            }
        }
    }

    // MARK: - Editor Sheets

    @ViewBuilder
    private func editorSheet(for mode: EditorMode) -> some View {
        switch mode {
        case .slides:
            SlideEditorView(configuration: .constant(SlideConfiguration(
                title: "Presentation",
                theme: .professional,
                slides: [SlideConfiguration.Slide(title: "Title", body: "Body")],
                layout: .titleAndBody
            )))

        case .script:
            ScriptEditorView(configuration: .constant(ScriptConfiguration(
                title: "Script",
                scriptType: .podcast,
                sections: [ScriptConfiguration.ScriptSection(heading: "Introduction", content: "Script content...")],
                timing: ScriptConfiguration.TimingConfiguration(),
                formatting: ScriptConfiguration.FormattingOptions()
            )))

        case .chatbot:
            ChatbotEditorView(configuration: .constant(ChatbotConfiguration(
                intent: "User question",
                response: "Bot response",
                alternativeResponses: [],
                citations: [],
                metadata: ChatbotConfiguration.ChatbotMetadata(),
                validationStatus: .pending
            )))

        case .standard:
            EmptyView()
        }
    }

    // MARK: - Supporting Types

    enum CanvasView: String, CaseIterable {
        case panels = "Panels"
        case pipelines = "Pipelines"
        case localization = "Localization"
        case exports = "Exports"

        var title: String { rawValue }

        var icon: String {
            switch self {
            case .panels: return "square.grid.2x2"
            case .pipelines: return "arrow.triangle.branch"
            case .localization: return "globe"
            case .exports: return "square.and.arrow.up"
            }
        }
    }

    enum RightPanelTab: String, CaseIterable {
        case validation = "Validation"
        case comments = "Comments"
        case assets = "Assets"

        var title: String { rawValue }

        var icon: String {
            switch self {
            case .validation: return "checkmark.seal"
            case .comments: return "bubble.left.and.bubble.right"
            case .assets: return "photo.on.rectangle.angled"
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ModularCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        ModularCanvasView(fileSearchManager: GeminiFileSearchManager(apiKey: "preview"))
            .frame(width: 1400, height: 900)
    }
}
#endif
