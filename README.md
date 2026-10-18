# ReleaseKit

[![CI](https://github.com/hksw-io/ReleaseKit/actions/workflows/ci.yml/badge.svg)](https://github.com/hksw-io/ReleaseKit/actions/workflows/ci.yml)

A reusable SwiftUI "What's New" sheet for iOS and macOS apps in the HK Softworks portfolio.

The package and import name is `ReleaseKit`. Public view and content APIs intentionally use the
domain language `Release...`, for example `ReleaseView`, `ReleaseContent`, and
`ReleaseVersionTracker`.

## Preview

<p>
  <img src="Docs/Media/releasekit-demo.webp" alt="The release sheet sliding up on iPhone over an indigo animated gradient: the app icon and What's New title appear, then the feature rows reveal one after another above a pinned Continue button." width="250">
</p>

The sheet presenting on iPhone with `.animatedGradient()`. Rows reveal in sequence while the gradient drifts behind them.

The default `.system` background on iPhone. Rows fade out where they meet the pinned footer, and the button spans it:

<p>
  <img src="Docs/Media/releasekit-iphone-light.jpg" alt="The release sheet on iPhone in light mode: app icon, What's New title, five feature rows, and a pinned footer with a notice above a full-width Continue button." width="250">
  <img src="Docs/Media/releasekit-iphone-dark.jpg" alt="The same iPhone sheet in dark mode, with the same layout on a dark surface." width="250">
</p>

`.animatedGradient()`, taking its brand color from `ReleaseStyle.tint`. It adapts its tones per color scheme and holds still under Reduce Motion:

<p>
  <img src="Docs/Media/releasekit-iphone-gradient-light.jpg" alt="The iPhone sheet in light mode with the animated gradient background, tinted indigo." width="250">
  <img src="Docs/Media/releasekit-iphone-gradient-dark.jpg" alt="The iPhone sheet in dark mode with the animated gradient background, tinted indigo." width="250">
</p>

On iPad the same sheet presents as a centered card. Its size comes from the presentation, and ReleaseKit caps the content column at 560pt:

<p>
  <img src="Docs/Media/releasekit-ipad-gradient.jpg" alt="The release sheet on iPad in light mode with the animated gradient background, presented as a centered card." width="300">
  <img src="Docs/Media/releasekit-ipad-dark.jpg" alt="The release sheet on iPad in dark mode with the system background, presented as a centered card." width="300">
</p>

On macOS it is a resizable window with the platform's overlay scroller, and Escape runs `onDismiss`:

<p>
  <img src="Docs/Media/releasekit-mac-gradient.png" alt="The release sheet on macOS in light mode with the animated gradient background, shown as a sheet in a window with an overlay scroller." width="300">
  <img src="Docs/Media/releasekit-mac-dark.png" alt="The release sheet on macOS in dark mode with the system background, shown as a sheet in a window with an overlay scroller." width="300">
</p>

## Requirements

- iOS 26+ / macOS 26+
- Swift 6.2+

## Installation

```swift
.package(url: "https://github.com/hksw-io/ReleaseKit.git", from: "3.0.0")
```

Or in Xcode: **File > Add Package Dependencies** and enter the URL above.

`allowsInteractiveDismissal`, the Reduce Transparency and Increase Contrast fallback with its
matching `context` values, and the bundled privacy manifest are on `master` but not in 3.0.0.
They ship in the next tagged release.

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

The default background is the opaque system background color (`systemBackground` on iOS, `windowBackgroundColor` on macOS). Use `releaseBackground(_:)` when an app needs a more branded release note experience:

```swift
ReleaseView(content: MyRelease()) {
    isShowing = false
}
.releaseBackground(.animatedGradient())
.releaseStyle(ReleaseStyle(tint: .indigo))
```

`releaseBackground(_:)` and `releaseStyle(_:)` are methods on `ReleaseView` that return a `ReleaseView`, not general view modifiers. Apply them before any other modifier, such as `presentationDetents(_:)`.

Built-in options:

- `.system` — the default platform background.
- `.softGradient` / `.softGradient(brand:palette:)` — a restrained brand-derived background tuned for readable content.
- `.animatedGradient(brand:palette:)` — an opt-in smooth full-surface animated gradient. It uses the style tint by default, adapts its tones for light and dark mode, and automatically becomes static when Reduce Motion is enabled.
- `.custom { context in ... }` — a fully custom SwiftUI background, including a plain `LinearGradient` of your own colors. Use `context.reduceMotion`, `context.reduceTransparency`, `context.colorSchemeContrast`, `context.brandColor`, and `context.colorScheme` to keep custom backgrounds consistent and accessible.

Every background spans behind the pinned footer and button area, including `.system`. macOS shows its normal overlay scroller, which is how a Mac signals that a list continues; iOS hides the indicator and lets the content fade out at the footer instead.

`ReleaseStyle.tint` is the default brand color for `.softGradient` and `.animatedGradient()`, falling back to blue when no tint is set. The supporting tones are that same color washed toward the platform surface, so the field reads as one color family rather than as unrelated hues — and because the surface is light in light mode and dark in dark mode, the same wash lifts the palette in one and deepens it in the other.

Pass `brand:` when the background should use a different brand color from the controls, or pass a full palette when an app needs exact light and dark tones:

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

The animated gradient's travel, speed, and contrast are fixed. Reduce Motion holds it still; there is no per-app intensity to set.

Reduce Transparency or Increase Contrast replaces either built-in gradient with the opaque
system surface.

ReleaseKit keeps the footer pinned, sized to its own content. Rows fade out over a short band where they meet it, so the background carries through unbroken and a footer running to several lines never has content showing through it. The footer reserves no more space than it uses.

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

`ReleaseBackground` controls the surface behind the sheet content. `ReleaseStyle` controls the foreground roles: `titleColor`, `featureIconColor`, `featureTitleColor`, `featureDescriptionColor`, `noticeColor`, and `buttonForegroundColor`. Any color you leave as `nil` uses the standard system treatment. `tint` controls the prominent button accent and is also used by feature icons unless `featureIconColor` is set.

`buttonForegroundColor` is left out of the example on purpose. Its default is the system's prominent-button label color, which already adapts to your tint, to light and dark mode, and to Increase Contrast — setting it to a fixed color usually costs you contrast somewhere.

## Platform behavior

The sheet is one API with two deliberately different presentations. Apart from interactive dismissal, you do not configure this; it follows the platform.

| | iOS | macOS |
|---|---|---|
| Return | Activates the button | Activates the button |
| Escape | — | Runs the view's `onDismiss` |
| Swipe to dismiss | Off; on with `allowsInteractiveDismissal: true` | — |
| Scroll indicator | Hidden | Normal overlay scroller |
| Sheet size | Set by the presentation | 560×520 ideal, 480×420 floor |
| Reveal motion | 38pt travel | 20pt travel, leads sooner |

Under Reduce Motion the rows appear without the reveal.

The footer button is a full-width prominent capsule on both platforms. The sheet is a single-action surface, so the button reads as the end of the content rather than as a Mac sheet's bottom-trailing default button. Both platforms use the system prominent button style, so press, hover, focus, and Increase Contrast behavior come from the platform rather than from anything this package draws.

On macOS, Escape calls the view's `onDismiss` closure, the same one the button calls, instead of dismissing the sheet natively. Interactive dismissal is off by default, so on both platforms the user leaves through that closure. With `allowsInteractiveDismissal: true`, an iOS swipe closes the sheet without calling it, and programmatic dismissal skips it in either mode. Record acknowledgement (`ReleaseVersionTracker.markAsShown()`) in the presenting `.sheet(onDismiss:)`, which runs after every dismissal. See [Version tracking](#version-tracking).

Text in the title and feature rows is selectable, which Mac users expect of a window they may want to copy out of.

## Features and localization

Every `ReleaseFeature` requires a stable `id`. Stable IDs let SwiftUI preserve row identity when features are inserted, removed, or reordered. Because conformers usually expose `features` as a computed property, an ID derived per evaluation — a fresh `UUID()`, say — would re-create every row on each pass and replay the entrance animation.

`ReleaseFeature` and `ReleaseNotice` each have a `Text` initializer and a `LocalizedStringResource` one. Use `ReleaseFeature(id:image:label:description:)` for an asset-catalog icon or pre-styled `Text`; `ReleaseFeature(id:systemImage:label:description:)` takes an SF Symbol name and localized strings. Localized values resolve against your app's bundle, so ReleaseKit ships no strings of its own and never localizes on your behalf. That is also why `buttonText` has no default.

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

The first launch after install is treated as "not new" — users see the sheet only on subsequent version upgrades. `shouldShowRelease()` is not a pure query: on that first launch it writes both tracking keys before returning `false`. Every later call only reads. Specifically, the first call for a given `keyPrefix` and defaults store counts as the first launch, so an app adopting ReleaseKit in an update, changing `keyPrefix`, or moving to an App Group suite skips the sheet for existing users on that version.

Versions are compared for equality, not order, so `currentVersion` can be any string your app treats as its release identity. A rollback to an older version also shows the sheet.

`keyPrefix` namespaces the two keys the tracker writes, `<keyPrefix>.release.lastShownVersion` and `<keyPrefix>.hasLaunchedBefore`, so trackers with different prefixes never observe each other's state. Don't write either key from your own code.

`userDefaults` defaults to `.standard`. Pass a suite to share state across an App Group or to isolate tests:

```swift
let tracker = ReleaseVersionTracker(
    userDefaults: UserDefaults(suiteName: "group.com.example.myapp")!,
    keyPrefix: "com.example.myapp",
    currentVersion: "1.2.0")
```

The package bundles `PrivacyInfo.xcprivacy` for app-local (`CA92.1`) and same-App-Group
(`1C8F.1`) UserDefaults storage. Pass only your app's defaults or an entitled App Group suite,
and use an app-specific prefix. ReleaseKit does not collect data or perform tracking. Preserve
the Swift package resource bundle when embedding the library and verify the manifest in your archive.

`ReleaseView`'s `onDismiss` is a request. The button and the Mac Escape shortcut call it, and
your code updates the presentation state; it does not run when the sheet closes any other way.
To record acknowledgement, use the presentation's own `onDismiss`, which runs after every
dismissal. With that in place, an informational sheet can also allow native dismissal gestures:

```swift
.sheet(isPresented: $isShowing, onDismiss: tracker.markAsShown) {
    ReleaseView(content: MyRelease(), allowsInteractiveDismissal: true) {
        isShowing = false
    }
}
```

The default stays `false` for source and behavior compatibility. With the presentation callback
recording acknowledgement, the button closure only needs to set `isShowing = false`; marking
there as well is redundant but harmless.

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

The README media was captured from the iOS 27.2 Simulator (iPhone 17 Pro, iPad Pro 11-inch)
and a macOS window.

## OS 27 compatibility

The deployment minimum remains iOS 26 / macOS 26, with Swift tools 6.2. CI runs package tests
on macOS and iOS Simulator with Xcode 26.6 and the Xcode 27.0 preview image. Each job selects
its toolchain and runtime generation explicitly; the 27 image is maintained by GitHub as
[`xcode-27`](https://github.com/actions/runner-images/issues/14404). New SDK-only APIs must
preserve the existing deployment and compiler minimums. Local SDK 27.2 validation complements
these jobs; a local pass does not establish the result of a hosted CI run.

## License

MIT. See [LICENSE](LICENSE).
