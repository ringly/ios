/// A token for resetting a user's password.
public struct ResetToken
{
    // MARK: - Properties

    /// The reset token, which is also used for `RESTModelType`'s `identifier`.
    public let token: String

    /// The email address associated with the token.
    public let email: String
}

extension ResetToken: Decoding
{
    // MARK: - Decoding

    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: Encoded) throws -> ResetToken
    {
        return ResetToken(
            token: try encoded.decode("token"),
            email: try encoded.decode("email")
        )
    }
}

extension ResetToken: RESTModel
{
    // MARK: - REST Model

    /// The model's identifier, which is the value of `token`.
    public var identifier: String { return token }

    /// `users/reset-token`.
    public static var pathComponent: String { return "users/reset-token" }
}
