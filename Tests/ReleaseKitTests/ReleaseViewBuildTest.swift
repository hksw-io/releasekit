#if os(iOS) || os(macOS)
import SwiftUI
import Testing
@testable import ReleaseKit

@MainActor
struct ReleaseViewBuildTest {
    @Test
    func viewConstructsWithMockContent() {
        struct MockContent: ReleaseContent {
            var title: Text { Text("Mock") }
            var features: [ReleaseFeature] {
                [ReleaseFeature(id: "single", description: Text("Single feature."))]
            }
            var notice: ReleaseNotice? { nil }
            var buttonText: Text { Text("OK") }
        }

        _ = ReleaseView(content: MockContent(), onDismiss: {})
    }

    @Test
    func viewConstructsWithAllOptionalFields() {
        struct RichContent: ReleaseContent {
            var appIcon: Image? { Image(systemName: "app.gift.fill") }
            var title: Text { Text("Rich") }
            var features: [ReleaseFeature] {
                [
                    ReleaseFeature(
                        id: "labeled",
                        image: Image(systemName: "star"),
                        label: Text("Labeled"),
                        description: Text("With label and image."))
                ]
            }
            var notice: ReleaseNotice? { ReleaseNotice(text: Text("Notice")) }
            var buttonText: Text { Text("Continue") }
        }

        _ = ReleaseView(content: RichContent(), onDismiss: {})
    }

    @Test
    func viewConstructsWithConvenienceFeatureInitializer() {
        struct ConvenienceContent: ReleaseContent {
            var title: Text { Text("Convenience") }
            var features: [ReleaseFeature] {
                [
                    ReleaseFeature(
                        id: "localized-label",
                        systemImage: "sparkles",
                        label: "Localized label",
                        description: "Localized description.")
                ]
            }
            var notice: ReleaseNotice? { nil }
            var buttonText: Text { Text("OK") }
        }

        _ = ReleaseView(content: ConvenienceContent(), onDismiss: {})
    }

    @Test
    func viewConstructsWithLongLocalizedContentAndManyFeatures() {
        struct LongContent: ReleaseContent {
            var appIcon: Image? { Image(systemName: "sparkles") }
            var title: Text {
                Text("A much longer What's New title that needs to wrap cleanly on compact devices")
            }
            var features: [ReleaseFeature] {
                (1...12).map { index in
                    ReleaseFeature(
                        id: "feature-\(index)",
                        image: Image(systemName: "star.circle.fill"),
                        label: Text("Feature \(index) with a longer localized label"),
                        description: Text(
                            "This feature description is intentionally longer so the row has to wrap without clipping, overlapping, or pushing controls off screen."
                        ))
                }
            }
            var notice: ReleaseNotice? {
                ReleaseNotice(
                    text: Text("This notice is also long enough to wrap over multiple lines in a narrow sheet."))
            }
            var buttonText: Text {
                Text("Continue with all of these new improvements")
            }
        }

        _ = ReleaseView(content: LongContent(), onDismiss: {})
    }

    @Test
    func viewConstructsWhenComputedFeaturesRecreateValues() {
        struct ComputedContent: ReleaseContent {
            var title: Text { Text("Computed") }
            var features: [ReleaseFeature] {
                [
                    ReleaseFeature(id: "first", description: Text("First computed feature.")),
                    ReleaseFeature(id: "second", description: Text("Second computed feature.")),
                    ReleaseFeature(id: "third", description: Text("Third computed feature.")),
                ]
            }
            var notice: ReleaseNotice? { nil }
            var buttonText: Text { Text("Done") }
        }

        _ = ReleaseView(content: ComputedContent(), onDismiss: {})
    }

    @Test
    func viewConstructsWithStandardStyleModifier() {
        _ = ReleaseView(content: StyledContent(), onDismiss: {})
            .releaseStyle(.standard)
    }

    @Test
    func viewConstructsWithCustomStyleColors() {
        let style = ReleaseStyle(
            tint: .indigo,
            titleColor: .primary,
            featureIconColor: .mint,
            featureTitleColor: .primary,
            featureDescriptionColor: .secondary,
            noticeColor: .secondary,
            buttonForegroundColor: .white)

        _ = ReleaseView(content: StyledContent(), onDismiss: {})
            .releaseStyle(style)
    }

    @Test
    func styleProvidesCustomButtonSurface() {
        let style = ReleaseStyle(tint: .indigo, buttonForegroundColor: .white)

        _ = style.buttonBackgroundStyle
        _ = style.buttonForegroundStyle
    }

    @Test
    func viewConstructsWithSystemBackgroundModifier() {
        _ = self.backgroundView(.system)
    }

    @Test
    func viewConstructsWithSoftGradientBackground() {
        _ = self.backgroundView(.softGradient)
    }

    @Test
    func viewConstructsWithBrandSoftGradientBackground() {
        _ = self.backgroundView(.softGradient(brand: .orange))
    }

    @Test
    func viewConstructsWithLinearGradientBackground() {
        _ = self.backgroundView(
            .linearGradient(
                colors: [.blue.opacity(0.18), .mint.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
    }

    @Test
    func viewConstructsWithAnimatedGradientBackground() {
        _ = self.backgroundView(.animatedGradient())
    }

    @Test
    func viewConstructsWithExpressiveAnimatedGradientBackground() {
        _ = self.backgroundView(.animatedGradient(motion: .expressive))
    }

    @Test
    func viewConstructsWithGradientPaletteOverride() {
        let palette = ReleaseGradientPalette(
            light: .init(
                base: .white,
                primary: .pink,
                secondary: .orange,
                accent: .yellow),
            dark: .init(
                base: .black,
                primary: .purple,
                secondary: .blue,
                accent: .mint))

        _ = self.backgroundView(.animatedGradient(palette: palette))
    }

    @Test
    func viewConstructsWithCustomBackground() {
        _ = self.backgroundView(
            .custom { context in
                LinearGradient(
                    colors: [
                        Color.blue.opacity(context.reduceMotion ? 0.10 : 0.18),
                        context.colorScheme == .dark ? .purple.opacity(0.24) : .purple.opacity(0.12),
                    ],
                    startPoint: .top,
                    endPoint: .bottom)
            })
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

    @Test
    func footerMaskHeightQuantizesToWholePoints() {
        #expect(FooterMaskMetrics.quantizedHeight(123.4) == 123)
        #expect(FooterMaskMetrics.quantizedHeight(123.5) == 124)
    }

    @Test
    func footerMaskFrameQuantizesPositionAndHeight() {
        let frame = FooterMaskMetrics.quantizedFrame(CGRect(x: 0, y: 612.4, width: 390, height: 127.5))

        #expect(frame.minY == 612)
        #expect(frame.height == 128)
    }

    @Test
    func footerMaskFadeHeightCapsToAvoidEarlyMasking() {
        #expect(FooterMaskMetrics.resolvedFadeHeight(80) == FooterMaskMetrics.maximumFadeHeight)
    }

    @Test
    func footerMaskFadeHeightKeepsShorterValues() {
        #expect(FooterMaskMetrics.resolvedFadeHeight(18) == 18)
        #expect(FooterMaskMetrics.resolvedFadeHeight(0) == 0)
    }

    @Test
    func footerMaskFadeBottomIsHiddenWhenScrollableContentContinues() {
        #expect(FooterMaskMetrics.fadeBottomOpacity(scrollEdgeFadeOpacity: 1) == 0)
    }

    @Test
    func footerMaskFadeBottomIsVisibleAtScrollEnd() {
        #expect(FooterMaskMetrics.fadeBottomOpacity(scrollEdgeFadeOpacity: 0) == 1)
    }

    @Test
    func footerMaskLayoutUsesMeasuredFooterTop() {
        let layout = FooterMaskMetrics.layout(
            containerHeight: 740,
            footerFrame: FooterMaskFrame(minY: 612, height: 128),
            fadeHeight: FooterMaskMetrics.resolvedFadeHeight(80),
            scrollEdgeFadeOpacity: 1)

        #expect(layout.opaqueHeight == 584)
        #expect(layout.fadeHeight == 28)
        #expect(layout.clearHeight == 128)
        #expect(layout.fadeBottomOpacity == 0)
    }

    @Test
    func footerMaskLayoutStaysOpaqueBeforeFooterMeasurement() {
        let layout = FooterMaskMetrics.layout(
            containerHeight: 740,
            footerFrame: .zero,
            fadeHeight: FooterMaskMetrics.resolvedFadeHeight(80),
            scrollEdgeFadeOpacity: 1)

        #expect(layout.opaqueHeight == 740)
        #expect(layout.fadeHeight == 0)
        #expect(layout.clearHeight == 0)
        #expect(layout.fadeBottomOpacity == 1)
    }

    @Test
    func footerMaskContentBottomInsetMatchesMeasuredFooterArea() {
        let inset = FooterMaskMetrics.contentBottomInset(
            containerHeight: 740,
            footerFrame: FooterMaskFrame(minY: 612, height: 128))

        #expect(inset == 128)
    }

    @Test
    func footerMaskContentBottomInsetIsZeroBeforeFooterMeasurement() {
        let inset = FooterMaskMetrics.contentBottomInset(
            containerHeight: 740,
            footerFrame: .zero)

        #expect(inset == 0)
    }

    @Test
    func primaryButtonKeepsSharedMinimumLabelHeight() {
        #expect(Tokens.Layout.buttonLabelMinHeight == 28)
    }

    /// The footer button's intrinsic height is the label floor plus vertical padding on both
    /// edges. On macOS that lands on exactly 44, so the HIG minimum is met by arithmetic rather
    /// than by intent — this guards the invariant if either token is retuned.
    @Test
    func primaryButtonMeetsMinimumControlHeight() {
        let intrinsicHeight =
            Tokens.Layout.buttonLabelMinHeight + (Tokens.Platform.buttonVerticalPadding * 2)

        #expect(intrinsicHeight >= Tokens.Layout.minimumControlHeight)
    }

    @Test
    func footerBottomPaddingClearsSheetEdgeWithoutFloatingHigh() {
        #expect(Tokens.Layout.footerBottomPadding > 0)
        #expect(Tokens.Layout.footerBottomPadding < Tokens.Layout.footerTopPadding)
    }

    @Test
    func animatedGradientCentersAreStableWithReduceMotion() {
        let first = ReleaseAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: true,
            motion: .expressive)
        let second = ReleaseAnimatedGradientMotion.centers(
            phase: 0.5,
            reduceMotion: true,
            motion: .expressive)

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
    func expressiveAnimatedGradientMotionTravelsFartherThanSubtleMotion() {
        let subtleStart = ReleaseAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: false,
            motion: .subtle)
        let subtleEnd = ReleaseAnimatedGradientMotion.centers(
            phase: 0.25,
            reduceMotion: false,
            motion: .subtle)
        let expressiveStart = ReleaseAnimatedGradientMotion.centers(
            phase: 0,
            reduceMotion: false,
            motion: .expressive)
        let expressiveEnd = ReleaseAnimatedGradientMotion.centers(
            phase: 0.25,
            reduceMotion: false,
            motion: .expressive)

        #expect(
            self.totalTravel(from: expressiveStart, to: expressiveEnd)
                > self.totalTravel(from: subtleStart, to: subtleEnd))
    }

    @Test
    func expressiveAnimatedGradientMotionHasHigherVisualContrastThanSubtleMotion() {
        #expect(ReleaseGradientMotion.expressive.baseTintScale > ReleaseGradientMotion.subtle.baseTintScale)
        #expect(ReleaseGradientMotion.expressive.blobOpacityScale > ReleaseGradientMotion.subtle.blobOpacityScale)
        #expect(ReleaseGradientMotion.expressive.blobBlurScale < ReleaseGradientMotion.subtle.blobBlurScale)
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
    func scrollEdgeFadeQuantizesOpacity() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 955,
            fadeHeight: 100)

        #expect(opacity == 0.45)
    }

    @Test
    func scrollEdgeFadeIsOpaqueAtScrollEnd() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 1_000,
            fadeHeight: 100)

        #expect(opacity == 0)
    }

    @Test
    func scrollEdgeFadeIsOpaqueWhenVisibleRectExtendsPastContentEnd() {
        let opacity = ScrollEdgeFade.opacity(
            contentHeight: 1_000,
            visibleMaxY: 1_128,
            fadeHeight: 100)

        #expect(opacity == 0)
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

    private func backgroundView(_ background: ReleaseBackground) -> some View {
        ReleaseView(content: StyledContent(), onDismiss: {})
            .releaseBackground(background)
    }

    @Test
    func contentOmittingNoticeUsesProtocolDefault() {
        struct MinimalContent: ReleaseContent {
            var title: Text { Text("Minimal") }
            var features: [ReleaseFeature] { [] }
            var buttonText: Text { Text("OK") }
        }

        #expect(MinimalContent().notice == nil)
        #expect(MinimalContent().appIcon == nil)
        _ = ReleaseView(content: MinimalContent(), onDismiss: {})
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
        _ = ReleaseView(content: PublicContent(), onDismiss: {})

        #expect(PublicContent().notice == nil)
    }

    private func totalTravel(from first: [CGPoint], to second: [CGPoint]) -> Double {
        zip(first, second).reduce(0) { total, pair in
            let xDistance = Double(pair.0.x - pair.1.x)
            let yDistance = Double(pair.0.y - pair.1.y)
            return total + ((xDistance * xDistance) + (yDistance * yDistance)).squareRoot()
        }
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
#endif
