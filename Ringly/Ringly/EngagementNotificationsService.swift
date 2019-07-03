import Foundation
import ReactiveSwift
import HealthKit
import UIKit
import enum Result.NoError

/// A service that manages engagement notifications.
final class EngagementNotificationsService: NSObject
{
    fileprivate let cancelPipe = Signal<EngagementNotification, NoError>.pipe()
}

extension EngagementNotificationsService
{
    /// Cancels a notification.
    ///
    /// - Parameter notification: The notification to cancel.
    func cancel(_ notification: EngagementNotification)
    {
        cancelPipe.input.send(value: notification)
    }
    
    /// Determines the fire date for an engagement notification.
    ///
    /// - Parameters:
    ///   - days: The number of days after which the notification should fire.
    ///   - afterDate: The date to schedule the notification relative to use.
    ///   - calendar: The calendar to use for date calculations.
    ///   - notificationType: The engagement notification type, used to schedule breathing notification for afternoon
    /// - Returns: A notification fire date.
    static func notificationFireDate(days: Int, after afterDate: Date, in calendar: Calendar) -> Date
    {
        return calendar.date(byAdding: .day, value: days, to: afterDate).flatMap({ date -> Date? in
            // we need at least 12 hours in the day to inset the range correctly without overflowing
            guard
                let hourRange = calendar.range(of: .hour, in: .day, for: date),
                hourRange.count > 12
                else { return nil }
            
            // ensure that the notifcation is within the lower bound
            let insetRange = (hourRange.lowerBound + 8)...(hourRange.upperBound - 4)
            
            let hour = calendar.component(.hour, from: date)
            
            if insetRange.contains(hour)
            {
                return date
            }
            else if hour < insetRange.lowerBound
            {
                return calendar.date(bySetting: .hour, value: insetRange.lowerBound, of: date)
            }
            else
            {
                var components = calendar.dateComponents([.era, .year, .month, .day, .hour], from: date)
                components.day = components.day.map({ $0 + 1 })
                components.hour = 15 //schedule notifications for the afternoon
                return calendar.date(from: components)
            }
        }) ?? afterDate.addingTimeInterval(60 * 60 * 24 * TimeInterval(days))
    }
    
    /// Determines the fire date for an engagement notification for DEBUG.
    ///
    /// - Parameters:
    ///   - minutes: The number of minutes after which the notification should fire.
    ///   - afterDate: The date to schedule the notification relative to use.
    ///   - calendar: The calendar to use for date calculations.
    /// - Returns: A notification fire date.
    static func notificationFireDate(minutes: Int, after afterDate: Date, in calendar: Calendar) -> Date
    {
        return calendar.date(byAdding: .minute, value: minutes, to: afterDate).flatMap({ date -> Date? in
            // we need at least 12 hours in the day to inset the range correctly without overflowing
            guard
                let hourRange = calendar.range(of: .hour, in: .day, for: date),
                hourRange.count > 12
                else { return nil }
            
            // ensure that the notifcation is within the lower bound
            let insetRange = (hourRange.lowerBound + 8)...(hourRange.upperBound - 4)
            
            let hour = calendar.component(.hour, from: date)
            
            if insetRange.contains(hour)
            {
                return date
            }
            else if hour < insetRange.lowerBound
            {
                return calendar.date(bySetting: .hour, value: insetRange.lowerBound, of: date)
            }
            else
            {
                var components = calendar.dateComponents([.era, .year, .month, .day, .hour], from: date)
                components.minute = components.minute.map({ $0 + 1 })
                components.hour = insetRange.lowerBound
                return calendar.date(from: components)
            }
        }) ?? afterDate.addingTimeInterval(60 * TimeInterval(minutes))
    }
}

extension Reactive where Base: EngagementNotificationsService
{
    // MARK: - Scheduling Initial Pair Notifications
    
    /// A producer that, once started, will schedule and cancel all initial pair notifications.
    ///
    /// - Parameters:
    ///   - peripheralCountProducer: A producer for the current number of peripherals paired. This notification will be
    ///                              scheduled when the number of peripherals changes from 0 to 1.
    ///   - stepGoalProducer: A producer for the user's step goal. This is used in the "step goal encouragement"
    ///                       notification, but is required for all notifications.
    ///   - preferences: A preferences store containing engagement properties.
    func manageAllInitialPairNotifications(peripheralCountProducer: SignalProducer<Int, NoError>,
                                           stepGoalProducer: SignalProducer<Int, NoError>,
                                           preferences: Preferences.Engagement)
        -> SignalProducer<(), NoError>
    {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.autoupdatingCurrent
        
        return SignalProducer.merge(EngagementNotification.all.map({ notification in
            manageInitialPairNotification(
                notification: notification,
                dateScheduler: QueueScheduler.main,
                determineFireDate: { currentDate in
                    EngagementNotificationsService.notificationFireDate(
                        days: notification.schedulingDays,
                        after: currentDate,
                        in: calendar
                    )
            },
                notificationScheduler: UIApplication.shared,
                peripheralCountProducer: peripheralCountProducer,
                stepGoalProducer: stepGoalProducer,
                stateProperty: notification.stateProperty(in: preferences)
            )
        }))
    }
    
    /// A producer that, once started, will schedule and cancel all initial pair notifications for DEBUG.
    ///
    /// - Parameters:
    ///   - stepGoalProducer: A producer for the user's step goal. This is used in the "step goal encouragement"
    ///                       notification, but is required for all notifications.
    ///   - preferences: A preferences store containing engagement properties.
    func manageAllInitialPairNotificationsDebug(stepGoalProducer: SignalProducer<Int, NoError>,
                                                preferences: Preferences.Engagement)
        -> SignalProducer<(), NoError>
    {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.autoupdatingCurrent
        
        return SignalProducer.merge(EngagementNotification.all.map({ notification in
            scheduleInitialPairNotificationDebug(
                notification: notification,
                dateScheduler: QueueScheduler.main,
                determineFireDate: { currentDate in
                    EngagementNotificationsService.notificationFireDate(
                        minutes: notification.schedulingDays,
                        after: currentDate,
                        in: calendar
                    )
            },
                notificationScheduler: UIApplication.shared,
                stepGoalProducer: stepGoalProducer,
                stateProperty: notification.stateProperty(in: preferences)
            )
        }))
    }

    /// A producer that, once started, will schedule and cancel notifications after an initial peripheral pair.
    ///
    /// - Parameters:
    ///   - notification: The engagement notification to schedule.
    ///   - dateScheduler: A date scheduler for obtaining the current date.
    ///   - determineFireDate: A function that will receive the current date, and should return the fire date for the
    ///                        notification.
    ///   - notificationScheduler: A notification scheduler.
    ///   - peripheralCountProducer: A producer for the current number of peripherals paired. This notification will be
    ///                              scheduled when the number of peripherals changes from 0 to 1.
    ///   - stepGoalProducer: A producer for the user's step goal. This is used in the "step goal encouragement"
    ///                       notification, but is required for all notifications.
    ///   - stateProperty: A property to store the state of the notification in. This will be modified when the
    ///                    notification is scheduled or cancelled.
    func manageInitialPairNotification(notification: EngagementNotification,
                                       dateScheduler: DateSchedulerProtocol,
                                       determineFireDate: @escaping (Date) -> (Date),
                                       notificationScheduler: LocalNotificationScheduling,
                                       peripheralCountProducer: SignalProducer<Int, NoError>,
                                       stepGoalProducer: SignalProducer<Int, NoError>,
                                       stateProperty: MutableProperty<EngagementNotificationState>)
        -> SignalProducer<(), NoError>
    {
        return SignalProducer.merge(
            cancelInitialPairNotification(
                notification: notification,
                notificationScheduler: notificationScheduler,
                peripheralCountProducer: peripheralCountProducer,
                stateProperty: stateProperty
            ),
            
            scheduleInitialPairNotification(
                notification: notification,
                dateScheduler: dateScheduler,
                determineFireDate: determineFireDate,
                notificationScheduler: notificationScheduler,
                peripheralCountProducer: peripheralCountProducer,
                stepGoalProducer: stepGoalProducer,
                stateProperty: stateProperty
            )
        )
    }
    
    /// A producer that, once started, will schedule notifications after an initial peripheral pair.
    ///
    /// - Parameters:
    ///   - notification: The engagement notification to schedule.
    ///   - dateScheduler: A date scheduler for obtaining the current date.
    ///   - determineFireDate: A function that will receive the current date, and should return the fire date for the
    ///                        notification.
    ///   - notificationScheduler: A notification scheduler.
    ///   - peripheralCountProducer: A producer for the current number of peripherals paired. This notification will be
    ///                              scheduled when the number of peripherals changes from 0 to 1.
    ///   - stepGoalProducer: A producer for the user's step goal. This is used in the "step goal encouragement"
    ///                       notification, but is required for all notifications.
    ///   - stateProperty: A property to store the state of the notification in. This will be modified when the
    ///                    notification is scheduled or cancelled.
    fileprivate func scheduleInitialPairNotification(notification: EngagementNotification,
                                                     dateScheduler: DateSchedulerProtocol,
                                                     determineFireDate: @escaping (Date) -> (Date),
                                                     notificationScheduler: LocalNotificationScheduling,
                                                     peripheralCountProducer: SignalProducer<Int, NoError>,
                                                     stepGoalProducer: SignalProducer<Int, NoError>,
                                                     stateProperty: MutableProperty<EngagementNotificationState>)
        -> SignalProducer<(), NoError>
    {
        // when the number of peripherals becomes 1 from 0
        let scheduleTrigger = peripheralCountProducer.combinePrevious()
            .filter({ $0 == 0 && $1 != 0 })
            .take(first: 1) // only the first transition is applicable
        
        // schedule the notification if it is currently unscheduled
        return stepGoalProducer.sample(on: scheduleTrigger.void).on(value: { stepGoal in
            stateProperty.modify({ state in
                guard state == .unscheduled else { return }
                
                let notification = UILocalNotification(
                    engagementNotification: notification,
                    fireDate: determineFireDate(dateScheduler.currentDate),
                    stepGoal: stepGoal
                )
                notification.soundName = UILocalNotificationDefaultSoundName
                notificationScheduler.scheduleLocalNotification(notification)
                SLogAppleNotifications("Scheduled engagement notification: \(notification)")
                
                state = .scheduled
            })
        }).ignoreValues().take(until: lifetime.ended)
    }
    
    /// A producer that, once started, will schedule notifications after reseting in DEBUG.
    ///
    /// - Parameters:
    ///   - notification: The engagement notification to schedule.
    ///   - dateScheduler: A date scheduler for obtaining the current date.
    ///   - determineFireDate: A function that will receive the current date, and should return the fire date for the
    ///                        notification.
    ///   - notificationScheduler: A notification scheduler.
    ///   - stepGoalProducer: A producer for the user's step goal. This is used in the "step goal encouragement"
    ///                       notification, but is required for all notifications.
    ///   - stateProperty: A property to store the state of the notification in. This will be modified when the
    ///                    notification is scheduled or cancelled.
    fileprivate func scheduleInitialPairNotificationDebug(notification: EngagementNotification,
                                                     dateScheduler: DateSchedulerProtocol,
                                                     determineFireDate: @escaping (Date) -> (Date),
                                                     notificationScheduler: LocalNotificationScheduling,
                                                     stepGoalProducer: SignalProducer<Int, NoError>,
                                                     stateProperty: MutableProperty<EngagementNotificationState>)
        -> SignalProducer<(), NoError>
    {
        // schedule the notification if it is currently unscheduled
        return stepGoalProducer.on(value: { stepGoal in
            stateProperty.modify({ state in
                guard state == .unscheduled else { return }
                
                let notification = UILocalNotification(
                    engagementNotification: notification,
                    fireDate: determineFireDate(dateScheduler.currentDate),
                    stepGoal: stepGoal
                )
                notification.soundName = UILocalNotificationDefaultSoundName
                notificationScheduler.scheduleLocalNotification(notification)
                SLogAppleNotifications("Scheduled engagement notification: \(notification)")
                
                state = .scheduled
            })
        }).ignoreValues().take(until: lifetime.ended)
    }
    
    /// A producer that, once started, will cancel notifications to be scheduled after an initial peripheral pair.
    ///
    /// - Parameters:
    ///   - notification: The engagement notification to schedule.
    ///   - notificationScheduler: A notification scheduler.
    ///   - peripheralCountProducer: A producer for the current number of peripherals paired. This notification will be
    ///                              scheduled when the number of peripherals changes from 0 to 1.
    ///   - stateProperty: A property to store the state of the notification in. This will be modified when the
    ///                    notification is scheduled or cancelled.
    fileprivate func cancelInitialPairNotification(notification: EngagementNotification,
                                                   notificationScheduler: LocalNotificationScheduling,
                                                   peripheralCountProducer: SignalProducer<Int, NoError>,
                                                   stateProperty: MutableProperty<EngagementNotificationState>)
        -> SignalProducer<(), NoError>
    {
        // if there are already peripherals registered when started, do not ever schedule the notification
        let cancelIfUnscheduledTrigger = peripheralCountProducer.take(first: 1).filter({ $0 > 0 })
        
        // cancel whenever a client directly requests it
        let cancelTrigger = SignalProducer(base.cancelPipe.output).filter({ $0 == notification })
        
        return SignalProducer.merge(
            // when a cancel trigger fires, cancel the notifications and modify the state
            cancelIfUnscheduledTrigger.on(value: { _ in
                stateProperty.modify({ state in
                    if state == .unscheduled
                    {
                        state = .cancelled
                    }
                })
            }).ignoreValues(),
            
            cancelTrigger.on(value: { _ in
                stateProperty.value = .cancelled
                notificationScheduler.cancelEngagementNotifications(notification)
            }).ignoreValues()
            ).take(until: lifetime.ended)
    }
}

extension LocalNotificationScheduling
{
    fileprivate func cancelNotifications(matching: (UILocalNotification) -> Bool)
    {
        scheduledLocalNotifications?.filter(matching).forEach({ notification in
            cancelLocalNotification(notification)
            SLogAppleNotifications("Cancelled engagement notification \(notification)")
        })
    }
    
    func cancelEngagementNotifications(_ engagementNotification: EngagementNotification)
    {
        cancelNotifications(matching: { $0.isEngagementNotification(engagementNotification) })
    }
}
