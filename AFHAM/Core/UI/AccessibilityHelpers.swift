// AFHAM - Accessibility Helpers
// MEDICAL: Clinical-grade accessibility for healthcare environments
// INCLUSIVE: Dynamic Type, VoiceOver, reduced motion support

import SwiftUI

// MARK: - Dynamic Type Scale
enum DynamicTypeScale {
    case small      // .small, .extraSmall
    case standard   // .medium, .large
    case large      // .extraLarge, .extraExtraLarge
    case extraLarge // .extraExtraExtraLarge, .accessibilityMedium+

    init(from sizeCategory: ContentSizeCategory) {
        switch sizeCategory {
        case .extraSmall, .small:
            self = .small
        case .medium, .large:
            self = .standard
        case .extraLarge, .extraExtraLarge:
            self = .large
        default:
            self = .extraLarge
        }
    }

    var fontSizeMultiplier: CGFloat {
        switch self {
        case .small:      return 0.875  // 87.5%
        case .standard:   return 1.0    // 100%
        case .large:      return 1.125  // 112.5%
        case .extraLarge: return 1.25   // 125%
        }
    }

    var spacingMultiplier: CGFloat {
        switch self {
        case .small:      return 0.875
        case .standard:   return 1.0
        case .large:      return 1.125
        case .extraLarge: return 1.5
        }
    }

    var iconSizeMultiplier: CGFloat {
        switch self {
        case .small:      return 0.9
        case .standard:   return 1.0
        case .large:      return 1.15
        case .extraLarge: return 1.3
        }
    }

    func fontSize(base: CGFloat) -> CGFloat {
        base * fontSizeMultiplier
    }

    func spacing(base: CGFloat) -> CGFloat {
        base * spacingMultiplier
    }

    func iconSize(base: CGFloat) -> CGFloat {
        base * iconSizeMultiplier
    }
}

// MARK: - Accessibility Environment
struct AccessibilityEnvironment {
    let sizeCategory: ContentSizeCategory
    let colorSchemeContrast: ColorSchemeContrast
    let reduceMotion: Bool
    let differentiateWithoutColor: Bool

    var dynamicTypeScale: DynamicTypeScale {
        DynamicTypeScale(from: sizeCategory)
    }

    var shouldAnimate: Bool {
        !reduceMotion && !UserDefaults.standard.bool(forKey: "calmMode")
    }

    var highContrast: Bool {
        colorSchemeContrast == .increased
    }

    func contrastAdjusted(_ color: Color, opacity: Double) -> Color {
        if highContrast {
            return color.opacity(min(1.0, opacity * 1.2))
        }
        return color.opacity(opacity)
    }

    func contrastAdjusted(_ color: Color) -> Color {
        if highContrast {
            return color
        }
        return color.opacity(0.9)
    }
}

// MARK: - Accessibility Environment Key
private struct AccessibilityEnvironmentKey: EnvironmentKey {
    static let defaultValue = AccessibilityEnvironment(
        sizeCategory: .large,
        colorSchemeContrast: .standard,
        reduceMotion: false,
        differentiateWithoutColor: false
    )
}

extension EnvironmentValues {
    var accessibilityEnvironment: AccessibilityEnvironment {
        get {
            AccessibilityEnvironment(
                sizeCategory: self.sizeCategory,
                colorSchemeContrast: self.colorSchemeContrast,
                reduceMotion: self.accessibilityReduceMotion,
                differentiateWithoutColor: self.accessibilityDifferentiateWithoutColor
            )
        }
    }
}

// MARK: - Haptic Feedback Manager
enum HapticContext {
    case uploadComplete
    case errorOccurred
    case voiceRecognitionStart
    case voiceRecognitionComplete
    case documentProcessed
    case chatMessageSent
    case criticalAlert
    case buttonTap
    case selectionChanged

    var isCritical: Bool {
        switch self {
        case .uploadComplete, .errorOccurred, .criticalAlert, .documentProcessed:
            return true
        default:
            return false
        }
    }

    var feedbackType: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .uploadComplete, .documentProcessed:
            return .success
        case .errorOccurred, .criticalAlert:
            return .error
        case .voiceRecognitionComplete:
            return .success
        default:
            return nil
        }
    }

    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .voiceRecognitionStart:
            return .medium
        case .buttonTap:
            return .light
        case .selectionChanged:
            return .light
        default:
            return nil
        }
    }
}

@MainActor
class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        notification.prepare()
    }

    func trigger(for context: HapticContext) {
        let hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true

        guard hapticsEnabled || context.isCritical else { return }

        if let feedbackType = context.feedbackType {
            notification.notificationOccurred(feedbackType)
        } else if let impactStyle = context.impactStyle {
            switch impactStyle {
            case .light:
                impactLight.impactOccurred()
            case .medium:
                impactMedium.impactOccurred()
            default:
                break
            }
        }
    }
}

// MARK: - Accessibility Label Helpers
extension String {
    static func accessibilityLabel(
        for documentName: String,
        type: String,
        size: String,
        status: String,
        progress: Int? = nil
    ) -> String {
        var label = "\(documentName), \(type), \(size), \(status)"
        if let progress = progress {
            label += ", \(progress)% complete"
        }
        return label
    }

    static func accessibilityHint(for action: String) -> String {
        "Double tap to \(action)"
    }
}

// MARK: - Voice Over Grouping Helper
struct VoiceOverGroup<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
}

// MARK: - Calm Mode Animation Modifier
struct CalmModeAnimation: ViewModifier {
    let animation: Animation
    let value: some Equatable
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("calmMode") var calmMode = false

    var effectiveAnimation: Animation? {
        if reduceMotion || calmMode {
            return nil
        }
        return animation
    }

    func body(content: Content) -> some View {
        content
            .animation(effectiveAnimation, value: value)
    }
}

extension View {
    func calmModeAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(CalmModeAnimation(animation: animation, value: value))
    }
}

// MARK: - Adaptive Font Size
struct AdaptiveFontSize: ViewModifier {
    let baseSize: CGFloat
    @Environment(\.sizeCategory) var sizeCategory

    var adaptiveSize: CGFloat {
        let scale = DynamicTypeScale(from: sizeCategory)
        return scale.fontSize(base: baseSize)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: adaptiveSize))
    }
}

extension View {
    func adaptiveFont(size: CGFloat) -> some View {
        modifier(AdaptiveFontSize(baseSize: size))
    }
}

// MARK: - Accessible Color
struct AccessibleColor {
    static func adjusted(_ color: Color, contrast: ColorSchemeContrast, opacity: Double = 1.0) -> Color {
        if contrast == .increased {
            return color.opacity(min(1.0, opacity * 1.2))
        }
        return color.opacity(opacity)
    }

    static func accentColor(
        base: Color,
        context: ColorSchemeContrast,
        highContrastOverride: Color? = nil
    ) -> Color {
        if context == .increased, let override = highContrastOverride {
            return override
        }
        return base
    }
}
