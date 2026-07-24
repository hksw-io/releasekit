#if os(iOS) || os(macOS)
import SwiftUI

/// One row in the release sheet: an optional icon, an optional bold label, and a description.
///
/// Identity comes from `id` rather than position, so rows keep their identity when features are
/// inserted, removed, or reordered.
///
/// - Important: `id` must be stable across evaluations. Conformers normally expose `features` as a
///   computed property, so an id derived per call — a fresh `UUID()`, say — produces a new identity
///   on every pass, which re-creates each row and replays the entrance animation.
public struct ReleaseFeature: Identifiable, Equatable, Sendable {
    /// Stable identity for the row. See the note on ``ReleaseFeature`` about keeping it constant.
    public let id: String
    /// Leading icon, rendered with hierarchical symbol rendering and hidden from VoiceOver, which
    /// reads the label and description instead.
    public let image: Image?
    /// Optional headline shown above the description. Rows without one show only the description.
    public let label: Text?
    /// The body copy for the row.
    public let description: Text

    /// Creates a feature from pre-built `Text` and `Image` values.
    ///
    /// Use this when the app already holds formatted or styled `Text`. For plain localized strings,
    /// ``init(id:systemImage:label:description:)`` is shorter.
    ///
    /// - Parameters:
    ///   - id: Stable identity for the row.
    ///   - image: Leading icon, or `nil` for a row with no icon.
    ///   - label: Headline, or `nil` for a description-only row.
    ///   - description: Body copy for the row.
    public init(id: String, image: Image? = nil, label: Text? = nil, description: Text) {
        self.id = id
        self.image = image
        self.label = label
        self.description = description
    }

    /// Creates a feature from localized strings and an SF Symbol name.
    ///
    /// Localized values resolve against the calling app's bundle, so the app keeps ownership of its
    /// string catalog.
    ///
    /// - Parameters:
    ///   - id: Stable identity for the row.
    ///   - systemImage: SF Symbol name for the leading icon, or `nil` for a row with no icon.
    ///   - label: Headline, or `nil` for a description-only row.
    ///   - description: Body copy for the row.
    public init(
        id: String,
        systemImage: String? = nil,
        label: LocalizedStringResource? = nil,
        description: LocalizedStringResource
    ) {
        self.id = id
        self.image = systemImage.map { Image(systemName: $0) }
        self.label = label.map { Text($0) }
        self.description = Text(description)
    }
}

/// A short line of secondary copy shown in the pinned footer, above the dismiss button.
///
/// Typically the catch-all for changes too small to list, such as "Plus many other improvements."
public struct ReleaseNotice: Equatable, Sendable {
    /// The notice copy.
    public let text: Text

    /// Creates a notice from a pre-built `Text`.
    /// - Parameter text: The notice copy.
    public init(text: Text) {
        self.text = text
    }

    /// Creates a notice from a localized string, resolved against the calling app's bundle.
    /// - Parameter text: The notice copy.
    public init(_ text: LocalizedStringResource) {
        self.text = Text(text)
    }
}

/// The strings and icon a ``ReleaseView`` presents.
///
/// Implement this on a per-app type and hand it to ``ReleaseView``. The package supplies layout,
/// typography, motion, and accessibility; the app supplies the copy and owns its localization.
///
/// ```swift
/// struct MyRelease: ReleaseContent {
///     var appIcon: Image? { Image("AppIconImage") }
///     var title: Text { Text("What's New in MyApp") }
///     var features: [ReleaseFeature] {
///         [
///             ReleaseFeature(
///                 id: "new-charts",
///                 systemImage: "chart.line.uptrend.xyaxis.circle",
///                 label: "New Charts",
///                 description: "Track your progress with redesigned charts."),
///         ]
///     }
///     var buttonText: Text { Text("Continue") }
/// }
/// ```
///
/// `appIcon` and `notice` have defaults returning `nil`, so only `title`, `features`, and
/// `buttonText` are required. `buttonText` has no default deliberately: a built-in string would
/// render unlocalized, because this package declares no `defaultLocalization` and ships no string
/// catalog.
public protocol ReleaseContent: Sendable {
    /// Icon shown above the title, clipped to a rounded rectangle and hidden from VoiceOver.
    /// Defaults to `nil`.
    var appIcon: Image? { get }
    /// Heading for the sheet, exposed to VoiceOver as a header.
    var title: Text { get }
    /// The rows to list, in display order.
    var features: [ReleaseFeature] { get }
    /// Secondary footer copy shown above the button. Defaults to `nil`.
    var notice: ReleaseNotice? { get }
    /// Label for the dismiss button.
    var buttonText: Text { get }
}

public extension ReleaseContent {
    /// Defaults to `nil`, which omits the icon and starts the sheet at the title.
    var appIcon: Image? {
        nil
    }

    /// Defaults to `nil`, which leaves the button alone in the footer.
    var notice: ReleaseNotice? {
        nil
    }
}
#endif
