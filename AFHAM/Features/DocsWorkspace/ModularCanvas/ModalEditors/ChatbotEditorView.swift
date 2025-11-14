//
//  ChatbotEditorView.swift
//  AFHAM
//
//  Structured editor for chatbot knowledge snippets
//

import SwiftUI

struct ChatbotEditorView: View {
    @Binding var configuration: ChatbotConfiguration
    @State private var showValidationResults: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                // Intent Section
                intentSection

                // Response Section
                responseSection

                // Alternative Responses
                alternativeResponsesSection

                // Citations
                citationsSection

                // Metadata
                metadataSection

                // Validation
                validationSection

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Chatbot Snippet Editor")
        .toolbar {
            ToolbarItemGroup {
                Button(action: validateSnippet) {
                    Label("Validate", systemImage: "checkmark.seal")
                }

                Button(action: exportSnippet) {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "message.badge.waveform")
                    .font(.title)
                    .foregroundColor(.blue)

                Text("Knowledge Snippet")
                    .font(.title2.bold())
            }

            Text("Create structured chatbot responses with citations and metadata")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Intent Section

    private var intentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("User Intent / Question", systemImage: "bubble.left.fill")
                .font(.headline)
                .foregroundColor(.primary)

            Text("What question or query will trigger this response?")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("e.g., What are the side effects of this medication?", text: $configuration.intent, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            // Intent Examples
            VStack(alignment: .leading, spacing: 6) {
                Text("Similar phrases:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                HStack {
                    Button("Add variation") {
                        // Add intent variation
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Response Section

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Primary Response", systemImage: "text.bubble.fill")
                    .font(.headline)

                Spacer()

                // Character Count
                Text("\(configuration.response.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("The main response the chatbot will provide")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $configuration.response)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )

            // Tone Suggestions
            HStack(spacing: 8) {
                Text("Tone:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Formal") { adjustTone(.formal) }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Friendly") { adjustTone(.friendly) }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Clinical") { adjustTone(.clinical) }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Alternative Responses Section

    private var alternativeResponsesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Alternative Responses", systemImage: "arrow.triangle.branch")
                    .font(.headline)

                Spacer()

                Button(action: addAlternativeResponse) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Provide 2-3 variations of the response for more natural conversations")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(configuration.alternativeResponses.enumerated()), id: \.offset) { index, response in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("Alternative response \(index + 1)", text: Binding(
                        get: { configuration.alternativeResponses[index] },
                        set: { configuration.alternativeResponses[index] = $0 }
                    ), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                    Button(action: { removeAlternativeResponse(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if configuration.alternativeResponses.isEmpty {
                Text("No alternative responses added yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Citations Section

    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Citations", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)

                Spacer()

                Button(action: addCitation) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Source references for this response")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(configuration.citations.enumerated()), id: \.0) { index, citation in
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(citation.source)
                            .font(.subheadline.bold())

                        Text(citation.excerpt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        if let pageNumber = citation.pageNumber {
                            Text("Page \(pageNumber)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer()

                    Button(action: { removeCitation(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            if configuration.citations.isEmpty {
                Text("No citations added yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Metadata", systemImage: "tag.fill")
                .font(.headline)

            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                TextField("e.g., Medication, Symptoms, Treatment", text: $configuration.metadata.category)
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
                        configuration.metadata.tags.append("New Tag")
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                FlowLayout(spacing: 8) {
                    ForEach(Array(configuration.metadata.tags.enumerated()), id: \.offset) { index, tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)

                            Button(action: { configuration.metadata.tags.remove(at: index) }) {
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
            }

            // Language
            VStack(alignment: .leading, spacing: 8) {
                Text("Language")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                Picker("Language", selection: $configuration.metadata.language) {
                    Text("English").tag("en")
                    Text("Arabic").tag("ar")
                }
                .pickerStyle(.segmented)
            }

            // Confidence Score
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Confidence Score")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(format: "%.0f%%", configuration.metadata.confidenceScore * 100))
                        .font(.subheadline.bold())
                        .foregroundColor(confidenceColor)
                }

                Slider(value: $configuration.metadata.confidenceScore, in: 0...1)
                    .tint(confidenceColor)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Validation Section

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Validation Status", systemImage: validationIcon)
                    .font(.headline)
                    .foregroundColor(validationColor)

                Spacer()

                Text(configuration.validationStatus.rawValue)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(validationColor.opacity(0.1))
                    .foregroundColor(validationColor)
                    .cornerRadius(8)
            }

            // Validation Checklist
            VStack(alignment: .leading, spacing: 8) {
                ValidationCheckRow(
                    isValid: !configuration.intent.isEmpty,
                    text: "Intent defined"
                )

                ValidationCheckRow(
                    isValid: !configuration.response.isEmpty && configuration.response.count >= 20,
                    text: "Response complete (minimum 20 characters)"
                )

                ValidationCheckRow(
                    isValid: configuration.alternativeResponses.count >= 2,
                    text: "At least 2 alternative responses"
                )

                ValidationCheckRow(
                    isValid: !configuration.citations.isEmpty,
                    text: "Citations provided"
                )

                ValidationCheckRow(
                    isValid: !configuration.metadata.category.isEmpty,
                    text: "Category assigned"
                )

                ValidationCheckRow(
                    isValid: configuration.metadata.confidenceScore >= 0.7,
                    text: "Confidence score ≥ 70%"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

            // Approve/Reject Buttons
            HStack(spacing: 12) {
                Button(action: { configuration.validationStatus = .approved }) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button(action: { configuration.validationStatus = .needsReview }) {
                    Label("Needs Review", systemImage: "exclamationmark.triangle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Button(action: { configuration.validationStatus = .rejected }) {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var confidenceColor: Color {
        if configuration.metadata.confidenceScore >= 0.8 {
            return .green
        } else if configuration.metadata.confidenceScore >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var validationIcon: String {
        switch configuration.validationStatus {
        case .approved:
            return "checkmark.seal.fill"
        case .needsReview:
            return "exclamationmark.triangle.fill"
        case .rejected:
            return "xmark.seal.fill"
        case .pending:
            return "clock.fill"
        }
    }

    private var validationColor: Color {
        switch configuration.validationStatus {
        case .approved:
            return .green
        case .needsReview:
            return .orange
        case .rejected:
            return .red
        case .pending:
            return .secondary
        }
    }

    // MARK: - Helper Functions

    private func addAlternativeResponse() {
        configuration.alternativeResponses.append("")
    }

    private func removeAlternativeResponse(at index: Int) {
        configuration.alternativeResponses.remove(at: index)
    }

    private func addCitation() {
        let newCitation = Citation(
            source: "Source Document",
            pageNumber: 1,
            excerpt: "Relevant excerpt..."
        )
        configuration.citations.append(newCitation)
    }

    private func removeCitation(at index: Int) {
        configuration.citations.remove(at: index)
    }

    private func adjustTone(_ tone: LocalizationLayer.ToneStyle) {
        // Implement tone adjustment logic with AI
    }

    private func validateSnippet() {
        showValidationResults = true
        // Perform validation
    }

    private func exportSnippet() {
        // Export as JSON
    }
}

// MARK: - Validation Check Row

struct ValidationCheckRow: View {
    let isValid: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)

            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .primary : .secondary)

            Spacer()
        }
    }
}

// MARK: - Flow Layout
// FlowLayout is now available from AFHAM/Core/UI/FlowLayout.swift
// This shared utility is used across multiple ModularCanvas components
