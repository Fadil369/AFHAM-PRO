// AFHAM - Flow Layout Utilities
// NEURAL: Flexible flow layout for tags, chips, and dynamic content
// Standalone utility with no external dependencies
// Extracted from ModularCanvas components for shared use

import SwiftUI

// MARK: - Flow Layout

/// A custom layout that arranges views in a flowing pattern, wrapping to new lines as needed
/// Similar to CSS flexbox with flex-wrap enabled
public struct FlowLayout: Layout {
    /// The spacing between items in the same line and between lines
    public var spacing: CGFloat

    /// Creates a flow layout with the specified spacing
    /// - Parameter spacing: The spacing between items (default: 8)
    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let position = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: position, proposal: .unspecified)
        }
    }

    /// Helper struct that calculates the layout positions for all subviews
    struct FlowResult {
        var height: CGFloat = 0
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                // Check if we need to wrap to a new line
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                // Store position for this subview
                positions.append(CGPoint(x: x, y: y))

                // Update tracking variables
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            // Final height is the y position plus the last line's height
            height = y + lineHeight
        }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    /// Wraps the view in a flow layout container
    ///
    /// - Parameter spacing: The spacing between items (default: 8)
    /// - Returns: A view wrapped in a flow layout
    @ViewBuilder
    public func flowLayout(spacing: CGFloat = 8) -> some View {
        FlowLayout(spacing: spacing) {
            self
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FlowLayout_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Example 1: Tag cloud
            Text("Tag Cloud")
                .font(.headline)
                .padding(.horizontal)

            FlowLayout(spacing: 8) {
                ForEach(["Swift", "SwiftUI", "iOS", "Development", "AFHAM", "AI", "Medical", "Healthcare", "Arabic", "Bilingual"], id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)

            Divider()

            // Example 2: Feature chips
            Text("Feature Chips")
                .font(.headline)
                .padding(.horizontal)

            FlowLayout(spacing: 10) {
                ForEach(["🎤 Voice", "📄 Documents", "🤖 AI Assistant", "🌍 Bilingual", "♿️ Accessible", "🔒 Secure"], id: \.self) { feature in
                    HStack(spacing: 4) {
                        Text(feature)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.green.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal)

            Divider()

            // Example 3: Status badges
            Text("Status Badges")
                .font(.headline)
                .padding(.horizontal)

            FlowLayout(spacing: 6) {
                ForEach(["Active", "Pending", "Completed", "In Review", "Approved", "Rejected", "Draft"], id: \.self) { status in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor(for: status))
                            .frame(width: 6, height: 6)
                        Text(status)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(for: status).opacity(0.15))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
    }

    static func statusColor(for status: String) -> Color {
        switch status {
        case "Active", "Approved", "Completed": return .green
        case "Pending", "In Review", "Draft": return .orange
        case "Rejected": return .red
        default: return .gray
        }
    }
}
#endif
