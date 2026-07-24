#if os(iOS) || os(macOS)
import SwiftUI

public struct ReleaseStyle: Equatable, Sendable {
    public var tint: Color?
    public var titleColor: Color?
    public var featureIconColor: Color?
    public var featureTitleColor: Color?
    public var featureDescriptionColor: Color?
    public var noticeColor: Color?
    public var buttonForegroundColor: Color?

    public static var standard: Self {
        Self()
    }

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

    var buttonForegroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.buttonForegroundColor, fallback: AnyShapeStyle(.white))
    }

    var buttonBackgroundStyle: AnyShapeStyle {
        Self.foregroundStyle(for: self.tint, fallback: AnyShapeStyle(.tint))
    }

    private static func foregroundStyle(for color: Color?, fallback: AnyShapeStyle) -> AnyShapeStyle {
        guard let color else {
            return fallback
        }

        return AnyShapeStyle(color)
    }
}
#endif
