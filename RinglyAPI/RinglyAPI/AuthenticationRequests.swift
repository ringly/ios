import Foundation
import Result
import UIKit

// MARK: - Login

/// An endpoint for logging and and retrieving an access token.
internal struct AuthenticationRequest
{
    // MARK: - Authentication Fields

    /// The username to log in with.
    let username: String

    /// The password to log in with.
    let password: String

    // MARK: - Snapshot Fields

    /// The device to use for snapshot fields.
    let device: UIDevice
}

extension AuthenticationRequest: RequestProviding, ResponseProcessing
{
    // MARK: - Request
    func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "api-token-auth",
            jsonBody: [
                // authentication fields
                "username": username,
                "password": password,

                // snapshot fields
                "operating_system": "0",
                "os_version": device.systemVersion,
                "model": device.modelIdentifier as Any? ?? NSNull(),
            ]
        )
    }

    /**
     Processes the input as a dictionary and attempts to extract the “token” value.

     - parameter input: The input value.
     */
    func result(for input: Any) -> Result<String, NSError>
    {
        if let token = (input as? [String:Any])?["token"] as? String
        {
            return .success(token)
        }
        else
        {
            return .failure(APIServiceError.tokenNotFound as NSError)
        }
    }
}

// MARK: - User Registration

/// An endpoint for registering users.
internal struct UserRegisterRequest
{
    /// The username to register.
    let username: String

    /// The password to register.
    let password: String

    /// The user's first name.
    let firstName: String?

    /// The user's last name.
    let lastName: String?

    /// Whether or not the user would like to receive updates.
    let receiveUpdates: Bool
}

extension UserRegisterRequest: RequestProviding, ResponseProcessing
{
    func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "users",
            jsonBody: [
                "email": username as AnyObject,
                "password": password as AnyObject,
                "first_name": firstName as Any? ?? NSNull(),
                "last_name": lastName as Any? ?? NSNull(),
                "receive_updates": receiveUpdates
            ]
        )
    }

    /// The output is a user model.
    typealias Output = User
}
