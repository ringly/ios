import Foundation
import ReactiveSwift

/// A utility for determining whether or not user notifications are enabled.
final class EnableNotificationsController: NSObject
{
    // MARK: - Initialization
    init(analytics: AnalyticsService)
    {
        // Initialize derived properties
        notificationsEnabled = Property(_notificationsEnabled)
        userPrompted = Property(_userPrompted)

        self.analytics = analytics

        super.init()

        NotificationCenter.default.reactive
            .notifications(forName: .UIApplicationWillEnterForeground, object: nil)
            .take(until: reactive.lifetime.ended)
            .observeValues({ [weak self] _ in
                self?._notificationsEnabled.value = EnableNotificationsController.areNotificationsEnabled()
            })
    }

    let analytics: AnalyticsService

    // MARK: - Prompting the User

    /// Prompts the user to enable the notification permission.
    func promptUser(completion: @escaping ((Bool) -> Void))
    {
        UIApplication.shared.registerForNotificationsProducer(analytics)
            .startWithCompleted({ [weak self] in
                self?._notificationsEnabled.value = EnableNotificationsController.areNotificationsEnabled()
                self?._userPrompted.value = true
                
                completion(EnableNotificationsController.areNotificationsEnabled())
            })
    }

    // MARK: - Enabled State

    /// Backing property for `notificationsEnabled`.
    fileprivate let _notificationsEnabled = MutableProperty(EnableNotificationsController.areNotificationsEnabled())

    /// Whether or not notifications are currently enabled.
    let notificationsEnabled: Property<Bool>

    // MARK: - Queried State

    /// Backing property for `userPrompted`.
    fileprivate let _userPrompted = MutableProperty(false)

    /// Whether or not this controller has prompted the user to enable the notification permission.
    let userPrompted: Property<Bool>

    // MARK: - Utilities

    /// A static function that returns whether or not user notifications are currently enabled.
    static func areNotificationsEnabled() -> Bool
    {
        return UIApplication.shared
            .currentUserNotificationSettings?
            .types.contains(.alert) ?? false
    }
}
