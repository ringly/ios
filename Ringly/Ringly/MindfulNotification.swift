import ReactiveSwift
import UIKit

// MARK: - Mindful Notifications

/// Enumerates the mindful notifications. These are scheduled daily if battery alerts are turned on.
enum MindfulNotification: String
{
    /// Daily meditation reminders.
    case sunday

    case monday
    
    case tuesday
    
    case wednesday
    
    case thursday
    
    case friday
    
    case saturday
}

extension MindfulNotification
{
    fileprivate var userInfoKey: String
    {
        return rawValue
    }
    
    /// An array of all mindful notifications.
    static var all: [MindfulNotification]
    {
        return [
            .sunday,
            .monday,
            .tuesday,
            .wednesday,
            .thursday,
            .friday,
            .saturday
        ]
    }

    var schedulingDays: Int
    {
        switch self
        {
        case .sunday:
            return 1
            
        case .monday:
            return 2
            
        case .tuesday:
            return 3
            
        case .wednesday:
            return 4
            
        case .thursday:
            return 5
            
        case .friday:
            return 6
            
        case .saturday:
            return 7
        }
    }
    
    func stateProperty(in mindfulPreference: Preferences.Mindful) -> MutableProperty<MindfulNotificationState>
    {
        switch self
        {
        case .sunday:
            return mindfulPreference.sundayState
            
        case .monday:
            return mindfulPreference.mondayState
            
        case .tuesday:
            return mindfulPreference.tuesdayState
            
        case .wednesday:
            return mindfulPreference.wednesdayState
            
        case .thursday:
            return mindfulPreference.thursdayState
            
        case .friday:
            return mindfulPreference.fridayState
            
        case .saturday:
            return mindfulPreference.saturdayState
        }
    }
}

enum MindfulNotificationState: String
{
    /// The notification has not been scheduled.
    case unscheduled
    
    /// The notification has been scheduled.
    case scheduled
}

// MARK: - Local Notification Extensions
extension UILocalNotification
{
    convenience init(mindfulNotification: MindfulNotification, fireDate: Date)
    {
        self.init()
        self.fireDate = fireDate
        self.repeatInterval = .weekOfYear
        self.userInfo = [mindfulNotification.userInfoKey: true]
        
        switch mindfulNotification
        {
        case .sunday:
            alertBody = "Sunday scaries? We get them too, take some time to meditate today and get ready for the week to come. Swipe to start."
            
        case .monday:
            alertBody = "Happy Monday, kick the week off by taking a few minutes to be mindful. Swipe to start!"
            
        case .tuesday:
            alertBody = "It's Tuesday, keep up your mindfulness momentum- take a few minutes for a meditation or breathing exercise."

        case .wednesday:
            alertBody = "Happy hump day, don't forget to treat yourself to some mindful minutes. Swipe to start one."
            
        case .thursday:
            alertBody = "Almost through the week, let's take a few minutes to breath and relax this Thursday. Swipe to start!"
            
        case .friday:
            alertBody = "TGIF, be sure to take a few mindful minutes to reflect and energize yourself for the weekend. Swipe to start."
            
        case .saturday:
            alertBody = "The weekends are a great time to recharge. Take a few minutes to breath or meditate. Swipe to start."
        }
    }
}

extension LocalNotification
{
    func isMindfulNotification(_ mindfulNotification: MindfulNotification) -> Bool
    {
        return userInfo?[mindfulNotification.userInfoKey] as? Bool ?? false
    }
}

