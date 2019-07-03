import AirshipKit
import Foundation

final class UrbanAirshipDelegate: NSObject
{
    weak var delegate: UrbanAirshipDelegateDelegate?
}

extension UrbanAirshipDelegate: UARegistrationDelegate
{
    func registrationSucceeded(forChannelID channelID: String, deviceToken: String)
    {
        SLogAppleNotifications("Urban Airship registration succeeded for channel \(channelID), token \(deviceToken)")
    }

    func registrationFailed()
    {
        SLogAppleNotifications("Urban Airship registration failed")
    }
}

extension UrbanAirshipDelegate: UAPushNotificationDelegate
{
    func receivedForegroundNotification(_ notificationContent: UANotificationContent, completionHandler: @escaping () -> Void)
    {
        SLogAppleNotifications("Received foreground notification: \(notificationContent.notificationInfo)")
        delegate?.receivedForegroundNotification(notificationContent)
        completionHandler()
    }

    func receivedBackgroundNotification(_ notificationContent: UANotificationContent, completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        SLogAppleNotifications("Received background notification: \(notificationContent.notificationInfo)")
        delegate?.receivedBackgroundNotification(notificationContent)
        completionHandler(.noData)
    }

    func receivedNotificationResponse(_ notificationResponse: UANotificationResponse, completionHandler: @escaping () -> Void)
    {
        SLogAppleNotifications("Received notification response action \(notificationResponse.actionIdentifier) with notification: \(notificationResponse.notificationContent.notificationInfo)")
        delegate?.receivedNotificationResponse(notificationResponse)
        completionHandler()
    }
}

protocol UrbanAirshipDelegateDelegate: class
{
    func receivedForegroundNotification(_ notificationContent: UANotificationContent)
    func receivedBackgroundNotification(_ notificationContent: UANotificationContent)
    func receivedNotificationResponse(_ response: UANotificationResponse)
}
