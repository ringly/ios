import Foundation
import ReactiveSwift
import HealthKit
import UIKit
import enum Result.NoError

/// A service that manages mindful notifications.
final class MindfulNotificationsService: NSObject
{
    /// Determines the fire date for an mindful notification.
    ///
    /// - Parameters:
    ///   - weekday: The weekday to schedule the notification for.
    ///   - afterDate: The date to schedule the notification relative to use.
    ///   - calendar: The calendar to use for date calculations.
    ///   - preferences: Preferences.
    /// - Returns: A notification fire date.
    static func notificationFireDate(weekday: Int, afterDate: Date, calendar: Calendar, reminderTime: DateComponents) -> Date?
    {
        let preferredTime = reminderTime
        
        var components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .weekday], from: afterDate)
        if components.hour! < preferredTime.hour! && components.minute! < preferredTime.minute!
        {
            // schedule the reminder to start the next day
            components.day = components.day.map({ $0 + 1 })
            components.weekday = components.weekday.map({ $0 + 1 })
        }
        
        // adjust day to fire to match notification day message
        for day in 0...6
        {
            let date = afterDate.addingTimeInterval(Double(day) * 86400.0)
            var dateComponents = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .weekday], from: date)
            if dateComponents.weekday == weekday
            {
                dateComponents.hour = preferredTime.hour
                dateComponents.minute = preferredTime.minute
                dateComponents.weekday = weekday
                return calendar.date(from: dateComponents)
            }
        }
        return nil
    }
}

extension Reactive where Base: MindfulNotificationsService
{
    // MARK: - Scheduling Initial Pair Notifications

    /// A producer that, once started, will schedule mindful notifications
    ///
    /// - Parameters:
    ///   - preferences: A preferences store containing mindful properties.
    func scheduleMindfulNotifications(preferences: Preferences)
    {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.autoupdatingCurrent

        preferences.mindfulRemindersEnabled.producer
            .combineLatest(with: preferences.mindfulReminderTime.producer.debounce(2, on: QueueScheduler.main))
            .startWithValues({ current, time in
                for notification in MindfulNotification.all
                {
                    UIApplication.shared.cancelMindfulNotifications(notification)
                    notification.stateProperty(in: preferences.mindful).value = .unscheduled
                }
                if current
                {
                    for notification in MindfulNotification.all
                    {
                        notification.stateProperty(in: preferences.mindful).modify({ state in
                            guard state == .unscheduled else { return }

                            let notification = UILocalNotification(
                                mindfulNotification: notification,
                                fireDate: MindfulNotificationsService.notificationFireDate(
                                        weekday: notification.schedulingDays,
                                        afterDate: QueueScheduler.main.currentDate,
                                        calendar: calendar,
                                        reminderTime: time)!
                            )

                            UIApplication.shared.scheduleLocalNotification(notification)
                            SLogAppleNotifications("Scheduled mindful notification \(notification)")
                            
                            state = .scheduled
                        })
                    }
                }
            })
    }
}

extension LocalNotificationScheduling
{
    fileprivate func cancelNotifications(matching: (UILocalNotification) -> Bool)
    {
        scheduledLocalNotifications?.filter(matching).forEach({ notification in
            cancelLocalNotification(notification)
            SLogAppleNotifications("Cancelled mindful notification \(notification)")
        })
    }
    
    func cancelMindfulNotifications(_ mindfulNotification: MindfulNotification)
    {
        cancelNotifications(matching: { $0.isMindfulNotification(mindfulNotification) })
    }
}


