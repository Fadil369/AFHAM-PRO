// AFHAM - Radial Pulse Voice Visualization
// MEDICAL: Clinical-inspired pulse visualization with confidence indicator
// BILINGUAL: Instant captions with confidence percentage

import SwiftUI

// MARK: - Voice Confidence Level
enum VoiceConfidenceLevel {
    case high      // 90-100%
    case medium    // 70-89%
    case low       // 50-69%
    case veryLow   // < 50%

    init(percentage: Double) {
        switch percentage {
        case 0.9...1.0:  self = .high
        case 0.7..<0.9:  self = .medium
        case 0.5..<0.7:  self = .low
        default:         self = .veryLow
        }
    }

    var color: Color {
        switch self {
        case .high:    return .green
        case .medium:  return .yellow
        case .low:     return .orange
        case .veryLow: return AFHAMConfig.deepOrange
        }
    }

    var arabicLabel: String {
        switch self {
        case .high:    return "ثقة عالية"
        case .medium:  return "ثقة متوسطة"
        case .low:     return "ثقة منخفضة"
        case .veryLow: return "ثقة ضعيفة جداً"
        }
    }

    var englishLabel: String {
        switch self {
        case .high:    return "High Confidence"
        case .medium:  return "Medium Confidence"
        case .low:     return "Low Confidence"
        case .veryLow: return "Very Low Confidence"
        }
    }
}

// MARK: - Radial Pulse View
struct RadialPulseView: View {
    let isListening: Bool
    let confidence: Double  // 0.0 to 1.0
    let isArabic: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var rotationAngle: Double = 0
    @Environment(\.accessibilityEnvironment) var a11y

    private var confidenceLevel: VoiceConfidenceLevel {
        VoiceConfidenceLevel(percentage: confidence)
    }

    var body: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3) { index in
                let delay = Double(index) * 0.3
                let scale = 1.0 + (CGFloat(index) * 0.2)

                Circle()
                    .stroke(
                        confidenceLevel.color.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 140 * scale, height: 140 * scale)
                    .scaleEffect(isListening ? pulseScale : 1.0)
                    .opacity(isListening ? pulseOpacity : 0.2)
                    .calmModeAnimation(
                        .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(delay),
                        value: isListening
                    )
            }

            // Confidence ring background
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 8
                )
                .frame(width: 140, height: 140)

            // Confidence ring (progress)
            Circle()
                .trim(from: 0, to: confidence)
                .stroke(
                    LinearGradient(
                        colors: [confidenceLevel.color, confidenceLevel.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(isListening ? rotationAngle : 0))
                .calmModeAnimation(.spring(response: 0.5), value: confidence)

            // Inner pulse circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            confidenceLevel.color,
                            confidenceLevel.color.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isListening ? 1.05 : 1.0)
                .calmModeAnimation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isListening
                )

            // Microphone icon
            VStack(spacing: 4) {
                Image(systemName: isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, isActive: isListening)

                if isListening && confidence > 0 {
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityLabel(
            isListening ?
                "\(isArabic ? "الاستماع نشط" : "Listening active"), \(Int(confidence * 100))% \(isArabic ? "ثقة" : "confidence")" :
                isArabic ? "ميكروفون متاح" : "Microphone ready"
        )
        .accessibilityValue(confidenceLevel.englishLabel)
        .onAppear {
            if isListening && a11y.shouldAnimate {
                startPulseAnimation()
                startRotationAnimation()
            }
        }
        .onChange(of: isListening) { oldValue, newValue in
            if newValue && a11y.shouldAnimate {
                startPulseAnimation()
                startRotationAnimation()
            } else {
                pulseScale = 1.0
                rotationAngle = 0
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
            pulseOpacity = 0.2
        }
    }

    private func startRotationAnimation() {
        withAnimation(
            .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
}

// MARK: - Bilingual Caption View
struct BilingualCaptionView: View {
    let recognizedText: String
    let translatedText: String?
    let confidence: Double
    let isArabic: Bool

    @Environment(\.accessibilityEnvironment) var a11y

    var confidenceLevel: VoiceConfidenceLevel {
        VoiceConfidenceLevel(percentage: confidence)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Primary recognized text
            if !recognizedText.isEmpty {
                HStack(spacing: 8) {
                    Text(recognizedText)
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 18), weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(isArabic ? .trailing : .leading)
                        .lineLimit(3)

                    // Confidence indicator
                    ZStack {
                        Circle()
                            .fill(confidenceLevel.color.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(confidenceLevel.color)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.4))
                        .background(.ultraThinMaterial)
                )
            }

            // Translation preview (if available)
            if let translatedText = translatedText, !translatedText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundColor(AFHAMConfig.signalTeal)
                        .font(.system(size: 14))

                    Text(translatedText)
                        .font(.system(size: a11y.dynamicTypeScale.fontSize(base: 14)))
                        .foregroundColor(a11y.contrastAdjusted(AFHAMConfig.professionalGray))
                        .multilineTextAlignment(isArabic ? .trailing : .leading)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recognizedText), \(Int(confidence * 100))% confidence")
    }
}

// MARK: - Voice Quick Settings Sheet
struct VoiceQuickSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var autoSpeak: Bool
    @Binding var ambientMode: Bool
    let isArabic: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityEnvironment) var a11y

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(isArabic ? "اللغة" : "Language")) {
                    Picker(isArabic ? "لغة التعرف" : "Recognition Language", selection: $selectedLanguage) {
                        Text(isArabic ? "العربية" : "Arabic").tag("ar-SA")
                        Text(isArabic ? "الإنجليزية" : "English").tag("en-US")
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text(isArabic ? "الخيارات" : "Options")) {
                    Toggle(isArabic ? "تحدث تلقائياً بالردود" : "Auto-speak Responses", isOn: $autoSpeak)

                    Toggle(isArabic ? "وضع الاستماع المستمر" : "Ambient Listening Mode", isOn: $ambientMode)
                }

                Section(header: Text(isArabic ? "معلومات" : "Info")) {
                    HStack {
                        Text(isArabic ? "الحالة" : "Status")
                        Spacer()
                        Text(isArabic ? "متصل" : "Connected")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle(isArabic ? "إعدادات الصوت" : "Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isArabic ? "تم" : "Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
struct RadialPulseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Listening with high confidence
            ZStack {
                RadialGradient(
                    colors: [
                        AFHAMConfig.signalTeal.opacity(0.3),
                        AFHAMConfig.midnightBlue
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Listening - High Confidence")
                        .foregroundColor(.white)
                        .font(.headline)

                    RadialPulseView(
                        isListening: true,
                        confidence: 0.95,
                        isArabic: false
                    )

                    BilingualCaptionView(
                        recognizedText: "How are you today?",
                        translatedText: "كيف حالك اليوم؟",
                        confidence: 0.95,
                        isArabic: false
                    )
                }
            }
            .previewDisplayName("Listening - High")

            // Listening with medium confidence
            ZStack {
                RadialGradient(
                    colors: [
                        AFHAMConfig.signalTeal.opacity(0.3),
                        AFHAMConfig.midnightBlue
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Listening - Medium Confidence")
                        .foregroundColor(.white)
                        .font(.headline)

                    RadialPulseView(
                        isListening: true,
                        confidence: 0.75,
                        isArabic: false
                    )

                    BilingualCaptionView(
                        recognizedText: "What is the weather...",
                        translatedText: nil,
                        confidence: 0.75,
                        isArabic: false
                    )
                }
            }
            .previewDisplayName("Listening - Medium")

            // Idle state
            ZStack {
                RadialGradient(
                    colors: [
                        AFHAMConfig.signalTeal.opacity(0.3),
                        AFHAMConfig.midnightBlue
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Idle - Ready")
                        .foregroundColor(.white)
                        .font(.headline)

                    RadialPulseView(
                        isListening: false,
                        confidence: 0.0,
                        isArabic: false
                    )
                }
            }
            .previewDisplayName("Idle")

            // Arabic RTL
            ZStack {
                RadialGradient(
                    colors: [
                        AFHAMConfig.signalTeal.opacity(0.3),
                        AFHAMConfig.midnightBlue
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("استماع - ثقة عالية")
                        .foregroundColor(.white)
                        .font(.headline)

                    RadialPulseView(
                        isListening: true,
                        confidence: 0.92,
                        isArabic: true
                    )

                    BilingualCaptionView(
                        recognizedText: "كيف حالك اليوم؟",
                        translatedText: "How are you today?",
                        confidence: 0.92,
                        isArabic: true
                    )
                }
                .environment(\.layoutDirection, .rightToLeft)
            }
            .previewDisplayName("Arabic RTL")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
