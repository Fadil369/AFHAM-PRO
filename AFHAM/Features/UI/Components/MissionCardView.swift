// AFHAM - Mission Card View
// NEURAL: Interactive mission/task cards with glass morphism design
// BILINGUAL: RTL/LTR adaptive layouts with Arabic/English support
// Dependencies: GlassMorphism, AccessibilityHelpers, FlowLayout (from Core/UI)

import SwiftUI

// MARK: - Mission Type

/// Represents different types of missions or tasks in AFHAM
public enum MissionType: String, Codable, CaseIterable {
    case documentAnalysis = "document_analysis"
    case voiceInteraction = "voice_interaction"
    case contentCreation = "content_creation"
    case medicalQuery = "medical_query"
    case chatAssistance = "chat_assistance"
    case intelligentCapture = "intelligent_capture"
    case collaboration = "collaboration"
    case healthcareCompliance = "healthcare_compliance"

    /// Icon for each mission type
    var icon: String {
        switch self {
        case .documentAnalysis: return "doc.text.magnifyingglass"
        case .voiceInteraction: return "waveform.circle.fill"
        case .contentCreation: return "square.and.pencil"
        case .medicalQuery: return "stethoscope"
        case .chatAssistance: return "message.fill"
        case .intelligentCapture: return "camera.viewfinder"
        case .collaboration: return "person.2.fill"
        case .healthcareCompliance: return "checkmark.shield.fill"
        }
    }

    /// Color theme for each mission type
    var color: Color {
        switch self {
        case .documentAnalysis: return .blue
        case .voiceInteraction: return .purple
        case .contentCreation: return .green
        case .medicalQuery: return .red
        case .chatAssistance: return .cyan
        case .intelligentCapture: return .orange
        case .collaboration: return .indigo
        case .healthcareCompliance: return .teal
        }
    }

    /// English name
    var nameEnglish: String {
        switch self {
        case .documentAnalysis: return "Document Analysis"
        case .voiceInteraction: return "Voice Interaction"
        case .contentCreation: return "Content Creation"
        case .medicalQuery: return "Medical Query"
        case .chatAssistance: return "Chat Assistance"
        case .intelligentCapture: return "Intelligent Capture"
        case .collaboration: return "Collaboration"
        case .healthcareCompliance: return "Healthcare Compliance"
        }
    }

    /// Arabic name
    var nameArabic: String {
        switch self {
        case .documentAnalysis: return "تحليل المستندات"
        case .voiceInteraction: return "التفاعل الصوتي"
        case .contentCreation: return "إنشاء المحتوى"
        case .medicalQuery: return "استعلام طبي"
        case .chatAssistance: return "مساعدة المحادثة"
        case .intelligentCapture: return "التقاط ذكي"
        case .collaboration: return "التعاون"
        case .healthcareCompliance: return "الامتثال الصحي"
        }
    }
}

// MARK: - Mission Suggestion

/// Represents a suggested mission or action for the user
public struct MissionSuggestion: Identifiable, Codable {
    public let id: UUID
    public let type: MissionType
    public let titleEnglish: String
    public let titleArabic: String
    public let descriptionEnglish: String
    public let descriptionArabic: String
    public let priority: Priority
    public let estimatedTime: String // e.g., "5 min", "10 min"
    public let tags: [String]

    public enum Priority: String, Codable {
        case low, medium, high, urgent

        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }

        var nameEnglish: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }

        var nameArabic: String {
            switch self {
            case .low: return "منخفض"
            case .medium: return "متوسط"
            case .high: return "عالي"
            case .urgent: return "عاجل"
            }
        }
    }

    public init(
        id: UUID = UUID(),
        type: MissionType,
        titleEnglish: String,
        titleArabic: String,
        descriptionEnglish: String,
        descriptionArabic: String,
        priority: Priority,
        estimatedTime: String,
        tags: [String] = []
    ) {
        self.id = id
        self.type = type
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.descriptionEnglish = descriptionEnglish
        self.descriptionArabic = descriptionArabic
        self.priority = priority
        self.estimatedTime = estimatedTime
        self.tags = tags
    }
}

// MARK: - Mission Card View

/// Interactive card displaying a mission suggestion with glass morphism design
public struct MissionCardView: View {
    let mission: MissionSuggestion
    let isArabic: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    public init(
        mission: MissionSuggestion,
        isArabic: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.mission = mission
        self.isArabic = isArabic
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and type
                HStack(spacing: 12) {
                    Image(systemName: mission.type.icon)
                        .font(.title2)
                        .foregroundColor(mission.type.color)
                        .frame(width: 44, height: 44)
                        .background(mission.type.color.opacity(0.15))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isArabic ? mission.type.nameArabic : mission.type.nameEnglish)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(isArabic ? mission.titleArabic : mission.titleEnglish)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Priority badge
                    priorityBadge
                }

                // Description
                Text(isArabic ? mission.descriptionArabic : mission.descriptionEnglish)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(isArabic ? .trailing : .leading)

                // Tags and time
                HStack {
                    // Tags
                    if !mission.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(mission.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.15))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Spacer()

                    // Estimated time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(mission.estimatedTime)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .glassMorphism(
                style: .regular,
                tintColor: isPressed ? mission.type.color : .white,
                cornerRadius: 16
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
            labelArabic: mission.titleArabic,
            labelEnglish: mission.titleEnglish,
            hintArabic: "اضغط لبدء المهمة",
            hintEnglish: "Tap to start mission"
        )
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(mission.priority.color)
                .frame(width: 6, height: 6)

            Text(isArabic ? mission.priority.nameArabic : mission.priority.nameEnglish)
                .font(.caption2)
                .foregroundColor(mission.priority.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(mission.priority.color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Mission Card Grid

/// Grid layout for displaying multiple mission cards
public struct MissionCardGrid: View {
    let missions: [MissionSuggestion]
    let isArabic: Bool
    let onMissionTap: (MissionSuggestion) -> Void

    public init(
        missions: [MissionSuggestion],
        isArabic: Bool = false,
        onMissionTap: @escaping (MissionSuggestion) -> Void
    ) {
        self.missions = missions
        self.isArabic = isArabic
        self.onMissionTap = onMissionTap
    }

    public var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(missions) { mission in
                MissionCardView(
                    mission: mission,
                    isArabic: isArabic,
                    onTap: { onMissionTap(mission) }
                )
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct MissionCardView_Previews: PreviewProvider {
    static let sampleMissions = [
        MissionSuggestion(
            type: .documentAnalysis,
            titleEnglish: "Analyze Medical Report",
            titleArabic: "تحليل تقرير طبي",
            descriptionEnglish: "Review and extract key information from your latest lab results",
            descriptionArabic: "مراجعة واستخراج المعلومات الرئيسية من نتائج المختبر الأخيرة",
            priority: .high,
            estimatedTime: "5 min",
            tags: ["Medical", "Lab Results", "AI Analysis"]
        ),
        MissionSuggestion(
            type: .voiceInteraction,
            titleEnglish: "Voice Health Check",
            titleArabic: "فحص صحي صوتي",
            descriptionEnglish: "Quick voice-based assessment of your current symptoms",
            descriptionArabic: "تقييم سريع قائم على الصوت لأعراضك الحالية",
            priority: .medium,
            estimatedTime: "3 min",
            tags: ["Voice", "Health", "Quick"]
        ),
        MissionSuggestion(
            type: .medicalQuery,
            titleEnglish: "Ask About Medication",
            titleArabic: "استفسر عن الدواء",
            descriptionEnglish: "Get information about your prescribed medications",
            descriptionArabic: "احصل على معلومات حول الأدوية الموصوفة لك",
            priority: .urgent,
            estimatedTime: "2 min",
            tags: ["Medication", "Important"]
        ),
        MissionSuggestion(
            type: .intelligentCapture,
            titleEnglish: "Scan Prescription",
            titleArabic: "مسح الوصفة الطبية",
            descriptionEnglish: "Use AI to scan and digitize your prescription",
            descriptionArabic: "استخدم الذكاء الاصطناعي لمسح وصفتك الطبية ورقمنتها",
            priority: .low,
            estimatedTime: "4 min",
            tags: ["OCR", "Prescription"]
        )
    ]

    static var previews: some View {
        Group {
            // English Version
            ScrollView {
                VStack(spacing: 20) {
                    Text("Mission Cards - English")
                        .font(.title2.bold())

                    MissionCardGrid(
                        missions: sampleMissions,
                        isArabic: false,
                        onMissionTap: { mission in
                            print("Tapped: \(mission.titleEnglish)")
                        }
                    )
                    .padding()
                }
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
                    Text("بطاقات المهام - العربية")
                        .font(.title2.bold())

                    MissionCardGrid(
                        missions: sampleMissions,
                        isArabic: true,
                        onMissionTap: { mission in
                            print("نقر: \(mission.titleArabic)")
                        }
                    )
                    .padding()
                }
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
