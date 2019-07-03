import Foundation
import RinglyExtensions

public enum APIServer
{
    // MARK: - Cases

    /// The main production server (api.ringly.com)
    case production

    /// The staging server.
    case staging

    /// A custom server, provided in the developer view controller.
    case custom(appToken: String, baseURL: URL)
}

extension APIServer
{
    // MARK: - API Information

    /// The app token to include with requests.
    public var appToken: String
    {
        switch self
        {
        case .production:
            return "BZNXjzut2wGcDsUrFZlilqgV"
        case .staging:
            return "stgios"
        case .custom(let parameters):
            return parameters.appToken
        }
    }

    /// The base URL for requests.
    public var baseURL: URL
    {
        switch self
        {
        case .production:
            return URL(string: "https://api.ringly.com/v0/")!
        case .staging:
            return URL(string: "https://stage.theringly.com/v0/")!
        case .custom(let parameters):
            return parameters.baseURL
        }
    }
}

extension APIServer: CustomStringConvertible
{
    // MARK: - Custom String Convertible
    public var description: String
    {
        switch self
        {
        case .production:
            return "Production"
        case .staging:
            return "Staging"
        case .custom(let appToken, let baseURL):
            return "App Token = \(appToken), Base URL = \(baseURL.absoluteString)"
        }
    }
}

extension APIServer: Coding
{
    // MARK: - Codable
    public typealias Encoded = Any

    public static func decode(_ encoded: Encoded) throws -> APIServer
    {
        // The decode behavior is complicated so that we can handle legacy sessions, when this value was a simple C
        // enumeration of production and staging.
        if let integer = encoded as? Int
        {
            switch integer
            {
            case 0: return .production
            case 1: return .staging
            default: throw APIServerInvalidIntegerError(invalidInteger: integer)
            }
        }
        else if let dictionary = encoded as? [String:String]
        {
            guard let appToken = dictionary["appToken"] else {
                throw APIServerInvalidCustomError.appTokenMissing
            }

            guard let baseURL = dictionary["baseURL"].flatMap({ URL(string: $0) }) else {
                throw APIServerInvalidCustomError.baseURLMissing
            }

            return .custom(appToken: appToken, baseURL: baseURL)
        }
        else
        {
            throw APIServerInvalidEncodedTypeError(encoded: encoded)
        }
    }

    public var encoded: Encoded
    {
        switch self
        {
        case .production: return 0 as APIServer.Encoded
        case .staging: return 1 as APIServer.Encoded
        case .custom(let appToken, let baseURL):
            return ["appToken": appToken, "baseURL": baseURL.absoluteString]
        }
    }
}

// MARK: - Equatable
extension APIServer: Equatable {}
public func ==(lhs: APIServer, rhs: APIServer) -> Bool
{
    switch (lhs, rhs)
    {
    case (.production, .production):
        return true
    case (.staging, .staging):
        return true
    case (.custom(let lhsAppToken, let lhsBaseURL), .custom(let rhsAppToken, let rhsBaseURL)):
        return lhsAppToken == rhsAppToken && lhsBaseURL == rhsBaseURL
    default:
        return false
    }
}

// MARK: - Invalid Integer Error
public struct APIServerInvalidIntegerError: Error
{
    public let invalidInteger: Int
}

extension APIServerInvalidIntegerError: CustomNSError
{
    public static var errorDomain: String { return "RinglyAPI.APIServerInvalidIntegerError" }
    public var errorCode: Int { return invalidInteger }
}

// MARK: - Invalid Custom Error
public enum APIServerInvalidCustomError: Int, Error
{
    case appTokenMissing
    case baseURLMissing
}

extension APIServerInvalidCustomError: CustomNSError
{
    public static var errorDomain: String { return "RinglyAPI.APIServerInvalidCustomError" }
}

// MARK: - Invalid Encoded Type Error
public struct APIServerInvalidEncodedTypeError: Error
{
    public let encoded: Any
}

extension APIServerInvalidEncodedTypeError: CustomNSError
{
    public static var errorDomain: String { return "RinglyAPI.APIServerInvalidEncodedTypeError" }
    public var errorCode: Int { return 0 }
}
