// AFHAM - Accessibility Helpers
// NEURAL: Comprehensive accessibility utilities for inclusive design
// BILINGUAL: RTL/LTR accessibility support
// Standalone utility with no external dependencies

import SwiftUI

// MARK: - Accessibility Configuration

/// Global accessibility configuration for AFHAM
public struct AFHAMAccessibilityConfig {
    /// Minimum tap target size (44x44 points per Apple HIG)
    public static let minimumTapTarget: CGFloat = 44

    /// Recommended tap target size for better UX
    public static let recommendedTapTarget: CGFloat = 48

    /// Large tap target for accessibility mode
    public static let largeTapTarget: CGFloat = 64
}

// MARK: - Accessibility Traits Helper

/// Convenience wrapper for common accessibility trait combinations
public struct AFHAMAccessibilityTraits {
    /// Button that can be activated
    public static let button: AccessibilityTraits = [.isButton]

    /// Header text for sections
    public static let header: AccessibilityTraits = [.isHeader]

    /// Important static text
    public static let staticText: AccessibilityTraits = [.isStaticText]

    /// Interactive image
    public static let image: AccessibilityTraits = [.isImage]

    /// Selected state
    public static let selected: AccessibilityTraits = [.isSelected]

    /// Link to another view or content
    public static let link: AccessibilityTraits = [.isLink]

    /// Search field
    public static let searchField: AccessibilityTraits = [.isSearchField]

    /// Summary text
    public static let summary: AccessibilityTraits = [.isStaticText, .isSummaryElement]
}

// MARK: - Dynamic Type Helper

/// Helper for managing Dynamic Type scaling
public enum AFHAMDynamicTypeHelper {
    /// Check if accessibility text sizes are enabled
    public static var isAccessibilitySizeEnabled: Bool {
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }

    /// Get scaled font size based on Dynamic Type
    public static func scaledFontSize(base: CGFloat) -> CGFloat {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        let multiplier = contentSize.scalingMultiplier
        return base * multiplier
    }

    /// Get appropriate line spacing for current text size
    public static func lineSpacing(for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall, .small, .medium:
            return 4
        case .large, .extraLarge, .extraExtraLarge:
            return 6
        default:
            return 8
        }
    }
}

// MARK: - ContentSizeCategory Extension

extension ContentSizeCategory {
    /// Multiplier for scaling based on content size category
    var scalingMultiplier: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.3
        case .accessibilityExtraExtraExtraLarge: return 2.6
        @unknown default: return 1.0
        }
    }
}

// MARK: - Accessibility View Modifiers

/// View modifier for minimum tap target size
public struct MinimumTapTargetModifier: ViewModifier {
    let size: CGFloat

    public init(size: CGFloat = AFHAMAccessibilityConfig.minimumTapTarget) {
        self.size = size
    }

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: size, minHeight: size)
    }
}

/// View modifier for accessibility-optimized tap targets
public struct AccessibleTapTargetModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory

    public func body(content: Content) -> some View {
        let targetSize = sizeCategory.isAccessibilityCategory
            ? AFHAMAccessibilityConfig.largeTapTarget
            : AFHAMAccessibilityConfig.recommendedTapTarget

        return content
            .frame(minWidth: targetSize, minHeight: targetSize)
    }
}

/// View modifier for RTL/LTR mirror support
public struct RTLAwareModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection

    public func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, layoutDirection)
    }
}

/// View modifier for bilingual accessibility labels
public struct BilingualAccessibilityModifier: ViewModifier {
    let labelArabic: String
    let labelEnglish: String
    let hintArabic: String?
    let hintEnglish: String?
    @Environment(\.locale) var locale

    public init(
        labelArabic: String,
        labelEnglish: String,
        hintArabic: String? = nil,
        hintEnglish: String? = nil
    ) {
        self.labelArabic = labelArabic
        self.labelEnglish = labelEnglish
        self.hintArabic = hintArabic
        self.hintEnglish = hintEnglish
    }

    public func body(content: Content) -> some View {
        let isArabic = locale.language.languageCode?.identifier == "ar"
        let label = isArabic ? labelArabic : labelEnglish
        let hint = isArabic ? hintArabic : hintEnglish

        return content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - View Extensions

extension View {
    /// Ensures minimum tap target size for accessibility
    ///
    /// - Parameter size: Minimum size (default: 44pt per Apple HIG)
    /// - Returns: View with minimum tap target applied
    public func accessibleTapTarget(size: CGFloat = AFHAMAccessibilityConfig.minimumTapTarget) -> some View {
        self.modifier(MinimumTapTargetModifier(size: size))
    }

    /// Applies adaptive tap target based on accessibility settings
    ///
    /// - Returns: View with adaptive tap target
    public func adaptiveTapTarget() -> some View {
        self.modifier(AccessibleTapTargetModifier())
    }

    /// Makes view RTL-aware for proper layout direction
    ///
    /// - Returns: RTL-aware view
    public func rtlAware() -> some View {
        self.modifier(RTLAwareModifier())
    }

    /// Adds bilingual accessibility labels
    ///
    /// - Parameters:
    ///   - labelArabic: Arabic accessibility label
    ///   - labelEnglish: English accessibility label
    ///   - hintArabic: Optional Arabic accessibility hint
    ///   - hintEnglish: Optional English accessibility hint
    /// - Returns: View with bilingual accessibility
    public func bilingualAccessibility(
        labelArabic: String,
        labelEnglish: String,
        hintArabic: String? = nil,
        hintEnglish: String? = nil
    ) -> some View {
        self.modifier(
            BilingualAccessibilityModifier(
                labelArabic: labelArabic,
                labelEnglish: labelEnglish,
                hintArabic: hintArabic,
                hintEnglish: hintEnglish
            )
        )
    }

    /// Adds accessibility traits with common patterns
    ///
    /// - Parameter traits: Accessibility traits to apply
    /// - Returns: View with accessibility traits
    public func afhamAccessibility(traits: AccessibilityTraits) -> some View {
        self.accessibilityAddTraits(traits)
    }
}

// MARK: - Accessibility Announcement Helper

/// Helper for making accessibility announcements
public struct AFHAMAccessibilityAnnouncement {
    /// Make an accessibility announcement
    ///
    /// - Parameters:
    ///   - message: The message to announce
    ///   - priority: The priority of the announcement
    public static func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        UIAccessibility.post(notification: priority, argument: message)
    }

    /// Announce screen change
    ///
    /// - Parameter message: Optional message to announce with screen change
    public static func announceScreenChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    /// Announce layout change
    ///
    /// - Parameter message: Optional message to announce with layout change
    public static func announceLayoutChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }
}

// MARK: - Reduce Motion Helper

/// Helper for respecting reduce motion preferences
public struct AFHAMReduceMotionHelper {
    /// Check if reduce motion is enabled
    public static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Get animation duration respecting reduce motion
    ///
    /// - Parameter standard: Standard animation duration
    /// - Returns: Adjusted duration (0 if reduce motion is on)
    public static func animationDuration(standard: Double) -> Double {
        isReduceMotionEnabled ? 0 : standard
    }

    /// Create animation respecting reduce motion
    ///
    /// - Parameter animation: Standard animation
    /// - Returns: Animation or nil if reduce motion is enabled
    public static func animation(_ animation: Animation) -> Animation? {
        isReduceMotionEnabled ? nil : animation
    }
}

// MARK: - Voice Over Helper

/// Helper for VoiceOver detection and support
public struct AFHAMVoiceOverHelper {
    /// Check if VoiceOver is running
    public static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Check if Switch Control is running
    public static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    /// Check if any assistive technology is running
    public static var isAssistiveTechEnabled: Bool {
        isVoiceOverRunning || isSwitchControlRunning
    }
}

// MARK: - Preview Provider

#if DEBUG
struct AccessibilityHelpers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Minimum tap target
            Text("Tap Me")
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .accessibleTapTarget()

            // Adaptive tap target
            Button("Adaptive Button") {
                print("Tapped")
            }
            .adaptiveTapTarget()

            // Bilingual accessibility
            Image(systemName: "heart.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
                .bilingualAccessibility(
                    labelArabic: "قلب",
                    labelEnglish: "Heart",
                    hintArabic: "اضغط للإعجاب",
                    hintEnglish: "Tap to like"
                )

            // RTL aware layout
            HStack {
                Text("First")
                Spacer()
                Text("Last")
            }
            .padding()
            .rtlAware()

            // Accessibility traits
            Text("Header Text")
                .font(.title)
                .afhamAccessibility(traits: AFHAMAccessibilityTraits.header)
        }
        .padding()
    }
}
#endif
