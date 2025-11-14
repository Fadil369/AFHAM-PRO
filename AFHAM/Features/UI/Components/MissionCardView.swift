// AFHAM - Mission Card Component
// INTENT: User-driven entry points for Upload, Ask, Create
// SMART: Context-aware suggestions based on recent activity

import SwiftUI

// MARK: - Mission Type
enum MissionType: String, CaseIterable, Identifiable {
    case upload = "Upload"
    case ask = "Ask"
    case create = "Create"

    var id: String { rawValue }

    var arabicName: String {
        switch self {
        case .upload: return "رفع"
        case .ask:    return "اسأل"
        case .create: return "أنشئ"
        }
    }

    var icon: String {
        switch self {
        case .upload: return "arrow.up.doc.fill"
        case .ask:    return "bubble.left.and.bubble.right.fill"
        case .create: return "sparkles.rectangle.stack.fill"
        }
    }

    var description: String {
        switch self {
        case .upload: return "Add documents to your knowledge base"
        case .ask:    return "Query your documents with AI-powered search"
        case .create: return "Generate content from your documents"
        }
    }

    var arabicDescription: String {
        switch self {
        case .upload: return "أضف مستندات إلى قاعدة معرفتك"
        case .ask:    return "استعلم عن مستنداتك بالذكاء الاصطناعي"
        case .create: return "أنشئ محتوى من مستنداتك"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .upload: return [AFHAMConfig.deepOrange, AFHAMConfig.signalTeal]
        case .ask:    return [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue]
        case .create: return [AFHAMConfig.medicalBlue, Color.purple]
        }
    }

    var tabIndex: Int {
        switch self {
        case .upload: return 1  // Documents tab (Tab 1)
        case .ask:    return 2  // Chat tab (Tab 2)
        case .create: return 4  // Content Creator tab (Tab 4)
        }
    }
}

// MARK: - Mission Suggestion
struct MissionSuggestion: Identifiable {
    let id = UUID()
    let type: MissionType
    let title: String
    let subtitle: String?
    let progress: Double?  // 0.0 to 1.0
    let badge: String?     // e.g., "New", "Continue"

    static func example(isArabic: Bool) -> MissionSuggestion {
        MissionSuggestion(
            type: .create,
            title: isArabic ? "استكمل: تلخيص العقد_2024.pdf" : "Continue: Summarizing Contract_2024.pdf",
            subtitle: isArabic ? "67% مكتمل" : "67% complete",
            progress: 0.67,
            badge: isArabic ? "استكمل" : "Continue"
        )
    }
}

// MARK: - Mission Card View
struct MissionCardView: View {
    let mission: MissionType
    let suggestion: MissionSuggestion?
    let isArabic: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityEnvironment) var a11y
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(for: .buttonTap)
            onTap()
        }) {
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
                // Header: Icon + Title
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mission.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: a11y.dynamicTypeScale.iconSize(base: 56),
                                height: a11y.dynamicTypeScale.iconSize(base: 56)
                            )

                        Image(systemName: mission.icon)
                            .font(.system(size: a11y.dynamicTypeScale.iconSize(base: 24), weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                        Text(isArabic ? mission.arabicName : mission.rawValue)
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 22), weight: .bold))
                            .foregroundColor(.white)

                        Text(isArabic ? mission.arabicDescription : mission.description)
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 13)))
                            .foregroundColor(
                                a11y.contrastAdjusted(AFHAMConfig.professionalGray, opacity: 0.9)
                            )
                            .lineLimit(2)
                    }

                    Spacer()
                }

                // Suggestion (if available)
                if let suggestion = suggestion {
                    suggestionView(suggestion)
                }
            }
            .padding(a11y.dynamicTypeScale.spacing(base: 20))
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            .glassMorphism(
                elevation: suggestion != nil ? .prominent : .elevated,
                cornerRadius: 20,
                accent: mission.gradientColors.first
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(missionAccessibilityLabel)
        .accessibilityHint(String.accessibilityHint(for: missionAction))
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

    @ViewBuilder
    private func suggestionView(_ suggestion: MissionSuggestion) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let badge = suggestion.badge {
                        Text(badge)
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 10), weight: .semibold))
                            .foregroundColor(mission.gradientColors.first)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(mission.gradientColors.first?.opacity(0.2) ?? Color.clear)
                            )
                    }

                    Text(suggestion.title)
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                if let subtitle = suggestion.subtitle {
                    Text(subtitle)
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12)))
                        .foregroundColor(
                            a11y.contrastAdjusted(AFHAMConfig.professionalGray)
                        )
                }
            }

            Spacer()

            // Progress indicator (if available)
            if let progress = suggestion.progress {
                ZStack {
                    Circle()
                        .stroke(
                            mission.gradientColors.first?.opacity(0.3) ?? Color.clear,
                            lineWidth: 3
                        )
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            mission.gradientColors.first ?? Color.clear,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var missionAccessibilityLabel: String {
        var label = "\(isArabic ? mission.arabicName : mission.rawValue) mission"
        if let suggestion = suggestion {
            label += ". \(suggestion.title)"
            if let progress = suggestion.progress {
                label += ", \(Int(progress * 100))% complete"
            }
        }
        return label
    }

    private var missionAction: String {
        switch mission {
        case .upload: return "upload documents"
        case .ask:    return "ask questions"
        case .create: return "create content"
        }
    }
}

// MARK: - Mission Grid View
struct MissionGridView: View {
    @Binding var selectedTab: Int
    let isArabic: Bool
    let suggestions: [MissionSuggestion]
    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: a11y.dynamicTypeScale.spacing(base: 16)) {
            Text(isArabic ? "ماذا تريد أن تفعل؟" : "What would you like to do?")
                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 28), weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, a11y.dynamicTypeScale.spacing(base: 20))

            VStack(spacing: a11y.dynamicTypeScale.spacing(base: 16)) {
                ForEach(MissionType.allCases) { mission in
                    MissionCardView(
                        mission: mission,
                        suggestion: suggestions.first { $0.type == mission },
                        isArabic: isArabic,
                        onTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = mission.tabIndex
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, a11y.dynamicTypeScale.spacing(base: 20))
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
struct MissionCardView_Previews: PreviewProvider {
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

            ScrollView {
                VStack(spacing: 20) {
                    // English LTR
                    Group {
                        Text("English (LTR)").foregroundColor(.white).font(.headline)

                        MissionCardView(
                            mission: .upload,
                            suggestion: nil,
                            isArabic: false,
                            onTap: {}
                        )

                        MissionCardView(
                            mission: .ask,
                            suggestion: MissionSuggestion(
                                type: .ask,
                                title: "Ask about Financial_Report.pdf",
                                subtitle: "Recently uploaded",
                                progress: nil,
                                badge: "New"
                            ),
                            isArabic: false,
                            onTap: {}
                        )

                        MissionCardView(
                            mission: .create,
                            suggestion: MissionSuggestion(
                                type: .create,
                                title: "Continue: Summarizing Contract_2024.pdf",
                                subtitle: "67% complete",
                                progress: 0.67,
                                badge: "Continue"
                            ),
                            isArabic: false,
                            onTap: {}
                        )
                    }

                    Divider().background(Color.white)

                    // Arabic RTL
                    Group {
                        Text("Arabic (RTL)").foregroundColor(.white).font(.headline)

                        MissionCardView(
                            mission: .upload,
                            suggestion: nil,
                            isArabic: true,
                            onTap: {}
                        )

                        MissionCardView(
                            mission: .create,
                            suggestion: MissionSuggestion(
                                type: .create,
                                title: "استكمل: تلخيص العقد_2024.pdf",
                                subtitle: "67% مكتمل",
                                progress: 0.67,
                                badge: "استكمل"
                            ),
                            isArabic: true,
                            onTap: {}
                        )
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
