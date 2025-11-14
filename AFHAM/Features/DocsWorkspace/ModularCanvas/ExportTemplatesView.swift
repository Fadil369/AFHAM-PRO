//
//  ExportTemplatesView.swift
//  AFHAM
//
//  Platform-ready export templates with one-click actions
//

import SwiftUI

struct ExportTemplatesView: View {
    let pipeline: TransformationPipeline
    @State private var selectedTemplate: ExportTemplate?
    @State private var customMetadata: ExportTemplate.ExportMetadata
    @State private var isExporting: Bool = false
    @State private var exportedURL: URL?
    @State private var showShareSheet: Bool = false

    init(pipeline: TransformationPipeline) {
        self.pipeline = pipeline
        _customMetadata = State(initialValue: ExportTemplate.ExportMetadata(
            title: pipeline.name,
            author: "AFHAM User"
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                // Platform Templates Grid
                platformTemplatesGrid

                Divider()

                // Metadata Editor
                if selectedTemplate != nil {
                    metadataEditor
                }

                // Export Button
                if selectedTemplate != nil {
                    exportButton
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Export Templates")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                Text("Platform-Ready Exports")
                    .font(.title2.bold())
            }

            Text("Export your content to various platforms with auto-filled metadata and compliance footers")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Platform Templates Grid

    private var platformTemplatesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Export Platform")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ExportTemplate.ExportPlatform.allCases, id: \.self) { platform in
                    PlatformTemplateCard(
                        platform: platform,
                        isSelected: selectedTemplate?.platform == platform
                    ) {
                        selectTemplate(for: platform)
                    }
                }
            }
        }
    }

    // MARK: - Metadata Editor

    private var metadataEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Metadata")
                .font(.headline)

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                TextField("Export title", text: $customMetadata.title)
                    .textFieldStyle(.roundedBorder)
            }

            // Author
            VStack(alignment: .leading, spacing: 8) {
                Text("Author")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                TextField("Author name", text: $customMetadata.author)
                    .textFieldStyle(.roundedBorder)
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tags")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Add Tag") {
                        customMetadata.tags.append("New Tag")
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                FlowLayout(spacing: 8) {
                    ForEach(Array(customMetadata.tags.enumerated()), id: \.offset) { index, tag in
                        TagView(tag: tag) {
                            customMetadata.tags.remove(at: index)
                        }
                    }
                }
            }

            // Compliance Footers
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Compliance Footers")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Add Footer") {
                        customMetadata.complianceFooters.append("Compliance footer text")
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                ForEach(Array(customMetadata.complianceFooters.enumerated()), id: \.offset) { index, footer in
                    HStack(alignment: .top, spacing: 8) {
                        TextField("Footer text", text: Binding(
                            get: { customMetadata.complianceFooters[index] },
                            set: { customMetadata.complianceFooters[index] = $0 }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                        Button(action: {
                            customMetadata.complianceFooters.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Preset Footers
                Menu("Add Preset Footer") {
                    Button("PDPL Compliance") {
                        customMetadata.complianceFooters.append("This content complies with Saudi PDPL regulations")
                    }

                    Button("BrainSAIT Footer") {
                        customMetadata.complianceFooters.append("Powered by BrainSAIT Healthcare AI Platform")
                    }

                    Button("Medical Disclaimer") {
                        customMetadata.complianceFooters.append("This information is for educational purposes only. Consult a healthcare professional for medical advice.")
                    }

                    Button("Copyright Notice") {
                        customMetadata.complianceFooters.append("© \(Calendar.current.component(.year, from: Date())) All rights reserved.")
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Export Button

    private var exportButton: some View {
        VStack(spacing: 12) {
            Button(action: performExport) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Export to \(selectedTemplate?.platform.rawValue ?? "")")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)

            if let url = exportedURL {
                HStack(spacing: 12) {
                    Button(action: { showShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: copyToClipboard) {
                        Label("Copy Path", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Text("Exported to: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helper Functions

    private func selectTemplate(for platform: ExportTemplate.ExportPlatform) {
        selectedTemplate = ExportTemplate(
            platform: platform,
            configuration: ExportTemplate.ExportConfiguration(),
            metadata: customMetadata
        )
    }

    private func performExport() {
        guard var template = selectedTemplate,
              let output = pipeline.output else { return }

        isExporting = true
        template.metadata = customMetadata

        Task {
            let exportedContent = generateExportContent(for: template, output: output)
            let url = saveExport(content: exportedContent, template: template)

            await MainActor.run {
                exportedURL = url
                isExporting = false
            }
        }
    }

    private func generateExportContent(for template: ExportTemplate, output: TransformationOutput) -> String {
        var content = ""

        switch template.platform {
        case .linkedInCarousel:
            content = generateLinkedInCarousel(output: output, metadata: template.metadata)

        case .whatsAppBrief:
            content = generateWhatsAppBrief(output: output, metadata: template.metadata)

        case .applePagesbrochure:
            content = generateApplePagesBrochure(output: output, metadata: template.metadata)

        case .fhirPatientInstructions:
            content = generateFHIRInstructions(output: output, metadata: template.metadata)

        case .pdf:
            content = generatePDF(output: output, metadata: template.metadata)

        case .html:
            content = generateHTML(output: output, metadata: template.metadata)

        case .cms:
            content = generateCMS(output: output, metadata: template.metadata)

        case .email:
            content = generateEmail(output: output, metadata: template.metadata)
        }

        return content
    }

    // MARK: - Platform-Specific Generators

    private func generateLinkedInCarousel(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        var carousel = """
        # LinkedIn Carousel: \(metadata.title)

        ## Slide 1 (Cover)
        \(metadata.title)
        By \(metadata.author)

        ---

        """

        // Split content into slides (max 10 slides)
        let paragraphs = output.content.components(separatedBy: "\n\n")
        let slideCount = min(paragraphs.count + 2, 10)

        for (index, paragraph) in paragraphs.prefix(slideCount - 2).enumerated() {
            carousel += """
            ## Slide \(index + 2)
            \(paragraph)

            ---

            """
        }

        carousel += """
        ## Slide \(slideCount) (CTA)
        Thanks for reading!

        \(metadata.tags.map { "#\($0.replacingOccurrences(of: " ", with: ""))" }.joined(separator: " "))

        ---

        """

        // Add footers
        for footer in metadata.complianceFooters {
            carousel += "\n\(footer)\n"
        }

        return carousel
    }

    private func generateWhatsAppBrief(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        var brief = """
        *\(metadata.title)*

        \(output.content.prefix(500))

        """

        if output.content.count > 500 {
            brief += "...\n\n"
        }

        brief += "\n---\n"
        for footer in metadata.complianceFooters {
            brief += "\(footer)\n"
        }

        return brief
    }

    private func generateApplePagesBrochure(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        """
        # \(metadata.title)

        **Author:** \(metadata.author)
        **Date:** \(Date().formatted(date: .long, time: .omitted))

        ---

        \(output.content)

        ---

        ## Tags
        \(metadata.tags.joined(separator: ", "))

        ## Compliance
        \(metadata.complianceFooters.joined(separator: "\n\n"))
        """
    }

    private func generateFHIRInstructions(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        """
        {
          "resourceType": "Communication",
          "id": "\(UUID().uuidString)",
          "status": "completed",
          "category": [{
            "coding": [{
              "system": "http://terminology.hl7.org/CodeSystem/communication-category",
              "code": "instruction",
              "display": "Instruction"
            }]
          }],
          "subject": {
            "reference": "Patient/example"
          },
          "payload": [{
            "contentString": "\(output.content.replacingOccurrences(of: "\"", with: "\\\""))"
          }],
          "note": [{
            "text": "\(metadata.complianceFooters.joined(separator: " "))"
          }],
          "meta": {
            "tag": [
              \(metadata.tags.map { "{\"code\": \"\($0)\"}" }.joined(separator: ",\n      "))
            ]
          }
        }
        """
    }

    private func generatePDF(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        // Generate PDF-ready markdown
        """
        # \(metadata.title)

        **Author:** \(metadata.author)
        **Generated:** \(Date().formatted(date: .long, time: .shortened))

        ---

        \(output.content)

        \(metadata.complianceFooters.isEmpty ? "" : "---\n\n## Compliance\n\n" + metadata.complianceFooters.joined(separator: "\n\n"))
        """
    }

    private func generateHTML(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(metadata.title)</title>
            <meta name="author" content="\(metadata.author)">
            <meta name="keywords" content="\(metadata.tags.joined(separator: ", "))">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.6; }
                h1 { color: #333; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
                .metadata { color: #666; font-size: 0.9em; margin-bottom: 30px; }
                .content { margin: 30px 0; }
                .footer { margin-top: 50px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 0.85em; color: #666; }
            </style>
        </head>
        <body>
            <h1>\(metadata.title)</h1>
            <div class="metadata">
                <p><strong>Author:</strong> \(metadata.author)</p>
                <p><strong>Date:</strong> \(Date().formatted(date: .long, time: .omitted))</p>
                <p><strong>Tags:</strong> \(metadata.tags.joined(separator: ", "))</p>
            </div>
            <div class="content">
                <p>\(output.content.replacingOccurrences(of: "\n", with: "</p><p>"))</p>
            </div>
            <div class="footer">
                \(metadata.complianceFooters.map { "<p>\($0)</p>" }.joined(separator: "\n"))
            </div>
        </body>
        </html>
        """
    }

    private func generateCMS(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        """
        {
          "title": "\(metadata.title)",
          "author": "\(metadata.author)",
          "content": "\(output.content.replacingOccurrences(of: "\"", with: "\\\""))",
          "tags": [\(metadata.tags.map { "\"\($0)\"" }.joined(separator: ", "))],
          "metadata": {
            "format": "\(output.format.rawValue)",
            "generatedAt": "\(output.generatedAt.ISO8601Format())",
            "complianceFooters": [\(metadata.complianceFooters.map { "\"\($0)\"" }.joined(separator: ", "))]
          }
        }
        """
    }

    private func generateEmail(output: TransformationOutput, metadata: ExportTemplate.ExportMetadata) -> String {
        """
        Subject: \(metadata.title)

        Dear Recipient,

        \(output.content)

        Best regards,
        \(metadata.author)

        ---
        \(metadata.complianceFooters.joined(separator: "\n"))
        """
    }

    private func saveExport(content: String, template: ExportTemplate) -> URL {
        let fileName = "\(template.metadata.title)_\(template.platform.rawValue)_\(Date().timeIntervalSince1970)"
        let fileExtension: String

        switch template.platform {
        case .html:
            fileExtension = "html"
        case .fhirPatientInstructions, .cms:
            fileExtension = "json"
        case .pdf:
            fileExtension = "md"
        default:
            fileExtension = "txt"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension(fileExtension)

        try? content.write(to: url, atomically: true, encoding: .utf8)

        return url
    }

    private func copyToClipboard() {
        guard let url = exportedURL else { return }

        #if os(iOS)
        UIPasteboard.general.string = url.path
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        #endif
    }
}

// MARK: - Platform Template Card

struct PlatformTemplateCard: View {
    let platform: ExportTemplate.ExportPlatform
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: platform.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                Text(platform.rawValue)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(platformDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var platformDescription: String {
        switch platform {
        case .linkedInCarousel:
            return "Multi-slide carousel format"
        case .whatsAppBrief:
            return "Brief text for messaging"
        case .applePagesbrochure:
            return "Formatted brochure document"
        case .fhirPatientInstructions:
            return "FHIR-compliant JSON"
        case .pdf:
            return "PDF-ready document"
        case .html:
            return "Standalone web page"
        case .cms:
            return "CMS push format"
        case .email:
            return "Email template"
        }
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
