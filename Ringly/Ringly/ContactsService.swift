import Contacts
import ReactiveSwift
import Result

/// Manages the current contacts added by the user.
final class ContactsService: NSObject, ConfigurationService
{
    // MARK: - Initialization

    /**
    Initializes a contacts service.

    - parameter configurations:   The initial contact configurations to use.
    */
    init(configurations: [ContactConfiguration])
    {
        self.configurations = MutableProperty(configurations)
        self.activatedConfigurations = Property(self.configurations)
    }

    // MARK: - Current Configurations

    /// The current configurations stored by the service.
    let configurations: MutableProperty<[ContactConfiguration]>

    /// The current activated configurations, which includes all configurations.
    let activatedConfigurations: Property<[ContactConfiguration]>
    
    // MARK: - Adding Configurations
    
    /**
     Adds a configuration from a `CNContact` object, if possible.
     
     - parameter contact: The `CNContact` object.
     
     - returns: A result value, with the added configuration if successful, or an error if unsuccessful.
     */
    func addConfiguration(from contact: CNContact) -> Result<ContactConfiguration, ContactsError>
    {
        if configurations.value.any({ $0.identifier == contact.identifier })
        {
            return .failure(.alreadyAdded)
        }
        else
        {
            let result = Result(CNContactFormatter.string(from: contact, style: .fullName),
                failWith: ContactsError.noProperName)
                .map({ _ in
                    ContactConfiguration(dataSource: contact, color: .blue)
                })

            if let configuration = result.value
            {
                configurations.modify({ $0.append(configuration) })
            }

            return result
        }
    }
}

extension ContactsService
{
    @nonobjc static let contactsFilename = "contacts-modern.plist"
}

extension ContactsService
{
    static func contactConfigurations(from path: String) -> [ContactConfiguration]
    {
        // load the plist file
        let contents = NSArray(contentsOfFile: path)

        // if the plist file conforms and is not empty, load configurations from a contacts store
        if let representations = contents as? [[String:AnyObject]], representations.count > 0
        {
            let configurationResults = representations.contactConfigurations(from: CNContactStore())

            return configurationResults.flatMap({ result in
                switch result
                {
                case let .success(configuration):
                    return configuration
                case let .failure(error):
                    SLogContacts("Error loading contact from dictionary representation: \(error)")
                    return nil
                }
            })
        }
        else
        {
            SLogContacts("Could not load array from file path: \(path)")
            return []
        }
    }
}

extension ContactsService
{
    /// A signal producer that, when started, will automatically update the receiver's `configurations` when the
    /// application receives a notification that the contact store changed.
    var automaticContactUpdateProducer: SignalProducer<(), NoError>
    {
        let changed = NotificationCenter.default.reactive
            .notifications(forName: .CNContactStoreDidChange, object: nil)
            .observe(on: QueueScheduler.main)
            .take(until: reactive.lifetime.ended)

        return SignalProducer(changed).on(value: { [weak self] _ in
            guard let strong = self else { return }

            SLogContacts("Contacts changed, updating")

            strong.configurations.modify({ current in
                current = current.updateToContacts(from: CNContactStore()).flatMap({ result in
                    switch result
                    {
                    case .success(let configuration):
                        return configuration
                    case .failure(let error):
                        SLogContacts("Error updating contact, did it disappear? \(error)")
                        return nil
                    }
                })
            })
        }).ignoreValues()
    }
}

extension Sequence where Iterator.Element == ContactConfiguration
{
    // MARK: - Contact Configurations

    /**
     Finds a contact configuration matching the given name, if possible.

     - parameter name:              The name to match.
     - parameter trimLengthToMatch: If the configuration's name should be trimmed to the same length as the given name.
                                    This is used to match names received from ANCS, which have a length limit.

     - returns: If a configuration is found, the configuration. Otherwise, `nil`.
     */
    func contactConfiguration(_ name: String, trimLengthToMatch: Bool) -> ContactConfiguration?
    {
        return first(where: { configuration in
            configuration.names.any({ configurationName in
                let contactName = trimLengthToMatch
                    ? configurationName.trimmedTo(length: name.characters.count)
                    : configurationName

                return name.caseInsensitiveCompare(contactName) == .orderedSame
            })
        })
    }
}
