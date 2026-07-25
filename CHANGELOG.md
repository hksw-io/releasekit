# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-07-25

### Fixed

- A footer running to several lines — a long `ReleaseNotice` — drew its own text on top of the feature rows behind it. 2.0.0 used the soft scroll edge effect, which fades content rather than erasing it, so anything behind a tall bar stayed partly visible. The scroll view is masked instead: rows are opaque above the footer, fade over a short band, and are gone behind it. The background is still a sibling behind the scroll view, so it shows through unbroken — including the animated gradient, which no bar-local background could match.

## [2.0.0] - 2026-07-25

Platform idioms and API currency for iOS 26 / macOS 26. The package had platform-aware *measurements* but a single iOS interaction model; this pass splits the parts a Mac user actually touches.

### Added

- Keyboard support, which the sheet previously had none of. Return activates the footer button on both platforms. On macOS, Escape also runs `onDismiss` — it is bound to the same closure rather than dismissing the sheet natively, so the caller's bookkeeping (typically `markAsShown()`) still runs.
- Text selection for the title and feature rows, so release copy can be copied out of a Mac window.
- A Mac-shaped sheet size: 560x520 ideal over a 480x420 floor, replacing a 320x560 minimum that was an iPhone shape on a desktop.

### Changed

- **Breaking:** `ReleaseStyle.buttonForegroundColor` defaults to the system's prominent-button label color instead of white. Set it explicitly to keep a specific color.
- The footer button is a `.glassProminent` capsule spanning the footer on both platforms, via `buttonSizing(.flexible)`. Press, hover, focus, and contrast behavior now come from the platform rather than from a hand-drawn `.plain` button that had no press state on iOS and no hover state on macOS.
- The pinned footer is a `safeAreaBar` with the system's soft scroll edge effect, replacing a root `GeometryReader`, an overlay, a measured footer frame, and a hand-built gradient mask — about 145 lines. The background stays a sibling behind the scroll view; moving it onto the scroll view leaves the edge effect nothing to composite against, which shows as a seam and a ghost of the rows behind the bar.
- macOS shows its normal overlay scroller. Hiding it applied an iPhone assumption to a pointer; it is how a Mac signals that a list continues, and it already hides itself when idle.
- The feature reveal no longer shakes as it lands. It used `animation(_:value:)`, which fires on a value change but animates *every* animatable difference in the subtree at that moment — so a `ScaledMetric` resolving or a description rewrapping on the same frame was swept into the reveal and replayed with the row's delay. The scoped `animation(_:body:)` form animates only the opacity and offset. Timing is tuned per platform, and Reduce Motion still suppresses the reveal entirely.
- The app icon is clipped with continuous curvature, matching the squircle an app icon actually is.

### Removed

- **Breaking:** the internal `buttonBackgroundStyle` / `buttonForegroundStyle` helpers on `ReleaseStyle`, along with the `Radius.button`, `minimumControlHeight` (the iOS *touch* target, wrong for a Mac pointer), `buttonLabelMinHeight`, and `buttonVerticalPadding` tokens. System button styles own the button's size and shape now.

## [1.0.0] - 2026-07-24

First tagged release. Everything before this was consumed off the `master` branch.

### Added

- Documentation comments across the entire public API. `AllPublicDeclarationsHaveDocumentation` is enforced in CI, so undocumented public API now fails the build.
- `ReleaseNotice(_:)` taking a `LocalizedStringResource`, matching the initializer `ReleaseFeature` already had.
- A `notice` default on `ReleaseContent` returning `nil`, alongside the existing `appIcon` default. Only `title`, `features`, and `buttonText` are required now.
- `Equatable` and `Sendable` on `ReleaseFeature`, `ReleaseNotice`, `ReleaseStyle`, `ReleaseGradientPalette` and its `Tones`, and `ReleaseBackgroundContext`. `ReleaseBackground` and `ReleaseVersionTracker` are `Sendable`.
- `swift-format` configuration and a GitHub Actions workflow running build, test, and lint.

### Changed

- **Breaking:** `ReleaseContent` now refines `Sendable`. Conformers whose members are all `Sendable` — the normal case — need no change, but a `public` conformer relies on the protocol to carry the conformance rather than on inference.
- **Breaking:** the closure passed to `ReleaseBackground.custom(_:)` is now `@Sendable @MainActor`.
- The footer button guarantees the 44pt Human Interface Guidelines hit target explicitly, rather than arriving at it by arithmetic coincidence.

### Removed

- **Breaking:** the two `ReleaseFeature` initializers without an `id`. They derived identity from `UUID()`, and because conformers expose `features` as a computed property, that produced a fresh identity on every evaluation — re-creating each row and replaying the entrance animation. Use the initializers taking an explicit `id`.
- **Breaking:** `ReleaseBackground.animatedMesh(primary:secondary:accent:)`. Use `animatedGradient(brand:palette:motion:)`.

### Fixed

- Replaced the deprecated `ScrollView(_:showsIndicators:)` initializer, and removed a duplicate `scrollIndicators` modifier, an inert `controlSize` under `buttonStyle(.plain)`, and a redundant single-child `ZStack` in the footer overlay.

[2.0.1]: https://github.com/hksw-io/ReleaseKit/releases/tag/2.0.1
[2.0.0]: https://github.com/hksw-io/ReleaseKit/releases/tag/2.0.0
[1.0.0]: https://github.com/hksw-io/ReleaseKit/releases/tag/1.0.0
