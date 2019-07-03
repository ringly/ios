import ReactiveSwift
import enum Result.NoError

enum PreferencesSwitch
{
    // MARK: - Battery Settings
    case batteryAlerts
    case sleepMode

    // MARK: - Notification Settings
    case outOfRangeNotifications
    case connectionTaps
}

extension PreferencesSwitch
{
    // MARK: - Grouping

    /// All preferences, in presentation order.
    static var all: [PreferencesSwitch]
    {
        return  [.batteryAlerts, .sleepMode, .outOfRangeNotifications, .connectionTaps]
    }

    /// All preferences, in presentation order, grouped into sections.
    static var sections: [(title: String, switches: [PreferencesSwitch])]
    {
        return [
            (title: "BATTERY SETTINGS", switches: [
                .batteryAlerts,
                .sleepMode
            ]),
            (title: "CONNECTION SETTINGS", switches: [
                .outOfRangeNotifications,
                .connectionTaps
            ])
        ]
    }
}

extension PreferencesSwitch
{
    // MARK: - Display Attributes

    /// The title for the preference.
    var title: String
    {
        switch self
        {
        case .batteryAlerts:
            return "BATTERY ALERTS"
        case .sleepMode:
            return "SLEEP MODE"
        case .outOfRangeNotifications:
            return "OUT OF RANGE ALERTS"
        case .connectionTaps:
            return "CONNECTION TAPS"
        }
    }

    /// More information about the preference's purpose.
    var information: String
    {
        switch self
        {
        case .batteryAlerts:
            return "Receive a notification on your phone when your Ringly is fully charged or has low battery. Also receive smart reminders to charge your Ringly at night."
        case .sleepMode:
            return "Save power when your Ringly is not moving."
        case .outOfRangeNotifications:
            return "Your Ringly will send 7 quick buzzes when it disconnects from your phone."
        case .connectionTaps:
            return "Tap your Ringly twice. Blue indicates connected, pink indicates disconnected."
        }
    }

    /// An icon representing the preference.
    var iconImage: UIImage?
    {
        switch self
        {
        case .batteryAlerts:
            return UIImage(asset: .notConnectingLowBattery)
        case .sleepMode:
            return UIImage(asset: .notConnectingAsleep)
        case .outOfRangeNotifications:
            return UIImage(asset: .notConnectingProximity)
        case .connectionTaps:
            return UIImage(asset: .notConnectingProximity)
        }
    }
}

extension PreferencesSwitch
{
    // MARK: - Preferences

    /**
     Returns the property in the specified preferences object that is associated with the preference.

     - parameter preferences: The preferences object.
     */
    func property(in preferences: Preferences) -> MutableProperty<Bool>
    {
        switch self
        {
        case .batteryAlerts:
            return preferences.batteryAlertsEnabled
        case .sleepMode:
            return preferences.sleepMode
        case .outOfRangeNotifications:
            return preferences.disconnectVibrations
        case .connectionTaps:
            return preferences.connectionTaps
        }
    }
    
    func propertyBacking(in preferences: Preferences) -> MutableProperty<Bool>
    {
        switch self
        {
        case .batteryAlerts:
            return preferences.batteryAlertsBacking
        // only need backing for battery alert notifications
        default:
            return MutableProperty<Bool>(false)
        }
    }
}

extension PreferencesSwitch
{
    // MARK: - Analytics
    var analyticsSetting: AnalyticsSetting
    {
        switch self
        {
        case .batteryAlerts:
            return .batteryAlerts
        case .sleepMode:
            return .sleepMode
        case .outOfRangeNotifications:
            return .outOfRange
        case .connectionTaps:
            return .connectionTaps
        }
    }
}
