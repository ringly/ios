import Foundation

// MARK: - Applications
struct ApplicationChangedEvent
{
    let configuration: ApplicationConfiguration
    let method: ApplicationChangedMethod
}

extension ApplicationChangedEvent: AnalyticsEventType
{
    var name: String { return "Changed Notification" }

    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            "Name": configuration.application.analyticsName,
            "Color": DefaultColorToString(configuration.color),
            "Vibration": RLYVibrationToString(configuration.vibration),
            "Method": method
        ]
    }
}

// MARK: - Contacts
struct ContactChangedEvent
{
    let configuration: ContactConfiguration
    let method: ColorSliderViewSelectionMethod
}

extension ContactChangedEvent: AnalyticsEventType
{
    var name: String { return "Changed Contact" }

    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            "Color": DefaultColorToString(configuration.color),
            "Method": method
        ]
    }
}

struct ExceededContactLimitEvent: AnalyticsEventType
{
    var name: String { return "Exceeded Contact Limit" }
}

// MARK: - Methods
enum ApplicationChangedMethod
{
    case enabled
    case vibration
    case color(ColorSliderViewSelectionMethod)
}

extension ApplicationChangedMethod: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .color(let method):
            return method.analyticsString
        case .enabled:
            return "Enabled"
        case .vibration:
            return "Vibration"
        }
    }
}

extension ColorSliderViewSelectionMethod: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .pan: return "Pan"
        case .tap: return "Tap"
        }
    }
}
