// AFHAM - Glass Morphism Elevation System
// NEURAL: Layered depth with adaptive elevation
// BrainSAIT design language with enhanced visual hierarchy

import SwiftUI

// MARK: - Elevation Levels
enum GlassElevation {
    case base       // Standard list items, background cards
    case elevated   // Active items, processing states
    case prominent  // Hero cards, suggested actions
    case critical   // CTAs, alerts, primary actions

    var material: Material {
        switch self {
        case .base:      return .ultraThinMaterial
        case .elevated:  return .thinMaterial
        case .prominent: return .regularMaterial
        case .critical:  return .regularMaterial
        }
    }

    var overlayOpacity: Double {
        switch self {
        case .base:      return 0.05
        case .elevated:  return 0.1
        case .prominent: return 0.15
        case .critical:  return 0.2
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .base:      return 2
        case .elevated:  return 6
        case .prominent: return 10
        case .critical:  return 16
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .base:      return 1
        case .elevated:  return 3
        case .prominent: return 6
        case .critical:  return 8
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .base:      return 0.1
        case .elevated:  return 0.2
        case .prominent: return 0.3
        case .critical:  return 0.4
        }
    }
}

// MARK: - Glass Morphism Modifier
struct GlassMorphismModifier: ViewModifier {
    let elevation: GlassElevation
    let cornerRadius: CGFloat
    let accent: Color?

    init(elevation: GlassElevation, cornerRadius: CGFloat = 16, accent: Color? = nil) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.accent = accent
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(elevation.material)

                    // Overlay gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(elevation.overlayOpacity),
                                    Color.white.opacity(elevation.overlayOpacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Accent glow (if provided)
                    if let accent = accent {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(accent.opacity(0.3), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: (accent ?? .white).opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }
}

// MARK: - View Extension
extension View {
    func glassMorphism(
        elevation: GlassElevation = .base,
        cornerRadius: CGFloat = 16,
        accent: Color? = nil
    ) -> some View {
        modifier(GlassMorphismModifier(
            elevation: elevation,
            cornerRadius: cornerRadius,
            accent: accent
        ))
    }
}

// MARK: - Parallax Effect Modifier
struct ParallaxModifier: ViewModifier {
    let scrollOffset: CGFloat
    let intensity: CGFloat
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("calmMode") var calmMode = false

    var shouldAnimate: Bool {
        !reduceMotion && !calmMode
    }

    func body(content: Content) -> some View {
        if shouldAnimate {
            content
                .rotation3DEffect(
                    .degrees(Double(scrollOffset * intensity * 0.02)),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 1.0
                )
                .offset(y: scrollOffset * intensity * 0.05)
        } else {
            content
        }
    }
}

extension View {
    func parallax(scrollOffset: CGFloat, intensity: CGFloat = 1.0) -> some View {
        modifier(ParallaxModifier(scrollOffset: scrollOffset, intensity: intensity))
    }
}

// MARK: - Adaptive Elevation Helper
struct AdaptiveElevation {
    static func level(for context: Context) -> GlassElevation {
        switch context {
        case .latestDocument, .suggestedAction, .activeChat:
            return .prominent
        case .processingDocument, .activeVoice, .selectedTemplate:
            return .elevated
        case .completedDocument, .historyItem, .standardCard:
            return .base
        case .primaryCTA, .errorAlert, .criticalAction:
            return .critical
        }
    }

    enum Context {
        // Prominent
        case latestDocument
        case suggestedAction
        case activeChat

        // Elevated
        case processingDocument
        case activeVoice
        case selectedTemplate

        // Base
        case completedDocument
        case historyItem
        case standardCard

        // Critical
        case primaryCTA
        case errorAlert
        case criticalAction
    }
}
