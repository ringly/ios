/// A user model from the Ringly API.
public struct User: Equatable
{
    // MARK: - Initializers

    /**
    Initializes a `User` model.

    - parameter identifier:     The user's unique identifier.
    - parameter email:          The user's email address.
    - parameter firstName:      The user's first name.
    - parameter lastName:       The user's last name.
    - parameter receiveUpdates: `true` if the user has requested email updates from Ringly.
    */
    public init(identifier: String, email: String, firstName: String?, lastName: String?, receiveUpdates: Bool)
    {
        self.identifier = identifier
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.receiveUpdates = receiveUpdates
    }

    // MARK: - Properties

    /// The user's unique identifier.
    public let identifier: String

    /// The user's email address.
    public let email: String

    /// The user's first name.
    public let firstName: String?

    /// The user's last name.
    public let lastName: String?

    /// `true` if the user has requested email updates from Ringly.
    public let receiveUpdates: Bool
}

extension User
{
    // MARK: - Name

    /// The user's full name, calculated from the `firstName` and `lastName` properties.
    public var name: String?
    {
        func emptyToNil(_ string: String?) -> String?
        {
            return string.flatMap({ $0.characters.count > 0 ? $0 : nil })
        }

        switch (emptyToNil(firstName), emptyToNil(lastName))
        {
        case let (.some(first), .some(last)):
            return "\(first) \(last)"
        case let (.some(first), .none):
            return first
        case let (.none, .some(last)):
            return last
        default:
            return nil
        }
    }
}

extension User: CustomStringConvertible
{
    // MARK: - Description
    public var description: String
    {
        return "(identifier = \(identifier), email = \(email), firstName = \(firstName), lastName = \(lastName))"
    }
}

extension User: Coding
{
    // MARK: - Codable
    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: Encoded) throws -> User
    {
        return User(
            identifier: try encoded.decode("id"),
            email: try encoded.decode("email"),
            firstName: encoded["first_name"] as? String,
            lastName: encoded["last_name"] as? String,
            receiveUpdates: try encoded.decode("receive_updates")
        )
    }

    public var encoded: Encoded
    {
        return [
            "id": identifier as AnyObject,
            "email": email as AnyObject,
            "first_name": firstName as AnyObject? ?? NSNull(),
            "last_name": lastName as AnyObject? ?? NSNull(),
            "receive_updates": receiveUpdates as AnyObject
        ]
    }
}

extension User: RESTModel
{
    // MARK: - REST Model

    /// `users`
    public static var pathComponent: String { return "users" }
}

public func ==(lhs: User, rhs: User) -> Bool
{
    return lhs.identifier == rhs.identifier
        && lhs.email == rhs.email
        && lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.receiveUpdates == rhs.receiveUpdates
}
