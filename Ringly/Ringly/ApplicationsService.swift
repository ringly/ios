import ReactiveSwift
import Result
import RinglyExtensions
import RinglyKit

/// Manages notification settings for supported applications.
final class ApplicationsService: NSObject, ConfigurationService
{
    // MARK: - Initialization
    init(configurations: [ApplicationConfiguration], supportedApplications: [SupportedApplication])
    {
        self.configurations = MutableProperty(configurations)
        self.supportedApplications = supportedApplications

        // build set of installed URL schemes
        let schemes = Set(supportedApplications.map({ $0.scheme }))

        let willEnterForeground = NotificationCenter.default.reactive
            .notifications(forName: .UIApplicationWillEnterForeground, object: UIApplication.shared)

        let checkInstalledSchemes: () -> Set<String> = {
            Set(schemes.filter(SupportedApplication.withSchemeIsInstalled))
        }

        let installedSchemes = Property(
            initial: checkInstalledSchemes(),
            then: willEnterForeground.map({ _ in checkInstalledSchemes() })
        )

        self.installedSchemes = installedSchemes
        
        // build array of installed applications
        self.installedConfigurations = Property.combineLatest(installedSchemes, self.configurations)
            .map({ installed, configurations in
                configurations.filter({ installed.contains($0.application.scheme) })
            })

        // build array of activated applications
        self.activatedConfigurations = self.installedConfigurations.map({ configurations in
            configurations.filter({ configuration in configuration.activated })
        })
    }
    
    // MARK: - Installed Schemes
    
    /// The set of supported application schemes currently available on the device. This is updated whenever the
    /// application enters the foreground.
    fileprivate let installedSchemes: Property<Set<String>>

    /// The supported applications this service is using.
    let supportedApplications: [SupportedApplication]
    
    // MARK: - Configurations
    
    /// The service's configurations.
    var configurations: MutableProperty<[ApplicationConfiguration]>
    
    /// The service's installed configurations.
    var installedConfigurations: Property<[ApplicationConfiguration]>
    
    /// The service's activated configurations.
    var activatedConfigurations: Property<[ApplicationConfiguration]>

    /// The default file name for storing application configurations.
    @nonobjc static let applicationsFileName = "notifications.plist"
}

extension Sequence where Iterator.Element == ApplicationConfiguration
{
    // MARK: - Application Configurations

    /**
     Returns the configuration for the specified application identifier, if one exists. This uses the `configurations`
     value, so the configuration will not necessarily be installed or activated.

     - parameter applicationIdentifier: The application identifier to look up.
     - parameter trimLengthToMatch:     If `true`, the application identifier will be used as a prefix for comparison.
     */
    func configurationMatching(applicationIdentifier: String, trimLengthToMatch: Bool = false)
        -> ApplicationConfiguration?
    {
        return first(where: { configuration in
            configuration.application.identifiers.containsCaseInsensitive(
                applicationIdentifier,
                trimLengthToMatch: trimLengthToMatch
            )
        })
    }
}

extension Sequence where Iterator.Element == String
{
    // MARK: - Case Insensitive Contents

    /**
     Returns `true` if the receiver contains `string`, using a case insensitive comparison, and, if requested, cropping
     the receiver's elements to the length of `string` before comparing.

     - parameter string:            The string to look up.
     - parameter trimLengthToMatch: If `true`, `string` will be used as a prefix for comparison.
     */
    func containsCaseInsensitive(_ string: String, trimLengthToMatch: Bool = false) -> Bool
    {
        return reduce(false, { current, element in
            let trimmed = trimLengthToMatch ? element.trimmedTo(length: string.characters.count) : element
            return current || string.caseInsensitiveCompare(trimmed) == .orderedSame
        })
    }
}
