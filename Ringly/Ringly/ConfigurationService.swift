import ReactiveSwift
import Result
import RinglyAPI

// MARK: - Protocol

/// A protocol for services that store an array of configuration values (i.e. contacts or applications).
protocol ConfigurationService
{
    /// The type of configuration stored by this service.
    associatedtype Configuration

    /// The service's current configuration values.
    var configurations: MutableProperty<[Configuration]> { get }

    /// The service's activated configurations. This can be the same property as `configurations`.
    var activatedConfigurations: Property<[Configuration]> { get }
}

// MARK: - Modifying Configurations
extension ConfigurationService
{
    /**
     Modifies configurations matching a predicate function.

     The last modified value, if any, is returned.

     - parameter predicate: A predicate to match the configurations to modify.
     - parameter modify:    A function to modify the configuration, returning a new configuration.
     */
    @discardableResult
    func modify(matching predicate: (Configuration) -> Bool, with modify: (Configuration) -> Configuration) -> Configuration?
    {
        var modified: Configuration? = nil

        configurations.pureModify({ current in
            current.map({ configuration in
                if predicate(configuration)
                {
                    let new = modify(configuration)
                    modified = new
                    return new
                }
                else
                {
                    return configuration
                }
            })
        })

        return modified
    }
}

extension ConfigurationService where Configuration: IdentifierConfigurable
{
    /**
     Modifies configurations matching an identifier.

     The last modified value, if any, is returned.

     - parameter identifier: The identifier for configurations to modify.
     - parameter modify:     A function to modify the configuration, returning a new configuration.
     */
    @discardableResult
    func modify(identifier: String, with modify: (Configuration) -> Configuration) -> Configuration?
    {
        return self.modify(matching: { $0.identifier == identifier }, with: modify)
    }
}

// MARK: - Removing Configurations
extension ConfigurationService where Configuration: Equatable
{
    /**
     Removes the specified configuration.

     - parameter configuration: The configuration to remove.
     */
    func removeConfiguration(_ configuration: Configuration)
    {
        configurations.pureModify({ current in
            current.filter({ configuration != $0 })
        })
    }
}

extension ConfigurationService where Configuration: IdentifierConfigurable
{
    /**
     Removes any configuration with the specified identifier.

     - parameter identifier: The identifier to remove.
     */
    func removeConfiguration(identifier: String)
    {
        configurations.pureModify({ current in
            current.filter({ identifier != $0.identifier })
        })
    }
}

// MARK: - Writing Configurations to Property List Files
extension ConfigurationService where Configuration: Encoding, Configuration.Encoded == [String:Any]
{
    /// A signal producer that will write changes to the receiver's `configurations` to the specified file path.
    ///
    /// The current value is skipped if `skipFirst` is `true`, as it is presumed to have been the source of the original
    /// data.
    func writeConfigurationsToPropertyListFileProducer(path: String, skipFirst: Bool, logFunction: @escaping (String) -> ())
        -> SignalProducer<(), NoError>
    {
        // a background scheduler for writing configurations to disk
        let scheduler = QueueScheduler(qos: .userInitiated, name: "Writing Configurations", targeting: nil)

        return configurations.producer
            .skip(first: skipFirst ? 1 : 0)
            .debounce(2, on: scheduler)
            .map({ configurations in configurations.map({ $0.encoded }) })
            .on(value: { representations in
                // attempt to write the current representations
                do
                {
                    let data = try PropertyListSerialization.data(
                        fromPropertyList: representations,
                        format: .xml,
                        options: 0
                    )
                    
                    try data.write(to: URL(fileURLWithPath: path), options: .atomicWrite)
                    
                    logFunction("Saved \(representations.count) configurations to \(path)")
                }
                catch let error as NSError
                {
                    logFunction("Failed to save configurations to path \(path) with error \(error)")
                }
            })
            .ignoreValues()
    }
}
