import Foundation

/// Errors that may occur while using the `KeyedEncoded` extensions.
public enum DecodeError: Error
{
    /// A key was missing from the encoded representation, or could not be converted to the desired type.
    case key(Any, from: Any)

    /// A raw value could be be decoded from the encoded representation.
    case rawValue(typeString: String)
}

extension DecodeError: CustomNSError
{
    // MARK: - NSError

    /// The domain for `DecodeError` values.
    public static let errorDomain = "DecodeError"

    /// The error code for the value.
    public var errorCode: Int
    {
        switch self
        {
        case .key:
            return 0
        case .rawValue:
            return 1
        }
    }

    /// The user info for the value.
    public var errorUserInfo: [String:Any]
    {
        switch self
        {
        case let .key(key, encoded):
            return [
                NSLocalizedDescriptionKey: "Failed to decode “\(key)”." as AnyObject,
                NSLocalizedFailureReasonErrorKey: "Encoded representation was \(encoded)" as AnyObject
            ]
        case .rawValue(let typeString):
            return [
                NSLocalizedDescriptionKey: "Failed to decode “\(typeString)”" as AnyObject
            ]
        }
    }
}

/// `Dictionary` is extended with key-decoding methods.
extension Dictionary
{
    // MARK: - Decoding Keys

    /**
     Attempts to extract `key` from `self`, constraining its type.

     - parameter key: The key.

     - throws: `DecodeError.Key`.
     */
    public func decode<Result>(_ key: Key) throws -> Result
    {
        guard let decoded = self[key] as? Result else {
            throw DecodeError.key(key, from: self)
        }

        return decoded
    }

    /**
     Attempts to extract a URL located at `key` from `self`.

     - parameter key:     The key.
     - parameter encoded: The encoded representation.

     - throws: `DecodeError.Key`
     */
    public func decodeURL(_ key: Key) throws -> URL
    {
        guard let URL = URL(string: try decode(key)) else {
            throw DecodeError.key(key, from: self)
        }

        return URL
    }

    /**
     Attempts to extract `key` from `self` as a raw value, and convert it to a value of type `T`.

     - parameter key:     The key.

     - throws: `DecodeError.Key` or `DecodeError.RawValue`.
     */
    public func decodeRaw<Result: RawRepresentable>(_ key: Key) throws -> Result
    {
        guard let decoded = Result(rawValue: try decode(key)) else {
            throw DecodeError.rawValue(typeString: "\(Result.self)")
        }

        return decoded
    }
}
