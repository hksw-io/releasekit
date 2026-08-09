#if os(iOS) || os(macOS)
import Foundation
import SwiftUI

/// Environment values handed to a custom background so it can stay consistent and accessible.
///
/// Read these rather than querying the environment directly, so a custom background reacts to the
/// same inputs the built-in ones do.
public struct ReleaseBackgroundContext: Equatable, Sendable {
    /// Whether Reduce Motion is enabled. Custom backgrounds must not animate when this is `true`.
    public let reduceMotion: Bool
    /// The `tint` from the applied ``ReleaseStyle``, or `nil` when the style sets no tint.
    public let brandColor: Color?
    /// The active color scheme, so a background can pick its own light and dark tones.
    public let colorScheme: ColorScheme

    /// Creates a context. The package builds this for you; construct one directly only in tests or
    /// previews.
    ///
    /// - Parameters:
    ///   - reduceMotion: Whether Reduce Motion is enabled.
    ///   - brandColor: Brand color from the applied style.
    ///   - colorScheme: The active color scheme.
    public init(
        reduceMotion: Bool,
        brandColor: Color? = nil,
        colorScheme: ColorScheme = .light
    ) {
        self.reduceMotion = reduceMotion
        self.brandColor = brandColor
        self.colorScheme = colorScheme
    }

    /// The tones a gradient background should draw with: an explicit palette wins, then an explicit
    /// brand color, then the style tint, then blue.
    func tones(brand: Color?, palette: ReleaseGradientPalette?) -> ReleaseGradientPalette.Tones {
        (palette ?? .brand(brand ?? self.brandColor ?? .blue)).tones(for: self.colorScheme)
    }
}

/// Exact light and dark tones for the gradient backgrounds.
///
/// Pass one when brand-derived tones are not close enough; otherwise ``brand(_:)`` derives a full
/// palette from a single color.
public struct ReleaseGradientPalette: Equatable, Sendable {
    /// The four colors a gradient background draws with in one color scheme.
    public struct Tones: Equatable, Sendable {
        /// The surface color under the gradient, and the color veiling its edges.
        public var base: Color
        /// The dominant gradient color.
        public var primary: Color
        /// The second gradient color.
        public var secondary: Color
        /// The third gradient color, carrying the least weight.
        public var accent: Color

        /// Creates a set of tones for one color scheme.
        ///
        /// - Parameters:
        ///   - base: Surface color under the gradient.
        ///   - primary: Dominant gradient color.
        ///   - secondary: Second gradient color.
        ///   - accent: Third gradient color.
        public init(base: Color, primary: Color, secondary: Color, accent: Color) {
            self.base = base
            self.primary = primary
            self.secondary = secondary
            self.accent = accent
        }
    }

    /// Tones used in light mode.
    public var light: Tones
    /// Tones used in dark mode.
    public var dark: Tones

    /// The blue-derived palette used when no brand color or palette is supplied.
    public static let standard = Self.brand(.blue)

    /// Creates a palette.
    ///
    /// - Parameters:
    ///   - light: Tones for light mode.
    ///   - dark: Tones for dark mode. Passing `nil` reuses `light` in both schemes, which is rarely
    ///     what you want for a saturated palette — dark mode needs its own tones to stay readable.
    public init(light: Tones, dark: Tones? = nil) {
        self.light = light
        self.dark = dark ?? light
    }

    /// Derives a full light and dark palette from a single brand color.
    ///
    /// The brand color becomes `primary`, and the supporting tones are that same color washed
    /// toward the platform surface, so the field reads as one color rather than as three unrelated
    /// hues. Because the surface is light in light mode and dark in dark mode, the same wash lifts
    /// the palette in one and deepens it in the other.
    ///
    /// Dark mode washes less: a dark surface swallows chroma faster, so an equal mix would flatten
    /// the supporting tones into the background.
    ///
    /// - Parameter brand: The color to build the palette around.
    /// - Returns: A palette tuned for both color schemes.
    public static func brand(_ brand: Color) -> Self {
        Self(
            light: Tones(
                base: Tokens.background,
                primary: brand,
                secondary: brand.mix(with: Tokens.background, by: 0.30),
                accent: brand.mix(with: Tokens.background, by: 0.55)),
            dark: Tones(
                base: Tokens.background,
                primary: brand,
                secondary: brand.mix(with: Tokens.background, by: 0.22),
                accent: brand.mix(with: Tokens.background, by: 0.42)))
    }

    func tones(for colorScheme: ColorScheme) -> Tones {
        colorScheme == .dark ? self.dark : self.light
    }
}

/// The surface drawn behind the release sheet's content.
///
/// Apply one with ``ReleaseView/releaseBackground(_:)``. Every option spans the full sheet,
/// including the area behind the pinned footer, so the footer never sits on a seam.
///
/// ```swift
/// ReleaseView(content: MyRelease()) { isShowing = false }
///     .releaseBackground(.animatedGradient())
///     .releaseStyle(ReleaseStyle(tint: .indigo))
/// ```
///
/// The gradient options take their brand color from ``ReleaseStyle/tint`` unless you pass `brand:`
/// or a full `palette:`. Use ``ReleaseStyle`` for the colors on top of this surface.
public struct ReleaseBackground: Sendable {
    enum Storage: Sendable {
        case system
        case softGradient(brand: Color?, palette: ReleaseGradientPalette?)
        case animatedGradient(brand: Color?, palette: ReleaseGradientPalette?)
        case custom(@Sendable @MainActor (ReleaseBackgroundContext) -> AnyView)
    }

    let storage: Storage

    /// The default: the platform sheet surface, with no gradient.
    public static let system = Self(storage: .system)

    /// A restrained brand-derived gradient, tuned to keep content readable.
    ///
    /// Uses ``ReleaseStyle/tint`` as its brand color. Use ``softGradient(brand:palette:)`` to
    /// override that.
    public static let softGradient = Self(storage: .softGradient(brand: nil, palette: nil))

    /// A restrained brand-derived gradient with an explicit brand color or palette.
    ///
    /// - Parameters:
    ///   - brand: Brand color for the gradient. `nil` falls back to ``ReleaseStyle/tint``, then to
    ///     blue.
    ///   - palette: Exact light and dark tones. Takes precedence over `brand` when both are given.
    /// - Returns: A background you can pass to ``ReleaseView/releaseBackground(_:)``.
    public static func softGradient(
        brand: Color? = nil,
        palette: ReleaseGradientPalette? = nil
    ) -> Self {
        Self(storage: .softGradient(brand: brand, palette: palette))
    }

    /// A slowly drifting full-surface gradient, rendered in a `Canvas`.
    ///
    /// Adapts its tones to the color scheme, and becomes static automatically when Reduce Motion is
    /// enabled — no extra handling needed at the call site.
    ///
    /// - Parameters:
    ///   - brand: Brand color for the gradient. `nil` falls back to ``ReleaseStyle/tint``, then to
    ///     blue.
    ///   - palette: Exact light and dark tones. Takes precedence over `brand` when both are given.
    /// - Returns: A background you can pass to ``ReleaseView/releaseBackground(_:)``.
    public static func animatedGradient(
        brand: Color? = nil,
        palette: ReleaseGradientPalette? = nil
    ) -> Self {
        Self(storage: .animatedGradient(brand: brand, palette: palette))
    }

    /// A fully custom SwiftUI background.
    ///
    /// The closure receives a ``ReleaseBackgroundContext``; read `reduceMotion`, `brandColor`, and
    /// `colorScheme` from it so a custom surface stays as consistent and accessible as the built-in
    /// ones.
    ///
    /// ```swift
    /// .releaseBackground(.custom { context in
    ///     LinearGradient(
    ///         colors: [
    ///             .blue.opacity(context.reduceMotion ? 0.10 : 0.18),
    ///             context.colorScheme == .dark ? .purple.opacity(0.24) : .purple.opacity(0.12),
    ///         ],
    ///         startPoint: .top,
    ///         endPoint: .bottom)
    /// })
    /// ```
    ///
    /// - Parameter background: Builds the background for a given context. Runs on the main actor.
    /// - Returns: A background you can pass to ``ReleaseView/releaseBackground(_:)``.
    public static func custom<Background: View>(
        @ViewBuilder _ background: @Sendable @MainActor @escaping (ReleaseBackgroundContext) -> Background
    ) -> Self {
        Self(
            storage: .custom { context in
                AnyView(background(context))
            })
    }
}

extension ReleaseBackground {
    @MainActor
    func makeView(context: ReleaseBackgroundContext) -> AnyView {
        switch self.storage {
        case .system:
            AnyView(Tokens.background)
        case let .softGradient(brand, palette):
            AnyView(
                ReleaseSoftGradientBackground(
                    tones: context.tones(brand: brand, palette: palette),
                    colorScheme: context.colorScheme))
        case let .animatedGradient(brand, palette):
            AnyView(
                ReleaseAnimatedGradientBackground(
                    tones: context.tones(brand: brand, palette: palette),
                    colorScheme: context.colorScheme,
                    reduceMotion: context.reduceMotion))
        case let .custom(background):
            background(context)
        }
    }
}

private struct ReleaseSoftGradientBackground: View {
    let tones: ReleaseGradientPalette.Tones
    let colorScheme: ColorScheme

    var body: some View {
        let isDark = self.colorScheme == .dark
        let baseTint = isDark ? 0.20 : 0.12

        ZStack {
            self.tones.base

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(baseTint),
                    self.tones.secondary.opacity(baseTint * 0.7),
                    self.tones.accent.opacity(baseTint * 0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.primary.opacity(isDark ? 0.24 : 0.18),
                    self.tones.secondary.opacity(isDark ? 0.18 : 0.12),
                    self.tones.accent.opacity(isDark ? 0.16 : 0.10),
                    self.tones.base.opacity(isDark ? 0.54 : 0.62),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)

            LinearGradient(
                colors: [
                    self.tones.base.opacity(isDark ? 0.08 : 0.04),
                    self.tones.base.opacity(isDark ? 0.42 : 0.78),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
    }
}

private struct ReleaseAnimatedGradientBackground: View {
    let tones: ReleaseGradientPalette.Tones
    let colorScheme: ColorScheme
    let reduceMotion: Bool

    private static let cycleDuration: TimeInterval = 9.35

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: self.reduceMotion)) { timeline in
            let phase =
                self.reduceMotion
                ? 0
                : timeline.date.timeIntervalSinceReferenceDate / Self.cycleDuration

            GeometryReader { geometry in
                let centers = ReleaseAnimatedGradientMotion.centers(
                    phase: phase,
                    reduceMotion: self.reduceMotion)
                let isDark = self.colorScheme == .dark

                Canvas(
                    opaque: true,
                    colorMode: .extendedLinear,
                    rendersAsynchronously: true
                ) { context, size in
                    ReleaseAnimatedGradientRenderer.draw(
                        context: &context,
                        size: size,
                        tones: self.tones,
                        isDark: isDark,
                        centers: centers)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

private enum ReleaseAnimatedGradientRenderer {
    /// The veil is the surface color painted back over the field. It is what keeps the gradient
    /// behind the content rather than competing with it, and light mode previously had almost none
    /// — a 0.38 base tint under a 0.04 veil, where the soft gradient reaches 0.78. That inversion
    /// is why the animated background read heavy in light mode and calm in dark.
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        tones: ReleaseGradientPalette.Tones,
        isDark: Bool,
        centers: [CGPoint]
    ) {
        let rect = CGRect(origin: .zero, size: size)
        let baseSize = max(size.width, size.height)
        let baseTint = isDark ? 0.145 : 0.165

        context.fill(Path(rect), with: .color(tones.base))

        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [
                    tones.primary.opacity(baseTint),
                    tones.secondary.opacity(baseTint * 0.76),
                    tones.accent.opacity(baseTint * 0.68),
                    tones.primary.opacity(baseTint * 0.58),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)))

        var blobContext = context
        blobContext.addFilter(.blur(radius: baseSize * 0.035))
        blobContext.drawLayer { layer in
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.primary,
                opacity: 0.324,
                center: centers[0],
                radius: baseSize * 0.92)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.secondary,
                opacity: isDark ? 0.259 : 0.281,
                center: centers[1],
                radius: baseSize * 1.00)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.accent,
                opacity: isDark ? 0.238 : 0.259,
                center: centers[2],
                radius: baseSize * 0.88)
            self.drawBlob(
                context: &layer,
                canvasRect: rect,
                size: size,
                color: tones.primary,
                opacity: isDark ? 0.194 : 0.216,
                center: centers[3],
                radius: baseSize * 1.08)
        }

        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [
                    tones.base.opacity(isDark ? 0.30 : 0.20),
                    tones.base.opacity(isDark ? 0.55 : 0.38),
                ]),
                startPoint: CGPoint(x: size.width * 0.5, y: 0),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height)))
    }

    private static func drawBlob(
        context: inout GraphicsContext,
        canvasRect: CGRect,
        size: CGSize,
        color: Color,
        opacity: Double,
        center: CGPoint,
        radius: CGFloat
    ) {
        let centerPoint = CGPoint(x: center.x * size.width, y: center.y * size.height)

        context.fill(
            Path(canvasRect),
            with: .radialGradient(
                Gradient(colors: [
                    color.opacity(opacity),
                    color.opacity(opacity * 0.42),
                    color.opacity(opacity * 0.12),
                    color.opacity(opacity * 0.08),
                ]),
                center: centerPoint,
                startRadius: 0,
                endRadius: radius))
    }
}

enum ReleaseAnimatedGradientMotion {
    static func centers(phase: Double, reduceMotion: Bool) -> [CGPoint] {
        let phase = reduceMotion ? 0 : phase
        let travel: Double = reduceMotion ? 0 : 1
        let baseAngle = phase * .pi * 2
        let slowAngle = (phase * 0.63 * .pi * 2) + 1.4
        let fastAngle = (phase * 1.21 * .pi * 2) + 2.1

        return [
            self.point(0.30 + (0.216 * travel * sin(baseAngle)), 0.22 + (0.168 * travel * cos(slowAngle))),
            self.point(0.70 + (0.216 * travel * cos(slowAngle)), 0.28 + (0.192 * travel * sin(fastAngle))),
            self.point(0.30 + (0.192 * travel * sin(fastAngle)), 0.72 + (0.216 * travel * cos(baseAngle))),
            self.point(0.70 + (0.216 * travel * cos(baseAngle)), 0.68 + (0.192 * travel * sin(slowAngle))),
        ]
    }

    private static func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y)))
    }
}
#endif
