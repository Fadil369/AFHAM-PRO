//
//  DocumentPanelView.swift
//  AFHAM
//
//  Panel view for individual documents with quick actions and live previews
//

import SwiftUI

struct DocumentPanelView: View {
    @ObservedObject var viewModel: ModularCanvasViewModel
    @State var panel: DocumentPanel
    @State private var showPreview: Bool = true
    @State private var selectedAction: QuickAction?
    @State private var showPipelineBuilder: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader

            // Content Area
            if panel.isExpanded {
                VStack(spacing: 12) {
                    // Quick Actions
                    quickActionsGrid

                    Divider()

                    // Preview/Output Area
                    previewArea
                        .frame(maxHeight: .infinity)
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    viewModel.selectedPanel?.id == panel.id ? Color.blue : Color.gray.opacity(0.2),
                    lineWidth: viewModel.selectedPanel?.id == panel.id ? 2 : 1
                )
        )
        .onTapGesture {
            viewModel.selectPanel(panel)
        }
    }

    // MARK: - Panel Header

    private var panelHeader: some View {
        HStack {
            // Document Icon
            Image(systemName: documentIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(panel.documentMetadata.fileName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Status Badge
                    statusBadge

                    // File Size
                    Text(formatFileSize(panel.documentMetadata.fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Language
                    Text(panel.documentMetadata.language.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Spacer()

            // Actions Menu
            Menu {
                Button(action: { showPipelineBuilder = true }) {
                    Label("Create Pipeline", systemImage: "arrow.triangle.branch")
                }

                Button(action: { togglePreview() }) {
                    Label(showPreview ? "Hide Preview" : "Show Preview", systemImage: "eye")
                }

                Button(action: { toggleExpanded() }) {
                    Label(panel.isExpanded ? "Collapse" : "Expand", systemImage: panel.isExpanded ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                }

                Divider()

                Button(role: .destructive, action: { viewModel.removePanel(panel) }) {
                    Label("Remove Panel", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .sheet(isPresented: $showPipelineBuilder) {
            PipelineBuilderSheet(viewModel: viewModel, panel: panel)
        }
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(panel.quickActions, id: \.self) { action in
                QuickActionButton(action: action) {
                    selectedAction = action
                    Task {
                        await viewModel.executeQuickAction(action, on: panel)
                    }
                }
                .disabled(viewModel.isProcessing)
            }
        }
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output Preview")
                    .font(.headline)

                Spacer()

                // Preview Mode Picker
                Picker("Mode", selection: $panel.previewMode) {
                    ForEach([PreviewMode.source, .sideBySide, .preview], id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }

            ScrollView {
                if panel.activeTransformations.isEmpty {
                    emptyPreviewState
                } else {
                    transformationsListView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    private var emptyPreviewState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No transformations yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Use quick actions above to start repurposing this document")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }

    private var transformationsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(panel.activeTransformations) { pipeline in
                TransformationOutputView(
                    pipeline: pipeline,
                    previewMode: panel.previewMode
                )
            }
        }
    }

    // MARK: - Helper Views

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(panel.documentMetadata.processingStatus.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var documentIcon: String {
        let fileName = panel.documentMetadata.fileName.lowercased()
        if fileName.hasSuffix(".pdf") {
            return "doc.fill"
        } else if fileName.hasSuffix(".docx") || fileName.hasSuffix(".doc") {
            return "doc.text.fill"
        } else if fileName.hasSuffix(".pptx") {
            return "rectangle.stack.fill"
        } else if fileName.hasSuffix(".xlsx") {
            return "tablecells.fill"
        } else {
            return "doc"
        }
    }

    private var statusColor: Color {
        switch panel.documentMetadata.processingStatus {
        case .ready:
            return .green
        case .processing, .uploading:
            return .orange
        case .indexed:
            return .blue
        case .error:
            return .red
        }
    }

    // MARK: - Helper Functions

    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    private func togglePreview() {
        showPreview.toggle()
    }

    private func toggleExpanded() {
        var updatedPanel = panel
        updatedPanel.isExpanded.toggle()
        viewModel.updatePanel(updatedPanel)
        panel = updatedPanel
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(action.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transformation Output View

struct TransformationOutputView: View {
    let pipeline: TransformationPipeline
    let previewMode: PreviewMode
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.purple)

                Text(pipeline.name)
                    .font(.headline)

                Spacer()

                // Status
                if pipeline.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                // Pipeline Stages
                if !pipeline.stages.isEmpty {
                    PipelineStepperView(pipeline: pipeline)
                        .padding(.vertical, 8)
                }

                // Output Content
                if let output = pipeline.output {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Output", systemImage: "doc.text")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(output.format.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }

                        ScrollView {
                            Text(output.content)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)

                        // Export Actions
                        HStack {
                            Button(action: { copyToClipboard(output.content) }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)

                            Button(action: { /* Export */ }) {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Pipeline Builder Sheet

struct PipelineBuilderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ModularCanvasViewModel
    let panel: DocumentPanel

    @State private var selectedPreset: PipelinePreset?
    @State private var customStages: [TransformationStage] = []
    @State private var pipelineName: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Presets Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pipeline Presets")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(PipelinePreset.allCases, id: \.self) { preset in
                                PresetCard(preset: preset, isSelected: selectedPreset == preset) {
                                    selectedPreset = preset
                                }
                            }
                        }
                    }

                    Divider()

                    // Custom Pipeline Builder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Pipeline")
                            .font(.headline)

                        TextField("Pipeline Name", text: $pipelineName)
                            .textFieldStyle(.roundedBorder)

                        Text("Add Stages:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(QuickAction.allCases, id: \.self) { action in
                            Button(action: {
                                customStages.append(TransformationStage(type: action))
                            }) {
                                HStack {
                                    Image(systemName: action.icon)
                                    Text(action.rawValue)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        if !customStages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pipeline Stages:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(Array(customStages.enumerated()), id: \.offset) { index, stage in
                                    HStack {
                                        Text("\(index + 1).")
                                            .foregroundColor(.secondary)
                                        Text(stage.type.rawValue)
                                        Spacer()
                                        Button(action: {
                                            customStages.remove(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Create Pipeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPipeline()
                        dismiss()
                    }
                    .disabled(selectedPreset == nil && (pipelineName.isEmpty || customStages.isEmpty))
                }
            }
        }
    }

    private func createPipeline() {
        if let preset = selectedPreset {
            viewModel.createPipeline(preset: preset, for: panel)
        } else if !pipelineName.isEmpty && !customStages.isEmpty {
            let pipeline = TransformationPipeline(
                name: pipelineName,
                stages: customStages
            )
            var updatedPanel = panel
            updatedPanel.activeTransformations.append(pipeline)
            viewModel.updatePanel(updatedPanel)
        }
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: PipelinePreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundColor(.blue)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Text(preset.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
