import Foundation
import ReactiveSwift
import RinglyAPI

/// A wrapper class for `NSUserDefaults`, exposing ReactiveCocoa properties to Swift.
///
/// Objective-C bridging `...Value` and `...Signal` properties should be added as necessary.
final class Preferences: NSObject
{
    // MARK: - Initialization
    init(backing: PreferencesBackingType)
    {
        // perform migration for connection taps
        backing.migrateConnectionTapsSetting()

        // sub-preferences
        engagement = Engagement(backing: backing)
        mindful = Mindful(backing: backing)

        // API
        authentication = MutableProperty(
            backing: backing,
            key: "APISessionDictionary_1",
            defaultValue: Authentication(user: nil, token: nil, server: .production),
            makeBridge: PropertyListBridge.coding
        )

        registeredRingNames = MutableProperty(
            backing: backing,
            key: "RegisteredRingNames",
            defaultValue: [],
            makeBridge: PropertyListBridge.cast
        )

        lastAuthenticatedEmail = MutableProperty(
            backing: backing,
            key: "LastAuthenticatedEmail",
            defaultValue: nil,
            makeBridge: PropertyListBridge.cast
        )
        
        // Bluetooth
        savedPeripheral = MutableProperty(
            backing: backing,
            key: "BluetoothSavedPeripheral",
            makeBridge: PropertyListBridge.optionalCoding
        )

        savedPeripherals = MutableProperty(
            backing: backing,
            key: "BluetoothSavedPeripherals",
            defaultValue: [],
            makeBridge: PropertyListBridge.arrayCoding
        )

        activatedPeripheralIdentifier = MutableProperty(
            backing: backing,
            key: "ActivatedPeripheralIdentifier",
            makeBridge: PropertyListBridge.optionalCoding
        )
        
        deviceInRecovery = MutableProperty(
            backing: backing,
            key: "DeviceInRecovery",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Developer
        #if DEBUG || FUTURE
        developerModeEnabled = MutableProperty(
            backing: backing,
            key: "DeveloperMode",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        launchNotificationsEnabled = MutableProperty(
            backing: backing,
            key: "RINGLY_DEBUG_LaunchNotificationsEnabled",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        developerCurrentDayStepsNotifications = MutableProperty(
            backing: backing,
            key: "RINGLY_DEBUG_developerCurrentDayStepsNotifications",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        #endif

        // Analytics
        backgroundMixpanelEventCount = MutableProperty(
            backing: backing,
            key: "BackgroundMixpanelEventCount",
            defaultValue: 0,
            makeBridge: PropertyListBridge.cast
        )
        
        // Preferences
        sleepMode = MutableProperty(
            backing: backing,
            key: "SleepRing_2",
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )

        disconnectVibrations = MutableProperty(
            backing: backing,
            key: "DisconnectVibeMode",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        innerRing = MutableProperty(
            backing: backing,
            key: "InnerRing",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        #if DEBUG || FUTURE
        ANCSTimeout = MutableProperty(
            backing: backing,
            key: "ANCSTimeoutEnabled",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        simulatedScreenSize = MutableProperty(
            backing: backing,
            key: "SimulatedScreenSize",
            bridge: PropertyListBridge(
                from: { any in
                    guard let dict = any as? [String:CGFloat], let width = dict["width"], let height = dict["height"]
                        else { return nil }

                    return CGSize(width: width, height: height)
                },
                to: { optional in
                    optional.map({ ["width": $0.width, "height": $0.height] }) as Any
                }
            )
        )
        #endif

        connectionTaps = MutableProperty(
            backing: backing,
            key: Preferences.connectionTapsKey,
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        notificationsEnabled = MutableProperty(
            backing: backing,
            key: "NotificationAlertsEnabled",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Low Battery
        batteryAlertsEnabled = MutableProperty(
            backing: backing,
            key: "LowBatteryWarningEnabled",
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )

        batteryAlertsBacking = MutableProperty(
            backing: backing,
            key: "BatteryAlertsBacking",
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )
        lowBatterySentIdentifiers = MutableProperty(
            backing: backing,
            key: "LowBatteryWarningSentIdentifiers",
            bridge: PropertyListBridge.arrayCoding()
        )

        fullBatterySentIdentifiers = MutableProperty(
            backing: backing,
            key: "FullBatteryWarningSentIdentifiers",
            bridge: PropertyListBridge.arrayCoding()
        )

        fullBatteryLastSent = MutableProperty(
            backing: backing,
            key: "FullBatteryLastSent",
            defaultValue: nil,
            makeBridge: PropertyListBridge.cast
        )
        
        chargeBatterySentIdentifiers = MutableProperty(
            backing: backing,
            key: "ChargeBatteryWarningSentIdentifiers",
            bridge: PropertyListBridge.arrayCoding()
        )
        
        chargeNotificationState = MutableProperty(
            backing: backing,
            key: "ChargeNotificationState",
            defaultValue: .unscheduled,
            makeBridge: PropertyListBridge.raw
        )
        
        // Migrations
        emailMigrationPerformed = MutableProperty(
            backing: backing,
            key: "EmailMigrationPerformed",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        mindfulnessMigrationPerformed = MutableProperty(
            backing: backing,
            key: "MindfulnessMigrationPerformed",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Onboarding
        onboardingShown = MutableProperty(
            backing: backing,
            key: Preferences.onboardingShownKey,
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Camera Onboarding
        cameraOnboardingShown = MutableProperty(
            backing: backing,
            key: Preferences.cameraOnboardingShownKey,
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Breathing should buzz
        breathingExerciseShouldBuzz = MutableProperty(
            backing: backing,
            key: Preferences.breathingExerciseShouldBuzzKey,
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )

        applicationsOnboardingState = MutableProperty(
            backing: backing,
            key: "ApplicationsOnboardingShown",
            defaultValue: .overlay,
            makeBridge: PropertyListBridge.raw
        )

        // Interface
        lastTabSelected = MutableProperty(
            backing: backing,
            key: "LastTabSelected",
            bridge: PropertyListBridge.optionalRaw()
        )
        
        // Notifications View
        alertViewEnabled = MutableProperty(
            backing: backing,
            key: "NotificationViewOn",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        presentedActivityUnsupportedAlert = MutableProperty(
            backing: backing,
            key: "PresentedActivityUnsupportedAlert",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        // Activity Tracking
        activityTrackingBodyMass = MutableProperty(
            backing: backing,
            key: "ActivityTrackingBodyMass",
            makeBridge: PropertyListBridge.optionalCoding
        )

        activityTrackingHeight = MutableProperty(
            backing: backing,
            key: "ActivityTrackingHeight",
            makeBridge: PropertyListBridge.optionalCoding
        )

        activityTrackingBirthDateComponents = MutableProperty(
            backing: backing,
            key: "activityTrackingBirthDateComponents",
            makeBridge: PropertyListBridge.optionalCoding
        )

        activityTrackingStepsGoal = MutableProperty(
            backing: backing,
            key: "ActivityTrackingStepsGoal",
            defaultValue: 10000,
            makeBridge: PropertyListBridge.cast
        )
        
        activityTrackingMindfulnessReminderTime = MutableProperty(
            backing: backing,
            key: "activityTrackingMindfulnessReminderTime",
            makeBridge: PropertyListBridge.optionalCoding
        )
        
        activityTrackingMindfulnessGoal = MutableProperty(
            backing: backing,
            key: "ActivityTrackingMindfulnessGoal",
            defaultValue: 5,
            makeBridge: PropertyListBridge.cast
        )

        activityTrackingHourlyStepsGoal = MutableProperty(
            backing: backing,
            key: "ActivityTrackingHourlyStepsGoal",
            defaultValue: 250,
            makeBridge: PropertyListBridge.cast
        )
        
        activityTrackingMindfulnessOnboardingSet = MutableProperty(
            backing: backing,
            key: "ActivityTrackingMindfulnessOnboardingSet",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        activityEncouragementEnabled = MutableProperty(
            backing: backing,
            key: "ActivityEncouragementEnabled",
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )
        
        activityEncouragementBacking = MutableProperty(
            backing: backing,
            key: "ActivityEncouragementBacking",
            defaultValue: true,
            makeBridge: PropertyListBridge.cast
        )

        activityTrackingDailyHourGoal = MutableProperty(
            backing: backing,
            key: "ActivityTrackingDailyHourGoal",
            defaultValue: 9,
            makeBridge: PropertyListBridge.cast
        )
        
        motorPower = MutableProperty(
            backing: backing,
            key: "MindfulnessMotorPower",
            defaultValue: 125,
            makeBridge: PropertyListBridge.cast
        )
        
        breathingVibrationStyle = MutableProperty(
            backing: backing,
            key: "BreathingVibrationStyle",
            defaultValue: BreathingVibrationStyle.heavy.rawValue,
            makeBridge: PropertyListBridge.cast
        )

        activityEventLastReadCompletionDate = MutableProperty(
            backing: backing,
            key: "activityEventLastReadCompletionDate",
            defaultValue: nil,
            makeBridge: PropertyListBridge.cast
        )
        
        // Mindful notification
        mindfulReminderTime = MutableProperty(
            backing: backing,
            key: "MindfulReminderTime",
            defaultValue: DateComponents.init(hour: 8, minute: 0),
            makeBridge: PropertyListBridge.coding
        )
        
        mindfulRemindersEnabled = MutableProperty(
            backing: backing,
            key: "MindfulRemindersEnabled",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )

        mindfulRemindersBacking = MutableProperty(
            backing: backing,
            key: "MindfulRemindersBacking",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        mindfulReminderAlertOnboardingState = MutableProperty(
            backing: backing,
            key: "MindfulReminderAlertOnboardingState",
            defaultValue: false,
            makeBridge: PropertyListBridge.cast
        )
        
        // Activity notifications
        activityNotificationsState = MutableProperty(
            backing: backing,
            key: "activityNotificationsState",
            makeBridge: PropertyListBridge.optionalCoding
        )

        activityReminderNotificationsState = MutableProperty(
            backing: backing,
            key: "activityReminderNotificationsState",
            makeBridge: PropertyListBridge.optionalCoding
        )

        // Reviews
        reviewsState = MutableProperty(
            backing: backing,
            key: "reviewsState",
            makeBridge: PropertyListBridge.optionalCoding
        )

        reviewsTextFeedback = MutableProperty(
            backing: backing,
            key: "reviewsTextFeedback",
            makeBridge: PropertyListBridge.optionalCoding
        )
    }

    // MARK: - Shared
    
    /// A shared preferences instance, using `NSUserDefaults.standardUserDefaults()`.
    static let shared = Preferences(backing: UserDefaults.standard)

    // MARK: - Sub-Preferences

    /// The engagement preferences.
    let engagement: Engagement
    
    /// The mindful preferemces.
    let mindful : Mindful
    
    // MARK: - API
    
    /// A dictionary representation of the current API session.
    let authentication: MutableProperty<Authentication>
    
    /// The ring names that have already been registered.
    let registeredRingNames: MutableProperty<[String]>

    /// The last email that was authenticated with.
    let lastAuthenticatedEmail: MutableProperty<String?>
    
    // MARK: - Bluetooth

    /// The current saved peripheral dictionary representations.
    let savedPeripherals: MutableProperty<[SavedPeripheral]>

    /// The currently activated peripheral UUID.
    let activatedPeripheralIdentifier: MutableProperty<UUID?>
    
    /// The current saved peripheral dictionary representation.
    let savedPeripheral: MutableProperty<SavedPeripheral?>
    
    /// Whether or not a save device is stuck in recovery.
    let deviceInRecovery: MutableProperty<Bool>

    #if DEBUG || FUTURE
    // MARK: - Developer Mode
    
    /// Whether or not developer mode is currently enabled.
    let developerModeEnabled: MutableProperty<Bool>
    
    /// Whether or not launch notifications are enabled.
    let launchNotificationsEnabled: MutableProperty<Bool>

    /// Whether or not continuous notifications for the current day's steps are enabled.
    let developerCurrentDayStepsNotifications: MutableProperty<Bool>
    #endif
    
    // MARK: - Analytics
    
    /// The number of events that have been registered with Mixpanel in the background, without flushing the queue.
    let backgroundMixpanelEventCount: MutableProperty<Int>
    
    // MARK: - Preferences
    
    /// Whether or not sleep mode is enabled.
    let sleepMode: MutableProperty<Bool>

    /// The key previously used for the connection taps setting.
    static let legacyConnectionTapsKey = "connectionLEDMode"

    /// The key used for the connection taps setting.
    static let connectionTapsKey = "ConnectionTaps"
    
    /// Whether or not connection taps are enabled.
    let connectionTaps: MutableProperty<Bool>
    
    /// Whether or not local notifications are enabled.
    let notificationsEnabled: MutableProperty<Bool>
    
    /// Whether or not connection taps are enabled.
    var connectionTapsValue: Bool
    {
        get { return connectionTaps.value }
        set { connectionTaps.value = newValue }
    }
    
    #if DEBUG || FUTURE
    /// Whether or not the ANCS timeout alert is enabled.
    let ANCSTimeout: MutableProperty<Bool>

    /// A simulated size for the screen.
    let simulatedScreenSize: MutableProperty<CGSize?>
    #endif
    
    /// Whether or not disconnect vibrations are enabled.
    let disconnectVibrations: MutableProperty<Bool>
    
    /// Whether or not Inner Ring is enabled.
    let innerRing: MutableProperty<Bool>
    
    // MARK: - Low Battery Warning
    
    /// Whether or not the low battery warning is enabled.
    let batteryAlertsEnabled: MutableProperty<Bool>
    let batteryAlertsBacking: MutableProperty<Bool>
    
    /// Whether or not the low battery warning has been sent.
    let lowBatterySentIdentifiers: MutableProperty<Set<UUID>>
    
    /// Whether or not the charge battery notification has been scheduled.
    let chargeBatterySentIdentifiers: MutableProperty<Set<UUID>>
    
    /// Whether or not the full battery notification has been sent.
    let fullBatterySentIdentifiers: MutableProperty<Set<UUID>>
    
    /// Last full battery notification sent. Should not happen more than once a day.
    let fullBatteryLastSent: MutableProperty<Date?>
    
    /// Whether or not daily charge batter notifications have been scheduled.
    let chargeNotificationState: MutableProperty<ChargeNotificationState>
    
    // MARK: - Migrations

    /// Whether or not the Email -> (Mail, Inbox, Gmail) migration has been performed.
    let emailMigrationPerformed: MutableProperty<Bool>
    
    /// Whether or not existing mindful sessions have been written to HealthKit
    let mindfulnessMigrationPerformed: MutableProperty<Bool>
    
    // MARK: - Onboarding

    /// The key used for storing the value of `onboardingShown`.
    static let onboardingShownKey = "OnboardingShown"
    
    /// Whether or not the onboarding process has been shown.
    let onboardingShown: MutableProperty<Bool>

    /// Whether or not the applications onboarding view has been shown and closed.
    let applicationsOnboardingState: MutableProperty<ApplicationsOnboardingState>
    
    /// Whether you should use peripheral buzzing during the breathing exercese
    let breathingExerciseShouldBuzz: MutableProperty<Bool>
    
    static let breathingExerciseShouldBuzzKey = "breathingExerciseShouldBuzz"

    /// The key used for storing the value of `cameraOnboardingShown`.
    static let cameraOnboardingShownKey = "cameraOnboardingShown"
    
    /// Whether or not the onboarding process has been shown.
    let cameraOnboardingShown: MutableProperty<Bool>
    
    // MARK: - Saved Alerts
    
    /// Whether or not saved alert is enabled.
    let alertViewEnabled: MutableProperty<Bool>
    

    // MARK: - Interface

    /// The last selected tab, which should be opened again when the app is next started.
    let lastTabSelected: MutableProperty<TabBarViewControllerItem?>

    /// Whether or not the "activity unsupported" alert has been presented after activating a peripheral.
    let presentedActivityUnsupportedAlert: MutableProperty<Bool>

    // MARK: - Activity Tracking Body Data

    /// The user's set body mass, if any.
    let activityTrackingBodyMass: MutableProperty<Skippable<PreferencesHKQuantity>?>

    /// The user's set height, if any.
    let activityTrackingHeight: MutableProperty<Skippable<PreferencesHKQuantity>?>

    /// The user's birth date, if set.
    let activityTrackingBirthDateComponents: MutableProperty<Skippable<DateComponents>?>

    // MARK: - Activity Tracking Goals

    /// The user's activity tracking steps goal.
    let activityTrackingStepsGoal: MutableProperty<Int>
    
    /// The user's activity daily mindfulness reminder time.
    let activityTrackingMindfulnessReminderTime: MutableProperty<Skippable<DateComponents>?>
    
    /// The user's activity mindfulness minutes goal.
    let activityTrackingMindfulnessGoal: MutableProperty<Int>

    /// The user's hourly activity tracking steps goal.
    let activityTrackingHourlyStepsGoal: MutableProperty<Int>

    /// The number of hours in which it is the user's goal to meet `activityTrackingHourlyStepsGoal`.
    let activityTrackingDailyHourGoal: MutableProperty<Int>
    
    /// Whether or not onboarding is completed for mindfulness
    let activityTrackingMindfulnessOnboardingSet: MutableProperty<Bool>
    
    /// Breathing Exercise Motor Power
    let motorPower: MutableProperty<Int>
    
    /// Breathing Vibration Style
    let breathingVibrationStyle: MutableProperty<String>
        
    ///

    // MARK: - Activity Tracking Dates

    /// The last date at which an activity tracking completion event was received.
    let activityEventLastReadCompletionDate: MutableProperty<Date?>

    // MARK: - Activity Tracking Notifications
    
    /// Whether or not activity encouragement is enabled
    let activityEncouragementEnabled: MutableProperty<Bool>
    let activityEncouragementBacking: MutableProperty<Bool>
    
    /// The current state of activity notifications.
    let activityNotificationsState: MutableProperty<ActivityNotificationsState?>

    /// The current state of activity reminder notifications.
    let activityReminderNotificationsState: MutableProperty<ActivityReminderNotificationsState?>

    /// MARK: - Mindful Notification
    let mindfulReminderTime: MutableProperty<DateComponents>
    
    let mindfulRemindersEnabled: MutableProperty<Bool>
    let mindfulRemindersBacking: MutableProperty<Bool>
    
    let mindfulReminderAlertOnboardingState: MutableProperty<Bool>
    
    // MARK: - Reviews

    /// The current state of reviews prompt display.
    let reviewsState: MutableProperty<ReviewsState?>

    /// The reviews feedback provided by the user. When set, this value should be sent to the API, then cleared.
    let reviewsTextFeedback: MutableProperty<ReviewsTextFeedback?>
}

// MARK: - Backing Type

/// A protocol for `Preferences` backing storage. `NSUserDefaults` is extended to conform, but other types can be used
/// for testing.
protocol PreferencesBackingType
{
    func object(forKey key: String) -> Any?
    func setObject(_ object: Any?, forKey: String)

    @discardableResult
    func synchronize() -> Bool
}

extension UserDefaults: PreferencesBackingType {}

extension PreferencesBackingType
{
    func migrateConnectionTapsSetting()
    {
        // do not overwite a connection taps setting, only perform this migration once
        guard object(forKey: Preferences.connectionTapsKey) == nil else { return }

        // only perform a migration if the user has completed the onboarding process, otherwise set to false so that the
        // previous guard will fail in the future
        guard object(forKey: Preferences.onboardingShownKey) as? Bool == true else {
            setObject(false as AnyObject?, forKey: Preferences.connectionTapsKey)
            return
        }

        // find the legacy value, defaulting to 0 if one is not set - this will apply to users that have not manually
        // modified the preference, and have left it at its default setting
        let legacy = object(forKey: Preferences.legacyConnectionTapsKey) as? Int ?? 0
        setObject(legacy != 2, forKey: Preferences.connectionTapsKey)
    }
}
