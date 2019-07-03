@testable import Ringly
import XCTest

final class PreferencesMigrationTest: UserDefaultsTestCase
{
    // MARK: - Without Onboarding
    func testConnectionTapsMigrationPreviouslyNilWithoutOnboarding()
    {
        defaults.migrateConnectionTapsSetting()
        XCTAssertEqual(defaults.object(forKey: Preferences.connectionTapsKey) as? Bool, false)
    }

    func testConnectionTapsMigrationPreviously1WithoutOnboarding()
    {
        defaults.set(1, forKey: Preferences.legacyConnectionTapsKey)
        defaults.migrateConnectionTapsSetting()

        XCTAssertEqual(defaults.object(forKey: Preferences.connectionTapsKey) as? Bool, false)
    }

    func testConnectionTapsMigrationPreviously2WithoutOnboarding()
    {
        defaults.set(2, forKey: Preferences.legacyConnectionTapsKey)
        defaults.migrateConnectionTapsSetting()

        XCTAssertEqual(defaults.object(forKey:Preferences.connectionTapsKey) as? Bool, false)
    }

    // MARK: - With Onboarding
    func testConnectionTapsMigrationPreviouslyNilWithOnboarding()
    {
        defaults.set(true, forKey: Preferences.onboardingShownKey)
        defaults.migrateConnectionTapsSetting()

        XCTAssertEqual(defaults.object(forKey: Preferences.connectionTapsKey) as? Bool, true)
    }

    func testConnectionTapsMigrationPreviously1WithOnboarding()
    {
        defaults.set(true, forKey: Preferences.onboardingShownKey)
        defaults.set(1, forKey: Preferences.legacyConnectionTapsKey)
        defaults.migrateConnectionTapsSetting()

        XCTAssertEqual(defaults.object(forKey: Preferences.connectionTapsKey) as? Bool, true)
    }

    func testConnectionTapsMigrationPreviously2WithOnboarding()
    {
        defaults.set(true, forKey: Preferences.onboardingShownKey)
        defaults.set(2, forKey: Preferences.legacyConnectionTapsKey)
        defaults.migrateConnectionTapsSetting()

        XCTAssertEqual(defaults.object(forKey: Preferences.connectionTapsKey) as? Bool, false)
    }
}
