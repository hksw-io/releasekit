import Foundation
import Testing
@testable import ReleaseKit

struct ReleaseVersionTrackerTests {
    @Test
    func packageIncludesItsUserDefaultsPrivacyDeclaration() throws {
        let url = try #require(Bundle.module.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let manifest = try #require(
            PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        let categories = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let defaults = try #require(
            categories.first {
                $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
            })
        #expect(Set(defaults["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? []) == ["CA92.1", "1C8F.1"])
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
    }

    private let keyPrefix = "test.releasekit"
    private var lastShownVersionKey: String { "\(self.keyPrefix).release.lastShownVersion" }
    private var hasLaunchedBeforeKey: String { "\(self.keyPrefix).hasLaunchedBefore" }

    private func makeUserDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    /// The first ever call does three things at once, so they are asserted together: it reports
    /// "nothing new", records the launch, and marks the running version as already seen.
    @Test
    func freshInstallMarksCurrentVersionSeenWithoutShowingRelease() {
        let userDefaults = self.makeUserDefaults()
        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.7.0")

        #expect(tracker.shouldShowRelease() == false)
        #expect(userDefaults.bool(forKey: self.hasLaunchedBeforeKey) == true)
        #expect(userDefaults.string(forKey: self.lastShownVersionKey) == "1.7.0")
    }

    @Test
    func existingUserSameVersionDoesNotShowRelease() {
        let userDefaults = self.makeUserDefaults()
        userDefaults.set(true, forKey: self.hasLaunchedBeforeKey)
        userDefaults.set("1.7.0", forKey: self.lastShownVersionKey)

        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.7.0")

        #expect(tracker.shouldShowRelease() == false)
    }

    @Test
    func existingUserNewVersionShowsRelease() {
        let userDefaults = self.makeUserDefaults()
        userDefaults.set(true, forKey: self.hasLaunchedBeforeKey)
        userDefaults.set("1.6.0", forKey: self.lastShownVersionKey)

        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.7.0")

        #expect(tracker.shouldShowRelease() == true)
    }

    @Test
    func existingUserNoLastVersionShowsRelease() {
        let userDefaults = self.makeUserDefaults()
        userDefaults.set(true, forKey: self.hasLaunchedBeforeKey)

        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.7.0")

        #expect(tracker.shouldShowRelease() == true)
    }

    @Test
    func markAsShownUpdatesLastShownVersion() {
        let userDefaults = self.makeUserDefaults()
        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.8.0")

        tracker.markAsShown()

        #expect(userDefaults.string(forKey: self.lastShownVersionKey) == "1.8.0")
    }

    @Test
    func afterMarkAsShownDoesNotShowRelease() {
        let userDefaults = self.makeUserDefaults()
        userDefaults.set(true, forKey: self.hasLaunchedBeforeKey)
        userDefaults.set("1.6.0", forKey: self.lastShownVersionKey)

        let tracker = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: self.keyPrefix,
            currentVersion: "1.7.0")

        #expect(tracker.shouldShowRelease() == true)

        tracker.markAsShown()

        #expect(tracker.shouldShowRelease() == false)
    }

    @Test
    func keyPrefixIsolation() {
        let userDefaults = self.makeUserDefaults()
        let appA = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: "com.example.appA",
            currentVersion: "1.0.0")
        let appB = ReleaseVersionTracker(
            userDefaults: userDefaults,
            keyPrefix: "com.example.appB",
            currentVersion: "2.0.0")

        _ = appA.shouldShowRelease()
        appA.markAsShown()

        #expect(appB.shouldShowRelease() == false)
    }
}
