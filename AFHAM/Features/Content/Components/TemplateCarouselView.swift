// AFHAM - Swipeable Template Carousel
// DISCOVERY: Horizontal scrolling tiles with micro-descriptions
// PREVIEW: Sample outputs for each template type

import SwiftUI

// MARK: - Template Preview Data
struct TemplatePreviewData {
    let type: ContentType
    let sampleInput: String
    let sampleOutput: String

    static func sample(for type: ContentType, isArabic: Bool) -> TemplatePreviewData {
        switch type {
        case .summary:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "تقرير مالي طويل" : "Long financial report",
                sampleOutput: isArabic ?
                    "ملخص: يعرض التقرير نمواً بنسبة 15% في الإيرادات..." :
                    "Summary: The report shows 15% revenue growth..."
            )
        case .article:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "بيانات بحثية" : "Research data",
                sampleOutput: isArabic ?
                    "مقدمة: في عصر التحول الرقمي، تبرز أهمية..." :
                    "Introduction: In the digital age, the importance..."
            )
        case .socialPost:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "إطلاق منتج" : "Product launch",
                sampleOutput: isArabic ?
                    "🚀 متحمسون لإطلاق منتجنا الجديد! #ابتكار #تكنولوجيا" :
                    "🚀 Excited to launch our new product! #Innovation #Tech"
            )
        case .presentation:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "استراتيجية العمل" : "Business strategy",
                sampleOutput: isArabic ?
                    "الشريحة 1: نظرة عامة\n• النقطة الأولى\n• النقطة الثانية" :
                    "Slide 1: Overview\n• First point\n• Second point"
            )
        case .email:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "طلب اجتماع" : "Meeting request",
                sampleOutput: isArabic ?
                    "الموضوع: طلب اجتماع\nعزيزي المستلم،\nأود ترتيب..." :
                    "Subject: Meeting Request\nDear Recipient,\nI would like to arrange..."
            )
        case .translation:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "نص إنجليزي" : "Arabic text",
                sampleOutput: isArabic ?
                    "الترجمة: مرحباً بكم في نظام أفهم..." :
                    "Translation: Welcome to the AFHAM system..."
            )
        case .explanation:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "مفهوم تقني" : "Technical concept",
                sampleOutput: isArabic ?
                    "التفسير المبسط: الذكاء الاصطناعي هو..." :
                    "Simple explanation: AI is like teaching..."
            )
        case .quiz:
            return TemplatePreviewData(
                type: type,
                sampleInput: isArabic ? "محتوى تعليمي" : "Educational content",
                sampleOutput: isArabic ?
                    "السؤال 1: ما هي الفكرة الرئيسية؟\nأ) الخيار الأول" :
                    "Question 1: What is the main idea?\nA) First option"
            )
        }
    }
}

// MARK: - Template Tile View
struct TemplateTileView: View {
    let type: ContentType
    let isSelected: Bool
    let isArabic: Bool
    let onTap: () -> Void
    let onPreview: () -> Void

    @Environment(\.accessibilityEnvironment) var a11y
    @State private var isPressed = false

    private var microDescription: String {
        switch type {
        case .summary:
            return isArabic ? "خلاصة موجزة ومنظمة" : "Concise, organized overview"
        case .article:
            return isArabic ? "مقالة تفصيلية وجذابة" : "Detailed, engaging piece"
        case .socialPost:
            return isArabic ? "منشور قصير مع هاشتاجات" : "Short post with hashtags"
        case .presentation:
            return isArabic ? "شرائح بنقاط رئيسية" : "Slides with key points"
        case .email:
            return isArabic ? "رسالة احترافية" : "Professional message"
        case .translation:
            return isArabic ? "ترجمة دقيقة" : "Accurate translation"
        case .explanation:
            return isArabic ? "شرح سهل ومبسط" : "Easy, simplified explanation"
        case .quiz:
            return isArabic ? "أسئلة مع إجابات" : "Questions with answers"
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(for: .selectionChanged)
            onTap()
        }) {
            VStack(alignment: .center, spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: isSelected ?
                                    [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue] :
                                    [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: type.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AFHAMConfig.signalTeal)
                }

                // Title
                Text(isArabic ? type.arabicName : type.rawValue)
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 18), weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Micro description
                Text(microDescription)
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 13)))
                    .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Preview button
                Button(action: {
                    HapticManager.shared.trigger(for: .buttonTap)
                    onPreview()
                }) {
                    HStack(spacing: 4) {
                        Text(isArabic ? "مثال" : "Sample")
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 12), weight: .semibold))

                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AFHAMConfig.signalTeal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AFHAMConfig.signalTeal.opacity(0.2))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .frame(width: 200, height: 280)
            .glassMorphism(
                elevation: isSelected ? .prominent : .elevated,
                cornerRadius: 24,
                accent: isSelected ? AFHAMConfig.signalTeal : nil
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ?
                            LinearGradient(
                                colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(isArabic ? type.arabicName : type.rawValue) template")
        .accessibilityHint("\(microDescription). \(String.accessibilityHint(for: "select template"))")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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
}

// MARK: - Template Carousel View
struct TemplateCarouselView: View {
    @Binding var selectedTemplate: ContentType
    let isArabic: Bool
    let onPreview: (ContentType) -> Void

    @Environment(\.accessibilityEnvironment) var a11y
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(isArabic ? "اختر نوع المحتوى" : "Choose Content Type")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 20), weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(isArabic ? "← اسحب →" : "← Swipe →")
                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14)))
                    .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
            }
            .padding(.horizontal, 20)

            // Horizontal Scrolling Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        TemplateTileView(
                            type: type,
                            isSelected: selectedTemplate == type,
                            isArabic: isArabic,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedTemplate = type
                                }
                            },
                            onPreview: {
                                onPreview(type)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Template Preview Sheet
struct TemplatePreviewSheet: View {
    let preview: TemplatePreviewData
    let isArabic: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        AFHAMConfig.midnightBlue,
                        AFHAMConfig.medicalBlue.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: isArabic ? .trailing : .leading, spacing: 24) {
                        // Template info
                        VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: preview.type.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(AFHAMConfig.signalTeal)

                                Text(isArabic ? preview.type.arabicName : preview.type.rawValue)
                                    .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 28), weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text(isArabic ? "مثال على النتيجة" : "Sample Output")
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 16)))
                                .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                        }
                        .padding(20)
                        .glassMorphism(elevation: .base, cornerRadius: 16, accent: nil)

                        // Sample input
                        VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                            Label(
                                isArabic ? "المدخلات" : "Input",
                                systemImage: "arrow.down.doc"
                            )
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .semibold))
                            .foregroundColor(AFHAMConfig.signalTeal)

                            Text(preview.sampleInput)
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 15)))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(isArabic ? .trailing : .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                        .glassMorphism(elevation: .base, cornerRadius: 12, accent: nil)

                        // Arrow
                        Image(systemName: "arrow.down")
                            .font(.system(size: 24))
                            .foregroundColor(AFHAMConfig.professionalGray)

                        // Sample output
                        VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                            Label(
                                isArabic ? "المخرجات" : "Output",
                                systemImage: "arrow.up.doc"
                            )
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .semibold))
                            .foregroundColor(AFHAMConfig.signalTeal)

                            Text(preview.sampleOutput)
                                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 15)))
                                .foregroundColor(.white)
                                .multilineTextAlignment(isArabic ? .trailing : .leading)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                        .glassMorphism(elevation: .elevated, cornerRadius: 12, accent: AFHAMConfig.signalTeal)

                        // Note
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AFHAMConfig.professionalGray)

                            Text(isArabic ?
                                "هذا مثال توضيحي. النتائج الفعلية ستعتمد على مستنداتك." :
                                "This is a sample. Actual results will depend on your documents."
                            )
                            .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 13)))
                            .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                            .multilineTextAlignment(isArabic ? .trailing : .leading)
                        }
                        .padding(12)
                        .glassMorphism(elevation: .base, cornerRadius: 12, accent: nil)
                    }
                    .padding()
                }
            }
            .navigationTitle(isArabic ? "معاينة النموذج" : "Template Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isArabic ? "إغلاق" : "Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sticky Controls Bottom Sheet
struct StickyControlsSheet: View {
    let selectedTemplate: ContentType
    let isArabic: Bool
    @Binding var tone: String
    @Binding var audience: String
    @Binding var length: String

    @Environment(\.accessibilityEnvironment) var a11y

    private let toneOptions = ["Professional", "Casual", "Formal", "Friendly"]
    private let tonOptionsArabic = ["احترافي", "غير رسمي", "رسمي", "ودي"]
    private let audienceOptions = ["General", "Technical", "Executive", "Students"]
    private let audienceOptionsArabic = ["عام", "تقني", "تنفيذي", "طلاب"]
    private let lengthOptions = ["Short", "Medium", "Long", "Detailed"]
    private let lengthOptionsArabic = ["قصير", "متوسط", "طويل", "مفصل"]

    var body: some View {
        VStack(spacing: 16) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Title
            Text(isArabic ? "تخصيص المحتوى" : "Customize Output")
                .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 18), weight: .bold))
                .foregroundColor(.white)

            // Controls
            VStack(spacing: 12) {
                // Tone
                HStack {
                    Text(isArabic ? "الأسلوب:" : "Tone:")
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: isArabic ? .trailing : .leading)

                    Picker("", selection: $tone) {
                        ForEach(isArabic ? tonOptionsArabic : toneOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AFHAMConfig.signalTeal)
                }

                // Audience
                HStack {
                    Text(isArabic ? "الجمهور:" : "Audience:")
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: isArabic ? .trailing : .leading)

                    Picker("", selection: $audience) {
                        ForEach(isArabic ? audienceOptionsArabic : audienceOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AFHAMConfig.signalTeal)
                }

                // Length
                HStack {
                    Text(isArabic ? "الطول:" : "Length:")
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14), weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, alignment: isArabic ? .trailing : .leading)

                    Picker("", selection: $length) {
                        ForEach(isArabic ? lengthOptionsArabic : lengthOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AFHAMConfig.signalTeal)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .glassMorphism(elevation: .prominent, cornerRadius: 20, accent: nil)
        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
    }
}

// MARK: - Preview Provider
#if DEBUG
struct TemplateCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AFHAMConfig.midnightBlue,
                    AFHAMConfig.deepOrange.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                TemplateCarouselView(
                    selectedTemplate: .constant(.summary),
                    isArabic: false,
                    onPreview: { _ in }
                )

                StickyControlsSheet(
                    selectedTemplate: .summary,
                    isArabic: false,
                    tone: .constant("Professional"),
                    audience: .constant("General"),
                    length: .constant("Medium")
                )
                .padding(.horizontal)
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
