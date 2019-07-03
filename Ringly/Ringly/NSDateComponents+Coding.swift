import Foundation
import RinglyAPI
import RinglyExtensions

extension DateComponents: Coding
{
    public typealias Encoded = [String:Any]
    fileprivate static let dataKey = "data"

    public static func decode(_ encoded: Encoded) throws -> DateComponents
    {
        return try reinterpret(
            NSKeyedUnarchiver.unarchiveObject(with: encoded.decode(dataKey)) as AnyObject?
        )
    }

    public var encoded: Encoded
    {
        return [DateComponents.dataKey: NSKeyedArchiver.archivedData(withRootObject: self) as AnyObject]
    }
}

struct DecodeCodingError: Error, CustomNSError
{
    static let errorDomain = "com.ringly.Ringly.DecodeCodingError"
    var errorCode: Int { return 0 }
}

/// A helper for decoding, working around around the type system.
private func reinterpret<T>(_ value: AnyObject?) throws -> T
{
    if let typed = value as? T
    {
        return typed
    }
    else
    {
        throw DecodeCodingError()
    }
}
