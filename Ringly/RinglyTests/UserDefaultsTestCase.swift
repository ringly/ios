import Foundation
import Nimble
import XCTest

class UserDefaultsTestCase: XCTestCase
{
    // MARK: - Setup and Teardown
    var defaults: UserDefaults!
    private let suiteName = "InitializableMutablePropertyTypePreferencesBackingTests"

    override func setUp()
    {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown()
    {
        super.tearDown()
        defaults = nil
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNonpropagation1()
    {
        expect(self.defaults.object(forKey: "test")).to(beNil())
        defaults.set(1, forKey: "test")
    }

    func testNonpropagation2()
    {
        expect(self.defaults.object(forKey: "test")).to(beNil())
        defaults.set(1, forKey: "test")
    }
}
