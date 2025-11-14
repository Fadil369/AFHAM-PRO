//
//  ScriptEditorView.swift
//  AFHAM
//
//  Teleprompter-style editor for podcast scripts and voiceovers
//

import SwiftUI

struct ScriptEditorView: View {
    @Binding var configuration: ScriptConfiguration
    @State private var selectedSectionIndex: Int = 0
    @State private var isTeleprompterMode: Bool = false
    @State private var scrollPosition: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            scriptToolbar

            Divider()

            // Main Content
            if isTeleprompterMode {
                teleprompterView
            } else {
                editorView
            }
        }
        .navigationTitle(configuration.title)
    }

    // MARK: - Toolbar

    private var scriptToolbar: some View {
        HStack {
            // Mode Toggle
            Picker("Mode", selection: $isTeleprompterMode) {
                Text("Edit").tag(false)
                Text("Teleprompter").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            if !isTeleprompterMode {
                // Script Type
                Picker("Type", selection: $configuration.scriptType) {
                    ForEach([ScriptConfiguration.ScriptType.podcast, .voiceover, .presentation, .video], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Divider()
                    .frame(height: 20)

                // Timing Settings
                Button(action: {}) {
                    Label("Timing", systemImage: "clock")
                }

                // Add Section
                Button(action: addSection) {
                    Label("Add Section", systemImage: "plus.rectangle")
                }
            } else {
                // Teleprompter Controls
                teleprompterControls
            }

            Divider()
                .frame(height: 20)

            // Export
            Button(action: exportScript) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    private var teleprompterControls: some View {
        HStack(spacing: 16) {
            // Font Size
            HStack(spacing: 8) {
                Button(action: { configuration.formatting.fontSize = max(16, configuration.formatting.fontSize - 2) }) {
                    Image(systemName: "textformat.size.smaller")
                }

                Text("\(Int(configuration.formatting.fontSize))pt")
                    .font(.caption)
                    .frame(width: 40)

                Button(action: { configuration.formatting.fontSize = min(48, configuration.formatting.fontSize + 2) }) {
                    Image(systemName: "textformat.size.larger")
                }
            }

            Divider()
                .frame(height: 20)

            // Scroll Speed
            HStack(spacing: 8) {
                Image(systemName: "tortoise")
                    .font(.caption)

                Slider(value: $configuration.formatting.scrollSpeed, in: 0.5...2.0, step: 0.1)
                    .frame(width: 120)

                Image(systemName: "hare")
                    .font(.caption)
            }

            Divider()
                .frame(height: 20)

            // Highlight Toggle
            Toggle(isOn: $configuration.formatting.highlightCurrentLine) {
                Label("Highlight", systemImage: "highlighter")
                    .labelStyle(.iconOnly)
            }
            .toggleStyle(.switch)
        }
    }

    // MARK: - Editor View

    private var editorView: some View {
        HSplitView {
            // Section List
            sectionListView
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            // Section Editor
            sectionEditorView
                .frame(minWidth: 400)

            // Preview
            scriptPreviewView
                .frame(minWidth: 350)
        }
    }

    private var sectionListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sections")
                .font(.headline)
                .padding()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(configuration.sections.enumerated()), id: \.element.id) { index, section in
                        SectionRowView(
                            section: section,
                            index: index,
                            isSelected: selectedSectionIndex == index
                        ) {
                            selectedSectionIndex = index
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            // Total Duration
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text(formatDuration(totalDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }

    private var sectionEditorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedSectionIndex < configuration.sections.count {
                let binding = Binding(
                    get: { configuration.sections[selectedSectionIndex] },
                    set: { configuration.sections[selectedSectionIndex] = $0 }
                )

                // Section Header
                HStack {
                    Text("Section \(selectedSectionIndex + 1)")
                        .font(.title2.bold())

                    Spacer()

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatDuration(binding.wrappedValue.duration))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Divider()

                // Heading Field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Section Heading", systemImage: "textformat.size")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextField("Enter section heading", text: binding.heading)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                }

                // Speaker Field (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Speaker (optional)", systemImage: "person.wave.2")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextField("Speaker name", text: Binding(
                        get: { binding.wrappedValue.speaker ?? "" },
                        set: { binding.wrappedValue.speaker = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                // Content Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Script Content", systemImage: "text.alignleft")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        Spacer()

                        // Word Count
                        Text("\(wordCount(binding.wrappedValue.content)) words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextEditor(text: binding.content)
                        .frame(minHeight: 300)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .onChange(of: binding.wrappedValue.content) { newValue in
                            updateDuration(for: binding)
                        }
                }

                // Delete Section
                if configuration.sections.count > 1 {
                    Button(role: .destructive, action: deleteCurrentSection) {
                        Label("Delete Section", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
        }
        .padding()
    }

    private var scriptPreviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(configuration.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            // Heading
                            Text(section.heading)
                                .font(.title2.bold())

                            // Speaker
                            if let speaker = section.speaker {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(speaker)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Content
                            Text(section.content)
                                .font(.body)

                            // Duration
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(formatDuration(section.duration))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)

                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Teleprompter View

    private var teleprompterView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(Array(configuration.sections.enumerated()), id: \.element.id) { index, section in
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Heading
                            Text(section.heading.uppercased())
                                .font(.system(size: configuration.formatting.fontSize * 0.8, weight: .bold))
                                .foregroundColor(.secondary)

                            // Speaker
                            if let speaker = section.speaker {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                    Text(speaker)
                                }
                                .font(.system(size: configuration.formatting.fontSize * 0.7))
                                .foregroundColor(.blue)
                            }

                            // Script Content
                            Text(section.content)
                                .font(.system(size: configuration.formatting.fontSize))
                                .lineSpacing(configuration.formatting.fontSize * 0.5)
                                .background(
                                    configuration.formatting.highlightCurrentLine ?
                                    Color.yellow.opacity(0.2) : Color.clear
                                )

                            // Pause Indicator
                            HStack {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                                Text("PAUSE (\(Int(configuration.timing.pauseDuration))s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 60)
                    }

                    // End Marker
                    VStack(spacing: 16) {
                        Text("END OF SCRIPT")
                            .font(.system(size: configuration.formatting.fontSize, weight: .bold))
                            .foregroundColor(.secondary)

                        Text("Total Duration: \(formatDuration(totalDuration))")
                            .font(.system(size: configuration.formatting.fontSize * 0.7))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 100)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Helper Functions

    private func addSection() {
        let newSection = ScriptConfiguration.ScriptSection(
            heading: "New Section",
            content: "Script content goes here..."
        )
        configuration.sections.append(newSection)
        selectedSectionIndex = configuration.sections.count - 1
    }

    private func deleteCurrentSection() {
        guard configuration.sections.count > 1 else { return }
        configuration.sections.remove(at: selectedSectionIndex)
        if selectedSectionIndex >= configuration.sections.count {
            selectedSectionIndex = configuration.sections.count - 1
        }
    }

    private func exportScript() {
        // Export logic
    }

    private func wordCount(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func updateDuration(for binding: Binding<ScriptConfiguration.ScriptSection>) {
        let words = wordCount(binding.wrappedValue.content)
        let duration = Double(words) / Double(configuration.timing.wordsPerMinute) * 60
        binding.wrappedValue.duration = duration
    }

    private var totalDuration: TimeInterval {
        configuration.sections.reduce(0) { $0 + $1.duration }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Section Row View

struct SectionRowView: View {
    let section: ScriptConfiguration.ScriptSection
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Section \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let speaker = section.speaker {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text(section.heading)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(formatDuration(section.duration))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension ScriptConfiguration.ScriptType: CaseIterable {}
