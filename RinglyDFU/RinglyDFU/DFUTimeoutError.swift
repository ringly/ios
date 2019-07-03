import RinglyExtensions

public enum DFUTimeoutError: Int
{
    case repeatedlyWriting
}

extension DFUTimeoutError: CustomNSError
{
    public static let errorDomain = "RinglyDFU.DFUTimeoutError"
}

extension DFUTimeoutError: LocalizedError
{
    public var errorDescription: String?
    {
        return "Update Error"
    }

    public var failureReason: String?
    {
        return "The update timed out."
    }
}
