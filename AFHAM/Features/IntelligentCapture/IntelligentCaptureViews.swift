//
//  IntelligentCaptureViews.swift
//  AFHAM - Intelligent Capture UI Components
//
//  SwiftUI views for document capture, analysis, and results display
//

import SwiftUI
import AVFoundation

// MARK: - Main Intelligent Capture View

struct IntelligentCaptureView: View {

    @StateObject private var captureManager: IntelligentCaptureManager
    @StateObject private var cameraManager: CameraIntakeManager

    @State private var selectedDocumentType: DocumentType = .generic
    @State private var showingResults = false
    @State private var currentInsight: CapturedInsight?
    @State private var showingHistory = false
    @State private var userConsentPHI = false

    init(captureManager: IntelligentCaptureManager) {
        _captureManager = StateObject(wrappedValue: captureManager)
        _cameraManager = StateObject(wrappedValue: captureManager.getCameraManager())
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                if showingResults, let insight = currentInsight {
                    // Results View
                    CaptureResultView(
                        insight: insight,
                        onDismiss: {
                            showingResults = false
                            currentInsight = nil
                        }
                    )
                } else if showingHistory {
                    // History View
                    CaptureHistoryView(
                        insights: captureManager.capturedInsights,
                        onSelect: { insight in
                            currentInsight = insight
                            showingHistory = false
                            showingResults = true
                        },
                        onDismiss: {
                            showingHistory = false
                        }
                    )
                } else {
                    // Camera View
                    VStack(spacing: 0) {
                        // Camera preview
                        CameraPreviewView(manager: cameraManager)
                            .frame(maxHeight: .infinity)
                            .overlay(alignment: .topLeading) {
                                // Document detection overlays
                                DocumentDetectionOverlay(detectedDocuments: cameraManager.detectedDocuments)
                            }

                        // Controls
                        CaptureControlsView(
                            selectedType: $selectedDocumentType,
                            batchMode: cameraManager.batchMode,
                            pageCount: cameraManager.currentPageCount,
                            onCapture: {
                                captureDocument()
                            },
                            onToggleBatch: {
                                if cameraManager.batchMode {
                                    cameraManager.finalizeBatch()
                                } else {
                                    cameraManager.enableBatchMode()
                                }
                            },
                            onShowHistory: {
                                showingHistory = true
                            }
                        )
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }

                // Processing overlay
                if captureManager.isProcessing {
                    ProcessingOverlay(
                        stage: captureManager.currentStage,
                        progress: captureManager.progress
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Intelligent Capture")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Allow PHI Processing", isOn: $userConsentPHI)

                        Button(action: { showingHistory = true }) {
                            Label("View History", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .task {
                do {
                    try await cameraManager.startSession()
                    await captureManager.loadInsights()
                } catch {
                    print("Failed to start camera: \(error)")
                }
            }
        }
    }

    private func captureDocument() {
        cameraManager.captureDocument()

        // Wait for image to be captured
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let capturedImage = cameraManager.capturedImages.last {
                processDocument(capturedImage.image)
            }
        }
    }

    private func processDocument(_ image: UIImage) {
        Task {
            do {
                let insight = try await captureManager.processDocument(
                    image: image,
                    documentType: selectedDocumentType,
                    userConsent: userConsentPHI
                )

                await MainActor.run {
                    currentInsight = insight
                    showingResults = true
                }
            } catch {
                print("Processing failed: \(error)")
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let manager: CameraIntakeManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = manager.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Document Detection Overlay

struct DocumentDetectionOverlay: View {
    let detectedDocuments: [DetectedDocument]

    var body: some View {
        GeometryReader { geometry in
            ForEach(detectedDocuments) { doc in
                Path { path in
                    let frame = CGRect(
                        x: doc.boundingBox.origin.x * geometry.size.width,
                        y: doc.boundingBox.origin.y * geometry.size.height,
                        width: doc.boundingBox.width * geometry.size.width,
                        height: doc.boundingBox.height * geometry.size.height
                    )

                    path.addRect(frame)
                }
                .stroke(Color.green, lineWidth: 2)
            }
        }
    }
}

// MARK: - Capture Controls

struct CaptureControlsView: View {
    @Binding var selectedType: DocumentType
    let batchMode: Bool
    let pageCount: Int
    let onCapture: () -> Void
    let onToggleBatch: () -> Void
    let onShowHistory: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Document type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        DocumentTypeButton(
                            type: type,
                            isSelected: selectedType == type,
                            onTap: { selectedType = type }
                        )
                    }
                }
            }

            HStack(spacing: 20) {
                // History button
                Button(action: onShowHistory) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.gray.opacity(0.3)))
                }

                // Capture button
                Button(action: onCapture) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)

                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }

                // Batch mode button
                Button(action: onToggleBatch) {
                    VStack(spacing: 4) {
                        Image(systemName: batchMode ? "doc.on.doc.fill" : "doc.on.doc")
                            .font(.title2)
                            .foregroundColor(batchMode ? .blue : .white)

                        if batchMode {
                            Text("\(pageCount)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.gray.opacity(0.3)))
                }
            }
        }
    }
}

struct DocumentTypeButton: View {
    let type: DocumentType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)

                Text(type.displayName)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? .blue : .white)
            .padding(8)
            .frame(width: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlay: View {
    let stage: ProcessingStage
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2)

                VStack(spacing: 8) {
                    Text(stage.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.1))
            )
        }
    }
}

// MARK: - Capture Result View

struct CaptureResultView: View {
    let insight: CapturedInsight
    let onDismiss: () -> Void

    @State private var selectedTab = 0
    @State private var showingExport = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with image thumbnail
                    if let imageData = insight.capturedDocument.imageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }

                    // Deferred cloud analysis badge
                    if insight.deferredCloudAnalysis {
                        HStack {
                            Image(systemName: "cloud.slash")
                            Text("Some analysis deferred - will complete when online")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Tabs
                    Picker("View", selection: $selectedTab) {
                        Text("Summary").tag(0)
                        Text("Text").tag(1)
                        Text("Insights").tag(2)
                        if insight.templateAnalysis != nil {
                            Text("Analysis").tag(3)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Tab content
                    Group {
                        switch selectedTab {
                        case 0:
                            SummaryView(insight: insight)
                        case 1:
                            TextView(text: insight.unifiedText)
                        case 2:
                            InsightsView(insight: insight)
                        case 3:
                            if let templateAnalysis = insight.templateAnalysis {
                                TemplateAnalysisView(analysis: templateAnalysis)
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Document Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExport = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportView(insight: insight)
            }
        }
    }
}

// MARK: - Summary View

struct SummaryView: View {
    let insight: CapturedInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Document type
            HStack {
                Image(systemName: insight.capturedDocument.documentType.icon)
                Text(insight.capturedDocument.documentType.displayName)
                    .font(.headline)
            }

            // Confidence score
            HStack {
                Text("Confidence:")
                    .foregroundColor(.secondary)

                ProgressView(value: insight.overallConfidence)
                    .frame(maxWidth: 200)

                Text("\(Int(insight.overallConfidence * 100))%")
                    .font(.caption)
            }

            Divider()

            // Summary text
            Text(insight.unifiedSummary)
                .font(.body)

            if !insight.allActionItems.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Action Items")
                        .font(.headline)

                    ForEach(insight.allActionItems) { action in
                        ActionItemRow(action: action)
                    }
                }
            }
        }
    }
}

struct ActionItemRow: View {
    let action: ActionItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: priorityIcon(action.priority))
                .foregroundColor(priorityColor(action.priority))

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    func priorityIcon(_ priority: ActionPriority) -> String {
        switch priority {
        case .urgent: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "circle.fill"
        }
    }

    func priorityColor(_ priority: ActionPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

// MARK: - Text View

struct TextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Extracted Text")
                .font(.headline)

            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Insights View

struct InsightsView: View {
    let insight: CapturedInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let openAI = insight.openAIAnalysis, !openAI.keyInsights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Insights")
                        .font(.headline)

                    ForEach(openAI.keyInsights, id: \.self) { insightText in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(insightText)
                                .font(.body)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            if let gemini = insight.geminiAnalysis {
                Divider()

                // Bilingual summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bilingual Summary")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("English")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(gemini.bilingualSummary.english)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("العربية")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(gemini.bilingualSummary.arabic)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }

                // Compliance checks
                if !gemini.complianceChecks.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compliance")
                            .font(.headline)

                        ForEach(gemini.complianceChecks) { check in
                            ComplianceCheckRow(check: check)
                        }
                    }
                }
            }
        }
    }
}

struct ComplianceCheckRow: View {
    let check: ComplianceCheck

    var body: some View {
        HStack {
            Image(systemName: statusIcon(check.status))
                .foregroundColor(statusColor(check.status))

            VStack(alignment: .leading, spacing: 2) {
                Text(check.rule)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(check.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(statusColor(check.status).opacity(0.1))
        .cornerRadius(8)
    }

    func statusIcon(_ status: ComplianceStatus) -> String {
        switch status {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .notApplicable: return "minus.circle.fill"
        }
    }

    func statusColor(_ status: ComplianceStatus) -> Color {
        switch status {
        case .passed: return .green
        case .failed: return .red
        case .warning: return .orange
        case .notApplicable: return .gray
        }
    }
}

// MARK: - Template Analysis View

struct TemplateAnalysisView: View {
    let analysis: TemplateAnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Findings
            if !analysis.specificFindings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Findings")
                        .font(.headline)

                    ForEach(analysis.specificFindings) { finding in
                        FindingRow(finding: finding)
                    }
                }
            }

            // Interpretations
            if !analysis.interpretations.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Interpretations")
                        .font(.headline)

                    ForEach(analysis.interpretations) { interpretation in
                        InterpretationRow(interpretation: interpretation)
                    }
                }
            }

            // Recommendations
            if !analysis.recommendations.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)

                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            Text(recommendation)
                        }
                    }
                }
            }
        }
    }
}

struct FindingRow: View {
    let finding: TemplateFinding

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(finding.key)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let normalRange = finding.normalRange {
                    Text("Normal: \(normalRange)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(finding.value)
                        .fontWeight(.semibold)

                    if let unit = finding.unit {
                        Text(unit)
                            .font(.caption)
                    }
                }

                Circle()
                    .fill(finding.status.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(8)
        .background(finding.status.color.opacity(0.05))
        .cornerRadius(8)
    }
}

struct InterpretationRow: View {
    let interpretation: Interpretation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(interpretation.title)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(interpretation.description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Spacer()
                Text("Confidence: \(Int(interpretation.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - History View

struct CaptureHistoryView: View {
    let insights: [CapturedInsight]
    let onSelect: (CapturedInsight) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List(insights) { insight in
                Button(action: { onSelect(insight) }) {
                    HStack {
                        if let imageData = insight.capturedDocument.imageData,
                           let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .clipped()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.capturedDocument.documentType.displayName)
                                .font(.headline)

                            Text(insight.timestamp, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(insight.unifiedSummary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Capture History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    let insight: CapturedInsight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(ExportFormat.allCases, id: \.self) { format in
                Button(action: {
                    exportAs(format)
                }) {
                    HStack {
                        Image(systemName: format.icon)
                        Text(format.displayName)
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportAs(_ format: ExportFormat) {
        // Export functionality will be implemented in ExportManager
        let exportManager = ExportManager()
        Task {
            do {
                try await exportManager.export(insight: insight, format: format)
                dismiss()
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}
