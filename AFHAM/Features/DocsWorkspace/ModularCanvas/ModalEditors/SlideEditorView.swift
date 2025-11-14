//
//  SlideEditorView.swift
//  AFHAM
//
//  Modal-specific editor for slide deck creation with preview
//

import SwiftUI

struct SlideEditorView: View {
    @Binding var configuration: SlideConfiguration
    @State private var selectedSlideIndex: Int = 0
    @State private var showThemePicker: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Slide List (Thumbnail View)
            slideListView
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            Divider()

            // Main Editor
            slideEditorView
                .frame(minWidth: 400)

            Divider()

            // Preview Panel
            slidePreviewView
                .frame(minWidth: 400)
        }
        .navigationTitle("Slide Editor")
        .toolbar {
            ToolbarItemGroup {
                // Add Slide
                Button(action: addSlide) {
                    Label("Add Slide", systemImage: "plus.rectangle")
                }

                // Theme Picker
                Button(action: { showThemePicker.toggle() }) {
                    Label("Theme", systemImage: "paintpalette")
                }

                Divider()

                // Export
                Button(action: exportSlides) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerSheet(selectedTheme: $configuration.theme)
        }
    }

    // MARK: - Slide List View

    private var slideListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Slides")
                .font(.headline)
                .padding()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(configuration.slides.enumerated()), id: \.element.id) { index, slide in
                        SlideThumbnailView(
                            slide: slide,
                            index: index,
                            isSelected: selectedSlideIndex == index
                        ) {
                            selectedSlideIndex = index
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            // Add Slide Button
            Button(action: addSlide) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Slide")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Slide Editor View

    private var slideEditorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedSlideIndex < configuration.slides.count {
                let binding = Binding(
                    get: { configuration.slides[selectedSlideIndex] },
                    set: { configuration.slides[selectedSlideIndex] = $0 }
                )

                // Slide Number
                HStack {
                    Text("Slide \(selectedSlideIndex + 1)")
                        .font(.title2.bold())

                    Spacer()

                    // Layout Picker
                    Picker("Layout", selection: binding.layout) {
                        ForEach([SlideConfiguration.SlideLayout.title, .titleAndBody, .twoColumn, .imageAndText], id: \.self) { layout in
                            Text(layout.rawValue).tag(layout)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // Title Field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Title", systemImage: "textformat.size.larger")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextField("Enter slide title", text: binding.title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                }

                // Body Field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Body", systemImage: "text.alignleft")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextEditor(text: binding.body)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                // Speaker Notes
                VStack(alignment: .leading, spacing: 8) {
                    Label("Speaker Notes", systemImage: "note.text")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextEditor(text: binding.notes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                // Delete Slide
                if configuration.slides.count > 1 {
                    Button(role: .destructive, action: deleteCurrentSlide) {
                        Label("Delete Slide", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
        }
        .padding()
    }

    // MARK: - Slide Preview View

    private var slidePreviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.headline)

                Spacer()

                Text(configuration.theme.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            if selectedSlideIndex < configuration.slides.count {
                SlidePreviewCard(
                    slide: configuration.slides[selectedSlideIndex],
                    theme: configuration.theme
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Helper Functions

    private func addSlide() {
        let newSlide = SlideConfiguration.Slide(
            title: "New Slide",
            body: "Slide content goes here..."
        )
        configuration.slides.append(newSlide)
        selectedSlideIndex = configuration.slides.count - 1
    }

    private func deleteCurrentSlide() {
        guard configuration.slides.count > 1 else { return }
        configuration.slides.remove(at: selectedSlideIndex)
        if selectedSlideIndex >= configuration.slides.count {
            selectedSlideIndex = configuration.slides.count - 1
        }
    }

    private func exportSlides() {
        // Export logic
    }
}

// MARK: - Slide Thumbnail View

struct SlideThumbnailView: View {
    let slide: SlideConfiguration.Slide
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Mini Preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .frame(height: 120)
                    .overlay(
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slide.title)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(2)

                            Text(slide.body)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    )

                // Slide Number
                Text("Slide \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slide Preview Card

struct SlidePreviewCard: View {
    let slide: SlideConfiguration.Slide
    let theme: SlideConfiguration.SlideTheme

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Slide Content
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(slide.title)
                        .font(.system(size: min(geometry.size.width / 15, 32), weight: .bold))
                        .foregroundColor(titleColor)

                    // Body
                    Text(slide.body)
                        .font(.system(size: min(geometry.size.width / 25, 18)))
                        .foregroundColor(bodyColor)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Footer
                HStack {
                    Spacer()
                    Text(theme.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }

    private var backgroundColor: Color {
        switch theme {
        case .professional:
            return Color(.systemBackground)
        case .training:
            return Color.blue.opacity(0.05)
        case .medical:
            return Color.green.opacity(0.05)
        case .creative:
            return Color.purple.opacity(0.05)
        }
    }

    private var titleColor: Color {
        switch theme {
        case .professional:
            return .primary
        case .training:
            return .blue
        case .medical:
            return .green
        case .creative:
            return .purple
        }
    }

    private var bodyColor: Color {
        .primary
    }
}

// MARK: - Theme Picker Sheet

struct ThemePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTheme: SlideConfiguration.SlideTheme

    var body: some View {
        NavigationView {
            List(SlideConfiguration.SlideTheme.allCases, id: \.self) { theme in
                Button(action: {
                    selectedTheme = theme
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.rawValue)
                                .font(.headline)

                            Text(themeDescription(for: theme))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func themeDescription(for theme: SlideConfiguration.SlideTheme) -> String {
        switch theme {
        case .professional:
            return "Clean and business-focused design"
        case .training:
            return "Educational and engaging layout"
        case .medical:
            return "Healthcare-appropriate styling"
        case .creative:
            return "Vibrant and modern appearance"
        }
    }
}
