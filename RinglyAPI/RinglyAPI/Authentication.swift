import Foundation

public struct Authentication: Equatable
{
    // MARK: - Initialization

    /**
    Initializes an `Authentication` value.

    - parameter user:   The user associated with the session. If the session is anonymous, this value should be `nil`.
    - parameter token:  The access token for the session. If the session is anonymous, this value should be `nil`.
    - parameter server: The server the session was created on.
    */
    public init(user: User?, token: String?, server: APIServer)
    {
        self.user = user
        self.token = token
        self.server = server
    }

    // MARK: - Properties

    /// The user associated with the session. If the session is anonymous, this property will be `nil`.
    public let user: User?

    /// The access token for the session. If the session is anonymous, this property will be `nil`.
    public let token: String?

    /// The server the session was created on.
    public let server: APIServer
}

extension Authentication: Coding
{
    // MARK: - Codable

    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: Encoded) throws -> Authentication
    {
        let user = try encoded["user"].map({ try User.decode(any: $0) })
        let token: String? = try encoded["token"].map({ any in
            guard let string = any as? String else { throw DecodeAnyError() }
            return string
        })

        return Authentication(user: user, token: token, server: try APIServer.decode(any: encoded["server"]))
    }

    public var encoded: Encoded
    {
        var encoded: [String:Any] = ["server": server.encoded]
        encoded["token"] = token as Any?
        encoded["user"] = user?.encoded as Any?

        return encoded
    }
}

public func ==(lhs: Authentication, rhs: Authentication) -> Bool
{
    return lhs.user == rhs.user && lhs.token == rhs.token && lhs.server == rhs.server
}
