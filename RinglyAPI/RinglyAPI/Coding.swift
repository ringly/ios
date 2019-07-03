import RinglyExtensions

public protocol Coding: Decoding, Encoding {}

public protocol Decoding
{
    associatedtype Encoded

    static func decode(_ encoded: Encoded) throws -> Self
}

extension Decoding
{
    public static func decode(any: Any?) throws -> Self
    {
        if let encoded = any as? Encoded
        {
            return try decode(encoded)
        }
        else
        {
            throw DecodeAnyError()
        }
    }
}

public struct DecodeAnyError: CustomNSError
{
    public init() {}
    public static let domain: String = "DecodeAnyError"
    public var code: Int = 0
}

public protocol Encoding
{
    associatedtype Encoded
    var encoded: Encoded { get }
}
