# AGENTS.md

Instructions for agents working in this repository.

## Package Scope

- This is a Swift package for a reusable SwiftUI "What's New" experience.
- The supported product surfaces are iOS 26+ and macOS 26+.
- watchOS is out of scope unless the user explicitly asks for watchOS work. Do not widen implementation, tests, or compatibility policy for watchOS by default.
- Keep the library presentational and reusable. App-specific policy belongs in the consuming app unless the public API is explicitly changed.

## SwiftUI Standards

- Use pure SwiftUI for product UI. Avoid UIKit/AppKit bridging unless there is no native SwiftUI API and the bridge is small, isolated, and explained.
- Preserve accessibility in every UI change: VoiceOver labels/grouping, Dynamic Type, reduced motion, sufficient contrast, keyboard/focus behavior where relevant, and light/dark mode.
- Keep public API names, defaults, and initializer behavior stable unless the requested change explicitly requires a breaking change.

## ReleaseKit Rules

- `ReleaseView` should remain a reusable SwiftUI view driven by `ReleaseContent`.
- `ReleaseVersionTracker` owns only version display tracking. Keep persistence behavior deterministic and covered by tests.
- The first launch behavior is intentional: the sheet is not shown on fresh install, and the current version is marked as seen.
- Feature rows must keep stable identity and work with optional icons, labels, notices, and long localized text.
- Dismissal remains caller-controlled through the `onContinue` closure.

## Testing and Verification

- Add or update Swift Testing coverage for every feature, behavior change, or bug fix.
- Cover public API behavior, protocol defaults, optional content combinations, callbacks, persistence edge cases, and regression cases.
- UI-facing changes need automated construction/smoke coverage and manual or preview verification across varied screen sizes, orientations, and devices/windows.
- Run `swift test` before calling work complete. If the change is UI-heavy, also exercise Xcode previews or an equivalent local host app.
- Run `git diff --check` before finalizing.

## Formatting

- `swift-format` owns source formatting. The checked-in `.swift-format` is the single source of truth; do not hand-format against a remembered house style.
- Run `swift format --in-place --recursive Sources Tests` before committing, and `swift format lint --strict --recursive Sources Tests` to verify.
- `AllPublicDeclarationsHaveDocumentation` is enabled, so every public declaration must carry a `///` comment. CI fails otherwise.

## Documentation and Dependencies

- Keep README examples aligned with public APIs whenever API behavior changes.
- A minor release may contain a breaking change, marked **Breaking** in `CHANGELOG.md`, so consumers pin exact versions.
- Use semantic commit messages when committing changes, such as `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, or `chore:`.
