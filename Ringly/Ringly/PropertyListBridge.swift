import Foundation
import RinglyAPI
import RinglyExtensions

// MARK: - Property List Bridge

/// A set of functions to bridge to and from a property list.
struct PropertyListBridge<Value>
{
    // MARK: - Initialization

    /// Initializes a property list bridge.
    ///
    /// - Parameters:
    ///   - from: A function to convert from a property list value.
    ///   - to: A function to convert to a property list value.
    init(from: @escaping (Any?) -> Value, to: @escaping (Value) -> Any?)
    {
        self.from = from
        self.to = to
    }

    // MARK: - Bridging Functions

    /// A function to convert from a property list value.
    let from: (Any?) -> Value

    /// A function to convert to a property list value.
    fileprivate let to: (Value) -> Any?
}

extension PropertyListBridge
{
    /// Converts the value to a property list-compatible value.
    ///
    /// - Parameter value: The value to convert.
    func toSafePropertyList(_ value: Value) -> Any?
    {
        return to(value).map(cleanForPropertyList)
    }
}

// MARK: - Property List Bridge Extensions
extension PropertyListBridge
{
    /// A bridge that attempts to cast with `as?`, selecting a default value if the cast fails.
    ///
    /// - Parameter defaultValue: The default value to use when a decode operation fails.
    static func cast(defaultValue: Value) -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { $0 as? Value ?? defaultValue },
            to: { $0 }
        )
    }
}

extension PropertyListBridge where Value: Coding
{
    /// A bridge that used the `Coding` protocol to convert to and from property list values. If decoding fails, a
    /// default value will be substituted.
    ///
    /// - Parameters:
    ///   - key: The key to log when a decode operation fails.
    ///   - defaultValue: The default value to use when a decode operation fails.
    static func coding(key: String, defaultValue: Value) -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { Value.loggingDecode(any: $0, key: key) ?? defaultValue },
            to: { $0.encoded }
        )
    }
}

extension PropertyListBridge where Value: InitializableOptionalType, Value.Wrapped: Coding
{
    /// A bridge that uses the `Coding` protocol to convert to and from optional property list values.
    ///
    /// - Parameters:
    ///   - key: The key to log when a decode operation fails.
    static func optionalCoding(key: String) -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { Value(optional: Value.Wrapped.loggingDecode(any: $0, key: key)) },
            to: { $0.optional?.encoded }
        )
    }
}

extension PropertyListBridge where Value: InitializableArrayType, Value.Element: Coding
{
    /// A bridge that uses the `Coding` protocol to convert to and from array property list values.
    ///
    /// - Parameters:
    ///   - defaultValue: The default value to use when a decode operation fails.
    static func arrayCoding(defaultValue: Value = Value([])) -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { encoded in
                flattenOptional(try? (encoded as? [Value.Element.Encoded])?.map({ try Value.Element.decode($0) }))
                    .map(Value.init) ?? defaultValue
            },
            to: { $0.array.map({ $0.encoded }) }
        )
    }
}

extension PropertyListBridge where Value: RawRepresentable
{
    /// A bridge that uses the `RawRepresentable` protocol to convert to and from property list values.
    ///
    /// - Parameter defaultValue: The default value to use when a decode operation fails.
    static func raw(defaultValue: Value) -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { ($0 as? Value.RawValue).flatMap(Value.init) ?? defaultValue },
            to: { $0.rawValue }
        )
    }
}

extension PropertyListBridge where Value: InitializableOptionalType, Value.Wrapped: RawRepresentable
{
    /// A bridge that uses the `RawRepresentable` protocol to convert to and from optional property list values.
    static func optionalRaw() -> PropertyListBridge<Value>
    {
        return PropertyListBridge(
            from: { Value(optional: ($0 as? Value.Wrapped.RawValue).flatMap(Value.Wrapped.init)) },
            to: { $0.optional?.rawValue }
        )
    }
}

// MARK: - Property List Cleaning

/// Cleans a value, removing `NSNull` values, allowing to to be used as a property list.
///
/// - Parameter any: The value to clean.
func cleanForPropertyList(_ any: Any) -> Any
{
    if let dictionary = any as? [String:Any]
    {
        return cleanDictionaryForPropertyList(dictionary)
    }
    else if let array = any as? [Any]
    {
        return cleanArrayForPropertyList(array)
    }
    else
    {
        return any
    }
}

/// Cleans an array containing dictionaries of `NSNull` values, allowing it to be used as a property list. This does
/// not currently remove `NSNull` values from the array itself, only from dictionaries it contains.
///
/// - Parameter array: The array to clean.
func cleanArrayForPropertyList(_ array: [Any]) -> [Any]
{
    return array.map(cleanForPropertyList)
}

/// Cleans a dictionary of `NSNull` values, allowing it to be used as a property list.
///
/// - Parameter dictionary: The dictionary to clean.
func cleanDictionaryForPropertyList(_ dictionary: [String:Any]) -> [String:Any]
{
    var mutable = dictionary

    for key in dictionary.keys
    {
        guard let current = mutable[key] else { continue }

        if current is NSNull
        {
            mutable.removeValue(forKey: key)
        }
        else
        {
            mutable[key] = cleanForPropertyList(current)
        }
    }

    return mutable
}
