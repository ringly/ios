import Foundation

enum AnalyticsScreen: String, AnalyticsPropertyValueType
{
    case profile = "Profile"
    case connection = "Connection"
    case notifications = "Notifications"
    case contacts = "Contacts"
    case share = "Share"
    case developer = "Developer"
    case help = "Help"
    case legal = "Legal"
    case cantConnect = "Can't Connect"
    case loginWall = "Login Wall"
    case login = "Login"
    case register = "Register"
    case forgotPassword = "Forgot Password"
    case resetPassword = "Reset Password"
    case selfie = "Selfie"
    case mindfulness = "Mindfulness"
    case mindfulnessSettings = "Mindfulness Settings"
}

enum AnalyticsTrigger: String, AnalyticsPropertyValueType
{
    case peripheral = "peripheral"
    case uiButton = "ui button"
}

enum AnalyticsSticker: String, AnalyticsPropertyValueType
{
    case rLogo = "R Logo"
    case ringly = "Ringly"
    case gem = "Gem"
}

enum AnalyticsSetting: String, AnalyticsPropertyValueType
{
    case connectionTaps = "Connection Taps"
    case outOfRange = "Out of Range"
    case sleepMode = "Sleep Mode"
    case innerRing = "Inner Ring"
    case batteryAlerts = "Battery Alerts"
    case dailyReminders = "Daily Reminders"
    case dailyStepSummary = "Daily Step Summary"
    case activityEncouragement = "Activity Encouragement"
}

enum AnalyticsShareService: String, AnalyticsPropertyValueType
{
    case facebook = "Facebook"
    case pinterest = "Pinterest"
    case sms = "SMS"
    case email = "Email"
}

enum AnalyticsNotificationsPermissionResult: String, AnalyticsPropertyValueType
{
    case accepted = "Accepted"
    case denied = "Denied"
    case cancelled = "Cancelled"
}

/// Enumerates analytics in a type and nil-safe manner.
enum AnalyticsEvent: AnalyticsEventType
{
    case viewedScreen(name: AnalyticsScreen)
    case disabledNotification(name: String)
    case disabledContact
    case changedSetting(setting: AnalyticsSetting, value: Bool)
    case shareServiceTapped(service: AnalyticsShareService)
    case shareRedeemTapped
    case profileEditShown
    case profileSaved
    case applicationError(error: NSError)
    
    case notificationsRequested
    case notificationsCompleted(accepted: Bool)

    case onboardingShown
    case onboardingCompleted
    
    case selfieSnap(trigger: AnalyticsTrigger)
    case selfieDemoComplete(trigger: AnalyticsTrigger)
    case selfieAddSticker(sticker: AnalyticsSticker)
    case selfieShareOpen
    case selfieShareComplete(type: UIActivityType?)
    
    case breathingIntro
    case breathingStarted(totalMinutes: Int)
    case breathingCompleted(totalMinutes: Int)
    case breathingAbandoned(minutesCompleted: Int, totalMinutes: Int)
    
    case guidedAudioIntro(title: String, totalMinutes: Int)
    case guidedAudioStarted(title: String, totalMinutes: Int)
    case guidedAudioCompleted(title: String, totalMinutes: Int)
    case guidedAudioAbandoned(title: String, minutesCompleted: Int, totalMinutes: Int)
    
    case mindfulRemindersEnabled(source: String, enabled: Bool)
    case mindfulReminderAlertOpened
    case mindfulOverlayShown
    case mindfulEventSavedToHealth
    
    case notificationsPermission(AnalyticsNotificationsPermissionResult)

    var name: String
    {
        switch self
        {
        case .viewedScreen:
            return kAnalyticsViewedScreen
        case .disabledNotification:
            return Notification.Name.analyticsDisabled.rawValue
        case .disabledContact:
            return kAnalyticsDisabledContact
        case .changedSetting:
            return kAnalyticsChangedSetting
        case .shareServiceTapped:
            return kAnalyticsShareServiceTapped
        case .shareRedeemTapped:
            return kAnalyticsShareRedeemTapped
        case .profileEditShown:
            return kAnalyticsProfileEditShown
        case .profileSaved:
            return kAnalyticsProfileSaved
        case .applicationError:
            return kAnalyticsApplicationError
        case .notificationsRequested:
            return kAnalyticsNotificationsRequested
        case .notificationsCompleted:
            return kAnalyticsNotificationsCompleted
        case .onboardingShown:
            return "Onboarding Shown"
        case .onboardingCompleted:
            return "Onboarding Completed"
        case .notificationsPermission:
            return "Notifications Permission"
        case .selfieSnap:
            return "Selfie Snap"
        case .selfieDemoComplete:
            return "Selfie Demo Complete"
        case .selfieAddSticker:
            return "Selfie Add Sticker"
        case .selfieShareOpen:
            return "Selfie Share Open"
        case .selfieShareComplete:
            return "Selfie Share Complete"
        case .breathingIntro:
            return "Breathing Exercise Intro"
        case .breathingStarted:
            return "Breathing Exercise Started"
        case .breathingCompleted:
            return "Breathing Exercise Completed"
        case .breathingAbandoned:
            return "Breathing Exercise Abandoned"
        case .guidedAudioIntro:
            return "Guided Audio Intro"
        case .guidedAudioStarted:
            return "Guided Audio Started"
        case .guidedAudioCompleted:
            return "Guided Audio Completed"
        case .guidedAudioAbandoned:
            return "Guided Audio Abandoned"
        case .mindfulRemindersEnabled:
            return "Mindful Reminders Enabled"
        case .mindfulReminderAlertOpened:
            return "Mindful Reminder Alert Opened"
        case .mindfulOverlayShown:
            return "Mindful Overlay Shown"
        case .mindfulEventSavedToHealth:
            return "Mindfulness Session Saved to HealthKit"
        }
    }
    
    var properties: [String:AnalyticsPropertyValueType]
    {
        switch self
        {
        case .viewedScreen(let screen):
            return [kAnalyticsPropertyName: screen.rawValue]
            
        case .disabledNotification(let name):
            return [kAnalyticsPropertyName: name]
            
        case .changedSetting(let setting, let value):
            return [kAnalyticsPropertyName: setting.rawValue, "Value": value]
            
        case .shareServiceTapped(let service):
            return [kAnalyticsPropertyService: service.rawValue]
            
        case .applicationError(let error):
            return [
                kAnalyticsPropertyDomain: error.domain,
                kAnalyticsPropertyCode: "\(error.code)"
            ]
            
        case .notificationsCompleted(let accepted):
            return [
                kAnalyticsPropertyAccepted: accepted
            ]

        case .notificationsPermission(let result):
            return ["Result": result.rawValue]
        
        case .selfieDemoComplete(let trigger):
            return ["Trigger": trigger]
            
        case .selfieSnap(let trigger):
            return ["Trigger": trigger]
            
        case .selfieAddSticker(let sticker):
            return ["Sticker": sticker]
            
        case .selfieShareComplete(let type):
            if let type = type {
                return ["Type": type]
            } else {
                return [:]
            }
        case .breathingStarted(let totalMinutes):
            return ["TotalMinutes": totalMinutes]
        case .breathingCompleted(let totalMinutes):
            return ["TotalMinutes": totalMinutes]
        case .breathingAbandoned(let minutesCompleted, let totalMinutes):
            return ["TotalMinutes": totalMinutes, "MinutesCompleted": minutesCompleted]
            
        case .guidedAudioIntro(let title, let totalMinutes):
            return ["Title": title, "TotalMinutes": totalMinutes]
        case .guidedAudioStarted(let title, let totalMinutes):
            return ["Title": title, "TotalMinutes": totalMinutes]
        case .guidedAudioCompleted(let title, let totalMinutes):
            return ["Title": title, "TotalMinutes": totalMinutes]
        case .guidedAudioAbandoned(let title, let minutesCompleted, let totalMinutes):
            return ["Title": title, "MinutesCompleted": minutesCompleted, "TotalMinutes": totalMinutes]
            
        case .mindfulRemindersEnabled(let source, let enabled):
            return ["From": source, "MindfulRemindersEnabled": enabled]
            
        default:
            return [:]
        }
    }
}

extension UIActivityType: AnalyticsPropertyValueType
{
    var analyticsString: String {
        return self.rawValue
    }
}
