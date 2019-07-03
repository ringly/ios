import Foundation
import RinglyKit

struct NotifiedEvent
{
    /// The identifier for the application associated with the event.
    let applicationIdentifier: String

    /// `true` if the notification was sent to the peripheral.
    let sent: Bool

    /// `true` if the notification's application was enabled on the peripheral.
    let enabled: Bool

    /// `true` if the notification's application is supported by the Ringly app.
    let supported: Bool

    /// The version of the notification.
    let version: RLYANCSNotificationVersion
}

extension NotifiedEvent: AnalyticsEventType
{
    var name: String { return "Notified" }

    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            "Application": applicationIdentifier,
            "Sent": sent,
            "Enabled": enabled,
            "Supported": supported,
            "ANCS Version": version
        ]
    }
}

extension RLYANCSNotificationVersion: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .version1:
            return "1"
        case .version2:
            return "2"
        }
    }
}
