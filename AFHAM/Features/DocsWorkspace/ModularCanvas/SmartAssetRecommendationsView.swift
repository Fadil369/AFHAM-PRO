//
//  SmartAssetRecommendationsView.swift
//  AFHAM
//
//  AI-powered asset detection and visual recommendations
//

import SwiftUI

struct SmartAssetRecommendationsView: View {
    let assets: [ExtractedAsset]
    @State private var selectedAsset: ExtractedAsset?
    @State private var isGeneratingVisuals: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                if assets.isEmpty {
                    emptyStateView
                } else {
                    // Assets Grid
                    assetsGridView

                    // Selected Asset Details
                    if let selected = selectedAsset {
                        Divider()
                        assetDetailsView(for: selected)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Smart Assets")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title)
                    .foregroundColor(.purple)

                Text("Smart Asset Recommendations")
                    .font(.title2.bold())
            }

            Text("AI-detected figures, tables, and quotes with visual transformation suggestions")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "photo",
                    count: assets.filter { $0.type == .figure }.count,
                    label: "Figures"
                )

                StatBadge(
                    icon: "tablecells",
                    count: assets.filter { $0.type == .table }.count,
                    label: "Tables"
                )

                StatBadge(
                    icon: "quote.opening",
                    count: assets.filter { $0.type == .quote }.count,
                    label: "Quotes"
                )

                StatBadge(
                    icon: "chart.bar",
                    count: assets.filter { $0.type == .chart }.count,
                    label: "Charts"
                )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Assets Detected")
                .font(.title3.bold())
                .foregroundColor(.secondary)

            Text("Run 'Extract Assets' from the quick actions to detect visual elements in your document")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Assets Grid

    private var assetsGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
            ForEach(assets) { asset in
                AssetCardView(
                    asset: asset,
                    isSelected: selectedAsset?.id == asset.id
                ) {
                    selectedAsset = asset
                }
            }
        }
    }

    // MARK: - Asset Details View

    private func assetDetailsView(for asset: ExtractedAsset) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Asset Details")
                    .font(.headline)

                Spacer()

                Button(action: { selectedAsset = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Asset Info
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Type", value: asset.type.rawValue, icon: assetIcon(for: asset.type))
                InfoRow(label: "Source", value: asset.sourceReference, icon: "doc.text")

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    Text(asset.content)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                }

                Divider()

                // Recommendations
                if !asset.recommendations.isEmpty {
                    recommendationsSection(for: asset)
                } else {
                    Button(action: { generateRecommendations(for: asset) }) {
                        Label("Generate Visual Recommendations", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGeneratingVisuals)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Recommendations Section

    private func recommendationsSection(for asset: ExtractedAsset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Visual Recommendations")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { generateRecommendations(for: asset) }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isGeneratingVisuals)

                if isGeneratingVisuals {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            ForEach(asset.recommendations) { recommendation in
                RecommendationCardView(recommendation: recommendation) {
                    applyRecommendation(recommendation, to: asset)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func assetIcon(for type: ExtractedAsset.AssetType) -> String {
        switch type {
        case .figure:
            return "photo"
        case .table:
            return "tablecells"
        case .quote:
            return "quote.opening"
        case .chart:
            return "chart.bar"
        case .infographic:
            return "chart.pie"
        case .image:
            return "photo.fill"
        }
    }

    private func generateRecommendations(for asset: ExtractedAsset) {
        isGeneratingVisuals = true

        // Simulate AI recommendation generation
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            var updatedAsset = asset
            updatedAsset.recommendations = generateMockRecommendations(for: asset)

            // Update the asset in the list
            await MainActor.run {
                isGeneratingVisuals = false
                selectedAsset = updatedAsset
            }
        }
    }

    private func generateMockRecommendations(for asset: ExtractedAsset) -> [AssetRecommendation] {
        switch asset.type {
        case .figure:
            return [
                AssetRecommendation(
                    targetFormat: "Infographic",
                    description: "Convert to modern infographic with BrainSAIT brand colors",
                    confidence: 0.92
                ),
                AssetRecommendation(
                    targetFormat: "Diagram",
                    description: "Create flowchart or process diagram",
                    confidence: 0.85
                ),
                AssetRecommendation(
                    targetFormat: "Icon Set",
                    description: "Transform into icon-based representation",
                    confidence: 0.78
                )
            ]

        case .table:
            return [
                AssetRecommendation(
                    targetFormat: "Bar Chart",
                    description: "Visualize data as comparative bar chart",
                    confidence: 0.88
                ),
                AssetRecommendation(
                    targetFormat: "Data Grid",
                    description: "Enhanced interactive data table with sorting",
                    confidence: 0.90
                ),
                AssetRecommendation(
                    targetFormat: "Dashboard Card",
                    description: "Convert to dashboard-style KPI cards",
                    confidence: 0.82
                )
            ]

        case .quote:
            return [
                AssetRecommendation(
                    targetFormat: "Pull Quote",
                    description: "Large, stylized pull quote for emphasis",
                    confidence: 0.95
                ),
                AssetRecommendation(
                    targetFormat: "Testimonial Card",
                    description: "Formatted testimonial with attribution",
                    confidence: 0.88
                ),
                AssetRecommendation(
                    targetFormat: "Social Card",
                    description: "Quote card optimized for social media",
                    confidence: 0.85
                )
            ]

        case .chart:
            return [
                AssetRecommendation(
                    targetFormat: "Interactive Chart",
                    description: "Dynamic chart with hover interactions",
                    confidence: 0.90
                ),
                AssetRecommendation(
                    targetFormat: "Comparison View",
                    description: "Side-by-side comparison visualization",
                    confidence: 0.86
                ),
                AssetRecommendation(
                    targetFormat: "Trend Line",
                    description: "Simplified trend visualization",
                    confidence: 0.82
                )
            ]

        case .infographic, .image:
            return [
                AssetRecommendation(
                    targetFormat: "Optimized Image",
                    description: "Web-optimized version with placeholders",
                    confidence: 0.92
                )
            ]
        }
    }

    private func applyRecommendation(_ recommendation: AssetRecommendation, to asset: ExtractedAsset) {
        // Apply visual transformation
        print("Applying \(recommendation.targetFormat) to \(asset.type.rawValue)")
    }
}

// MARK: - Asset Card View

struct AssetCardView: View {
    let asset: ExtractedAsset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: assetIcon)
                        .font(.title2)
                        .foregroundColor(assetColor)
                        .frame(width: 40, height: 40)
                        .background(assetColor.opacity(0.1))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.type.rawValue)
                            .font(.headline)

                        Text(asset.sourceReference)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if !asset.recommendations.isEmpty {
                        Badge(
                            count: asset.recommendations.count,
                            label: "ideas",
                            color: .purple
                        )
                    }
                }

                // Content Preview
                Text(asset.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Metadata
                if !asset.metadata.isEmpty {
                    Divider()

                    FlowLayout(spacing: 6) {
                        ForEach(Array(asset.metadata.keys.sorted()), id: \.self) { key in
                            if let value = asset.metadata[key] {
                                Text("\(key): \(value)")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? assetColor.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? assetColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var assetIcon: String {
        switch asset.type {
        case .figure: return "photo"
        case .table: return "tablecells"
        case .quote: return "quote.opening"
        case .chart: return "chart.bar"
        case .infographic: return "chart.pie"
        case .image: return "photo.fill"
        }
    }

    private var assetColor: Color {
        switch asset.type {
        case .figure, .image, .infographic: return .blue
        case .table: return .green
        case .quote: return .orange
        case .chart: return .purple
        }
    }
}

// MARK: - Recommendation Card View

struct RecommendationCardView: View {
    let recommendation: AssetRecommendation
    let onApply: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.targetFormat)
                        .font(.subheadline.bold())

                    Spacer()

                    // Confidence Badge
                    HStack(spacing: 4) {
                        Image(systemName: confidenceIcon)
                            .font(.caption2)
                        Text("\(Int(recommendation.confidence * 100))%")
                            .font(.caption.bold())
                    }
                    .foregroundColor(confidenceColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.1))
                    .cornerRadius(12)
                }

                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Preview (if available)
                if let previewURL = recommendation.previewURL {
                    Text("Preview: \(previewURL)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                Button(action: onApply) {
                    Label("Apply Transformation", systemImage: "wand.and.stars")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private var confidenceIcon: String {
        if recommendation.confidence >= 0.9 {
            return "star.fill"
        } else if recommendation.confidence >= 0.8 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }

    private var confidenceColor: Color {
        if recommendation.confidence >= 0.9 {
            return .green
        } else if recommendation.confidence >= 0.75 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.headline)
            }
            .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

struct Badge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.caption.bold())
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}
