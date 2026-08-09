#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import ReleaseKit

@MainActor
struct ReleaseViewBuildTest {
    /// One construction pass over every content shape and background the package ships.
    ///
    /// It asserts nothing at runtime on purpose: the coverage is the type check, and a single test
    /// carries it exactly as well as the fifteen near-identical ones that used to live here.
    @Test
    func viewConstructsAcrossContentAndBackgroundVariants() {
        let palette = ReleaseGradientPalette(
            light: .init(base: .white, primary: .pink, secondary: .orange, accent: .yellow),
            dark: .init(base: .black, primary: .purple, secondary: .blue, accent: .mint))

        _ = ReleaseView(content: MinimalContent(), onDismiss: {})
        _ = ReleaseView(content: PublicContent(), onDismiss: {})
        _ = ReleaseView(content: LongContent(), onDismiss: {})
        _ = ReleaseView(content: StyledContent(), onDismiss: {})
            .releaseStyle(.standard)
        _ = ReleaseView(content: StyledContent(), onDismiss: {})
            .releaseStyle(
                ReleaseStyle(
                    tint: .indigo,
                    titleColor: .primary,
                    featureIconColor: .mint,
                    featureTitleColor: .primary,
                    featureDescriptionColor: .secondary,
                    noticeColor: .secondary,
                    buttonForegroundColor: .white))

        let backgrounds: [ReleaseBackground] = [
            .system,
            .softGradient,
            .softGradient(brand: .orange),
            .linearGradient(
                colors: [.blue.opacity(0.18), .mint.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing),
            .animatedGradient(),
            .animatedGradient(palette: palette),
            .custom { context in
                LinearGradient(
                    colors: [
                        Color.blue.opacity(context.reduceMotion ? 0.10 : 0.18),
                        context.colorScheme == .dark ? .purple.opacity(0.24) : .purple.opacity(0.12),
                    ],
                    startPoint: .top,
                    endPoint: .bottom)
            },
        ]

        for background in backgrounds {
            _ = ReleaseView(content: StyledContent(), onDismiss: {})
                .releaseBackground(background)
        }
    }

    @Test
    func styleKeepsButtonLabelColorOptional() {
        #expect(ReleaseStyle(tint: .indigo).buttonForegroundColor == nil)
        #expect(ReleaseStyle(buttonForegroundColor: .white).buttonForegroundColor == .white)
    }

    /// Supporting tones used to be fixed hues — `.cyan` and `.mint` regardless of brand — so the
    /// field read as three unrelated colours. They are now washed from the brand itself.
    @Test
    func gradientPaletteDerivesSupportingTonesFromTheBrand() {
        let red = ReleaseGradientPalette.brand(.red)
        let blue = ReleaseGradientPalette.brand(.blue)

        #expect(red.light.secondary != blue.light.secondary)
        #expect(red.light.accent != blue.light.accent)
        #expect(red.dark.secondary != blue.dark.secondary)
        #expect(red.dark.accent != blue.dark.accent)

        #expect(red.light.secondary != Color.cyan)
        #expect(red.light.accent != Color.mint)
    }

    @Test
    func backgroundContextStoresColorScheme() {
        let defaultContext = ReleaseBackgroundContext(reduceMotion: true)
        let darkContext = ReleaseBackgroundContext(
            reduceMotion: false,
            brandColor: .pink,
            colorScheme: .dark)

        #expect(defaultContext.reduceMotion)
        #expect(defaultContext.colorScheme == .light)
        #expect(!darkContext.reduceMotion)
        #expect(darkContext.colorScheme == .dark)
    }

    /// The fade band is the whole mask. `safeAreaBar` reserves the footer's height itself, so
    /// erasing that height again blanks a second footer's worth of content above the real one.
    @Test
    func footerMaskFadesWithoutReservingFooterHeight() {
        #expect(ReleaseFooterMask.clamped(Tokens.Platform.footerFadeHeight) == Tokens.Platform.footerFadeHeight)
        #expect(Tokens.Platform.footerFadeHeight > 0)
    }

    /// A negative height would flip the mask's frame, and Dynamic Type scaling can hand one back.
    @Test
    func footerMaskClampsNegativeHeights() {
        #expect(ReleaseFooterMask.clamped(-1) == 0)
        #expect(ReleaseFooterMask.clamped(-240) == 0)

        _ = ReleaseFooterMask(fadeHeight: -5, scrollerGutter: -5)
    }

    /// The mask covers everything the scroll view draws, indicator included. The spared strip has to
    /// stay narrower than the horizontal padding so it never sits over content.
    @Test
    func scrollerGutterStaysWithinHorizontalPadding() {
        #expect(Tokens.Platform.scrollerGutter < Tokens.Layout.regularHorizontalPadding)

        #if os(macOS)
        #expect(Tokens.Platform.scrollerGutter > 0)
        #else
        #expect(Tokens.Platform.scrollerGutter == 0)
        #endif
    }

    /// The button must clear the sheet edge rather than hug it, without floating so high that the
    /// bar looks detached from the bottom of the sheet.
    @Test
    func footerBottomPaddingClearsSheetEdgeWithoutFloatingHigh() {
        #expect(Tokens.Layout.footerBottomPadding > 0)
        #expect(Tokens.Layout.footerBottomPadding <= Tokens.Layout.footerTopPadding)
    }

    @Test
    func animatedGradientCentersAreStableWithReduceMotion() {
        let first = ReleaseAnimatedGradientMotion.centers(phase: 0, reduceMotion: true)
        let second = ReleaseAnimatedGradientMotion.centers(phase: 0.5, reduceMotion: true)

        #expect(first[0].x == second[0].x)
        #expect(first[0].y == second[0].y)
    }

    @Test
    func animatedGradientCentersChangeAcrossPhases() {
        let first = ReleaseAnimatedGradientMotion.centers(phase: 0, reduceMotion: false)
        let second = ReleaseAnimatedGradientMotion.centers(phase: 0.25, reduceMotion: false)

        #expect(abs(first[0].x - second[0].x) > 0.0001)
    }

    @Test
    func featureInitializerStoresStableID() {
        let feature = ReleaseFeature(
            id: "stable-feature",
            label: Text("Stable feature"),
            description: Text("A feature with stable identity."))

        #expect(feature.id == "stable-feature")
    }

    @Test
    func revealDelayStartsWithBaseDelay() {
        #expect(Tokens.Motion.revealDelay(for: 0) == Tokens.Motion.featureBaseDelay)
    }

    @Test
    func revealDelayCapsLongLists() {
        let expectedDelay = Tokens.Motion.featureBaseDelay + Tokens.Motion.maxFeatureStaggerDelay
        let actualDelay = Tokens.Motion.revealDelay(for: 100)

        #expect(abs(actualDelay - expectedDelay) < 0.0001)
    }

    @Test
    func layoutUsesCompactPaddingAtBreakpoint() {
        let padding = LayoutMetrics.horizontalPadding(
            for: 390,
            compact: 16,
            regular: 24,
            breakpoint: 390)

        #expect(padding == 16)
    }

    @Test
    func layoutUsesRegularPaddingAboveBreakpoint() {
        let padding = LayoutMetrics.horizontalPadding(
            for: 391,
            compact: 16,
            regular: 24,
            breakpoint: 390)

        #expect(padding == 24)
    }

    @Test
    func contentOmittingNoticeUsesProtocolDefault() {
        #expect(MinimalContent().notice == nil)
        #expect(MinimalContent().appIcon == nil)
    }

    @Test
    func noticeAcceptsLocalizedStringResource() {
        let localized = ReleaseNotice("Plus many other improvements.")
        let explicit = ReleaseNotice(text: Text(LocalizedStringResource("Plus many other improvements.")))

        #expect(localized == explicit)
    }

    @Test
    func featuresCompareByValue() {
        let feature = ReleaseFeature(id: "shared", label: Text("Label"), description: Text("Body."))
        let same = ReleaseFeature(id: "shared", label: Text("Label"), description: Text("Body."))
        let renamed = ReleaseFeature(id: "shared", label: Text("Other"), description: Text("Body."))
        let reidentified = ReleaseFeature(id: "other", label: Text("Label"), description: Text("Body."))

        #expect(feature == same)
        #expect(feature != renamed)
        #expect(feature != reidentified)
    }

    @Test
    func stylesCompareByValue() {
        #expect(ReleaseStyle(tint: .indigo) == ReleaseStyle(tint: .indigo))
        #expect(ReleaseStyle(tint: .indigo) != ReleaseStyle(tint: .mint))
        #expect(ReleaseStyle.standard == ReleaseStyle())
    }

    @Test
    func noticesCompareByValue() {
        #expect(ReleaseNotice(text: Text("Same")) == ReleaseNotice(text: Text("Same")))
        #expect(ReleaseNotice(text: Text("Same")) != ReleaseNotice(text: Text("Different")))
    }

    /// The one production consumer declares its conformer as a `public struct`, and public types
    /// do not get `Sendable` inferred the way internal ones do. Every other conformer in this
    /// suite is internal, so this is the only case that would catch a regression there.
    @Test
    func publicConformerSatisfiesSendableRequirement() {
        #expect(PublicContent().notice == nil)
    }
}

/// Mirrors the production consumer's shape: a `public struct` conformer. It omits `notice` so the
/// protocol default is exercised at the same time.
public struct PublicContent: ReleaseContent {
    public init() {}

    public var appIcon: Image? { Image(systemName: "app.gift.fill") }
    public var title: Text { Text("Public") }
    public var features: [ReleaseFeature] {
        [ReleaseFeature(id: "public-feature", description: Text("A feature."))]
    }
    public var buttonText: Text { Text("Continue") }
}

/// The smallest conformance the protocol allows: no icon, no notice, no rows.
private struct MinimalContent: ReleaseContent {
    var title: Text { Text("Minimal") }
    var features: [ReleaseFeature] { [] }
    var buttonText: Text { Text("OK") }
}

private struct StyledContent: ReleaseContent {
    var title: Text { Text("Styled") }
    var features: [ReleaseFeature] {
        [
            ReleaseFeature(
                id: "styled-feature",
                image: Image(systemName: "paintpalette.fill"),
                label: Text("Styled feature"),
                description: Text("This feature checks custom style construction."))
        ]
    }
    var notice: ReleaseNotice? { ReleaseNotice(text: Text("Styled notice")) }
    var buttonText: Text { Text("Done") }
}

/// Long localized copy through the `LocalizedStringResource` initializers, so wrapping and the
/// convenience initializers stay covered.
private struct LongContent: ReleaseContent {
    var appIcon: Image? { Image(systemName: "sparkles") }
    var title: Text {
        Text("A much longer What's New title that needs to wrap cleanly on compact devices")
    }
    var features: [ReleaseFeature] {
        (1...12).map { index in
            ReleaseFeature(
                id: "feature-\(index)",
                systemImage: "star.circle.fill",
                label: "Feature \(index) with a longer localized label",
                description:
                    "This feature description is intentionally longer so the row has to wrap without clipping, overlapping, or pushing controls off screen."
            )
        }
    }
    var notice: ReleaseNotice? {
        ReleaseNotice("This notice is also long enough to wrap over multiple lines in a narrow sheet.")
    }
    var buttonText: Text {
        Text("Continue with all of these new improvements")
    }
}
#endif
