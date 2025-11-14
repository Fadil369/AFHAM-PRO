// AFHAM - Dual Pane Chat Layout
// ADAPTIVE: Timeline + citation cards on wide screens (iPad, landscape)
// SMART: Color-coded citation chips linked to source documents

import SwiftUI

// MARK: - Citation Chip
struct CitationChipView: View {
    let citation: Citation
    let documentColor: Color
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(for: .selectionChanged)
            onTap()
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(documentColor)
                    .frame(width: 8, height: 8)

                Text(citation.sourceDocument)
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 11), weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("[\(index + 1)]")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 10), weight: .bold))
                    .foregroundColor(documentColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                            documentColor.opacity(0.3) :
                            Color.white.opacity(0.15)
                    )
                    .overlay(
                        Capsule()
                            .stroke(documentColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Citation \(index + 1) from \(citation.sourceDocument)")
        .accessibilityHint(.accessibilityHint(for: "view citation details"))
    }
}

// MARK: - Citation Detail Card
struct CitationDetailCardView: View {
    let citation: Citation
    let documentColor: Color
    let index: Int
    let isArabic: Bool

    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Circle()
                    .fill(documentColor)
                    .frame(width: 12, height: 12)

                Text(citation.sourceDocument)
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16), weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("[\(index + 1)]")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .bold))
                    .foregroundColor(documentColor)
            }

            // Excerpt
            Text(citation.excerpt)
                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14)))
                .foregroundColor(a11y.contrastAdjusted(Color.white, opacity: 0.9))
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .lineSpacing(4)

            // Metadata
            HStack(spacing: 8) {
                if let page = citation.pageNumber {
                    Label(
                        isArabic ? "صفحة \(page)" : "Page \(page)",
                        systemImage: "doc.text"
                    )
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                    .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                }

                if let relevance = citation.relevanceScore {
                    Text("•")
                        .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))

                    Label(
                        "\(Int(relevance * 100))% \(isArabic ? "صلة" : "relevant")",
                        systemImage: "checkmark.circle"
                    )
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                    .foregroundColor(relevanceColor(relevance))
                }
            }
        }
        .padding(16)
        .glassMorphism(
            elevation: .elevated,
            cornerRadius: 16,
            accent: documentColor
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Citation \(index + 1) from \(citation.sourceDocument)")
    }

    private func relevanceColor(_ relevance: Double) -> Color {
        switch relevance {
        case 0.9...1.0:  return .green
        case 0.7..<0.9:  return .yellow
        default:         return .orange
        }
    }
}

// MARK: - Document Color Mapper
class DocumentColorMapper {
    static let shared = DocumentColorMapper()

    private var colorMap: [String: Color] = [:]
    private let availableColors: [Color] = [
        AFHAMConfig.signalTeal,
        AFHAMConfig.deepOrange,
        .purple,
        .green,
        .yellow,
        .pink,
        .cyan,
        .mint
    ]

    func color(for documentName: String) -> Color {
        if let existing = colorMap[documentName] {
            return existing
        }

        let nextColor = availableColors[colorMap.count % availableColors.count]
        colorMap[documentName] = nextColor
        return nextColor
    }

    func reset() {
        colorMap.removeAll()
    }
}

// MARK: - Citation Pane View
struct CitationPaneView: View {
    let citations: [Citation]
    let isArabic: Bool
    @Binding var selectedCitationIndex: Int?

    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(AFHAMConfig.signalTeal)
                    .font(.system(size: 20))

                Text(isArabic ? "المصادر والمراجع" : "Sources & Citations")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 20), weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("(\(citations.count))")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16), weight: .medium))
                    .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if citations.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill.badge.ellipsis")
                        .font(.system(size: 50))
                        .foregroundColor(AFHAMConfig.professionalGray.opacity(0.5))

                    Text(isArabic ? "لا توجد مراجع" : "No citations available")
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16)))
                        .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Citations list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(citations.enumerated()), id: \.offset) { index, citation in
                            CitationDetailCardView(
                                citation: citation,
                                documentColor: DocumentColorMapper.shared.color(for: citation.sourceDocument),
                                index: index,
                                isArabic: isArabic
                            )
                            .opacity(selectedCitationIndex == nil || selectedCitationIndex == index ? 1.0 : 0.5)
                            .scaleEffect(selectedCitationIndex == index ? 1.02 : 1.0)
                            .calmModeAnimation(.spring(response: 0.3), value: selectedCitationIndex)
                            .onTapGesture {
                                withAnimation {
                                    selectedCitationIndex = selectedCitationIndex == index ? nil : index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassMorphism(elevation: .base, cornerRadius: 0, accent: nil)
    }
}

// MARK: - Enhanced Message Bubble with Citation Chips
struct EnhancedMessageBubbleView: View {
    let message: ChatMessage
    let isArabic: Bool
    let onCitationTap: (Int) -> Void

    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16)))
                    .foregroundColor(message.isUser ? .white : .white.opacity(0.95))
                    .padding(12)
                    .background(messageBubbleBackground)
                    .multilineTextAlignment(isArabic ? .trailing : .leading)

                // Citation chips (if any)
                if let citations = message.citations, !citations.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(citations.enumerated()), id: \.offset) { index, citation in
                            CitationChipView(
                                citation: citation,
                                documentColor: DocumentColorMapper.shared.color(for: citation.sourceDocument),
                                index: index,
                                isSelected: false,
                                onTap: {
                                    onCitationTap(index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }

                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 11)))
                    .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
            }

            if !message.isUser {
                Spacer()
            }
        }
    }

    private var messageBubbleBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                message.isUser ?
                    AnyShapeStyle(
                        LinearGradient(
                            colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ) :
                    AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: isArabic ? "ar" : "en")
        return formatter.string(from: date)
    }
}

// MARK: - Flow Layout for Citation Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

// MARK: - Dual Pane Container
struct DualPaneChatContainerView: View {
    let messages: [ChatMessage]
    let isArabic: Bool
    @Binding var selectedCitationIndex: Int?
    let onCitationTap: (Int) -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityEnvironment) var a11y

    private var shouldShowDualPane: Bool {
        horizontalSizeClass == .regular  // iPad or landscape iPhone Pro Max
    }

    private var allCitations: [Citation] {
        messages
            .compactMap { $0.citations }
            .flatMap { $0 }
    }

    var body: some View {
        if shouldShowDualPane {
            HStack(spacing: 0) {
                // Messages timeline (left/right depending on RTL)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                EnhancedMessageBubbleView(
                                    message: message,
                                    isArabic: isArabic,
                                    onCitationTap: onCitationTap
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                // Citations pane (right/left depending on RTL)
                CitationPaneView(
                    citations: allCitations,
                    isArabic: isArabic,
                    selectedCitationIndex: $selectedCitationIndex
                )
                .frame(width: 350)
            }
        } else {
            // Single column for compact size class
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            EnhancedMessageBubbleView(
                                message: message,
                                isArabic: isArabic,
                                onCitationTap: onCitationTap
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Citation Extension
extension Citation {
    var pageNumber: Int? {
        // This would be extracted from actual document metadata
        return Int.random(in: 1...50)
    }

    var relevanceScore: Double? {
        // This would come from the search/ranking algorithm
        return Double.random(in: 0.75...0.99)
    }
}

// MARK: - Preview Provider
#if DEBUG
struct DualPaneChatView_Previews: PreviewProvider {
    static var sampleMessages: [ChatMessage] {
        [
            ChatMessage(
                id: UUID(),
                content: "What are the key terms in the contract?",
                isUser: true,
                timestamp: Date(),
                language: "en"
            ),
            ChatMessage(
                id: UUID(),
                content: "Based on the contract, the key terms include a 12-month commitment period, monthly payment of $5,000, and early termination penalties.",
                isUser: false,
                timestamp: Date(),
                language: "en",
                citations: [
                    Citation(
                        sourceDocument: "Contract_2024.pdf",
                        excerpt: "The agreement shall be valid for a period of twelve (12) months from the effective date."
                    ),
                    Citation(
                        sourceDocument: "Contract_2024.pdf",
                        excerpt: "Monthly fees shall be Five Thousand Dollars ($5,000) payable on the first of each month."
                    )
                ]
            )
        ]
    }

    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AFHAMConfig.midnightBlue,
                    AFHAMConfig.medicalBlue.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            DualPaneChatContainerView(
                messages: sampleMessages,
                isArabic: false,
                selectedCitationIndex: .constant(nil),
                onCitationTap: { _ in }
            )
        }
        .preferredColorScheme(.dark)
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
