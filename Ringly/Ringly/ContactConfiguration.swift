import Contacts
import Result
import RinglyAPI
import RinglyExtensions
import RinglyKit
import UIKit

// MARK: - Configuration
struct ContactConfiguration: ColorConfigurable
{
    // MARK: - Properties

    /// The data source for the contact information.
    let dataSource: ContactDataSource

    /// The color for the configuration.
    var color: DefaultColor
}

extension ContactConfiguration: ContactDataSource, IdentifierConfigurable
{
    // MARK: - Contact Data Source

    /// A unique identifier for the contact configuration.
    var identifier: String { return dataSource.identifier }

    /// The contact's names for notification matching.
    var names: [String] { return dataSource.names }

    /// The contact's name for display.
    var displayName: String { return dataSource.displayName }

    /// An image of the contact, if available.
    var image: UIImage? { return dataSource.image }
}

extension ContactConfiguration: SettingsCommandsRepresentable
{
    // MARK: - Settings Commands Representable

    /**
     Returns the commands necessary to add or remove the configuration from a peripheral.

     - parameter mode: The command mode to use.
     */
    func commands(for mode: RLYSettingsCommandMode) -> [RLYCommand]
    {
        return names.map({ name in
            RLYContactSettingsCommand(
                mode: mode,
                contactName: name,
                color: DefaultColorToLEDColor(self.color)
            )
        })
    }
}

extension ContactConfiguration: Encoding
{
    // MARK: - Dictionary Representation

    /// A dictionary representation of the contact configuration, containing the contact's identifier and associated
    /// color.
    var encoded: [String:Any]
    {
        return [
            ContactConfiguration.colorKey: color.rawValue as AnyObject,
            ContactConfiguration.identifierKey: identifier as AnyObject
        ]
    }

    static let colorKey = "color"
    static let identifierKey = "identifier"
}

extension ContactConfiguration: Equatable {}
func==(lhs: ContactConfiguration, rhs: ContactConfiguration) -> Bool
{
    return lhs.identifier == rhs.identifier && lhs.color == rhs.color
}

extension ContactConfiguration
{
    // MARK: - Fetch Keys

    /// The contact keys we require for all `ContactsContactConfiguration` features.
    fileprivate static let keysToFetch: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactTypeKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactMiddleNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPreviousFamilyNameKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactNicknameKey as CNKeyDescriptor,
        CNContactPhoneticFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneticGivenNameKey as CNKeyDescriptor,
        CNContactPhoneticMiddleNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactDepartmentNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactImageDataAvailableKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
}

// MARK: - Sequence Extensions
extension Sequence where Iterator.Element == [String:AnyObject]
{
    /**
     Loads Contacts contact configurations from dictionary representations, if possible.

     - parameter store: The contact store to retrieve contacts from.
     */
    func contactConfigurations(from store: CNContactStore) -> [Result<ContactConfiguration, NSError>]
    {
        let keysToFetch = ContactConfiguration.keysToFetch

        return map({ representation in
            let color = Result(
                (representation[ContactConfiguration.colorKey] as? Int).flatMap(DefaultColor.init),
                failWith: ContactsError.invalidColor as NSError
            )

            let identifier = Result(
                representation[ContactConfiguration.identifierKey] as? String,
                failWith: ContactsError.noIdentifier as NSError
            )

            let contact = identifier.flatMap({ identifier in
                Result(attempt: { try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch) })
            })

            return (contact &&& color).map(ContactConfiguration.init)
        })
    }
}

extension Sequence where Iterator.Element == ContactConfiguration
{
    /**
     Migrates a sequence of stale contact configurations to current configurations.

     This should be used when the system notifies us that contacts have changed.

     Contacts will be updated. If a contact was deleted or cannot be retrieved for another reason, an error result will
     be included instead.

     - parameter store: The contact store to retrieve contacts from.
     */
    func updateToContacts(from store: CNContactStore) -> [Result<ContactConfiguration, NSError>]
    {
        return map({ configuration in
            do
            {
                let contact = try store.unifiedContact(
                    withIdentifier: configuration.identifier,
                    keysToFetch: ContactConfiguration.keysToFetch
                )

                return .success(ContactConfiguration(dataSource: contact, color: configuration.color))
            }
            catch let error as NSError
            {
                return .failure(error)
            }
        })
    }
}

// MARK: - Data Source Protocol

/// A protocol for types that provide contact information to `ContactConfiguration` values.
protocol ContactDataSource
{
    /// A unique identifier for the contact configuration.
    var identifier: String { get }

    /// The contact's names for notification matching.
    var names: [String] { get }

    /// The contact's name for display.
    var displayName: String { get }

    /// An image of the contact, if available.
    var image: UIImage? { get }
}

// MARK: - Contacts Framework Integration
extension CNContact: ContactDataSource
{
    // MARK: - Contact Data Source

    /// The contact's `displayName` is always used, and, if set, the contact's `nickname` is also included.
    var names: [String]
    {
        let nickname = self.nickname

        return nickname.characters.count > 0
            ? [displayName, nickname]
            : [displayName]
    }

    /// The contact's name is derived from `CNContactFormatter`, using the `.FullName` style.
    var displayName: String
    {
        return CNContactFormatter.string(from: self, style: .fullName) ?? ""
    }

    /// The image is the wrapped contact's thumbnail image, if available.
    var image: UIImage?
    {
        return thumbnailImageData.flatMap(UIImage.init)
    }
}
