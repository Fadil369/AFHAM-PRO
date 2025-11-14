//
//  PipelineStepperView.swift
//  AFHAM
//
//  Horizontal stepper UI for multi-stage transformation pipelines
//

import SwiftUI

struct PipelineStepperView: View {
    let pipeline: TransformationPipeline
    @State private var selectedStageIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Horizontal Stepper
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(pipeline.stages.enumerated()), id: \.offset) { index, stage in
                        HStack(spacing: 0) {
                            // Stage Node
                            StageNode(
                                stage: stage,
                                index: index,
                                isActive: index == pipeline.currentStageIndex,
                                isCompleted: index < pipeline.currentStageIndex,
                                isSelected: selectedStageIndex == index
                            ) {
                                selectedStageIndex = index
                            }

                            // Connector Line (except for last stage)
                            if index < pipeline.stages.count - 1 {
                                ConnectorLine(
                                    isCompleted: index < pipeline.currentStageIndex
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Selected Stage Details
            if let selectedIndex = selectedStageIndex,
               selectedIndex < pipeline.stages.count {
                StageDetailsView(
                    stage: pipeline.stages[selectedIndex],
                    stageIndex: selectedIndex
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Stage Node

struct StageNode: View {
    let stage: TransformationStage
    let index: Int
    let isActive: Bool
    let isCompleted: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Circle with icon or number
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 48, height: 48)

                    Circle()
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 2)
                        .frame(width: 48, height: 48)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.title3.bold())
                    } else if stage.status == .processing {
                        ProgressView()
                            .tint(.white)
                    } else if stage.status == .error {
                        Image(systemName: "exclamationmark")
                            .foregroundColor(.white)
                            .font(.title3.bold())
                    } else {
                        Image(systemName: stage.type.icon)
                            .foregroundColor(iconColor)
                            .font(.body)
                    }
                }

                // Stage Label
                VStack(spacing: 2) {
                    Text(stage.type.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(isActive || isSelected ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)

                    // Status Badge
                    Text(stage.status.rawValue)
                        .font(.system(size: 9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusBackgroundColor)
                        .foregroundColor(statusTextColor)
                        .cornerRadius(4)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var backgroundColor: Color {
        if stage.status == .error {
            return .red
        } else if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if stage.status == .error {
            return .red
        } else if isCompleted {
            return .green
        } else {
            return Color(.systemGray3)
        }
    }

    private var iconColor: Color {
        if isActive {
            return .white
        } else {
            return .secondary
        }
    }

    private var statusBackgroundColor: Color {
        switch stage.status {
        case .completed:
            return .green.opacity(0.2)
        case .processing:
            return .orange.opacity(0.2)
        case .error:
            return .red.opacity(0.2)
        case .pending:
            return Color(.systemGray5)
        }
    }

    private var statusTextColor: Color {
        switch stage.status {
        case .completed:
            return .green
        case .processing:
            return .orange
        case .error:
            return .red
        case .pending:
            return .secondary
        }
    }
}

// MARK: - Connector Line

struct ConnectorLine: View {
    let isCompleted: Bool

    var body: some View {
        Rectangle()
            .fill(isCompleted ? Color.green : Color(.systemGray4))
            .frame(width: 40, height: 2)
            .padding(.bottom, 60) // Align with circle centers
    }
}

// MARK: - Stage Details View

struct StageDetailsView: View {
    let stage: TransformationStage
    let stageIndex: Int
    @State private var editedOutput: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stage \(stageIndex + 1): \(stage.type.rawValue)")
                        .font(.headline)

                    Text(stage.status.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }

                Spacer()

                if stage.isEditable && stage.output != nil {
                    Button(action: { isEditing.toggle() }) {
                        Label(isEditing ? "Done" : "Edit", systemImage: isEditing ? "checkmark.circle" : "pencil.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Parameters
            if !stage.parameters.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Parameters")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    ForEach(Array(stage.parameters.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized + ":")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(stage.parameters[key] ?? "")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Output
            if let output = stage.output {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    if isEditing {
                        TextEditor(text: $editedOutput)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .onAppear {
                                editedOutput = output
                            }
                    } else {
                        ScrollView {
                            Text(output)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
            } else if stage.status == .processing {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Processing stage...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if stage.status == .error {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("This stage encountered an error")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                Text("Waiting to process...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch stage.status {
        case .completed:
            return .green
        case .processing:
            return .orange
        case .error:
            return .red
        case .pending:
            return .secondary
        }
    }
}

// MARK: - Pipeline Progress View

struct PipelineProgressView: View {
    let pipeline: TransformationPipeline

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pipeline Progress")
                    .font(.subheadline.bold())

                Spacer()

                Text("\(pipeline.currentStageIndex + 1) / \(pipeline.stages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progressValue)
                .tint(pipeline.isComplete ? .green : .blue)

            HStack {
                ForEach(Array(pipeline.stages.enumerated()), id: \.offset) { index, stage in
                    Circle()
                        .fill(circleColor(for: stage, at: index))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var progressValue: Double {
        guard !pipeline.stages.isEmpty else { return 0 }
        return Double(pipeline.currentStageIndex + 1) / Double(pipeline.stages.count)
    }

    private func circleColor(for stage: TransformationStage, at index: Int) -> Color {
        if stage.status == .error {
            return .red
        } else if stage.status == .completed {
            return .green
        } else if index == pipeline.currentStageIndex {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
}
