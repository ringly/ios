import Foundation

public struct WriterError: Error
{
    let message: String
}

extension WriterError: CustomNSError
{
    public static var errorDomain: String { return "RinglyDFU.WritableError" }
    public var errorCode: Int { return 0 }
}

extension WriterError: LocalizedError
{
    public var errorDescription: String? { return message }
}
