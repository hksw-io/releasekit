import Foundation

/// `UserDefaults` is an Objective-C class that is thread-safe by contract but carries no Swift
/// `Sendable` conformance, so the checking has to be opted out of here rather than derived.
public struct ReleaseVersionTracker: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let currentVersion: String
    private let lastShownVersionKey: String
    private let hasLaunchedBeforeKey: String

    public init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String,
        currentVersion: String
    ) {
        self.userDefaults = userDefaults
        self.currentVersion = currentVersion
        self.lastShownVersionKey = "\(keyPrefix).release.lastShownVersion"
        self.hasLaunchedBeforeKey = "\(keyPrefix).hasLaunchedBefore"
    }

    public func shouldShowRelease() -> Bool {
        let hasLaunchedBefore = self.userDefaults.bool(forKey: self.hasLaunchedBeforeKey)
        if !hasLaunchedBefore {
            self.userDefaults.set(true, forKey: self.hasLaunchedBeforeKey)
            self.userDefaults.set(self.currentVersion, forKey: self.lastShownVersionKey)
            return false
        }

        let lastShownVersion = self.userDefaults.string(forKey: self.lastShownVersionKey)
        return lastShownVersion != self.currentVersion
    }

    public func markAsShown() {
        self.userDefaults.set(self.currentVersion, forKey: self.lastShownVersionKey)
    }
}
