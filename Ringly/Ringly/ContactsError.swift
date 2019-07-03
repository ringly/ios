import Foundation
import RinglyExtensions

/// Enumerates error cases of `ContactsService` and its associated backend and configuration types.
enum ContactsError: Int, Error
{
    // MARK: - Cases
    
    /// The contact has already been added.
    case alreadyAdded
    
    /// The contact doesn't have a proper name.
    case noProperName
    
    /// The contact doesn't have an identifier.
    case noIdentifier
    
    /// The color is invalid.
    case invalidColor
    
    /// The wrong backend was used.
    case wrongBackend
    
    /// An unknown error occured.
    case unknown
}

extension ContactsError: CustomNSError
{
    // MARK: - Domain
    
    /// The domain for `NSError` representations.
    static var errorDomain: String { return "com.ringly.contactsError" }
}

extension ContactsError: LocalizedError
{
    // MARK: - User Info Convertible

    /// A description of the error.
    var errorDescription: String?
    {
        return "Contacts Error"
    }

    /// The failure reason associated with the error case.
    var failureReason: String?
    {
        switch self
        {
        case .alreadyAdded:
            return "The selected contact has already been added."
        case .noProperName:
            return "The selected contact doesn't have a proper name. Currently we aren't supporting contacts without names."
        case .noIdentifier:
            return "The selected contact doesn't have an identifier."
        case .invalidColor:
            return "Invalid color"
        case .wrongBackend:
            return "Wrong backend"
        case .unknown:
            return "Unknown error"
        }
    }
}
