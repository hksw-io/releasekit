import Foundation

/// Decides whether the release sheet should be presented for the running app version, and records
/// the versions a user has already seen in `UserDefaults`.
///
/// The tracker owns version display tracking and nothing else. Presentation and dismissal stay with
/// the caller:
///
/// ```swift
/// let tracker = ReleaseVersionTracker(
///     keyPrefix: "com.example.myapp",
///     currentVersion: "1.2.0")
///
/// if tracker.shouldShowRelease() {
///     // present ReleaseView
/// }
///
/// // after dismiss:
/// tracker.markAsShown()
/// ```
///
/// - Note: This type is `@unchecked Sendable`. `UserDefaults` is an Objective-C class that is
///   thread-safe by contract but still carries no Swift `Sendable` conformance to derive from, as of
///   the macOS 27 SDK.
public struct ReleaseVersionTracker: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let currentVersion: String
    private let lastShownVersionKey: String
    private let hasLaunchedBeforeKey: String

    /// Creates a tracker scoped to one app.
    ///
    /// - Parameters:
    ///   - userDefaults: Storage for the tracking keys. Defaults to `.standard`; pass a suite when
    ///     an app group or a test needs isolation.
    ///   - keyPrefix: Namespace for the two keys this type writes, usually a bundle identifier.
    ///     Two trackers with different prefixes never observe each other's state.
    ///   - currentVersion: The version to compare against. Supply whatever string the app treats as
    ///     its release identity — this type compares for equality and never parses or orders it.
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

    /// Reports whether the release sheet should be presented, and **writes to `UserDefaults` on the
    /// first ever call**.
    ///
    /// Despite the name, this is not a pure query. On a fresh install it marks the app as launched,
    /// records `currentVersion` as already seen, and returns `false` — a first-run user gets the app
    /// itself, not a list of changes they were never absent for. Every later call is read-only.
    ///
    /// Because the comparison is equality rather than ordering, rolling *back* to a version the user
    /// has not seen most recently also returns `true`.
    ///
    /// - Returns: `true` when the current version differs from the last one marked as shown.
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

    /// Records the current version as seen, so `shouldShowRelease()` returns `false` until the
    /// version changes. Call this when the sheet is dismissed.
    public func markAsShown() {
        self.userDefaults.set(self.currentVersion, forKey: self.lastShownVersionKey)
    }
}
