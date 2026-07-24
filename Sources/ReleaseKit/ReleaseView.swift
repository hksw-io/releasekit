#if os(iOS) || os(macOS)
import SwiftUI

public struct ReleaseView<Content: ReleaseContent>: View {
    let content: Content
    let onDismiss: () -> Void
    private var background: ReleaseBackground = .system
    private var style: ReleaseStyle = .standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var featuresVisible = false
    @State private var scrollEdgeFadeOpacity: Double = 1
    @State private var footerFrame: FooterMaskFrame = .zero

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var buttonPadding: CGFloat = Tokens.Platform.buttonVerticalPadding
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding
    @ScaledMetric(relativeTo: .body) private var scrollEdgeFadeHeight: CGFloat = Tokens.Platform.scrollEdgeFadeHeight
    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout
        .compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout
        .regularHorizontalPadding

    public init(content: Content, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            ReleaseBackgroundView(
                background: self.background,
                reduceMotion: self.reduceMotion,
                brandColor: self.style.tint,
                colorScheme: self.colorScheme)

            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(spacing: self.contentSpacing) {
                        ReleaseHeaderSection(
                            content: self.content,
                            iconSize: self.iconSize,
                            style: self.style)
                        ReleaseFeatureList(
                            features: self.content.features,
                            featureSpacing: self.featureSpacing,
                            featureIconSize: self.featureIconSize,
                            featuresVisible: self.featuresVisible,
                            reduceMotion: self.reduceMotion,
                            style: self.style)
                    }
                    .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                    .padding(.top, self.topPadding)
                    .padding(
                        .bottom,
                        self.bottomPadding
                            + FooterMaskMetrics.contentBottomInset(
                                containerHeight: geometry.size.height,
                                footerFrame: self.footerFrame))
                }
                .scrollIndicators(.never, axes: .vertical)
                .scrollBounceBehavior(.basedOnSize)
                .onScrollGeometryChange(for: Double.self) { geometry in
                    ScrollEdgeFade.opacity(
                        contentHeight: geometry.contentSize.height,
                        visibleMaxY: geometry.visibleRect.maxY,
                        fadeHeight: self.resolvedScrollEdgeFadeHeight)
                } action: { _, newOpacity in
                    if self.scrollEdgeFadeOpacity != newOpacity {
                        self.scrollEdgeFadeOpacity = newOpacity
                    }
                }
                .mask {
                    FooterContentMask(
                        containerHeight: geometry.size.height,
                        footerFrame: self.footerFrame,
                        fadeHeight: self.resolvedScrollEdgeFadeHeight,
                        scrollEdgeFadeOpacity: self.scrollEdgeFadeOpacity)
                }
                .overlay(alignment: .bottom) {
                    ReleaseFooterSection(
                        content: self.content,
                        buttonPadding: self.buttonPadding,
                        style: self.style,
                        onDismiss: self.onDismiss
                    )
                    .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                    .padding(.horizontal, self.horizontalPadding(for: geometry.size.width))
                    .onGeometryChange(for: FooterMaskFrame.self) { geometry in
                        FooterMaskMetrics.quantizedFrame(
                            geometry.frame(in: .named(FooterMaskMetrics.coordinateSpaceName)))
                    } action: { newFrame in
                        if self.footerFrame != newFrame {
                            self.footerFrame = newFrame
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .coordinateSpace(.named(FooterMaskMetrics.coordinateSpaceName))
            }
        }
        .clipped()
        .interactiveDismissDisabled()
        .releaseTint(self.style.tint)
        #if os(macOS)
        .frame(
            minWidth: Tokens.Layout.compactSheetMinWidth,
            minHeight: Tokens.Layout.compactSheetMinHeight)
        #endif
        .onAppear {
            self.featuresVisible = true
        }
    }

    public func releaseBackground(_ background: ReleaseBackground) -> Self {
        var view = self
        view.background = background
        return view
    }

    public func releaseStyle(_ style: ReleaseStyle) -> Self {
        var view = self
        view.style = style
        return view
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        LayoutMetrics.horizontalPadding(
            for: width,
            compact: self.compactHorizontalPadding,
            regular: self.regularHorizontalPadding,
            breakpoint: Tokens.Layout.compactWidthBreakpoint)
    }

    private var resolvedScrollEdgeFadeHeight: CGFloat {
        FooterMaskMetrics.resolvedFadeHeight(self.scrollEdgeFadeHeight)
    }
}

enum LayoutMetrics {
    static func horizontalPadding(
        for width: CGFloat,
        compact: CGFloat,
        regular: CGFloat,
        breakpoint: CGFloat
    ) -> CGFloat {
        width <= breakpoint ? compact : regular
    }
}

enum ScrollEdgeFade {
    static let opacityStep = 0.05

    static func opacity(
        contentHeight: CGFloat,
        visibleMaxY: CGFloat,
        fadeHeight: CGFloat
    ) -> Double {
        guard contentHeight > 0, fadeHeight > 0 else {
            return 1
        }

        let distance = contentHeight - visibleMaxY
        let rawOpacity = Double(min(1, max(0, distance / fadeHeight)))
        return self.quantize(rawOpacity)
    }

    static func quantize(_ opacity: Double, step: Double = Self.opacityStep) -> Double {
        guard step > 0 else {
            return opacity
        }

        return (opacity / step).rounded() * step
    }
}

enum FooterMaskMetrics {
    static let coordinateSpaceName = "ReleaseFooterMask"
    static let heightStep: CGFloat = 1
    static let maximumFadeHeight: CGFloat = 28

    static func quantizedFrame(_ frame: CGRect, step: CGFloat = Self.heightStep) -> FooterMaskFrame {
        FooterMaskFrame(
            minY: self.quantizedHeight(frame.minY, step: step),
            height: self.quantizedHeight(frame.height, step: step))
    }

    static func quantizedHeight(_ height: CGFloat, step: CGFloat = Self.heightStep) -> CGFloat {
        guard height > 0, step > 0 else {
            return 0
        }

        return (height / step).rounded() * step
    }

    static func resolvedFadeHeight(_ fadeHeight: CGFloat, maximum: CGFloat = Self.maximumFadeHeight) -> CGFloat {
        guard fadeHeight > 0, maximum > 0 else {
            return 0
        }

        return min(fadeHeight, maximum)
    }

    static func layout(
        containerHeight: CGFloat,
        footerFrame: FooterMaskFrame,
        fadeHeight: CGFloat,
        scrollEdgeFadeOpacity: Double
    ) -> FooterMaskLayout {
        guard containerHeight > 0, footerFrame.isMeasured else {
            return FooterMaskLayout(
                opaqueHeight: max(0, containerHeight),
                fadeHeight: 0,
                clearHeight: 0,
                fadeBottomOpacity: 1)
        }

        let footerMinY = min(max(0, footerFrame.minY), containerHeight)
        let resolvedFadeHeight = min(max(0, fadeHeight), footerMinY)
        let clearHeight = self.contentBottomInset(
            containerHeight: containerHeight,
            footerFrame: footerFrame)

        return FooterMaskLayout(
            opaqueHeight: max(0, footerMinY - resolvedFadeHeight),
            fadeHeight: resolvedFadeHeight,
            clearHeight: clearHeight,
            fadeBottomOpacity: self.fadeBottomOpacity(scrollEdgeFadeOpacity: scrollEdgeFadeOpacity))
    }

    static func contentBottomInset(containerHeight: CGFloat, footerFrame: FooterMaskFrame) -> CGFloat {
        guard containerHeight > 0, footerFrame.isMeasured else {
            return 0
        }

        let footerMinY = min(max(0, footerFrame.minY), containerHeight)
        return max(0, containerHeight - footerMinY)
    }

    static func fadeBottomOpacity(scrollEdgeFadeOpacity: Double) -> Double {
        1 - min(1, max(0, scrollEdgeFadeOpacity))
    }
}

struct FooterMaskFrame: Equatable {
    static let zero = Self(minY: 0, height: 0)

    let minY: CGFloat
    let height: CGFloat

    var isMeasured: Bool {
        self.height > 0
    }
}

struct FooterMaskLayout: Equatable {
    let opaqueHeight: CGFloat
    let fadeHeight: CGFloat
    let clearHeight: CGFloat
    let fadeBottomOpacity: Double
}

private struct FooterContentMask: View {
    let containerHeight: CGFloat
    let footerFrame: FooterMaskFrame
    let fadeHeight: CGFloat
    let scrollEdgeFadeOpacity: Double

    var body: some View {
        let layout = FooterMaskMetrics.layout(
            containerHeight: self.containerHeight,
            footerFrame: self.footerFrame,
            fadeHeight: self.fadeHeight,
            scrollEdgeFadeOpacity: self.scrollEdgeFadeOpacity)

        VStack(spacing: 0) {
            Rectangle()
                .fill(.black)
                .frame(height: layout.opaqueHeight)

            if layout.fadeHeight > 0 {
                LinearGradient(
                    colors: [
                        .black,
                        .black.opacity(layout.fadeBottomOpacity),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: layout.fadeHeight)
            }

            Rectangle()
                .fill(.clear)
                .frame(height: layout.clearHeight)
        }
    }
}

private struct ReleaseBackgroundView: View {
    let background: ReleaseBackground
    let reduceMotion: Bool
    let brandColor: Color?
    let colorScheme: ColorScheme

    var body: some View {
        self.background
            .makeView(
                context: ReleaseBackgroundContext(
                    reduceMotion: self.reduceMotion,
                    brandColor: self.brandColor,
                    colorScheme: self.colorScheme)
            )
            .ignoresSafeArea()
    }
}

private struct ReleaseHeaderSection<Content: ReleaseContent>: View {
    let content: Content
    let iconSize: CGFloat
    let style: ReleaseStyle

    var body: some View {
        VStack(spacing: Tokens.Spacing.large) {
            if let appIcon = self.content.appIcon {
                appIcon
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.iconSize, height: self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: self.iconSize * Tokens.Radius.iconScale))
                    .accessibilityHidden(true)
            }

            self.content.title
                #if os(macOS)
            .font(.title)
                #else
            .font(.largeTitle)
                #endif
                .fontWeight(.bold)
                .releaseOptionalForegroundStyle(self.style.titleColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

private struct ReleaseFeatureList: View {
    let features: [ReleaseFeature]
    let featureSpacing: CGFloat
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool
    let style: ReleaseStyle

    var body: some View {
        VStack(spacing: self.featureSpacing) {
            ForEach(Array(self.features.enumerated()), id: \.element.id) { index, feature in
                ReleaseFeatureRow(
                    feature: feature,
                    index: index,
                    featureIconSize: self.featureIconSize,
                    featuresVisible: self.featuresVisible,
                    reduceMotion: self.reduceMotion,
                    style: self.style)
            }
        }
    }
}

private struct ReleaseFeatureRow: View {
    let feature: ReleaseFeature
    let index: Int
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool
    let style: ReleaseStyle

    var body: some View {
        let delay = Tokens.Motion.revealDelay(for: self.index)
        let isVisible = self.featuresVisible

        HStack(alignment: .top, spacing: Tokens.Spacing.large) {
            if let image = self.feature.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(self.style.featureIconForegroundStyle)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label = self.feature.label {
                    label
                        .font(.headline)
                        .releaseOptionalForegroundStyle(self.style.featureTitleColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                self.feature.description
                    .font(.subheadline)
                    .foregroundStyle(self.style.featureDescriptionForegroundStyle)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : (self.reduceMotion ? 0 : Tokens.Motion.revealOffset))
        .animation(
            self.reduceMotion ? nil : .easeOut(duration: Tokens.Motion.revealDuration).delay(delay),
            value: isVisible)
    }
}

private struct ReleaseFooterSection<Content: ReleaseContent>: View {
    let content: Content
    let buttonPadding: CGFloat
    let style: ReleaseStyle
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Layout.footerControlSpacing) {
            if let notice = self.content.notice {
                notice.text
                    .font(.subheadline)
                    .foregroundStyle(self.style.noticeForegroundStyle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            Button {
                self.onDismiss()
            } label: {
                self.content.buttonText
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(self.style.buttonForegroundStyle)
                    .frame(maxWidth: .infinity, minHeight: Tokens.Layout.buttonLabelMinHeight)
                    .padding(.vertical, self.buttonPadding)
                    .frame(minHeight: Tokens.Layout.minimumControlHeight)
                    .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous)
                    .fill(self.style.buttonBackgroundStyle)
            }
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
        }
        .padding(.top, Tokens.Layout.footerTopPadding)
        .padding(.bottom, Tokens.Layout.footerBottomPadding)
    }
}

private extension View {
    @ViewBuilder
    func releaseTint(_ color: Color?) -> some View {
        if let color {
            self.tint(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func releaseOptionalForegroundStyle(_ color: Color?) -> some View {
        if let color {
            self.foregroundStyle(color)
        } else {
            self
        }
    }
}

private struct ReleasePreviewContent: ReleaseContent {
    var appIcon: Image? { Image(systemName: "app.gift.fill") }
    var title: Text { Text("What's New") }
    var features: [ReleaseFeature] {
        [
            ReleaseFeature(
                id: "first-feature",
                systemImage: "sparkles",
                label: "First feature",
                description: "A short description of the first feature."),
            ReleaseFeature(
                id: "second-feature",
                systemImage: "bolt",
                label: "Second feature",
                description: "A short description of the second feature."),
            ReleaseFeature(
                id: "third-feature",
                systemImage: "arrow.triangle.2.circlepath",
                label: "Third feature",
                description: "A short description of the third feature."),
        ]
    }
    var notice: ReleaseNotice? {
        ReleaseNotice(text: Text("Plus many other improvements."))
    }
    var buttonText: Text { Text("Continue") }
}

private struct LongReleasePreviewContent: ReleaseContent {
    var appIcon: Image? { Image(systemName: "square.stack.3d.up.fill") }
    var title: Text {
        Text("A much longer What's New title that needs to wrap cleanly")
    }
    var features: [ReleaseFeature] {
        (1...10).map { index in
            ReleaseFeature(
                id: "long-feature-\(index)",
                systemImage: "checkmark.seal.fill",
                label: "Feature \(index) with a longer localized label",
                description:
                    "This feature description is intentionally longer so the row wraps cleanly without clipping, overlapping, or hiding the footer action."
            )
        }
    }
    var notice: ReleaseNotice? {
        ReleaseNotice(text: Text("This notice is long enough to exercise multiline footer copy in a narrow sheet."))
    }
    var buttonText: Text {
        Text("Continue with all of these new improvements")
    }
}

#Preview("What's New") {
    ReleaseView(content: ReleasePreviewContent(), onDismiss: {})
}

#Preview("What's New Long Narrow") {
    ReleaseView(content: LongReleasePreviewContent(), onDismiss: {})
        .frame(width: 320, height: 720)
}

#Preview("What's New Dark Accessibility") {
    ReleaseView(content: LongReleasePreviewContent(), onDismiss: {})
        .frame(width: 390, height: 760)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}
#endif
