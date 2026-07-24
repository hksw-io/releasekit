# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/hksw-io/ReleaseKit/releases/tag/1.0.0
