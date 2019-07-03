import ReactiveSwift

extension ObserverProtocol where Error == NSError
{
    /// A completion-handler-compatible callback for Apple-style APIs.
    ///
    /// - Parameters:
    ///   - success: `true` if the operation succeeded, otherwise `false`.
    ///   - error: An error value that should be populated if `success` is `false.
    public func completionHandler(success: Bool, error: Swift.Error?)
    {
        if success
        {
            sendCompleted()
        }
        else
        {
            send(error: error as? NSError ?? UnknownError() as NSError)
        }
    }

    /// A completion-handler-compatible callback for Apple-style APIs.
    ///
    /// - Parameters:
    ///   - optional: A value that should be non-`nil` if the operation succeeded.
    ///   - error: An error value that should be populated if `optional` is `nil`.
    public func completionHandler(optional: Value?, error: Swift.Error?)
    {
        if let value = optional
        {
            send(value: value)
            sendCompleted()
        }
        else
        {
            send(error: error as? NSError ?? UnknownError() as NSError)
        }
    }
}

/// An error that is yielded when a completion handler indicates a failure, but does not provide an error value. This
/// should not happen, but the type system cannot enforce that safely.
public struct UnknownError: CustomNSError
{
    /// Initializes an unknown error.
    public init() {}

    /// The domain for unknown errors.
    public static let errorDomain = "UnknownError"

    /// The error code, which is always `0`.
    public let errorCode = 0
}
