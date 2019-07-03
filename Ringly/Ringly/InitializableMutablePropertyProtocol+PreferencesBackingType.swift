import Foundation
import ReactiveSwift
import RinglyAPI
import RinglyExtensions

extension InitializableMutablePropertyProtocol
{
    // MARK: - Preferences Backing

    /// Creates a mutable property that will automatically write value changes to the specified preferences backing
    /// value. The initial value of the property is also fetched from the preferences backing value. Property values are
    /// converted to and from preferences backing values with a `PropertyListBridge`.
    ///
    /// - Parameters:
    ///   - backing: The preferences backing value.
    ///   - key: The preferences backing key to use.
    ///   - bridge: The property list bridge to use.
    init(backing: PreferencesBackingType, key: String, bridge: PropertyListBridge<Value>)
    {
        self.init(bridge.from(backing.object(forKey: key) as Any))

        signal.map(bridge.toSafePropertyList).observeValues({ value in
            backing.setObject(value, forKey: key)
            backing.synchronize()
        })
    }

    /// Creates a mutable property that will automatically write value changes to the specified preferences backing
    /// value. The initial value of the property is also fetched from the preferences backing value. Property values are
    /// converted to and from preferences backing values with a `PropertyListBridge`.
    ///
    /// - Parameters:
    ///   - backing: The preferences backing value.
    ///   - key: The preferences backing key to use.
    ///   - makeBridge: A function accepting a `String` key and returning the property list bridge to use.
    init(backing: PreferencesBackingType, key: String, makeBridge: (String) -> PropertyListBridge<Value>)
    {
        self.init(backing: backing, key: key, bridge: makeBridge(key))
    }

    /// Creates a mutable property that will automatically write value changes to the specified preferences backing
    /// value. The initial value of the property is also fetched from the preferences backing value. Property values are
    /// converted to and from preferences backing values with a `PropertyListBridge`.
    ///
    /// - Parameters:
    ///   - backing: The preferences backing value.
    ///   - key: The preferences backing key to use.
    ///   - defaultValue: The default value for the property - this is passed on to the property list bridge.
    ///   - makeBridge: A function accepting a `String` key and a default value, and returning the property list bridge
    ///                 to use.
    init(backing: PreferencesBackingType,
         key: String,
         defaultValue: Value,
         makeBridge: (String, Value) -> PropertyListBridge<Value>)
    {
        self.init(backing: backing, key: key, bridge: makeBridge(key, defaultValue))
    }

    /// Creates a mutable property that will automatically write value changes to the specified preferences backing
    /// value. The initial value of the property is also fetched from the preferences backing value. Property values are
    /// converted to and from preferences backing values with a `PropertyListBridge`.
    ///
    /// - Parameters:
    ///   - backing: The preferences backing value.
    ///   - key: The preferences backing key to use.
    ///   - defaultValue: The default value for the property - this is passed on to the property list bridge.
    ///   - makeBridge: A function accepting a default value and returning the property list bridge to use.
    init(backing: PreferencesBackingType,
         key: String,
         defaultValue: Value,
         makeBridge: (Value) -> PropertyListBridge<Value>)
    {
        self.init(backing: backing, key: key, bridge: makeBridge(defaultValue))
    }
}

extension Decoding
{
    /// Attempts to decode a value, logging thrown errors to a logging function.
    ///
    /// - Parameters:
    ///   - any: The value to decode.
    ///   - key: A key associated with the decoding operation. This will be included in error logs.
    ///   - log: The logging function.
    /// - Returns: The decoded value, or `nil` if an error was thrown.
    static func loggingDecode(any: Any?, key: String, log: (String) -> () = SLogGeneric) -> Self?
    {
        do
        {
            return try decode(any: any)
        }
        catch let error as NSError
        {
            log("Error decoding preferences key \(key), error was \(error), encoded value was \(any ?? "nil")")
        }
        
        return nil
    }
}
