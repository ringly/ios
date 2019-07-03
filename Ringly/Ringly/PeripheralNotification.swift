import RinglyKit

/// A notification sent to ANCS v1 peripherals.
struct PeripheralNotification
{
    // MARK: - Initialization

    /**
    Initializes a peripheral notification. All parameters have default values.

    - parameter vibration:         The default value is `.none`.
    - parameter color:             The default value is `RLYColorNone`.
    - parameter secondaryColor:    The default value is `RLYColorNone`.
    - parameter colorFadeDuration: The default value is `25`.
    */
    init(vibration: RLYVibration = .none,
         color: RLYColor = RLYColorNone,
         secondaryColor: RLYColor = RLYColorNone,
         colorFadeDuration: UInt8 = 25)
    {
        self.vibration = vibration
        self.color = color
        self.secondaryColor = secondaryColor
        self.colorFadeDuration = colorFadeDuration
    }

    // MARK: - Properties

    /// The vibration for the notification.
    var vibration: RLYVibration

    /// The primary color for the notification, shown after the vibrations.
    var color: RLYColor

    /// The secondary color for the notification, shown after the primary color.
    var secondaryColor: RLYColor

    /// The duration of the LED's fade in and out, in milliseconds.
    var colorFadeDuration: UInt8
}

extension PeripheralNotification
{
    /// Returns a `RLYColorVibrationCommand` for performing the notification.
    var command: RLYColorVibrationCommand
    {
        return RLYColorVibrationCommand(
            color: color,
            secondaryColor: secondaryColor,
            vibration: vibration,
            ledFadeDuration: colorFadeDuration
        )
    }
}
