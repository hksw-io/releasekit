#if os(iOS) || os(macOS)
import SwiftUI

/// A "What's New" sheet: an app icon, a title, a scrolling list of features, and a pinned footer
/// with an optional notice and a button.
///
/// Supply the copy through a ``ReleaseContent`` conformer and present it however the app prefers —
/// usually a sheet. The view never dismisses itself: the button calls `onContinue`, and the caller
/// closes the presentation there. Return activates the button on both platforms, and on macOS
/// Escape runs `onContinue` too. Native dismissal gestures are allowed by default and do not run
/// `onContinue`, so record that the sheet was seen in the presenting sheet's `onDismiss`, which
/// covers the button, gestures, and programmatic dismissal alike.
///
/// ```swift
/// ContentView()
///     .sheet(isPresented: $isShowing, onDismiss: tracker.markAsShown) {
///         ReleaseView(content: MyRelease()) {
///             isShowing = false
///         }
///     }
/// ```
///
/// The footer is a bottom safe-area bar. Rows fade out over a short band where they meet it, and
/// the background runs behind it to the edges of the sheet, past the safe area. Its button spans
/// the footer on both platforms. Feature rows animate in with a staggered reveal that is suppressed
/// under Reduce Motion. Layout adapts to compact and regular widths, to Dynamic Type, and to
/// resizable macOS windows. At accessibility text sizes the words get the room: the app icon is
/// dropped and the notice scrolls with the rows, so only the button stays pinned.
///
/// Use ``releaseBackground(_:)`` for the surface and ``releaseStyle(_:)`` for the tint.
/// Pair with ``ReleaseVersionTracker`` to decide when to present.
public struct ReleaseView<Content: ReleaseContent>: View {
    let content: Content
    let onContinue: () -> Void
    let allowsInteractiveDismissal: Bool
    private var background: ReleaseBackground = .system
    private var style: ReleaseStyle = .standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var featuresVisible = false

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = Tokens.Platform.iconSize
    @ScaledMetric(relativeTo: .body) private var featureIconSize: CGFloat = Tokens.Platform.featureIconSize
    @ScaledMetric(relativeTo: .body) private var contentSpacing: CGFloat = Tokens.Platform.contentSpacing
    @ScaledMetric(relativeTo: .body) private var featureSpacing: CGFloat = Tokens.Platform.featureSpacing
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = Tokens.Platform.topPadding
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = Tokens.Platform.bottomPadding
    @ScaledMetric(relativeTo: .body) private var footerFadeHeight: CGFloat = Tokens.Platform.footerFadeHeight
    #if os(iOS)
    @ScaledMetric(relativeTo: .body) private var compactHorizontalPadding: CGFloat = Tokens.Layout
        .compactHorizontalPadding
    #endif
    @ScaledMetric(relativeTo: .body) private var regularHorizontalPadding: CGFloat = Tokens.Layout
        .regularHorizontalPadding

    /// Creates a release sheet.
    ///
    /// - Parameters:
    ///   - content: The copy and icon to present.
    ///   - allowsInteractiveDismissal: Allows native dismissal gestures, such as swiping the sheet
    ///     down. Defaults to `true`, as in GreetKit. Pass `false` to make the button, and Escape on
    ///     macOS, the only way out.
    ///   - onContinue: Runs when the footer button is activated or, on macOS, Escape is pressed.
    ///     Close the presentation here. It does not run for a dismissal gesture; use the
    ///     presenting sheet's `onDismiss` to observe every completed dismissal.
    public init(
        content: Content,
        allowsInteractiveDismissal: Bool = true,
        onContinue: @escaping () -> Void
    ) {
        self.content = content
        self.onContinue = onContinue
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
    }

    /// The composed sheet: a scrolling column with the footer pinned as a bottom bar, over a
    /// background that fills the sheet.
    ///
    /// The background is applied last, outside the row mask and the clip. Inside the mask it would
    /// fade with the rows; inside the clip it stops at the safe area, which left a flat band under
    /// the footer button on an iPhone.
    public var body: some View {
        // At accessibility text sizes the words need the room. The app icon is decorative and
        // would scale to fill most of the first screen, and a notice pinned above the button
        // holds the footer open over the rows — so the icon goes and the notice scrolls.
        let isAccessibilitySize = self.dynamicTypeSize.isAccessibilitySize

        ScrollView(.vertical) {
            VStack(spacing: self.contentSpacing) {
                ReleaseHeaderSection(
                    appIcon: isAccessibilitySize ? nil : self.content.appIcon,
                    title: self.content.title,
                    iconSize: self.iconSize)
                VStack(spacing: self.featureSpacing) {
                    ForEach(Array(self.content.features.enumerated()), id: \.element.id) { index, feature in
                        ReleaseFeatureRow(
                            feature: feature,
                            index: index,
                            featureIconSize: self.featureIconSize,
                            featuresVisible: self.featuresVisible,
                            reduceMotion: self.reduceMotion)
                    }
                }
                if isAccessibilitySize, let notice = self.content.notice {
                    ReleaseNoticeText(notice: notice)
                }
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
        // already hides itself when idle. iPhone leans on the fade above the footer instead.
        #if os(macOS)
        .scrollIndicators(.automatic, axes: .vertical)
        #else
        .scrollIndicators(.never, axes: .vertical)
        #endif
        .scrollBounceBehavior(.basedOnSize)
        // Fade the rows out where they meet the bar.
        //
        // Neither system edge effect fits. The hard style draws a divider across a surface meant
        // to be continuous; the soft style drops the divider but bleeds a tall footer's own text
        // over the rows behind it.
        //
        // The band is all that is needed. `safeAreaBar` already reserves the bar's height, so
        // rows stop at its top edge rather than running underneath — erasing a footer's height
        // as well, as this did at first, just blanks a second footer's worth of content above
        // the real one. Because the background is drawn outside this mask, it shows through the
        // band unbroken, including the animated gradient.
        .mask {
            ReleaseFooterMask(
                fadeHeight: self.footerFadeHeight,
                scrollerGutter: Tokens.Platform.scrollerGutter)
        }
        .safeAreaBar(edge: .bottom) {
            ReleaseFooterSection(
                notice: isAccessibilitySize ? nil : self.content.notice,
                buttonText: self.content.buttonText,
                onContinue: self.onContinue
            )
            .frame(maxWidth: Tokens.Layout.contentMaxWidth)
            .padding(.horizontal, self.horizontalPadding)
            .frame(maxWidth: .infinity)
        }
        .scrollEdgeEffectHidden(true, for: .bottom)
        .clipped()
        // Behind the clip, not inside it. Inside, the clip cut the background off at the safe
        // area, so a gradient stopped short of the sheet's bottom edge.
        .background {
            self.background
                .makeView(
                    context: ReleaseBackgroundContext(
                        reduceMotion: self.reduceMotion,
                        brandColor: self.style.tint,
                        colorScheme: self.colorScheme,
                        reduceTransparency: self.reduceTransparency,
                        colorSchemeContrast: self.colorSchemeContrast)
                )
                .ignoresSafeArea()
        }
        .interactiveDismissDisabled(!self.allowsInteractiveDismissal)
        .tint(self.style.tint)
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

    /// Sets the tint for the button and the feature icons, which is also the default brand color
    /// for the gradient backgrounds.
    ///
    /// - Parameter style: The style to apply. A `nil` tint keeps the inherited one.
    /// - Returns: A copy of the view using the given style.
    public func releaseStyle(_ style: ReleaseStyle) -> Self {
        var view = self
        view.style = style
        return view
    }

    /// A Mac window is never compact, so macOS skips the question entirely.
    private var horizontalPadding: CGFloat {
        #if os(iOS)
        self.horizontalSizeClass == .compact ? self.compactHorizontalPadding : self.regularHorizontalPadding
        #else
        self.regularHorizontalPadding
        #endif
    }
}

/// Fades the scroll view's rows out over a short band where they meet the footer.
///
/// The opaque section takes the remaining height rather than a measured one, so nothing has to be
/// measured to place the band.
///
/// A mask applies to everything the scroll view draws, including its indicator, so on macOS the
/// scroller faded out along with the rows. A trailing strip is therefore left opaque. It is narrower
/// than the sheet's horizontal padding, so it spares the scroller without ever holding content.
struct ReleaseFooterMask: View {
    /// Scaled for Dynamic Type, which can hand back a negative value — hence the `max(0,)` below,
    /// since a negative length flips a `frame`.
    let fadeHeight: CGFloat
    let scrollerGutter: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.black)
                    .frame(maxHeight: .infinity)

                LinearGradient(
                    colors: [.black, .black.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: max(0, self.fadeHeight))
            }

            if self.scrollerGutter > 0 {
                Rectangle()
                    .fill(.black)
                    .frame(width: max(0, self.scrollerGutter))
            }
        }
    }
}

private struct ReleaseHeaderSection: View {
    let appIcon: Image?
    let title: Text
    let iconSize: CGFloat

    var body: some View {
        VStack(spacing: Tokens.Layout.elementSpacing) {
            if let appIcon = self.appIcon {
                appIcon
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.iconSize, height: self.iconSize)
                    .clipShape(.rect(cornerRadius: self.iconSize * Tokens.Layout.iconRadiusScale, style: .continuous))
                    .accessibilityHidden(true)
            }

            self.title
                #if os(macOS)
            .font(.title)
                #else
            .font(.largeTitle)
                #endif
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

private struct ReleaseFeatureRow: View {
    let feature: ReleaseFeature
    let index: Int
    let featureIconSize: CGFloat
    let featuresVisible: Bool
    let reduceMotion: Bool

    var body: some View {
        let delay = Tokens.Motion.revealDelay(for: self.index)
        let isVisible = self.featuresVisible

        HStack(alignment: .top, spacing: Tokens.Layout.elementSpacing) {
            if let image = self.feature.image {
                image
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: self.featureIconSize, height: self.featureIconSize)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label = self.feature.label {
                    label
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                self.feature.description
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

/// The notice copy, wherever it sits: pinned above the button, or at the end of the rows at
/// accessibility text sizes.
private struct ReleaseNoticeText: View {
    let notice: ReleaseNotice

    var body: some View {
        self.notice.text
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

private struct ReleaseFooterSection: View {
    let notice: ReleaseNotice?
    let buttonText: Text
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Layout.footerControlSpacing) {
            if let notice = self.notice {
                ReleaseNoticeText(notice: notice)
            }

            ReleaseContinueButton(
                label: self.buttonText,
                onContinue: self.onContinue)
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
private struct ReleaseContinueButton: View {
    let label: Text
    let onContinue: () -> Void

    var body: some View {
        Button {
            self.onContinue()
        } label: {
            self.label
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
    /// Escape is the Mac's cancel gesture. The view never dismisses itself — the caller owns the
    /// presentation — so Escape is bound to the same closure as the button. `onExitCommand` does
    /// not reach a sheet's content, and a button carries only one shortcut, so the binding lives on
    /// a zero-sized companion button.
    private var escapeShortcut: some View {
        Button("", action: self.onContinue)
            .keyboardShortcut(.cancelAction)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
    }
    #endif

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
    ReleaseView(content: ReleasePreviewContent(), onContinue: {})
}

#Preview("What's New Long Narrow") {
    ReleaseView(content: LongReleasePreviewContent(), onContinue: {})
        .frame(width: 320, height: 720)
}

#Preview("What's New Dark Accessibility") {
    ReleaseView(content: LongReleasePreviewContent(), onContinue: {})
        .frame(width: 390, height: 760)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}
#endif
