import Foundation
import Result

// MARK: - App Events

/// An endpoint for the publishing app events to the API.
public struct AppEventsRequest
{
    // MARK: - Initialization

    /**
     Initializes an app events endpoint.

     - parameter parameters: The parameters to publish.
     */
    public init(parameters: [String:Any])
    {
        self.parameters = parameters
    }

    // MARK: - Parameters

    /// The parameters to publish.
    let parameters: [String:Any]
}

extension AppEventsRequest: RequestProviding
{
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "app-events",
            jsonBody: parameters
        )?.gzippedIfPossible()
    }
}

extension URLRequest
{
    /// Gzips the request's body, returning a modified request. Returns `self` if there is no `httpBody` or if gzipping
    /// fails.
    func gzippedIfPossible() -> URLRequest
    {
        return httpBody.flatMap({ try? ($0 as NSData).byGZipCompressing() }).map({ gzipped in
            var mutable = self
            mutable.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            mutable.httpBody = gzipped
            return mutable
        }) ?? self
    }
}
