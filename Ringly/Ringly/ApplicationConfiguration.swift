import RinglyAPI
import RinglyKit

/// A notification configuration for a supported application.
struct ApplicationConfiguration: ActivatedConfigurable, ColorConfigurable, VibrationConfigurable
{
    // MARK: - Properties
    
    /// The application.
    let application: SupportedApplication
    
    /// The color to display on the peripheral.
    var color: DefaultColor
    
    /// The vibration to use on the peripheral.
    var vibration: RLYVibration
    
    /// Whether or not this configuration is activated.
    var activated: Bool
}

extension ApplicationConfiguration: IdentifierConfigurable
{
    /// The configuration's application's scheme is used as an identifier.
    var identifier: String { return application.scheme }
}

extension ApplicationConfiguration
{
    // MARK: - Notifications
    
    /// Returns a notification structure with this configuration's parameters.
    var notification: PeripheralNotification
    {
        return PeripheralNotification(vibration: vibration, color: DefaultColorToLEDColor(color))
    }
    
    /**
    Returns a notification structure with this configuration's parameters and a custom fade duration.
    
    - parameter colorFadeDuration: The color fade duration.
    */
    func notificationWithColorFadeDuration(_ colorFadeDuration: UInt8) -> PeripheralNotification
    {
        return PeripheralNotification(
            vibration: vibration,
            color: DefaultColorToLEDColor(color),
            colorFadeDuration: colorFadeDuration
        )
    }
}

// MARK: - Default Configurations
extension ApplicationConfiguration
{
    static func defaultActivatedConfigurations(for applications: [SupportedApplication]) -> [ApplicationConfiguration]
    {
        return [
            ApplicationConfiguration(
                application: applications[0],
                color: .blue,
                vibration: .fourPulses,
                activated: true
            ),
            ApplicationConfiguration(
                application: applications[1],
                color: .green,
                vibration: .threePulses,
                activated: true
            ),
            ApplicationConfiguration(
                application: applications[2],
                color: .red,
                vibration: .twoPulses,
                activated: true
            ),
            ApplicationConfiguration(
                application: applications[3],
                color: .purple,
                vibration: .onePulse,
                activated: true
            )
        ]
    }
}

// MARK: - Decoding
extension ApplicationConfiguration
{
    init(application: SupportedApplication, encoded: [String:Any])
    {
        // load the configuration data
        let color = (encoded[ApplicationConfiguration.colorIndexKey] as? UInt).map(DefaultColorFromIndex) ?? .none
        let vibration = (encoded[ApplicationConfiguration.vibrationIndexKey] as? Int).map({ RLYVibration(index: $0) }) ?? .none
        let activated = (encoded[ApplicationConfiguration.activatedKey] as? Bool) ?? false

        self.init(
            application: application,
            color: color,
            vibration: vibration,
            activated: activated
        )
    }
}

// MARK: - Encodable
extension ApplicationConfiguration: Encoding
{
    static let applicationNameKey = "appName"
    static let colorIndexKey = "Color"
    static let vibrationIndexKey = "Vibe"
    static let activatedKey = "Active"

    var encoded: [String:Any]
    {
        return [
            ApplicationConfiguration.applicationNameKey: application.scheme,
            ApplicationConfiguration.colorIndexKey: DefaultColorToIndex(color),
            ApplicationConfiguration.vibrationIndexKey: vibration.index,
            ApplicationConfiguration.activatedKey: activated
        ]
    }
}

// MARK: - Equatable
extension ApplicationConfiguration: Equatable {}
func ==(a: ApplicationConfiguration, b: ApplicationConfiguration) -> Bool
{
    return a.application == b.application
        && a.color == b.color
        && a.vibration == b.vibration
        && a.activated == b.activated
}

extension ApplicationConfiguration: Hashable
{
    // MARK: - Hashable
    
    /// The hash value of the configuration.
    var hashValue: Int
    {
        return application.hashValue
             ^ color.hashValue
             ^ vibration.hashValue
             ^ activated.hashValue
    }
}

extension ApplicationConfiguration: SettingsCommandsRepresentable
{
    // MARK: - Settings Commands Representable
    
    /**
    Returns the commands necessary to add or remove the configuration from a peripheral.
    
    - parameter mode: The command mode to use.
    */
    func commands(for mode: RLYSettingsCommandMode) -> [RLYCommand]
    {
        let color = DefaultColorToLEDColor(self.color)
        
        return application.identifiers.map({ identifier in
            RLYApplicationSettingsCommand(
                mode: mode,
                applicationIdentifier: identifier,
                color: color,
                vibration: vibration
            )
        })
    }
}
