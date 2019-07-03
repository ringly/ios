import Foundation
import Result
import RinglyExtensions

// MARK: - Models

/// A protocol for types that can be used as REST models.
public protocol RESTModel
{
    /// The unique identifier for the model type.
    var identifier: String { get }

    /// The path component for accessing the model.
    static var pathComponent: String { get }
}

// MARK: - GET Requests

/// A request for performing a REST `GET`.
public struct RESTGetRequest<Value> where Value: RESTModel, Value: Decoding, Value.Encoded == [String:Any]
{
    // MARK: - Initialization

    /**
     Initializes a `GET` request.

     - parameter identifier: The model identifier to retrieve.
     */
    public init(identifier: String)
    {
        self.identifier = identifier
    }

    /// The model identifier to retrieve.
    public let identifier: String
}

extension RESTGetRequest: RequestProviding, ResponseProcessing
{
    public typealias Output = Value

    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .get,
            baseURL: baseURL,
            relativeURLString: "\(Output.pathComponent)/\(identifier)"
        )
    }
}

// MARK: - PATCH Requests

/// A request for performing a REST `PATCH`.
public struct RESTPatchRequest<Value> where Value: RESTModel, Value: Coding, Value.Encoded == [String:Any]
{
    // MARK: - Initialization

    /**
     Initializes a `PATCH` request.

     - parameter model: The model value to patch.
     */
    public init(model: Value)
    {
        self.model = model
    }

    // MARK: - Properties

    /// The model value.
    public let model: Value
}

extension RESTPatchRequest: RequestProviding, ResponseProcessing
{
    // MARK: - Request
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .patch,
            baseURL: baseURL,
            relativeURLString: "\(Output.pathComponent)/\(model.identifier)",
            jsonBody: model.encoded
        )
    }

    public typealias Output = Value
}
