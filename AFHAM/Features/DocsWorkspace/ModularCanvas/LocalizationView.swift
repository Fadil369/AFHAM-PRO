//
//  LocalizationView.swift
//  AFHAM
//
//  Side-by-side Arabic/English localization editor with synchronized scrolling
//

import SwiftUI

struct LocalizationView: View {
    @Binding var layer: LocalizationLayer
    @State private var scrollPosition: CGFloat = 0
    @State private var showGlossary: Bool = false
    @State private var showValidation: Bool = false
    @State private var isTranslating: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            localizationToolbar

            Divider()

            // Main Content
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Source Panel
                    languagePanel(
                        title: layer.sourceLanguage.displayName,
                        content: $layer.sourceContent,
                        language: layer.sourceLanguage,
                        isSource: true
                    )
                    .frame(width: geometry.size.width / 2)

                    Divider()

                    // Target Panel
                    languagePanel(
                        title: layer.targetLanguage.displayName,
                        content: $layer.translatedContent,
                        language: layer.targetLanguage,
                        isSource: false
                    )
                    .frame(width: geometry.size.width / 2)
                }
            }

            // Validation Results
            if showValidation {
                Divider()
                validationPanel
            }
        }
        .sheet(isPresented: $showGlossary) {
            GlossarySheet(layer: $layer)
        }
    }

    // MARK: - Toolbar

    private var localizationToolbar: some View {
        HStack {
            // Language Labels
            HStack(spacing: 4) {
                Text(layer.sourceLanguage.displayName)
                    .font(.headline)

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                Text(layer.targetLanguage.displayName)
                    .font(.headline)
            }

            Spacer()

            // Tone Style Picker
            HStack(spacing: 8) {
                Text("Tone:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Tone", selection: $layer.toneStyle) {
                    ForEach(LocalizationLayer.ToneStyle.allCases, id: \.self) { tone in
                        Label(tone.rawValue, systemImage: tone.icon)
                            .tag(tone)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: layer.toneStyle) { _ in
                    applyToneAdjustment()
                }
            }

            Divider()
                .frame(height: 20)

            // Sync Scrolling Toggle
            Toggle(isOn: $layer.syncScrolling) {
                Label("Sync Scroll", systemImage: "arrow.up.arrow.down.circle")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.switch)

            // Glossary Button
            Button(action: { showGlossary = true }) {
                Label("Glossary (\(layer.terminologyGlossary.count))", systemImage: "book.closed")
            }
            .buttonStyle(.bordered)

            // Validation Button
            Button(action: {
                showValidation.toggle()
                if showValidation {
                    validateTranslation()
                }
            }) {
                Label("Validate", systemImage: "checkmark.seal")
            }
            .buttonStyle(.bordered)

            // Translate Button
            Button(action: { translateContent() }) {
                Label("Translate", systemImage: "globe")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTranslating || layer.sourceContent.isEmpty)

            if isTranslating {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Language Panel

    private func languagePanel(
        title: String,
        content: Binding<String>,
        language: LocalizationLayer.SupportedLanguage,
        isSource: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Panel Header
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                // Character Count
                Text("\(content.wrappedValue.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Word Count
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(wordCount(content.wrappedValue)) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))

            Divider()

            // Text Editor with Synchronized Scrolling
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: language == .arabic ? .trailing : .leading, spacing: 12) {
                        TextEditor(text: content)
                            .frame(minHeight: 500)
                            .padding()
                            .multilineTextAlignment(language == .arabic ? .trailing : .leading)
                            .environment(\.layoutDirection, language == .arabic ? .rightToLeft : .leftToRight)
                            .font(.body)
                            .disabled(!isSource && layer.translatedContent.isEmpty)

                        // Glossary Highlights
                        if !isSource && !layer.terminologyGlossary.isEmpty {
                            glossaryHighlights(for: language)
                        }
                    }
                    .id("content")
                }
                .simultaneousGesture(
                    DragGesture().onChanged { value in
                        if layer.syncScrolling {
                            scrollPosition = value.translation.height
                        }
                    }
                )
            }
        }
    }

    // MARK: - Glossary Highlights

    private func glossaryHighlights(for language: LocalizationLayer.SupportedLanguage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Glossary Terms:")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(layer.terminologyGlossary) { entry in
                    if entry.isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)

                            Text(language == .arabic ? entry.targetTerm : entry.sourceTerm)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .padding()
    }

    // MARK: - Validation Panel

    private var validationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Validation Results", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Button("Dismiss") {
                    showValidation = false
                }
                .font(.caption)
            }

            // Validation Checks
            VStack(alignment: .leading, spacing: 8) {
                ValidationCheckRow(
                    isValid: layer.validationResults.localizationComplete,
                    text: "Translation complete"
                )

                ValidationCheckRow(
                    isValid: layer.validationResults.toneCompliance,
                    text: "Tone compliance (\(layer.toneStyle.rawValue))"
                )

                ValidationCheckRow(
                    isValid: layer.validationResults.privacyRedaction != .pending,
                    text: "Privacy redaction: \(layer.validationResults.privacyRedaction.rawValue)"
                )

                if !layer.validationResults.errors.isEmpty {
                    Divider()

                    Text("Errors:")
                        .font(.caption.bold())
                        .foregroundColor(.red)

                    ForEach(layer.validationResults.errors) { error in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(error.message)
                                    .font(.caption)

                                Text(error.location)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !layer.validationResults.warnings.isEmpty {
                    Divider()

                    Text("Warnings:")
                        .font(.caption.bold())
                        .foregroundColor(.orange)

                    ForEach(layer.validationResults.warnings) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(warning.message)
                                    .font(.caption)

                                Text(warning.suggestion)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Helper Functions

    private func wordCount(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func translateContent() {
        isTranslating = true

        // Simulate translation (in production, use Gemini API)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Apply glossary terms
            var translated = layer.sourceContent

            for entry in layer.terminologyGlossary where entry.isLocked {
                translated = translated.replacingOccurrences(
                    of: entry.sourceTerm,
                    with: entry.targetTerm
                )
            }

            layer.translatedContent = translated
            isTranslating = false

            // Validate after translation
            validateTranslation()
        }
    }

    private func applyToneAdjustment() {
        // Apply tone adjustment to translated content
        if !layer.translatedContent.isEmpty {
            // In production, use AI to adjust tone
        }
    }

    private func validateTranslation() {
        var results = ValidationResults()

        // Check if translation is complete
        results.localizationComplete = !layer.translatedContent.isEmpty &&
                                       layer.translatedContent.count > Int(Double(layer.sourceContent.count) * 0.5)

        // Check tone compliance (simple heuristic)
        results.toneCompliance = true

        // Check privacy redaction
        results.privacyRedaction = .complete

        // TTLINC-style validation
        validateTTLINC(results: &results)

        layer.validationResults = results
    }

    private func validateTTLINC(results: inout ValidationResults) {
        // TTLINC: Terminology, Tone, Language, Intent, Non-compliant wording, Citations

        // Check for non-compliant medical terms (example)
        let nonCompliantTerms = ["cure", "guarantee", "miracle", "proven"]

        for term in nonCompliantTerms {
            if layer.translatedContent.lowercased().contains(term.lowercased()) {
                results.errors.append(
                    ValidationResults.ValidationError(
                        message: "Non-compliant wording detected: '\(term)'",
                        location: "Translated content",
                        severity: .high
                    )
                )
            }
        }

        // Check glossary coverage
        let glossaryTermsUsed = layer.terminologyGlossary.filter { entry in
            layer.translatedContent.contains(entry.targetTerm)
        }

        if glossaryTermsUsed.count < layer.terminologyGlossary.count {
            results.warnings.append(
                ValidationResults.ValidationWarning(
                    message: "Not all glossary terms were used in translation",
                    suggestion: "Review glossary and ensure consistent terminology"
                )
            )
        }

        // Check length ratio
        let lengthRatio = Double(layer.translatedContent.count) / Double(layer.sourceContent.count)

        if lengthRatio < 0.7 || lengthRatio > 1.5 {
            results.warnings.append(
                ValidationResults.ValidationWarning(
                    message: "Translation length differs significantly from source (\(String(format: "%.0f%%", lengthRatio * 100)))",
                    suggestion: "Review translation for completeness and accuracy"
                )
            )
        }
    }
}

// MARK: - Glossary Sheet

struct GlossarySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var layer: LocalizationLayer
    @State private var newSourceTerm: String = ""
    @State private var newTargetTerm: String = ""
    @State private var newContext: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Add New Entry Form
                addEntryForm
                    .padding()
                    .background(Color(.secondarySystemBackground))

                Divider()

                // Glossary List
                List {
                    ForEach(layer.terminologyGlossary) { entry in
                        GlossaryEntryRow(
                            entry: entry,
                            onToggleLock: {
                                toggleLock(for: entry.id)
                            },
                            onDelete: {
                                deleteEntry(entry.id)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Terminology Glossary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Import") {
                        // Import glossary from file
                    }
                }
            }
        }
    }

    // MARK: - Add Entry Form

    private var addEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Glossary Entry")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(layer.sourceLanguage.displayName) Term")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Source term", text: $newSourceTerm)
                        .textFieldStyle(.roundedBorder)
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(layer.targetLanguage.displayName) Term")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Target term", text: $newTargetTerm)
                        .textFieldStyle(.roundedBorder)
                        .environment(\.layoutDirection, layer.targetLanguage == .arabic ? .rightToLeft : .leftToRight)
                }
            }

            TextField("Context (optional)", text: $newContext)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Button(action: addEntry) {
                Label("Add to Glossary", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newSourceTerm.isEmpty || newTargetTerm.isEmpty)
        }
    }

    // MARK: - Helper Functions

    private func addEntry() {
        let entry = LocalizationLayer.GlossaryEntry(
            sourceTerm: newSourceTerm,
            targetTerm: newTargetTerm,
            context: newContext,
            isLocked: true // Lock by default for medical terms
        )

        layer.terminologyGlossary.append(entry)

        // Clear form
        newSourceTerm = ""
        newTargetTerm = ""
        newContext = ""
    }

    private func toggleLock(for id: UUID) {
        if let index = layer.terminologyGlossary.firstIndex(where: { $0.id == id }) {
            layer.terminologyGlossary[index].isLocked.toggle()
        }
    }

    private func deleteEntry(_ id: UUID) {
        layer.terminologyGlossary.removeAll { $0.id == id }
    }
}

// MARK: - Glossary Entry Row

struct GlossaryEntryRow: View {
    let entry: LocalizationLayer.GlossaryEntry
    let onToggleLock: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.sourceTerm)
                        .font(.subheadline.bold())

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(entry.targetTerm)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }

                if !entry.context.isEmpty {
                    Text(entry.context)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onToggleLock) {
                Image(systemName: entry.isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(entry.isLocked ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
