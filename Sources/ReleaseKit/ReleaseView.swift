#if os(iOS) || os(macOS)
import SwiftUI

/// A "What's New" sheet: an app icon, a title, a scrolling list of features, and a pinned footer
/// with an optional notice and a dismiss button.
///
/// Supply the copy through a ``ReleaseContent`` conformer and present it however the app prefers —
/// usually a sheet. Dismissal stays with the caller through `onDismiss`; the view never dismisses
/// itself, and interactive dismissal is disabled, so every exit runs that closure. Return activates
/// the button on both platforms, and on macOS Escape runs `onDismiss` too.
///
/// ```swift
/// ContentView()
///     .sheet(isPresented: $isShowing) {
///         ReleaseView(content: MyRelease()) {
///             isShowing = false
///         }
///     }
/// ```
///
/// The footer is a bottom safe-area bar, so content scrolls beneath it and the system's scroll edge
/// effect keeps overflowing rows legible where they meet it. Its button spans the footer on both
/// platforms. Feature rows animate in with a staggered reveal that is suppressed under Reduce
/// Motion. Layout adapts to compact and regular widths, to Dynamic Type, and to resizable macOS
/// windows.
///
/// Use ``releaseBackground(_:)`` for the surface and ``releaseStyle(_:)`` for foreground colors.
/// Pair with ``ReleaseVersionTracker`` to decide when to present.
public struct ReleaseView<Content: ReleaseContent>: View {
    let content: Content
    let onDismiss: () -> Void
    private var background: ReleaseBackground = .system
    private var style: ReleaseStyle = .standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var featuresVisible = false
    @State private var containerWidth: CGFloat = Tokens.Platform.assumedContainerWidth

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding
    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout
        .compactHorizontalPadding
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout
        .regularHorizontalPadding

    /// Creates a release sheet.
    ///
    /// - Parameters:
    ///   - content: The copy and icon to present.
    ///   - onDismiss: Called when the footer button is tapped. The caller owns dismissal — the view
    ///     does not dismiss itself.
    public init(content: Content, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onDismiss = onDismiss
    }

    /// The composed sheet: background behind a scrolling column, with the footer pinned as a bottom
    /// bar.
    ///
    /// The background is a sibling in the `ZStack` rather than a `.background` on the scroll view.
    /// That placement is load-bearing: applied to the scroll view, the bar's scroll edge effect has
    /// no surface to composite against and leaves a visible seam and a ghost of the rows behind it.
    public var body: some View {
        ZStack {
            ReleaseBackgroundView(
                background: self.background,
                reduceMotion: self.reduceMotion,
                brandColor: self.style.tint,
                colorScheme: self.colorScheme)

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
                // Mac users expect to be able to select and copy release copy out of a window.
                .textSelection(.enabled)
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.horizontalPadding)
                .padding(.top, self.topPadding)
                .padding(.bottom, self.bottomPadding)
            }
            // The Mac's overlay scroller is the conventional signal that a list continues, and it
            // already hides itself when idle. iPhone leans on the scroll edge effect instead.
            #if os(macOS)
            .scrollIndicators(.automatic, axes: .vertical)
            #else
            .scrollIndicators(.never, axes: .vertical)
            #endif
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaBar(edge: .bottom) {
                ReleaseFooterSection(
                    content: self.content,
                    style: self.style,
                    onDismiss: self.onDismiss
                )
                .frame(maxWidth: Tokens.Layout.contentMaxWidth)
                .padding(.horizontal, self.horizontalPadding)
                .frame(maxWidth: .infinity)
            }
            // After the bar, not before: the effect applies to the edge the bar creates.
            .scrollEdgeEffectStyle(.hard, for: .bottom)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.width
            } action: { newWidth in
                if self.containerWidth != newWidth {
                    self.containerWidth = newWidth
                }
            }
        }
        .clipped()
        .interactiveDismissDisabled()
        .releaseTint(self.style.tint)
        #if os(macOS)
        .frame(
            minWidth: Tokens.Platform.sheetMinWidth,
            idealWidth: Tokens.Platform.sheetIdealWidth,
            minHeight: Tokens.Platform.sheetMinHeight,
            idealHeight: Tokens.Platform.sheetIdealHeight)
        #endif
        .onAppear {
            self.featuresVisible = true
        }
    }

    /// Sets the surface drawn behind the sheet's content.
    ///
    /// - Parameter background: The background to draw. Defaults to ``ReleaseBackground/system``.
    /// - Returns: A copy of the view using the given background.
    public func releaseBackground(_ background: ReleaseBackground) -> Self {
        var view = self
        view.background = background
        return view
    }

    /// Sets the foreground colors for the title, feature rows, notice, and button.
    ///
    /// - Parameter style: The colors to apply. Any property left `nil` keeps its standard system
    ///   treatment.
    /// - Returns: A copy of the view using the given style.
    public func releaseStyle(_ style: ReleaseStyle) -> Self {
        var view = self
        view.style = style
        return view
    }

    private var horizontalPadding: CGFloat {
        LayoutMetrics.horizontalPadding(
            for: self.containerWidth,
            compact: self.compactHorizontalPadding,
            regular: self.regularHorizontalPadding,
            breakpoint: Tokens.Layout.compactWidthBreakpoint)
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
                    .clipShape(.rect(cornerRadius: self.iconSize * Tokens.Radius.iconScale, style: .continuous))
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
        // Scoped to the two modifiers that do the revealing, and nothing else.
        //
        // `.animation(_:value:)` only controls *when* an animation fires; it still animates every
        // animatable difference in the subtree at that moment. So anything else settling on the
        // same frame — a `@ScaledMetric` resolving, the description rewrapping — got swept into
        // the reveal's transaction and animated with the row's delay, which read as the text
        // jumping and shaking before it landed. The body form animates only what it wraps, so
        // layout that settles underneath applies instantly and invisibly.
        //
        // Ease-in-out, not a spring: this is a one-shot entrance nothing can interrupt, and a
        // spring's asymptotic tail reads as the row drifting after it has visually arrived. The
        // eased onset matters as much as the eased landing — ease-out starts at full speed, which
        // makes a row snap into motion the instant its delay expires.
        .animation(self.revealAnimation(delay: delay)) { content in
            content
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : self.revealOffset)
        }
    }

    private var revealOffset: CGFloat {
        self.reduceMotion ? 0 : Tokens.Motion.revealOffset
    }

    private func revealAnimation(delay: Double) -> Animation? {
        guard !self.reduceMotion else {
            return nil
        }

        return .easeInOut(duration: Tokens.Motion.revealDuration).delay(delay)
    }
}

private struct ReleaseFooterSection<Content: ReleaseContent>: View {
    let content: Content
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

            ReleaseDismissButton(
                label: self.content.buttonText,
                style: self.style,
                onDismiss: self.onDismiss)
        }
        .padding(.top, Tokens.Layout.footerTopPadding)
        .padding(.bottom, Tokens.Layout.footerBottomPadding)
    }
}

/// The footer's primary action: a full-width prominent capsule on both platforms.
///
/// The sheet is a single-action surface, and the action reads as the end of the content rather than
/// as a Mac sheet's bottom-trailing default button — so it spans the footer on macOS too.
/// `.buttonSizing(.flexible)` does the spanning, rather than stretching the label inside it. The
/// system button style supplies press, hover, focus, and contrast behavior on both platforms.
private struct ReleaseDismissButton: View {
    let label: Text
    let style: ReleaseStyle
    let onDismiss: () -> Void

    var body: some View {
        Button {
            self.onDismiss()
        } label: {
            self.label
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .releaseOptionalForegroundStyle(self.style.buttonForegroundColor)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .buttonSizing(.flexible)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
        #if os(macOS)
        .background {
            self.escapeShortcut
        }
        #endif
    }

    #if os(macOS)
    /// Escape is the Mac's cancel gesture. The sheet cannot be allowed to dismiss itself — that
    /// bypasses `onDismiss` and leaves the caller's bookkeeping unrun — so Escape is bound to the
    /// same closure as the button. `onExitCommand` does not reach a sheet's content, and a button
    /// carries only one shortcut, so the binding lives on a zero-sized companion button.
    private var escapeShortcut: some View {
        Button("", action: self.onDismiss)
            .keyboardShortcut(.cancelAction)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
    }
    #endif

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
