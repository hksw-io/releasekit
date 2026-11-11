#if os(iOS) || os(macOS)
import SwiftUI

/// The accent color for the release sheet.
///
/// `tint` colors the button and the feature icons, and is the default brand color for the gradient
/// backgrounds. Text colors, layout, typography, and motion use the standard system treatment and
/// are not configurable.
///
/// ```swift
/// ReleaseView(content: MyRelease()) { isShowing = false }
///     .releaseStyle(ReleaseStyle(tint: .indigo))
/// ```
///
/// Use ``ReleaseBackground`` for the surface behind the content.
public struct ReleaseStyle: Equatable, Sendable {
    /// Accent color for the button and the feature icons, and the default brand color for the
    /// gradient backgrounds. `nil` keeps the tint the sheet inherits from its environment.
    public var tint: Color?

    /// The unbranded style: the inherited tint.
    public static let standard = Self()

    /// Creates a style.
    ///
    /// - Parameter tint: Accent color for the button and the feature icons. `nil` keeps the
    ///   inherited tint.
    public init(tint: Color? = nil) {
        self.tint = tint
    }
}
#endif
