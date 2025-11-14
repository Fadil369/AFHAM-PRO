// AFHAM - Document Capsule Component
// MODERN: Horizontally scrollable capsules with status grouping
// VISUAL: Progress rings and compliance badges

import SwiftUI

// MARK: - Document Status Group
enum DocumentStatusGroup: String, CaseIterable, Identifiable {
    case processing = "Processing"
    case ready = "Ready"
    case favorites = "Favorites"
    case error = "Error"

    var id: String { rawValue }

    var arabicName: String {
        switch self {
        case .processing: return "جاري المعالجة"
        case .ready:      return "جاهز"
        case .favorites:  return "المفضلة"
        case .error:      return "خطأ"
        }
    }

    var icon: String {
        switch self {
        case .processing: return "arrow.triangle.2.circlepath"
        case .ready:      return "checkmark.circle.fill"
        case .favorites:  return "star.fill"
        case .error:      return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .processing: return AFHAMConfig.signalTeal
        case .ready:      return .green
        case .favorites:  return .yellow
        case .error:      return AFHAMConfig.deepOrange
        }
    }

    func matches(document: DocumentMetadata) -> Bool {
        switch self {
        case .processing:
            return document.processingStatus == .processing
        case .ready:
            return document.processingStatus == .ready && !document.isFavorite
        case .favorites:
            return document.isFavorite
        case .error:
            return document.processingStatus == .error
        }
    }
}

// MARK: - Document Capsule View
struct DocumentCapsuleView: View {
    let document: DocumentMetadata
    let isArabic: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityEnvironment) var a11y
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(for: .buttonTap)
            onTap()
        }) {
            HStack(spacing: 12) {
                // Progress Ring + Icon
                ZStack {
                    // Background circle
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    // Progress ring (if processing)
                    if document.processingStatus == .processing, let progress = document.processingProgress {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                statusColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .calmModeAnimation(.spring(response: 0.5), value: progress)
                    }

                    // File icon
                    Image(systemName: fileIcon)
                        .font(.system(size: 26))
                        .foregroundColor(statusColor)
                }

                // Document Info
                VStack(alignment: isArabic ? .trailing : .leading, spacing: 6) {
                    // Filename + Badges
                    HStack(spacing: 8) {
                        if !isArabic {
                            Text(document.fileName)
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16), weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            badgesView
                        } else {
                            badgesView

                            Text(document.fileName)
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16), weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }

                    // Metadata Row
                    HStack(spacing: 8) {
                        // Status
                        Label(
                            statusText,
                            systemImage: statusIcon
                        )
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                        .foregroundColor(statusColor)

                        Text("•")
                            .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))

                        // File size
                        Text(formatFileSize(document.fileSize))
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                            .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))

                        // Upload time
                        if let uploadDate = document.uploadDate {
                            Text("•")
                                .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))

                            Text(relativeTime(from: uploadDate))
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                                .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                        }
                    }

                    // Progress text (if processing)
                    if document.processingStatus == .processing, let progress = document.processingProgress {
                        Text(isArabic ? "\(Int(progress * 100))% مكتمل" : "\(Int(progress * 100))% complete")
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 11), weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }

                Spacer()

                // Favorite star
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 18))
                }
            }
            .padding(16)
            .frame(width: 320, alignment: isArabic ? .trailing : .leading)
            .glassMorphism(
                elevation: elevationLevel,
                cornerRadius: 20,
                accent: statusColor
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String.accessibilityHint(for: "view document details"))
        .accessibilityValue(accessibilityValue)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if a11y.shouldAnimate {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    if a11y.shouldAnimate {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                }
        )
    }

    // MARK: - Computed Properties

    private var elevationLevel: GlassElevation {
        switch document.processingStatus {
        case .processing:
            return .elevated
        case .ready where document.isFavorite:
            return .prominent
        case .ready:
            return .base
        case .error:
            return .elevated
        default:
            return .base
        }
    }

    private var fileIcon: String {
        switch document.documentType.lowercased() {
        case "pdf":
            return "doc.richtext.fill"
        case "txt":
            return "doc.text.fill"
        case "docx", "doc":
            return "doc.fill"
        case "xlsx", "xls":
            return "tablecells.fill"
        default:
            return "doc.fill"
        }
    }

    private var statusIcon: String {
        switch document.processingStatus {
        case .ready:      return "checkmark.circle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .error:      return "exclamationmark.circle.fill"
        default:          return "clock.fill"
        }
    }

    private var statusColor: Color {
        switch document.processingStatus {
        case .ready:      return .green
        case .processing: return AFHAMConfig.signalTeal
        case .error:      return AFHAMConfig.deepOrange
        default:          return AFHAMConfig.professionalGray
        }
    }

    private var statusText: String {
        switch document.processingStatus {
        case .ready:      return isArabic ? "جاهز" : "Ready"
        case .processing: return isArabic ? "جاري المعالجة" : "Processing"
        case .error:      return isArabic ? "خطأ" : "Error"
        default:          return isArabic ? "في الانتظار" : "Pending"
        }
    }

    @ViewBuilder
    private var badgesView: some View {
        HStack(spacing: 4) {
            // PDF badge
            if document.documentType.lowercased() == "pdf" {
                BadgeView(text: "PDF", color: AFHAMConfig.signalTeal)
            }

            // Large file badge
            if document.fileSize > 10_000_000 { // > 10MB
                BadgeView(text: isArabic ? "كبير" : "Large", color: .orange)
            }

            // Indexed badge
            if document.processingStatus == .ready, let confidence = document.indexConfidence {
                BadgeView(
                    text: "\(Int(confidence * 100))%",
                    color: confidenceColor(confidence)
                )
            }
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0:  return .green
        case 0.7..<0.9:  return .yellow
        default:         return .orange
        }
    }

    // MARK: - Helper Functions

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: isArabic ? "ar-SA" : "en-US")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var accessibilityLabel: String {
        String.accessibilityLabel(
            for: document.fileName,
            type: document.documentType,
            size: formatFileSize(document.fileSize),
            status: statusText,
            progress: document.processingStatus == .processing ? Int((document.processingProgress ?? 0) * 100) : nil
        )
    }

    private var accessibilityValue: String {
        if document.isFavorite {
            return isArabic ? "مفضل" : "Favorite"
        }
        return ""
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.8))
            )
    }
}

// MARK: - Grouped Document Capsules View
struct GroupedDocumentCapsulesView: View {
    let documents: [DocumentMetadata]
    let group: DocumentStatusGroup
    let isArabic: Bool
    let onDocumentTap: (DocumentMetadata) -> Void

    @Environment(\.accessibilityEnvironment) var a11y

    private var filteredDocuments: [DocumentMetadata] {
        documents.filter { group.matches(document: $0) }
    }

    var body: some View {
        if !filteredDocuments.isEmpty {
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
                // Section Header
                HStack(spacing: 8) {
                    Image(systemName: group.icon)
                        .foregroundColor(group.accentColor)
                        .font(.system(size: 18))

                    Text(isArabic ? group.arabicName : group.rawValue)
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 20), weight: .bold))
                        .foregroundColor(.white)

                    Text("(\(filteredDocuments.count))")
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16), weight: .medium))
                        .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))

                    Spacer()
                }
                .padding(.horizontal, a11y.dynamicTypeScale.spacing(base: 20))

                // Horizontal Scrolling Capsules
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filteredDocuments) { document in
                            DocumentCapsuleView(
                                document: document,
                                isArabic: isArabic,
                                onTap: {
                                    onDocumentTap(document)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, a11y.dynamicTypeScale.spacing(base: 20))
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - All Groups View
struct DocumentCapsulesContainerView: View {
    let documents: [DocumentMetadata]
    let isArabic: Bool
    let onDocumentTap: (DocumentMetadata) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Processing
                GroupedDocumentCapsulesView(
                    documents: documents,
                    group: .processing,
                    isArabic: isArabic,
                    onDocumentTap: onDocumentTap
                )

                // Favorites
                GroupedDocumentCapsulesView(
                    documents: documents,
                    group: .favorites,
                    isArabic: isArabic,
                    onDocumentTap: onDocumentTap
                )

                // Ready
                GroupedDocumentCapsulesView(
                    documents: documents,
                    group: .ready,
                    isArabic: isArabic,
                    onDocumentTap: onDocumentTap
                )

                // Error
                GroupedDocumentCapsulesView(
                    documents: documents,
                    group: .error,
                    isArabic: isArabic,
                    onDocumentTap: onDocumentTap
                )
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - DocumentMetadata Extension
extension DocumentMetadata {
    var isFavorite: Bool {
        // TODO: Implement favorites functionality with user preferences or document metadata
        return false
    }

    var processingProgress: Double? {
        if processingStatus == .processing {
            // TODO: Get actual progress from processing pipeline
            return nil
        }
        return nil
    }

    var uploadDate: Date? {
        // TODO: Store and retrieve actual upload date from document metadata
        return self.uploadedAt
    }

    var indexConfidence: Double? {
        if processingStatus == .ready {
            // TODO: Get actual confidence score from indexing engine
            return nil
        }
        return nil
    }
}

// MARK: - Preview Provider
#if DEBUG
struct DocumentCapsuleView_Previews: PreviewProvider {
    static var sampleDocuments: [DocumentMetadata] {
        [
            DocumentMetadata(
                id: UUID(),
                fileName: "Financial_Report_2024.pdf",
                documentType: "pdf",
                fileSize: 2_458_632,
                processingStatus: .processing,
                geminiFileURI: "",
                uploadedAt: Date()
            ),
            DocumentMetadata(
                id: UUID(),
                fileName: "Contract_Agreement.docx",
                documentType: "docx",
                fileSize: 856_234,
                processingStatus: .ready,
                geminiFileURI: "",
                uploadedAt: Date()
            ),
            DocumentMetadata(
                id: UUID(),
                fileName: "Budget_Spreadsheet.xlsx",
                documentType: "xlsx",
                fileSize: 12_458_632,
                processingStatus: .ready,
                geminiFileURI: "",
                uploadedAt: Date()
            )
        ]
    }

    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AFHAMConfig.midnightBlue,
                    AFHAMConfig.medicalBlue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            DocumentCapsulesContainerView(
                documents: sampleDocuments,
                isArabic: false,
                onDocumentTap: { _ in }
            )
        }
        .preferredColorScheme(.dark)
    }
}
#endif
