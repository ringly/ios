import RinglyKit

// MARK: - Properties

/// A protocol for configuration types that can be activated or deactivated.
protocol ActivatedConfigurable
{
    /// Whether or not the configuration is activated or deactivated.
    var activated: Bool { get set }
}

/// A protocol for configuration types that have a Ringly color associated with them.
protocol ColorConfigurable
{
    /// The configured color.
    var color: DefaultColor { get set }
}

/// A protocol for configuration types that have a unique identifier.
protocol IdentifierConfigurable
{
    /// The configuration's identifier.
    var identifier: String { get }
}

/// A protocol for configuration types that have a vibration pattern associated with them.
protocol VibrationConfigurable
{
    /// The configured vibration pattern.
    var vibration: RLYVibration { get set }
}

// MARK: - Commands

/// A protocol for configuration types that can be represented as `RLYCommand` values.
protocol SettingsCommandsRepresentable
{
    /**
     Returns the commands necessary to add or remove the configuration from a peripheral.

     - parameter mode: The command mode to use.
     */
    func commands(for mode: RLYSettingsCommandMode) -> [RLYCommand]
}
