#if os(iOS) || os(macOS)
import SwiftUI

/// Foreground colors for the release sheet: title, feature rows, notice, and button text.
///
/// Every property is optional, and `nil` means "use the standard system treatment" rather than
/// "use no color". Set only the roles an app needs to brand; the rest stay adaptive across light
/// and dark mode. Layout, typography, and motion are not configurable.
///
/// ```swift
/// ReleaseView(content: MyRelease()) { isShowing = false }
///     .releaseStyle(ReleaseStyle(tint: .indigo))
/// ```
///
/// Use ``ReleaseBackground`` for the surface behind the content; this type governs what sits on top
/// of it.
public struct ReleaseStyle: Equatable, Sendable {
    /// Accent color for the button background, and for feature icons unless ``featureIconColor``
    /// overrides them. Also the default brand color for the gradient backgrounds.
    public var tint: Color?
    /// Color for the sheet title. `nil` uses the standard primary treatment.
    public var titleColor: Color?
    /// Color for feature row icons. `nil` falls back to ``tint``, then to the environment tint.
    public var featureIconColor: Color?
    /// Color for feature row headlines. `nil` uses the standard primary treatment.
    public var featureTitleColor: Color?
    /// Color for feature row body copy. `nil` uses the secondary treatment.
    public var featureDescriptionColor: Color?
    /// Color for the footer notice. `nil` uses the secondary treatment.
    public var noticeColor: Color?
    /// Color for the button label. `nil` uses the system's prominent-button label color, which
    /// already adapts to the tint, to light and dark mode, and to Increase Contrast.
    public var buttonForegroundColor: Color?

    /// The unbranded style: every role uses its standard system treatment.
    public static var standard: Self {
        Self()
    }

    /// Creates a style, overriding only the roles you pass.
    ///
    /// - Parameters:
    ///   - tint: Button accent, and feature icon color unless `featureIconColor` is set.
    ///   - titleColor: Title color.
    ///   - featureIconColor: Feature icon color, overriding `tint`.
    ///   - featureTitleColor: Feature headline color.
    ///   - featureDescriptionColor: Feature body copy color.
    ///   - noticeColor: Footer notice color.
    ///   - buttonForegroundColor: Button label color.
    public init(
        tint: Color? = nil,
        titleColor: Color? = nil,
        featureIconColor: Color? = nil,
        featureTitleColor: Color? = nil,
        featureDescriptionColor: Color? = nil,
        noticeColor: Color? = nil,
        buttonForegroundColor: Color? = nil
    ) {
        self.tint = tint
        self.titleColor = titleColor
        self.featureIconColor = featureIconColor
        self.featureTitleColor = featureTitleColor
        self.featureDescriptionColor = featureDescriptionColor
        self.noticeColor = noticeColor
        self.buttonForegroundColor = buttonForegroundColor
    }
}

extension ReleaseStyle {
    var featureIconForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.featureIconColor ?? self.tint, fallback: AnyShapeStyle(.tint))
    }

    var featureDescriptionForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.featureDescriptionColor, fallback: AnyShapeStyle(.secondary))
    }

    var noticeForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.noticeColor, fallback: AnyShapeStyle(.secondary))
    }

    private static func foregroundStyle(for color: Color?, fallback: AnyShapeStyle) -> AnyShapeStyle {
        guard let color else {
            return fallback
        }

        return AnyShapeStyle(color)
    }
}
#endif
