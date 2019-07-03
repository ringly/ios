import ReactiveSwift
import UIKit

// MARK: - Engagement Notifications

/// Enumerates the engagement notifications. These are scheduled eagerly, then cancelled when the conditions for
/// delivering them are no longer met.
enum EngagementNotification: String
{
    /// The prompt to add or remove an application.
    case addRemoveApplications
    
    /// The prompt to edit an application's behavior (color or vibration).
    case editApplicationBehavior
    
    /// The user is prompted to set up activity tracking.
    case setUpActivity
    
    /// The user is encouraged to stay hydrated.
    case stayHydrated
    
    /// The user is encouraged to meet her step goal.
    case stepGoalEncouragement
    
    /// The user is encouraged to try a breathing exercise.
    case startedBreather
    
    /// The user is encouraged to try a meditation program.
    case startedMeditation
}

extension EngagementNotification
{
    fileprivate var userInfoKey: String
    {
        return rawValue
    }
    
    /// An array of all engagement notifications.
    static var all: [EngagementNotification]
    {
        return [
            .addRemoveApplications,
            .editApplicationBehavior,
            .setUpActivity,
            .stayHydrated,
            .stepGoalEncouragement,
            .startedBreather,
            .startedMeditation
        ]
    }
    
    /// The state property in which to store the notification's state.
    ///
    /// - Parameter engagementPreferences: The engagement preferences store.
    func stateProperty(in engagementPreferences: Preferences.Engagement) -> MutableProperty<EngagementNotificationState>
    {
        switch self
        {
        case .addRemoveApplications:
            return engagementPreferences.addRemoveApplicationsState
            
        case .editApplicationBehavior:
            return engagementPreferences.editApplicationBehaviorState
            
        case .setUpActivity:
            return engagementPreferences.setUpActivityState
            
        case .stayHydrated:
            return engagementPreferences.stayHydratedState
            
        case .stepGoalEncouragement:
            return engagementPreferences.stepGoalEncouragementState
            
        case .startedBreather:
            return engagementPreferences.startedBreatherState
            
        case .startedMeditation:
            return engagementPreferences.startedMeditationState
        }
    }
    
    /// The number of days after which to schedule the notification.
    var schedulingDays: Int
    {
        switch self
        {
        case .addRemoveApplications:
            return 7

        case .editApplicationBehavior:
            return 1

        case .setUpActivity:
            return 3

        case .stayHydrated:
            return 12

        case .stepGoalEncouragement:
            return 15
            
        case .startedBreather:
            return 5
            
        case .startedMeditation:
            return 9
        }
    }
}

// MARK: - State

/// Describes the state of an engagement notification.
enum EngagementNotificationState: String
{
    /// The notification has not been scheduled.
    case unscheduled
    
    /// The notification has been scheduled.
    case scheduled
    
    /// The notification has been cancelled.
    case cancelled
}

// MARK: - Local Notification Extensions
extension UILocalNotification
{
    convenience init(engagementNotification: EngagementNotification, fireDate: Date, stepGoal: Int = 0)
    {
        self.init()
        self.fireDate = fireDate
        self.userInfo = [engagementNotification.userInfoKey: true]
        
        switch engagementNotification
        {
        case .editApplicationBehavior:
            alertAction = tr(.engagementEditApplicationBehaviorAlertAction)
            alertBody = tr(.engagementEditApplicationBehaviorAlertBody)
            
        case .addRemoveApplications:
            alertAction = tr(.engagementAddRemoveApplicationsAlertAction)
            alertBody = tr(.engagementAddRemoveApplicationsAlertBody)
            
        case .setUpActivity:
            alertAction = tr(.engagementSetUpActivityAlertAction)
            alertBody = tr(.engagementSetUpActivityAlertBody)
            
        case .stayHydrated:
            alertBody = tr(.engagementStayHydratedAlertBody)
            
        case .stepGoalEncouragement:
            let formatter = NumberFormatter()
            formatter.usesGroupingSeparator = true
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            
            let string = formatter.string(from: NSNumber(value: stepGoal)) ?? String(stepGoal)
            alertBody = tr(.engagementStepGoalEncouragementAlertBody(string))

        case .startedBreather:
            alertBody = tr(.engagementStartedBreatherAlertBody)
            
        case .startedMeditation:
            alertBody = tr(.engagementStartedMeditationAlertBody)
            
        }
    }
}

extension LocalNotification
{
    func isEngagementNotification(_ engagementNotification: EngagementNotification) -> Bool
    {
        return userInfo?[engagementNotification.userInfoKey] as? Bool ?? false
    }
}

