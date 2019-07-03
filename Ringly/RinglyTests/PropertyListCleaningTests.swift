@testable import Ringly
import Nimble
import XCTest

final class PropertyListCleaningTests: XCTestCase
{
    private let dictionaryWithNSNull: [String:Any] = ["Test1": "1", "Null": NSNull()]
    private let dictionaryWithNSNullRemoved: [String:Any] = ["Test1": "1"]
    private let dictionaryWithoutNSNull: [String:Any] = ["Test2": "2", "Test3": 3]

    func testNSNullRemovedFromDictionaryInArray()
    {
        expect(cleanArrayForPropertyList([self.dictionaryWithNSNull, self.dictionaryWithoutNSNull]) as? [[String:Any]])
            .to(match(==, [
                dictionaryWithNSNullRemoved, dictionaryWithoutNSNull
            ]))
    }

    func testNSNullRemovedFromDictionary()
    {
        expect(cleanDictionaryForPropertyList(self.dictionaryWithNSNull)).to(match(==, dictionaryWithNSNullRemoved))
    }

    func testDictionaryWithoutNSNullIsTheSame()
    {
        expect(cleanDictionaryForPropertyList(self.dictionaryWithoutNSNull)).to(match(==, dictionaryWithoutNSNull))
    }
}

func match<T>(_ function: @escaping (T, T) -> Bool, _ other: T) -> NonNilMatcherFunc<T>
{
    return NonNilMatcherFunc { expression, message in
        message.postfixMessage = "match \(other)"
        return try expression.evaluate().map({ function($0, other) }) ?? false
    }
}

/// Tests the dictionary equality functions used for other tests.
final class DictionaryEqualityTests: XCTestCase
{
    private let dictionary: [String:Any] = [
        "String": "String",
        "Bool": true,
        "Int": 0,
        "Date": Date()
    ]

    private let dictionaryWithDifferentKeys: [String:Any] = [
        "String2": "String",
        "Bool": true,
        "Int": 0,
        "Date": Date()
    ]

    private let dictionaryWithDifferentValues: [String:Any] = [
        "String2": "String",
        "Bool": true,
        "Int": 1,
        "Date": Date()
    ]

    private let dictionaryWithDifferentSize: [String:Any] = [
        "Bool": true,
        "Int": 0,
        "Date": Date()
    ]

    func testEqualDictionaries()
    {
        expect(self.dictionary).to(match(==, dictionary))
    }

    func testUnequalDictionaryKeys()
    {
        expect(self.dictionary).toNot(match(==, self.dictionaryWithDifferentKeys))
    }

    func testUnequalDictionarySize()
    {
        expect(self.dictionary).toNot(match(==, self.dictionaryWithDifferentSize))
    }

    func testUnequalDictionaryValues()
    {
        expect(self.dictionary).toNot(match(==, self.dictionaryWithDifferentValues))
    }

    func testEqualDictionaryArrays()
    {
        let array = [
            dictionary,
            dictionaryWithDifferentKeys,
            dictionaryWithDifferentSize,
            dictionaryWithDifferentValues
        ]

        expect(array).to(match(==, array))
    }

    func testUnequalDictionaryArraySize()
    {
        let array1 = [
            dictionary,
            dictionaryWithDifferentKeys,
            dictionaryWithDifferentSize,
            dictionaryWithDifferentValues
        ]

        let array2 = [
            dictionary,
            dictionaryWithDifferentKeys,
            dictionaryWithDifferentSize
        ]

        expect(array1).toNot(match(==, array2))
    }

    func testUnequalDictionaryArrayValues()
    {
        let array1 = [
            dictionary,
            dictionaryWithDifferentKeys,
            dictionaryWithDifferentSize,
            dictionaryWithDifferentValues
        ]

        let array2 = [
            dictionary,
            dictionaryWithDifferentKeys,
            dictionaryWithDifferentValues,
            dictionaryWithDifferentValues
        ]

        expect(array1).toNot(match(==, array2))
    }
}

func ==<Key: Hashable>(lhs: [Key:Any], rhs: [Key:Any]) -> Bool
{
    guard Set(lhs.keys) == Set(rhs.keys) else { return false }

    return lhs.keys.all({ key in
        guard let lhsObject = lhs[key] as? NSObject else { return false }
        return lhsObject.isEqual(rhs[key])
    })
}

func ==<Key: Hashable>(lhs: [[Key:Any]], rhs: [[Key:Any]]) -> Bool
{
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).all(==)
}
