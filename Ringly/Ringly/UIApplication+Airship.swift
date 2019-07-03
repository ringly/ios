import AirshipKit
import ReactiveSwift
import UIKit
import enum Result.NoError

extension UIApplication
{
    /// When started, registers for notifications. Completes once the registration for user notifications has completed.
    ///
    func registerForNotificationsProducer(_ analytics: AnalyticsService) -> SignalProducer<(), NoError>
    {
        guard let delegate = delegate as? AppDelegate else { return SignalProducer.empty }

        let selectors = [
            #selector(AppDelegate.application(_:didRegister:)), // required on simulator, iOS 9
            #selector(AppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)) // iOS 10
        ]

        let callbacks = Signal.merge(selectors.map(delegate.reactive.trigger))

        return SignalProducer(callbacks)
            .take(first: 1)
            .ignoreValues()
            .on(
                started: {
                    analytics.track(AnalyticsEvent.notificationsRequested)

                    if !UAirship.push().userPushNotificationsEnabled && TARGET_OS_SIMULATOR == 0
                    {
                        UAirship.push().userPushNotificationsEnabled = true
                    }
                    else
                    {
                        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                        self.registerUserNotificationSettings(settings)
                    }
                },
                completed: {
                    let accepted = (self.currentUserNotificationSettings?.types).map({ types in
                        types.contains(.alert) || types.contains(.sound)
                    }) ?? false

                    analytics.track(AnalyticsEvent.notificationsCompleted(accepted: accepted))
                    analytics.track(AnalyticsEvent.notificationsPermission(accepted ? .accepted : .denied))
                })
    }
}
