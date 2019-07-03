import Foundation

// MARK: - Reset Token Request

/// An endpoint for requesting a new password reset token.
public struct ResetTokenRequestRequest
{
    // MARK: - Initialization

    /**
     Initializes a reset token request endpoint.

     - parameter email: The email address to request a password reset for.
     */
    public init(email: String)
    {
        self.email = email
    }

    // MARK: - Properties

    /// The email address to request a password reset for.
    public let email: String
}

extension ResetTokenRequestRequest: RequestProviding, ResponseProcessing
{
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "users/reset-token",
            jsonBody: ["email": email]
        )
    }
    
    /// The input is not considered for this type - any non-error response code is considered a success.
    public typealias Output = ()
}

// MARK: - Password Reset

/// An endpoint for resetting a user's password.
public struct PasswordResetRequest
{
    // MARK: - Initialization

    /**
     Initializes a password reset endpoint.

     - parameter resetToken: The reset token to use for authentication.
     - parameter password:   The new password to use.
     */
    public init(resetToken: ResetToken, password: String)
    {
        self.resetToken = resetToken
        self.password = password
    }

    // MARK: - Properties

    /// The reset token to use for authentication.
    public let resetToken: ResetToken

    /// The new password to use.
    public let password: String
}

extension PasswordResetRequest: RequestProviding, ResponseProcessing
{
    // MARK: - Request
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(method: .post, baseURL: baseURL, relativeURLString: "users/reset-password", jsonBody: [
            "email": resetToken.email,
            "token": resetToken.token,
            "new_password": password
        ])
    }

    /// The input is not considered for this type - any non-error response code is considered a success.
    public typealias Output = ()
}
