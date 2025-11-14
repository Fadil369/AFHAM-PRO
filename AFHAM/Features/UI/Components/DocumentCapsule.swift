// AFHAM - Document Capsule View
// NEURAL: Compact document display with glass morphism design
// BILINGUAL: RTL/LTR adaptive layouts with Arabic/English support
// Dependencies: GlassMorphism, AccessibilityHelpers (from Core/UI)

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Info

/// Represents basic document information for display
public struct DocumentInfo: Identifiable, Codable {
    public let id: UUID
    public let nameEnglish: String
    public let nameArabic: String
    public let type: DocumentType
    public let sizeBytes: Int64
    public let dateModified: Date
    public let thumbnailURL: URL?
    public let tags: [String]

    public enum DocumentType: String, Codable {
        case pdf, image, text, word, excel, powerpoint, medical, prescription, labResult

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .image: return "photo"
            case .text: return "doc.text"
            case .word: return "doc.richtext"
            case .excel: return "tablecells"
            case .powerpoint: return "play.rectangle.fill"
            case .medical: return "cross.case.fill"
            case .prescription: return "pills.fill"
            case .labResult: return "chart.bar.doc.horizontal.fill"
            }
        }

        var color: Color {
            switch self {
            case .pdf: return .red
            case .image: return .blue
            case .text: return .gray
            case .word: return .blue
            case .excel: return .green
            case .powerpoint: return .orange
            case .medical: return .red
            case .prescription: return .purple
            case .labResult: return .teal
            }
        }

        var nameEnglish: String {
            switch self {
            case .pdf: return "PDF"
            case .image: return "Image"
            case .text: return "Text"
            case .word: return "Document"
            case .excel: return "Spreadsheet"
            case .powerpoint: return "Presentation"
            case .medical: return "Medical"
            case .prescription: return "Prescription"
            case .labResult: return "Lab Result"
            }
        }

        var nameArabic: String {
            switch self {
            case .pdf: return "PDF"
            case .image: return "صورة"
            case .text: return "نص"
            case .word: return "مستند"
            case .excel: return "جدول بيانات"
            case .powerpoint: return "عرض تقديمي"
            case .medical: return "طبي"
            case .prescription: return "وصفة طبية"
            case .labResult: return "نتيجة مختبر"
            }
        }
    }

    public init(
        id: UUID = UUID(),
        nameEnglish: String,
        nameArabic: String,
        type: DocumentType,
        sizeBytes: Int64,
        dateModified: Date = Date(),
        thumbnailURL: URL? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.nameEnglish = nameEnglish
        self.nameArabic = nameArabic
        self.type = type
        self.sizeBytes = sizeBytes
        self.dateModified = dateModified
        self.thumbnailURL = thumbnailURL
        self.tags = tags
    }

    /// Format file size in human-readable format
    public var formattedSize: String {
        let kb = Double(sizeBytes) / 1024.0
        let mb = kb / 1024.0

        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(sizeBytes) B"
        }
    }
}

// MARK: - Document Capsule View

/// Compact capsule-style view for displaying document information
public struct DocumentCapsule: View {
    let document: DocumentInfo
    let isArabic: Bool
    let style: CapsuleStyle
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    @State private var isPressed = false

    public enum CapsuleStyle {
        case compact   // Small, icon + name only
        case standard  // Icon + name + size + date
        case detailed  // All info including tags

        var height: CGFloat {
            switch self {
            case .compact: return 50
            case .standard: return 70
            case .detailed: return 100
            }
        }
    }

    public init(
        document: DocumentInfo,
        isArabic: Bool = false,
        style: CapsuleStyle = .standard,
        onTap: @escaping () -> Void = {},
        onDelete: (() -> Void)? = nil
    ) {
        self.document = document
        self.isArabic = isArabic
        self.style = style
        self.onTap = onTap
        self.onDelete = onDelete
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Document icon
                documentIcon

                // Document info
                VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                    // Name
                    Text(isArabic ? document.nameArabic : document.nameEnglish)
                        .font(style == .compact ? .subheadline : .headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(isArabic ? .trailing : .leading)

                    if style != .compact {
                        // Type and size
                        HStack(spacing: 8) {
                            Text(isArabic ? document.type.nameArabic : document.type.nameEnglish)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Circle()
                                .fill(Color.secondary)
                                .frame(width: 3, height: 3)

                            Text(document.formattedSize)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if style == .detailed {
                                Circle()
                                    .fill(Color.secondary)
                                    .frame(width: 3, height: 3)

                                Text(formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Tags (detailed style only)
                    if style == .detailed && !document.tags.isEmpty {
                        FlowLayout(spacing: 4) {
                            ForEach(document.tags.prefix(3), id: \.self) { tag in
                                tagBadge(tag)
                            }
                        }
                    }
                }

                Spacer()

                // Delete button (if provided)
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }

                // Chevron indicator
                Image(systemName: isArabic ? "chevron.left" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: style.height)
            .glassMorphism(
                style: .thin,
                tintColor: isPressed ? document.type.color : .white,
                cornerRadius: style == .compact ? 12 : 16
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .bilingualAccessibility(
            labelArabic: "\(document.type.nameArabic) - \(document.nameArabic)",
            labelEnglish: "\(document.type.nameEnglish) - \(document.nameEnglish)",
            hintArabic: "اضغط لفتح المستند",
            hintEnglish: "Tap to open document"
        )
    }

    private var documentIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(document.type.color.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: document.type.icon)
                .font(.title3)
                .foregroundColor(document.type.color)
        }
    }

    private func tagBadge(_ tag: String) -> some View {
        Text(tag)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(6)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: document.dateModified)
    }
}

// MARK: - Document List View

/// List view for displaying multiple document capsules
public struct DocumentCapsuleList: View {
    let documents: [DocumentInfo]
    let isArabic: Bool
    let style: DocumentCapsule.CapsuleStyle
    let onDocumentTap: (DocumentInfo) -> Void
    let onDocumentDelete: ((DocumentInfo) -> Void)?

    public init(
        documents: [DocumentInfo],
        isArabic: Bool = false,
        style: DocumentCapsule.CapsuleStyle = .standard,
        onDocumentTap: @escaping (DocumentInfo) -> Void,
        onDocumentDelete: ((DocumentInfo) -> Void)? = nil
    ) {
        self.documents = documents
        self.isArabic = isArabic
        self.style = style
        self.onDocumentTap = onDocumentTap
        self.onDocumentDelete = onDocumentDelete
    }

    public var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(documents) { document in
                DocumentCapsule(
                    document: document,
                    isArabic: isArabic,
                    style: style,
                    onTap: { onDocumentTap(document) },
                    onDelete: onDocumentDelete != nil ? { onDocumentDelete?(document) } : nil
                )
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct DocumentCapsule_Previews: PreviewProvider {
    static let sampleDocuments = [
        DocumentInfo(
            nameEnglish: "Patient Medical History",
            nameArabic: "التاريخ الطبي للمريض",
            type: .medical,
            sizeBytes: 2_500_000,
            tags: ["Medical", "Important", "2024"]
        ),
        DocumentInfo(
            nameEnglish: "Lab Results - Blood Test",
            nameArabic: "نتائج المختبر - فحص الدم",
            type: .labResult,
            sizeBytes: 1_200_000,
            tags: ["Lab", "Blood Test"]
        ),
        DocumentInfo(
            nameEnglish: "Prescription - Dr. Ahmed",
            nameArabic: "وصفة طبية - د. أحمد",
            type: .prescription,
            sizeBytes: 850_000,
            tags: ["Prescription", "Urgent"]
        ),
        DocumentInfo(
            nameEnglish: "MRI Scan Report",
            nameArabic: "تقرير فحص الرنين المغناطيسي",
            type: .pdf,
            sizeBytes: 15_000_000,
            tags: ["MRI", "Radiology"]
        ),
        DocumentInfo(
            nameEnglish: "Insurance Document",
            nameArabic: "وثيقة التأمين",
            type: .word,
            sizeBytes: 450_000,
            tags: ["Insurance"]
        )
    ]

    static var previews: some View {
        Group {
            // English - Different Styles
            ScrollView {
                VStack(spacing: 20) {
                    Text("Document Capsules - English")
                        .font(.title2.bold())
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compact Style")
                            .font(.headline)
                            .padding(.horizontal)

                        DocumentCapsuleList(
                            documents: Array(sampleDocuments.prefix(2)),
                            isArabic: false,
                            style: .compact,
                            onDocumentTap: { doc in print("Tapped: \(doc.nameEnglish)") }
                        )
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Standard Style")
                            .font(.headline)
                            .padding(.horizontal)

                        DocumentCapsuleList(
                            documents: Array(sampleDocuments.prefix(3)),
                            isArabic: false,
                            style: .standard,
                            onDocumentTap: { doc in print("Tapped: \(doc.nameEnglish)") },
                            onDocumentDelete: { doc in print("Deleted: \(doc.nameEnglish)") }
                        )
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detailed Style")
                            .font(.headline)
                            .padding(.horizontal)

                        DocumentCapsuleList(
                            documents: Array(sampleDocuments.prefix(2)),
                            isArabic: false,
                            style: .detailed,
                            onDocumentTap: { doc in print("Tapped: \(doc.nameEnglish)") }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Arabic Version
            ScrollView {
                VStack(spacing: 20) {
                    Text("كبسولات المستندات - العربية")
                        .font(.title2.bold())
                        .padding(.top)

                    VStack(alignment: .trailing, spacing: 8) {
                        Text("نمط مفصل")
                            .font(.headline)
                            .padding(.horizontal)

                        DocumentCapsuleList(
                            documents: sampleDocuments,
                            isArabic: true,
                            style: .detailed,
                            onDocumentTap: { doc in print("نقر: \(doc.nameArabic)") },
                            onDocumentDelete: { doc in print("حذف: \(doc.nameArabic)") }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}
#endif
