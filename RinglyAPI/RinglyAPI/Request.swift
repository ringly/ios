import Foundation
import Result

/// A protocol for types that may provide a URL request.
public protocol RequestProviding
{
    /// Asks for a URL request.
    ///
    /// - Parameter baseURL: The base URL for the request.
    /// - Returns: A URL request relative to `baseURL`.
    func request(for baseURL: URL) -> URLRequest?
}

public enum RequestMethod: String
{
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

extension URLRequest
{
    init?(method: RequestMethod,
          baseURL: URL,
          relativeURLString: String,
          queryItems: [URLQueryItem]? = nil,
          body: Data? = nil,
          headerFields: [String:String]? = nil)
    {
        guard let url = baseURL.fullURL(relativeURLString: relativeURLString, queryItems: queryItems) else {
            return nil
        }

        self.init(url: url)
        self.httpBody = body
        self.httpMethod = method.rawValue
        self.allHTTPHeaderFields = headerFields
    }

    init?(method: RequestMethod,
          baseURL: URL,
          relativeURLString: String,
          queryItems: [URLQueryItem]? = nil,
          jsonBody: Any)
    {
        self.init(
            method: method,
            baseURL: baseURL,
            relativeURLString: relativeURLString,
            queryItems: queryItems,
            body: try? JSONSerialization.data(withJSONObject: jsonBody, options: []),
            headerFields: ["Content-Type": "application/json"]
        )
    }
}

extension URL
{
    func fullURL(relativeURLString: String, queryItems: [URLQueryItem]?) -> URL?
    {
        guard let url = URL(string: relativeURLString, relativeTo: self) else { return nil }

        if let queryItems = queryItems
        {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            components?.queryItems = queryItems
            return components?.url
        }
        else
        {
            return url
        }
    }
}
