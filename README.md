# ReleaseKit

[![CI](https://github.com/hksw-io/ReleaseKit/actions/workflows/ci.yml/badge.svg)](https://github.com/hksw-io/ReleaseKit/actions/workflows/ci.yml)

A reusable SwiftUI "What's New" sheet for iOS and macOS apps in the HK Softworks portfolio.

The package and import name is `ReleaseKit`. Public view and content APIs intentionally use the
domain language `Release...`, for example `ReleaseView`, `ReleaseContent`, and
`ReleaseVersionTracker`.

## Preview

<p>
  <img src="Docs/Media/releasekit-animated-gradient.png" alt="ReleaseKit with an animated gradient background, long localized content, footer fade, and pinned action button." width="360">
  <img src="Docs/Media/releasekit-system-long-content.png" alt="ReleaseKit with the system background, long localized content, footer fade, and pinned action button." width="360">
</p>

## Requirements

- iOS 26+ / macOS 26+
- Swift 6.2+

## Installation

```swift
.package(url: "https://github.com/hksw-io/ReleaseKit.git", from: "1.0.0")
```

Or in Xcode: **File > Add Package Dependencies** and enter the URL above.

## Usage

Implement `ReleaseContent` with your app's strings and icon, then present the view. Only `title`, `features`, and `buttonText` are required — `appIcon` and `notice` default to `nil`:

```swift
import SwiftUI
import ReleaseKit

struct MyRelease: ReleaseContent {
    var appIcon: Image? { Image("AppIconImage") }
    var title: Text { Text("What's New in MyApp") }
    var features: [ReleaseFeature] {
        [
            ReleaseFeature(
                id: "new-charts",
                systemImage: "chart.line.uptrend.xyaxis.circle",
                label: "New Charts",
                description: "Track your progress with redesigned charts."),
        ]
    }
    var notice: ReleaseNotice? {
        ReleaseNotice("Plus many other improvements.")
    }
    var buttonText: Text { Text("Continue") }
}

struct RootView: View {
    @State private var isShowing = false

    var body: some View {
        ContentView()
            .sheet(isPresented: $isShowing) {
                ReleaseView(content: MyRelease()) {
                    isShowing = false
                }
            }
    }
}
```

## Backgrounds

The default background is the system sheet surface. Use `releaseBackground(_:)` when an app needs a more branded release note experience:

```swift
ReleaseView(content: MyRelease()) {
    isShowing = false
}
.releaseBackground(.animatedGradient())
.releaseStyle(ReleaseStyle(tint: .indigo))
```

Built-in options:

- `.system` — the default platform background.
- `.softGradient` / `.softGradient(brand:palette:)` — a restrained brand-derived background tuned for readable content.
- `.linearGradient(colors:startPoint:endPoint:)` — app-provided colors with the library-managed footer treatment.
- `.animatedGradient(brand:palette:motion:)` — an opt-in smooth full-surface animated gradient. It uses the style tint by default, adapts its tones for light and dark mode, and automatically becomes static when Reduce Motion is enabled.
- `.custom { context in ... }` — a fully custom SwiftUI background. Use `context.reduceMotion`, `context.brandColor`, and `context.colorScheme` to keep custom backgrounds consistent and accessible.

Every background spans behind the pinned footer and button area, including `.system`. macOS shows its normal overlay scroller, which is how a Mac signals that a list continues; iOS hides the indicator and relies on the scroll edge effect instead.

`ReleaseStyle.tint` is the default brand color for `.softGradient` and `.animatedGradient()`. Pass `brand:` when the background should use a different brand color from the controls, or pass a full palette when an app needs exact light and dark tones:

```swift
let palette = ReleaseGradientPalette(
    light: .init(
        base: .white,
        primary: .pink,
        secondary: .orange,
        accent: .yellow),
    dark: .init(
        base: .black,
        primary: .pink,
        secondary: .purple,
        accent: .cyan))

ReleaseView(content: MyRelease()) {
    isShowing = false
}
.releaseBackground(.animatedGradient(palette: palette))
```

Use `motion:` when the default dancing gradient should be calmer or more expressive:

```swift
ReleaseView(content: MyRelease()) {
    isShowing = false
}
.releaseBackground(.animatedGradient(motion: .expressive))
```

The built-in presets are `.subtle`, `.standard`, and `.expressive`. Stronger motion increases movement, speed, and gradient contrast. For finer control, pass `ReleaseGradientMotion(strength:)`; values are clamped from `0` to `2`, and `0` keeps the animated-gradient color field static.

ReleaseKit keeps the footer pinned while content scrolls behind it. A measured footer mask fades overflowing content only above the footer; when scrolling reaches the end, visible content is fully opaque again.

## Styling

Use `releaseStyle(_:)` to override foreground, tint, and button colors while keeping the library's layout, typography, and motion:

```swift
ReleaseView(content: MyRelease()) {
    isShowing = false
}
.releaseStyle(ReleaseStyle(
    tint: .indigo,
    titleColor: .primary,
    featureIconColor: .mint,
    featureDescriptionColor: .secondary,
    noticeColor: .secondary))
```

`ReleaseBackground` controls the surface behind the sheet content. `ReleaseStyle` controls foreground roles such as title, feature rows, notice text, and button text. Any color you leave as `nil` uses the standard system treatment. `tint` controls the prominent button accent and is also used by feature icons unless `featureIconColor` is set.

`buttonForegroundColor` is left out of the example on purpose. Its default is the system's prominent-button label color, which already adapts to your tint, to light and dark mode, and to Increase Contrast — setting it to a fixed color usually costs you contrast somewhere.

## Platform behavior

The sheet is one API with two deliberately different presentations. You do not configure this; it follows the platform.

| | iOS | macOS |
|---|---|---|
| Footer button | Full width, sized for touch | Natural width, trailing edge |
| Return | Activates the button | Activates the button |
| Escape | — (swipe-to-dismiss stays disabled) | Runs `onDismiss` |
| Scroll indicator | Hidden | Normal overlay scroller |
| Sheet size | Presenter's detents | `presentationSizing(.form)`, 460×580 floor |
| Reveal motion | Full stagger | About half the travel and run |

Both platforms use the system prominent button style, so press, hover, focus, and Increase Contrast behavior come from the platform rather than from anything this package draws.

Escape is bound to `onDismiss` rather than dismissing the sheet natively. That matters: a native dismissal would bypass your closure and skip whatever you do there — `ReleaseVersionTracker.markAsShown()`, typically — so the sheet would return on the next launch. Every exit runs `onDismiss`.

Text in the title and feature rows is selectable, which Mac users expect of a window they may want to copy out of.

## Features and localization

Every `ReleaseFeature` requires a stable `id`. Stable IDs let SwiftUI preserve row identity when features are inserted, removed, or reordered. Because conformers usually expose `features` as a computed property, an ID derived per evaluation — a fresh `UUID()`, say — would re-create every row on each pass and replay the entrance animation.

`ReleaseFeature` and `ReleaseNotice` each have a `Text` initializer and a `LocalizedStringResource` one. Localized values resolve against your app's bundle, so ReleaseKit ships no strings of its own and never localizes on your behalf. That is also why `buttonText` has no default.

The content types are `Equatable` and `Sendable`, and `ReleaseContent` refines `Sendable`.

## Version tracking

`ReleaseVersionTracker` persists the last-shown version in `UserDefaults` and decides whether to present the sheet on launch:

```swift
let tracker = ReleaseVersionTracker(
    keyPrefix: "com.example.myapp",
    currentVersion: "1.2.0")

if tracker.shouldShowRelease() {
    // present ReleaseView
}

// after dismiss:
tracker.markAsShown()
```

The first launch after install is treated as "not new" — users see the sheet only on subsequent version upgrades. `shouldShowRelease()` is not a pure query: on that first launch it writes both tracking keys before returning `false`. Every later call only reads.

Versions are compared for equality, not order, so `currentVersion` can be any string your app treats as its release identity. A rollback to an older version also shows the sheet.

`keyPrefix` namespaces the two keys the tracker writes, so trackers with different prefixes never observe each other's state.

## Local development

Run the package tests from the package root:

```sh
swift test
```

Formatting is owned by `swift-format` against the checked-in `.swift-format`:

```sh
swift format --in-place --recursive Sources Tests
swift format lint --strict --recursive Sources Tests
```

Lint runs in CI, and every public declaration must carry a documentation comment.

## License

MIT. See [LICENSE](LICENSE).
