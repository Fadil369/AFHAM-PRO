// AFHAM - Glass Morphism UI Utilities
// NEURAL: Modern glass morphism effects for AFHAM UI
// Standalone utility with no external dependencies

import SwiftUI

// MARK: - Glass Morphism Material Styles

/// Defines the intensity and appearance of glass morphism effects
public enum GlassMorphismStyle {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var blurRadius: CGFloat {
        switch self {
        case .ultraThin: return 5
        case .thin: return 10
        case .regular: return 20
        case .thick: return 30
        case .ultraThick: return 40
        }
    }

    var opacity: Double {
        switch self {
        case .ultraThin: return 0.05
        case .thin: return 0.1
        case .regular: return 0.15
        case .thick: return 0.2
        case .ultraThick: return 0.25
        }
    }
}

// MARK: - Glass Morphism View Modifier

/// View modifier that applies glass morphism effect to any view
public struct GlassMorphismModifier: ViewModifier {
    let style: GlassMorphismStyle
    let tintColor: Color
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    public init(
        style: GlassMorphismStyle = .regular,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1
    ) {
        self.style = style
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(tintColor.opacity(style.opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        tintColor.opacity(0.3),
                                        tintColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: borderWidth
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: style.blurRadius / 2, x: 0, y: 4)
    }
}

// MARK: - Glass Card Component

/// Ready-to-use glass morphism card component
public struct GlassCard<Content: View>: View {
    let content: Content
    let style: GlassMorphismStyle
    let tintColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets

    public init(
        style: GlassMorphismStyle = .regular,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .modifier(
                GlassMorphismModifier(
                    style: style,
                    tintColor: tintColor,
                    cornerRadius: cornerRadius
                )
            )
    }
}

// MARK: - Frosted Glass Background

/// Full-screen frosted glass background effect
public struct FrostedGlassBackground: View {
    let style: GlassMorphismStyle
    let tintColor: Color

    public init(
        style: GlassMorphismStyle = .regular,
        tintColor: Color = .white
    ) {
        self.style = style
        self.tintColor = tintColor
    }

    public var body: some View {
        Rectangle()
            .fill(tintColor.opacity(style.opacity))
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

// MARK: - View Extension for Easy Access

extension View {
    /// Applies glass morphism effect to the view
    ///
    /// - Parameters:
    ///   - style: The intensity of the glass effect
    ///   - tintColor: The tint color for the glass
    ///   - cornerRadius: The corner radius of the glass shape
    ///   - borderWidth: The width of the border stroke
    /// - Returns: A view with glass morphism effect applied
    public func glassMorphism(
        style: GlassMorphismStyle = .regular,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1
    ) -> some View {
        self.modifier(
            GlassMorphismModifier(
                style: style,
                tintColor: tintColor,
                cornerRadius: cornerRadius,
                borderWidth: borderWidth
            )
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct GlassMorphism_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue, .purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Ultra Thin Glass Card
                GlassCard(style: .ultraThin, tintColor: .white) {
                    VStack {
                        Text("Ultra Thin Glass")
                            .font(.headline)
                        Text("Subtle transparency")
                            .font(.caption)
                    }
                }

                // Regular Glass Card
                GlassCard(style: .regular, tintColor: .cyan) {
                    VStack {
                        Text("Regular Glass")
                            .font(.headline)
                        Text("Balanced effect")
                            .font(.caption)
                    }
                }

                // Ultra Thick Glass Card
                GlassCard(style: .ultraThick, tintColor: .white) {
                    VStack {
                        Text("Ultra Thick Glass")
                            .font(.headline)
                        Text("Strong frosted effect")
                            .font(.caption)
                    }
                }

                // Custom modifier usage
                Text("Custom Glass Effect")
                    .padding()
                    .glassMorphism(
                        style: .regular,
                        tintColor: .yellow,
                        cornerRadius: 20
                    )
            }
            .padding()
        }
    }
}
#endif
