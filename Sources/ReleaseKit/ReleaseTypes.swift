import SwiftUI

public struct ReleaseFeature: Identifiable, Equatable, Sendable {
    public let id: String
    public let image: Image?
    public let label: Text?
    public let description: Text

    public init(id: String, image: Image? = nil, label: Text? = nil, description: Text) {
        self.id = id
        self.image = image
        self.label = label
        self.description = description
    }

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

public struct ReleaseNotice: Equatable, Sendable {
    public let text: Text

    public init(text: Text) {
        self.text = text
    }

    public init(_ text: LocalizedStringResource) {
        self.text = Text(text)
    }
}

public protocol ReleaseContent: Sendable {
    var appIcon: Image? { get }
    var title: Text { get }
    var features: [ReleaseFeature] { get }
    var notice: ReleaseNotice? { get }
    var buttonText: Text { get }
}

public extension ReleaseContent {
    var appIcon: Image? {
        nil
    }

    var notice: ReleaseNotice? {
        nil
    }
}
