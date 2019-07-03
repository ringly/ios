@testable import Ringly
import Nimble
import XCTest

final class PropertyListBridgingTests: XCTestCase
{
    func testPassThrough()
    {
        let bridge = PropertyListBridge(from: { $0 }, to: { $0 })
        expect(bridge.from(0) as? Int) == 0
        expect(bridge.toSafePropertyList(0) as? Int) == 0
    }
}

final class PropertyListBridgingCodingTests: XCTestCase
{
    private let bridge = PropertyListBridge<CodableTest>.coding(
        key: "test",
        defaultValue: validCodable2
    )

    func testFromValidCodable()
    {
        expect(self.bridge.from(validCodable1.encoded)) == validCodable1
    }

    func testFromInvalidCodable()
    {
        expect(self.bridge.from(["foo": 1])) == validCodable2
    }

    func testToEncoded()
    {
        expect(self.bridge.toSafePropertyList(validCodable1)).to(saveToPropertyList(matching: validCodable1.encoded))
    }
}

final class PropertyListBridgingOptionalCodingTests: XCTestCase
{
    private let bridge = PropertyListBridge<CodableTest?>.optionalCoding(key: "test")

    func testFromValidCodable()
    {
        expect(self.bridge.from(validCodable1.encoded)) == validCodable1
    }

    func testFromInvalidCodable()
    {
        expect(self.bridge.from(["foo": 1])).to(beNil())
    }

    func testToEncoded()
    {
        expect(self.bridge.toSafePropertyList(validCodable1)).to(saveToPropertyList(matching: validCodable1.encoded))
    }

    func testToNil()
    {
        expect(self.bridge.toSafePropertyList(nil)).to(beNil())
    }
}

final class PropertyListBridgingArrayCodingTests: XCTestCase
{
    private let bridge = PropertyListBridge<[CodableTest]>.arrayCoding(defaultValue: [])

    func testFromValidArray()
    {
        expect(self.bridge.from([validCodable1.encoded, validCodable2.encoded])) == [validCodable1, validCodable2]
    }

    func testFromNonArray()
    {
        expect(self.bridge.from(0)) == []
    }

    func testFromInvalidArrayElement()
    {
        expect(self.bridge.from([validCodable1.encoded, 0])) == []
    }

    func testFromInvalidArrayElementEncoding()
    {
        expect(self.bridge.from([validCodable1.encoded, ["foo": "bar"]])) == []
    }

    func testToEncoded()
    {
        expect(self.bridge.toSafePropertyList([validCodable1, validCodable2])).to(saveToPropertyList(matching: [
            validCodable1.encoded, validCodable2.encoded
        ]))
    }
}

final class PropertyListBridgingRawRepresentableTests: XCTestCase
{
    private let bridge = PropertyListBridge<RawTest>.raw(defaultValue: .One)

    func testFromValidRawValue()
    {
        expect(self.bridge.from(0)) == RawTest.Zero
    }

    func testFromInvalidRawValue()
    {
        expect(self.bridge.from(2)) == RawTest.One
    }

    func testToRawValue()
    {
        expect(self.bridge.toSafePropertyList(.One)).to(saveToPropertyList(matching: RawTest.One.rawValue as AnyObject))
    }
}

final class PropertyListBridgingOptionalRawRepresentableTests: XCTestCase
{
    private let bridge = PropertyListBridge<RawTest?>.optionalRaw()

    func testFromValidRawValue()
    {
        expect(self.bridge.from(0)) == RawTest.Zero
    }

    func testFromInvalidRawValue()
    {
        expect(self.bridge.from(2)).to(beNil())
    }

    func testToRawValue()
    {
        expect(self.bridge.toSafePropertyList(.One)).to(saveToPropertyList(matching: RawTest.One.rawValue))
    }

    func testToNil()
    {
        expect(self.bridge.toSafePropertyList(nil)).to(MatcherFunc<Any> { expr, msg in
            if let thing = try expr.evaluate()
            {
                print(type(of: thing), thing as Any)
                return false
            }

            return true
        })
    }
}

/// A matcher function for ensuring that values can be converted to property lists. Will fail if the expression's return
/// value cannot be converted, the `expected` value cannot be converted, or the resulting property list data values are
/// not equal.
///
/// - Parameter expected: The expected property list value.
func saveToPropertyList<Actual>(matching expected: Any) -> MatcherFunc<Actual>
{
    return MatcherFunc { expression, message in
        message.postfixMessage = "convert cleanly to property list"

        if let actual = try expression.evaluate()
        {
            let actualData = try PropertyListSerialization.data(
                fromPropertyList: actual,
                format: .xml,
                options: 0
            )

            let expectedData = try PropertyListSerialization.data(
                fromPropertyList: actual,
                format: .xml,
                options: 0
            )

            return actualData == expectedData
        }

        return false
    }
}

private let validCodable1 = CodableTest(foo: "test", bar: 1)
private let validCodable2 = CodableTest(foo: "test2", bar: 2)

enum RawTest: Int
{
    case Zero
    case One
}
