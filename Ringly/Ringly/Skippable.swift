import Foundation
import RinglyAPI

/// A value that the user may skip entering.
enum Skippable<T: Coding> where T.Encoded == [String:Any]
{
    // MARK: - Cases

    /// The user entered a value.
    case Value(T)

    /// The user skipped entering a value.
    case skipped
}

extension Skippable
{
    // MARK: - Value

    /// The quantity value, if this value is not `.Skipped`.
    var value: T?
    {
        switch self
        {
        case let .Value(value):
            return value
        case .skipped:
            return nil
        }
    }

    /// Maps the skippable to another value.
    ///
    /// - parameter transform: A function to transform a value.
    ///
    /// - returns: The adjusted value, or `.Skipped` if the receiver is `.Skipped`.
    func map<Other>(_ transform: (T) -> Other) -> Skippable<Other>
    {
        switch self
        {
        case let .Value(value):
            return .Value(transform(value))
        case .skipped:
            return .skipped
        }
    }
}

private let skippedKey = "skipped"
private let valueKey = "value"

extension Skippable: Coding
{
    typealias Encoded = [String:Any]

    static func decode(_ encoded: Encoded) throws -> Skippable
    {
        if encoded[skippedKey] != nil
        {
            return .skipped
        }
        else
        {
            return try .Value(T.decode(any: encoded[valueKey]))
        }
    }

    var encoded: Encoded
    {
        switch self
        {
        case .skipped:
            return [skippedKey: true]
        case .Value(let value):
            return [valueKey: value.encoded]
        }
    }
}
