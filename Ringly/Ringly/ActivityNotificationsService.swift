import ReactiveSwift
import RinglyActivityTracking
import RinglyAPI
import UIKit
import func RinglyExtensions.unwrap
import HealthKit

final class ActivityNotificationsService: NSObject
{
    // MARK: - Initialization

    /// Initializes a notifications service.
    ///
    /// - parameter state:                      The initial state for the service.
    /// - parameter reminderState:              The initial reminder state for the service.
    /// - parameter localNotificationScheduler: An object that can schedule and cancel local notifications.
    /// - parameter sendNotification:           A callback function to send a notification.
    init(state: ActivityNotificationsState,
         reminderState: ActivityReminderNotificationsState,
         localNotificationScheduler: LocalNotificationScheduling,
         sendNotification: @escaping (ActivityNotification) -> Bool)
    {
        self._state = MutableProperty(state)
        self.state = Property(_state)

        self._reminderState = MutableProperty(reminderState)
        self.reminderState = Property(_reminderState)

        self.localNotificationScheduler = localNotificationScheduler
        self.sendNotification = sendNotification
    }

    /// Initializes a notifications service to validate notifications and track history.
    ///
    /// - parameter state:                      The initial state for the service.
    /// - parameter reminderState:              The initial reminder state for the service.
    /// - parameter calendar:                   A calendar to use for determining the fire dates of notifications.
    /// - parameter dateScheduler:              A date scheduler - `QueueScheduler.main` is fine,
    ///                                         `TestScheduler` for unit tests. The scheduler is only used for providing
    ///                                         the current date.
    /// - parameter localNotificationScheduler: An object that can schedule and cancel local notifications.
    /// - parameter displayNotification:        A function to display a validated notification - there is no need to
    ///                                         filter out notifications at this point.
    convenience init(state: ActivityNotificationsState,
                     reminderState: ActivityReminderNotificationsState,
                     calendar: Calendar,
                     dateScheduler: DateSchedulerProtocol,
                     localNotificationScheduler: LocalNotificationScheduling,
                     displayNotification: @escaping (ActivityNotification, Calendar, Date) -> ())
    {
        self.init(
            state: state,
            reminderState: reminderState,
            localNotificationScheduler: localNotificationScheduler,
            sendNotification: { notification in
                displayNotification(notification, calendar, dateScheduler.currentDate)
                return true
            }
        )
    }

    /// Initializes a notifications service to automatically send local notifications.
    ///
    /// - parameter state:            The initial state for the service.
    /// - parameter reminderState:    The initial reminder state for the service.
    /// - parameter activityTracking: An activity tracking service to load data from.
    /// - parameter preferences:      A preferences object, used for activity notification history.
    convenience init(state: ActivityNotificationsState,
                     reminderState: ActivityReminderNotificationsState,
                     activityTracking: ActivityTrackingService,
                     preferences: Preferences)
    {
        let calendar = Calendar.current

        self.init(
            state: state,
            reminderState: reminderState,
            calendar: calendar,
            dateScheduler: QueueScheduler.main,
            localNotificationScheduler: UIApplication.shared,
            displayNotification: { notification, calendar, currentDate in
                let localNotification = notification.localNotification(calendar: calendar, currentDate: currentDate)
                UIApplication.shared.scheduleLocalNotification(localNotification)
            }
        )

        // schedule current day steps notifications
        activityTracking.currentDaySteps.producer
            .skipNil()
            .combineLatest(with: preferences.activityEncouragementEnabled.producer)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] current, enabled in
                if enabled {
                    switch current
                    {
                    case let .success(currentSteps):
                        self?.updateState(calendar: calendar, currentDate: Date(), currentDateSteps: currentSteps)
                    default:
                        SLogActivityTrackingError("Error in activity notifications, current day result: \(current.error)")
                    }
                }
                else {
                    self?.localNotificationScheduler.scheduledLocalNotifications?
                        .filter({ $0.isActivityNotification })
                        .forEach((self?.localNotificationScheduler.cancelLocalNotification)!)
                }
            })
    }

    // MARK: - Notifications

    /// A function to send an activity notification. Returns `true` if the notification was sent, which prevents that
    /// notification from being sent again today.
    private let sendNotification: (ActivityNotification) -> Bool

    /// An object that can schedule and cancel local notifications.
    private let localNotificationScheduler: LocalNotificationScheduling

    // MARK: - Steps Goal

    /// The steps goal. This property must be set to a non-`nil` value before activity notifications will work.
    let stepsGoal = MutableProperty(Int?.none)

    // MARK: - States

    /// A backing property for `state`.
    private let _state: MutableProperty<ActivityNotificationsState>

    /// The current notifications state of the service.
    let state: Property<ActivityNotificationsState>

    /// A backing property for `reminderState`.
    private let _reminderState: MutableProperty<ActivityReminderNotificationsState>

    /// The current reminder notifications state of the service.
    let reminderState: Property<ActivityReminderNotificationsState>

    /// Whether or not a met goal notification was sent the previous day.
    let lastMetGoal = MutableProperty<Date>(Date.distantPast)
    
    /// Updates the state of the service. This will automatically send notifications if applicable.
    ///
    /// - parameter currentDateSteps:  The current day's steps.
    func updateState(calendar: Calendar, currentDate: Date, currentDateSteps: DateSteps)
    {
        _state.pureModify({ state in
            var sentMetGoalToday = state.sentMetGoalToday
            var sentMetPartGoalToday = state.sentMetPartGoalToday

            // when the day advances, reset the notification state
            if let components = state.current?.components, // TODO: better comparison of dates?
                  currentDateSteps.components.day != components.day
               || currentDateSteps.components.month != components.month
               || currentDateSteps.components.year != components.year
            {
                sentMetGoalToday = false
                sentMetPartGoalToday = false
            }

            // send notifications for the current day
            if let goal = stepsGoal.value
            {
                let currentSteps = currentDateSteps.steps.stepCount
                
                // met goal notification
                if !sentMetGoalToday && currentSteps > goal
                {
                    sentMetGoalToday = sendNotification(.metGoal(steps: currentSteps))
                    lastMetGoal.value = currentDate
                }
                
                // only send notification if between 25% and 35% of steps, did not meet goal day before
                if lastMetGoal.value.addingTimeInterval(60 * 60 * 24) < currentDate &&
                    !sentMetPartGoalToday &&
                    (currentSteps >= Int(Double(goal)*0.25)) &&
                    (currentSteps <= Int(Double(goal)*0.35))
                {
                    sentMetPartGoalToday = self.sendNotification(.metPartGoal)
                }
            }

            return ActivityNotificationsState(current: currentDateSteps, sentMetGoalToday: sentMetGoalToday, sentMetPartGoalToday: sentMetPartGoalToday)
        })
    }
}

// MARK: - Notifications State

/// The state of an `ActivityNotificationsService`.
struct ActivityNotificationsState: Equatable
{
    /// The current day's steps.
    var current: DateSteps?

    /// Whether or not the "met goal" notification was sent today.
    var sentMetGoalToday: Bool
    
    /// Whether or not the "25% through goal" notification was sent today.
    var sentMetPartGoalToday: Bool
}

extension ActivityNotificationsState
{
    /// An empty notifications state, to use as a default.
    static var empty: ActivityNotificationsState
    {
        return ActivityNotificationsState(current: nil, sentMetGoalToday: false, sentMetPartGoalToday: false)
    }
}

extension ActivityNotificationsState: Coding
{
    typealias Encoded = [String:Any]

    private static let currentKey = "current"
    private static let sentMetGoalKey = "sentMetGoal"
    private static let sentMetPartGoalKey = "sentPartGoal"

    static func decode(_ encoded: [String:Any]) throws -> ActivityNotificationsState
    {
        return try ActivityNotificationsState(
            current: DateSteps?.decode(any: encoded[currentKey]),
            sentMetGoalToday: encoded.decode(sentMetGoalKey),
            sentMetPartGoalToday: encoded.decode(sentMetPartGoalKey)
        )
    }

    var encoded: [String:Any]
    {
        return [
            ActivityNotificationsState.currentKey: current.encoded,
            ActivityNotificationsState.sentMetGoalKey: sentMetGoalToday,
            ActivityNotificationsState.sentMetPartGoalKey: sentMetPartGoalToday
        ]
    }
}

func ==(lhs: ActivityNotificationsState, rhs: ActivityNotificationsState) -> Bool
{
    return lhs.current == rhs.current
        && lhs.sentMetGoalToday == rhs.sentMetGoalToday
        && lhs.sentMetPartGoalToday == rhs.sentMetPartGoalToday
}

// MARK: - Activity Notifications
enum ActivityNotification: Equatable
{
    case metGoal(steps: Int)
    
    case metPartGoal
}

extension ActivityNotification
{
    /// Creates a local notification for the activity notification.
    ///
    /// - parameter calendar:    A calendar to use for determining the fire date.
    /// - parameter currentDate: The current date.
    func localNotification(calendar: Calendar, currentDate: Date) -> UILocalNotification
    {
        let notification = UILocalNotification()
        notification.userInfo = [activityNotificationKey: true]
        notification.soundName = UILocalNotificationDefaultSoundName

        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        func string(_ number: Int) -> String
        {
            return formatter.string(from: NSNumber(value: number)) ?? String(number)
        }

        switch self
        {
        case let .metGoal(steps):
            notification.alertBody = "You're a 💎 – you just hit your daily step goal, \(string(steps)) steps and counting!"
        case .metPartGoal:
            notification.alertBody = "You're about 25%% to your daily step goal, keep it up! 🏃‍♀️"
        }

        return notification
    }
}

func ==(lhs: ActivityNotification, rhs: ActivityNotification) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.metGoal(lhsSteps), .metGoal(rhsSteps)):
        return lhsSteps == rhsSteps
    case (.metPartGoal, .metPartGoal):
        return true
    default:
        return false
    }
}

extension LocalNotification
{
    @nonobjc var isActivityNotification: Bool
    {
        return userInfo?[activityNotificationKey] as? Bool ?? false
    }

    @nonobjc var isActivityReminderNotification: Bool
    {
        return userInfo?[activityReminderNotificationKey] as? Bool ?? false
    }
}

private let activityNotificationKey = "activityNotification"
private let activityReminderNotificationKey = "activityReminderNotification"

// MARK: - Reminder Notifications State
struct ActivityReminderNotificationsState: Equatable
{
    /// The dates at which notifications were scheduled.
    var scheduledDates: [Date]

    /// The dates at which "met goal" notifications were sent.
    var metGoalDates: [Date]
    
    /// The dates at which "25% of goal" notifications were sent.
    var metPartGoalDates: [Date]
}

extension ActivityReminderNotificationsState
{
    static var empty: ActivityReminderNotificationsState
    {
        return ActivityReminderNotificationsState(scheduledDates: [], metGoalDates: [], metPartGoalDates: [])
    }
}

func ==(lhs: ActivityReminderNotificationsState, rhs: ActivityReminderNotificationsState) -> Bool
{
    return lhs.scheduledDates == rhs.scheduledDates
        && lhs.metGoalDates == rhs.metGoalDates
        && lhs.metPartGoalDates == rhs.metPartGoalDates
}

extension ActivityReminderNotificationsState: Coding
{
    typealias Encoded = [String:Any]

    private static let scheduledDatesKey = "scheduledDates"
    private static let metGoalDatesKey = "metGoalDates"
    private static let metPartGoalDatesKey = "metPartGoalDates"

    static func decode(_ encoded: Encoded) throws -> ActivityReminderNotificationsState
    {
        return ActivityReminderNotificationsState(
            scheduledDates: try encoded.decode(scheduledDatesKey),
            metGoalDates: (try? encoded.decode(metGoalDatesKey)) ?? [], // allow migration
            metPartGoalDates: (try? encoded.decode(metPartGoalDatesKey)) ?? []
        )
    }

    var encoded: Encoded
    {
        return [
            ActivityReminderNotificationsState.scheduledDatesKey: scheduledDates as [NSDate],
            ActivityReminderNotificationsState.metGoalDatesKey: metGoalDates as [NSDate],
            ActivityReminderNotificationsState.metPartGoalDatesKey: metPartGoalDates as [NSDate]
        ]
    }
}

// MARK: - Local Notification Scheduling
protocol LocalNotificationScheduling
{
    func scheduleLocalNotification(_ notification: UILocalNotification)
    func cancelLocalNotification(_ notification: UILocalNotification)
    var scheduledLocalNotifications: [UILocalNotification]? { get }
}

extension UIApplication: LocalNotificationScheduling {}
