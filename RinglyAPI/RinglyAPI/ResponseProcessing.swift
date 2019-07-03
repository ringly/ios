import Result

/// A request type that takes response input and returns an output value or an error.
public protocol ResponseProcessing
{
    // MARK: - Output Type

    /// The type of output that this type produces.
    associatedtype Output

    // MARK: - Producing Output

    /**
     Produces output for a given input, or returns an error.

     - parameter input: The input value.
     */
    func result(for input: Any) -> Result<Output, NSError>
}

extension ResponseProcessing where Output: Decoding
{
    // MARK: - Default Implementation for Decodable

    /// The default implementation for `Decodable` attempts to decode the input value with `decode(any:)`.
    public func result(for input: Any) -> Result<Output, NSError>
    {
        do
        {
            return .success(try Output.decode(any: input))
        }
        catch let error as NSError
        {
            return .failure(error)
        }
    }
}

extension ResponseProcessing where Output == ()
{
    // MARK: - Default Implementation for Void

    /// The default implementation for `Void` always succeeds.
    public func result(for input: Any) -> Result<Output, NSError>
    {
        return .success(())
    }
}
