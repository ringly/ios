import Foundation
import RinglyAPI

extension UUID: Coding
{
    public typealias Encoded = String

    public static func decode(_ encoded: Encoded) throws -> UUID
    {
        guard let uuid = UUID(uuidString: encoded) else {
            throw NSUUIDCodableError(invalidString: encoded)
        }

        return uuid
    }

    public var encoded: Encoded
    {
        return uuidString
    }
}

struct NSUUIDCodableError: Error
{
    let invalidString: String
}
