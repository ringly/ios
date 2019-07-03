@testable import Ringly
import Nimble
import ReactiveSwift
import RinglyAPI
import XCTest

final class InitializableMutablePropertyProtocolPreferencesBackingTests: UserDefaultsTestCase
{
    // MARK: - Codable
    func testCodableStorage()
    {
        // start with empty value, test that the default is used
        let defaultValue = CodableTest(foo: "foo", bar: 1)
        let property = MutableProperty(
            backing: defaults,
            key: "test",
            defaultValue: defaultValue,
            makeBridge: PropertyListBridge.coding
        )

        XCTAssertEqual(property.value, defaultValue)

        // store a new value and test that is has changed
        property.value = CodableTest(foo: "baz", bar: 2)

        let stored = defaults.object(forKey: "test") as? [String:AnyObject]
        XCTAssertEqual(stored?["foo"] as? String, "baz")
        XCTAssertEqual(stored?["bar"] as? Int, 2)
    }

    func testCodableReading()
    {
        let expectedValue = CodableTest(foo: "foo", bar: 1)
        defaults.set(expectedValue.encoded as AnyObject?, forKey: "test")

        let defaultValue = CodableTest(foo: "baz", bar: 2)
        let property = MutableProperty(
            backing: defaults,
            key: "test",
            defaultValue: defaultValue,
            makeBridge: PropertyListBridge.coding
        )

        XCTAssertEqual(property.value, expectedValue)
    }

    // MARK: - Optional Codable
    func testOptionalCodableStorage()
    {
        let property = MutableProperty<CodableTest?>(
            backing: defaults,
            key: "test",
            makeBridge: PropertyListBridge.optionalCoding
        )

        XCTAssertNil(property.value)

        let value = CodableTest(foo: "foo", bar: 1)
        property.value = value
        XCTAssertNotNil(defaults.object(forKey: "test"))

        let stored = defaults.object(forKey: "test") as? [String:AnyObject]
        XCTAssertEqual(stored?["foo"] as? String, "foo")
        XCTAssertEqual(stored?["bar"] as? Int, 1)
    }

    func testOptionalCodableReading()
    {
        let value = CodableTest(foo: "foo", bar: 1)
        defaults.set(value.encoded as AnyObject?, forKey: "test")

        let property = MutableProperty<CodableTest?>(
            backing: defaults,
            key: "test",
            makeBridge: PropertyListBridge.optionalCoding
        )

        XCTAssertNotNil(property.value)
        XCTAssertEqual(property.value?.foo, value.foo)
        XCTAssertEqual(property.value?.bar, value.bar)
    }

    // MARK: - Array Codable
    func testArrayCodableStorage()
    {
        let property = MutableProperty<[CodableTest]>(
            backing: defaults,
            key: "test",
            defaultValue: [],
            makeBridge: PropertyListBridge.arrayCoding
        )

        XCTAssertEqual(property.value, [])

        let value = [CodableTest(foo: "foo", bar: 1), CodableTest(foo: "baz", bar: 2)]
        property.value = value
        XCTAssertNotNil(defaults.object(forKey: "test"))

        let stored = defaults.object(forKey: "test") as? [[String:AnyObject]]
        XCTAssertEqual(stored?[0]["foo"] as? String, "foo")
        XCTAssertEqual(stored?[0]["bar"] as? Int, 1)
        XCTAssertEqual(stored?[1]["foo"] as? String, "baz")
        XCTAssertEqual(stored?[1]["bar"] as? Int, 2)
    }

    func testArrayCodableReading()
    {
        let value = [CodableTest(foo: "foo", bar: 1), CodableTest(foo: "baz", bar: 2)]
        defaults.set(value.map({ $0.encoded }), forKey: "test")

        let property = MutableProperty<[CodableTest]>(
            backing: defaults,
            key: "test",
            defaultValue: [],
            makeBridge: PropertyListBridge.arrayCoding
        )

        XCTAssertEqual(property.value.count, 2)
        XCTAssertEqual(property.value, value)
    }

    func testArrayCodableDefaultWithNil()
    {
        let value = [CodableTest(foo: "foo", bar: 1)]
        let property = MutableProperty<[CodableTest]>(
            backing: defaults,
            key: "test",
            defaultValue: value,
            makeBridge: PropertyListBridge.arrayCoding
        )

        XCTAssertEqual(value, property.value)
    }

    func testArrayCodableDefaultWithNonArray()
    {
        defaults.set(1 as AnyObject?, forKey: "test")

        let value = [CodableTest(foo: "foo", bar: 1)]
        let property = MutableProperty<[CodableTest]>(
            backing: defaults,
            key: "test",
            defaultValue: value,
            makeBridge: PropertyListBridge.arrayCoding
        )

        XCTAssertEqual(value, property.value)
    }

    func testArrayCodableDefaultWithInvalidEncoded()
    {
        defaults.set([
            ["foo": "foo", "bar": 1],
            ["bar": 2],
        ], forKey: "test")

        let value = [CodableTest(foo: "foo", bar: 1)]
        let property = MutableProperty<[CodableTest]>(
            backing: defaults,
            key: "test",
            defaultValue: value,
            makeBridge: PropertyListBridge.arrayCoding
        )

        XCTAssertEqual(value, property.value)
    }

    // MARK: - UUIDs
    func testSetOfUUIDs()
    {
        let uuids: Set<UUID> = [UUID(), UUID(), UUID()]
        defaults.set(uuids.map({ $0.encoded }), forKey: "test")

        let property = MutableProperty<Set<UUID>>(
            backing: defaults,
            key: "test",
            bridge: PropertyListBridge<Set<UUID>>.arrayCoding()
        )

        expect(property.value) == uuids
    }

    // MARK: - Applications Onboarding State Migration
    func testApplicationOnboardingStateMigrationFromFalse()
    {
        defaults.set(false, forKey: "test")

        let property = MutableProperty<ApplicationsOnboardingState>(
            backing: defaults,
            key: "test",
            defaultValue: .overlay,
            makeBridge: PropertyListBridge.raw
        )

        expect(property.value) == ApplicationsOnboardingState.overlay
    }

    func testApplicationOnboardingStateMigrationFromTrue()
    {
        defaults.set(true, forKey: "test")

        let property = MutableProperty<ApplicationsOnboardingState>(
            backing: defaults,
            key: "test",
            defaultValue: .overlay,
            makeBridge: PropertyListBridge.coding
        )

        expect(property.value) == ApplicationsOnboardingState.complete
    }
}

// MARK: - Codable Test
struct CodableTest
{
    let foo: String
    let bar: Int
}

extension CodableTest: Coding
{
    typealias Encoded = [String:Any]

    var encoded: Encoded
    {
        return ["foo": foo, "bar": bar]
    }

    static func decode(_ encoded: [String:Any]) throws -> CodableTest
    {
        guard let foo = encoded["foo"] as? String else { throw CodableTestError() }
        guard let bar = encoded["bar"] as? Int else { throw CodableTestError() }

        return CodableTest(foo: foo, bar: bar)
    }
}

extension CodableTest: Equatable {}
func ==(lhs: CodableTest, rhs: CodableTest) -> Bool
{
    return lhs.foo == rhs.foo && lhs.bar == rhs.bar
}

struct CodableTestError: Error {}
