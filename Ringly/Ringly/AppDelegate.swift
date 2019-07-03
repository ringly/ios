import AirshipKit
import MessageUI
import Mixpanel
import RinglyActivityTracking
import RinglyExtensions
import ReactiveSwift
import Result
import RinglyAPI
import RinglyDFU
import UIKit
import Fabric
import Crashlytics

#if FUTURE
    import HockeySDK

    #if EXPERIMENTAL
        private let hockeyAppToken = "YOUR-TOKEN-HERE"
        private let hockeyAppSecret = "YOUR-SECRET-HERE"
    #else
        #if NIGHTLY
            private let hockeyAppToken = "YOUR-TOKEN-HERE"
            private let hockeyAppSecret = "YOUR-SECRET-HERE"
        #else
            private let hockeyAppToken = "YOUR-TOKEN-HERE"
            private let hockeyAppSecret = "YOUR-SECRET-HERE"
        #endif
    #endif
#endif

#if DEBUG || FUTURE || FUTURE_RELEASE
    private let airshipConfigDevelopmentAppKey = "YOUR-KEY-HERE"
    private let airshipConfigDevelopmentAppSecret = "YOUR-SECRET-HERE"
    private let airshipConfigProductionAppKey = "YOUR-KEY-HERE"
    private let airshipConfigProductionAppSecret = "YOUR-SECRET-HERE"
#else
    private let airshipConfigDevelopmentAppKey = "YOUR-KEY-HERE"
    private let airshipConfigDevelopmentAppSecret = "YOUR-SECRET-HERE"
    private let airshipConfigProductionAppKey = "YOUR-KEY-HERE"
    private let airshipConfigProductionAppSecret = "YOUR-SECRET-HERE"
#endif

final class AppDelegate: NSObject, UIApplicationDelegate
{
    // MARK: - Properties

    /// The application's primary window.
    var window: UIWindow?

    /// The application's primary view controller, and the root view controller of `window`.
    fileprivate(set) var viewController: ContainerViewController?

    /// The services used to receive, store, and process data in the application.
    fileprivate var services: Services?

    /// The root view controllers for
    fileprivate let container = ContainerViewController()

    /// The shared delegate for Urban Airship classes.
    fileprivate let urbanAirshipDelegate = UrbanAirshipDelegate()

    // MARK: - Launch
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool
    {
        guard NSClassFromString("XCTestCase") == nil else { return true }

        // mixpanel setup
        let mixpanel = Mixpanel.sharedInstance(withToken: kAnalyticsMixpanelToken, launchOptions: launchOptions)
        mixpanel.enableLogging = false // these logs are mostly useless and spam the console
        mixpanel.timeEvent(kAnalyticsApplicationLaunched)

        // crashlytics setup
        Fabric.with([Crashlytics.self])

        // set up RLog
        RLogIgnoredTypes = .dfuNordic
        APILogFunction = SLogAPI
        DFULogFunction = SLogDFU
        HKHealthStoreDebugLogFunction = SLogUI // temporary

        #if DEBUG
            LoggingService.sharedLoggingService?.NSLogTypes = [
                .API,
                .appleNotifications,
                .activityTracking,
                .bluetooth,
                .DFU
            ]
        #endif

        SLogUI("Application launched, state “\(application.applicationState.loggingString)”, options: \(launchOptions)")

        // create the services object
        let services = Services()
        self.services = services

        // prime cache
        services.cache.cacheGuidedAudioSessions(completion: nil)


        // log startup centrals
        if let centrals = launchOptions?[UIApplicationLaunchOptionsKey.bluetoothCentrals] as? [String]
        {
            #if !RELEASE
            // if the user requested background launch notifications, deliver one
            if centrals.count == 1 && services.preferences.launchNotificationsEnabled.value
            {
                let notification = UILocalNotification()
                notification.alertBody = "🚀 Launched in background"
                application.presentLocalNotificationNow(notification)
            }
            #endif

            SLogBluetooth("Started with central manager IDs: \(centrals)")
        }

        // in debug mode, automatically enable developer features
        #if DEBUG
            services.preferences.developerModeEnabled.value = true
        #endif

        // create a window for the application
        #if DEBUG || FUTURE
            let simulatedScreenSize = services.preferences.simulatedScreenSize
            let screenBounds = UIScreen.main.bounds

            let window = UIWindow(frame: simulatedScreenSize.value?.centered(in: screenBounds) ?? screenBounds)
            window.clipsToBounds = true

            simulatedScreenSize.signal.observeValues({ optional in
                window.frame = optional?.centered(in: screenBounds) ?? screenBounds
            })
        #else
            let window = UIWindow(frame: UIScreen.main.bounds)
        #endif
        window.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        self.window = window

        // add root view controller to window
        self.viewController = container

        container.childTransitioningDelegate = self
        window.rootViewController = container

        // make the window visible on screen
        window.makeKeyAndVisible()

        // wait until the application will become active before showing UI, so that it doesn't start when the app is
        // woken up in the background.
        let readyForInterfaceProducer = application.applicationState == .background
            ? SignalProducer(NotificationCenter.default.reactive
                .notifications(forName: Notification.Name.UIApplicationWillEnterForeground, object: application))
                .take(first: 1)
                .ignoreValues()
            : SignalProducer.empty

        container.childViewController <~ readyForInterfaceProducer
            .then(services.api.authenticated.producer.combineLatest(with: services.preferences.onboardingShown.producer))
            .skipRepeats(==)
            .map({ authenticated, shownOnboarding -> UIViewController in
                // require authentication before showing main interface
                guard authenticated else { return AuthenticationViewController(services: services) }

                // show onboarding before showing main UI
                if shownOnboarding
                {
                    return TabBarViewController(services: services)
                }
                else
                {
                    let onboarding = OnboardingViewController(services: services)
                    onboarding.completionProducer.take(first: 1).startWithValues({ _ in
                        services.preferences.onboardingShown.value = true
                    })
                    return onboarding
                }
            })

            // when changing from onboarding to normal, show notifications view
            .combinePrevious(nil)
            .on(value: { previous, current in
                guard let tabs = current as? TabBarViewController else { return }

                if previous is AuthenticationViewController
                {
                    tabs.defaultVia = .login
                }
                else if previous is OnboardingViewController
                {
                    tabs.defaultVia = .onboarding
                }
                else if previous == nil
                {
                    tabs.defaultVia = .launch
                }

                if let tab = services.preferences.lastTabSelected.value
                {
                    tabs.selectedTabBarItem = tab
                }
            })
            .map({ _, current in current })

        // configure HockeyApp
        #if FUTURE
            let manager = BITHockeyManager.shared()
            manager.configure(withIdentifier: hockeyAppToken)
            manager.authenticator.authenticationSecret = hockeyAppSecret
            manager.authenticator.identificationType = .hockeyAppEmail
            manager.crashManager.crashManagerStatus = .autoSend
            manager.start()
            manager.authenticator.authenticateInstallation()
        #endif

        // configure urban airship
        let airshipConfig = UAConfig()
        airshipConfig.detectProvisioningMode = true
        airshipConfig.developmentAppKey = airshipConfigDevelopmentAppKey
        airshipConfig.developmentAppSecret = airshipConfigDevelopmentAppSecret
        airshipConfig.productionAppKey = airshipConfigProductionAppKey
        airshipConfig.productionAppSecret = airshipConfigProductionAppSecret

        SLogGeneric("Airship config key is \(airshipConfig.appKey ?? "none")")

        UAirship.takeOff(airshipConfig)
        urbanAirshipDelegate.delegate = self
        UAirship.push().pushNotificationDelegate = urbanAirshipDelegate
        UAirship.push().registrationDelegate = urbanAirshipDelegate

        services.api.authentication.producer.map({ $0.user?.identifier }).startWithValues({ identifier in
            UAirship.namedUser().identifier = identifier
        })

        // backport local notification users to Urban Airship
        if application.currentUserNotificationSettings.map({ !$0.types.isEmpty }) ?? false
        {
            UAirship.push().userPushNotificationsEnabled = true
        }

        // protected data logging
        if application.isProtectedDataAvailable
        {
            SLogUI("Protected data is available at launch")
        }
        else
        {
            SLogUI("Protected data is unavailable at launch")
        }

        NotificationCenter.default.reactive
            .notifications(forName: .UIApplicationProtectedDataDidBecomeAvailable, object: application)
            .observeValues({ _ in SLogUI("Protected data became available") })

        NotificationCenter.default.reactive
            .notifications(forName: .UIApplicationProtectedDataWillBecomeUnavailable, object: application)
            .observeValues({ _ in SLogUI("Protected data became unavailable") })

        if services.preferences.deviceInRecovery.value {
            if let tab = self.container.childViewController.value as? TabBarViewController,
                tab.selectedTabBarItem != .connection {
                switchTab(tab: .connection)
            }

            if let container = self.window?.rootViewController?.childViewControllers.first?
                .childViewControllers.first?.childViewControllers.first as? ContainerViewController {

                container.presentAlert { alert in
                    alert.content = AlertImageTextContent(text: tr(.
                        dfuFailedAlertTitle), detailText: tr(.dfuFailedAlertDescription))

                    alert.actionGroup = .double(
                        action: (title: trUpper(.restartUpdate), dismiss: true, action: {
                            let add = AddPeripheralViewController(services: services)
                            if let peripheral = container.childViewControllers.first as? PeripheralsViewController {
                                peripheral.navigation.pushViewController(add, animated: true)
                            }
                        }),
                        dismiss:(title: tr(.notNow), dismiss: true, action: { })
                    )
                }
            }
        }

        // launch background steps queries for goal notification
        if let healthStore = services.activityTracking.healthStore, let stepsType = services.activityTracking.stepsType
        {
            healthStore.enableBackgroundDelivery(
                for: stepsType,
                frequency: .hourly,
                withCompletion: { success, optionalError in
                    if let error = optionalError, !success
                    {
                        SLogActivityTrackingError("Error enabling background steps delivery: \(error)")
                    }
                }
            )

            services.activityTracking.currentDaySteps.producer.skipNil().startWithValues({ result in
                switch result
                {
                case let .success(date):
                    SLogActivityTracking("Current day steps are \(date.steps)")

                    #if DEBUG || FUTURE
                        if services.preferences.developerCurrentDayStepsNotifications.value
                        {
                            let notification = UILocalNotification()
                            notification.soundName = UILocalNotificationDefaultSoundName
                            notification.alertTitle = "Daily Steps Update"
                            notification.alertBody = "Daily steps are now \(date.steps)"
                            application.presentLocalNotificationNow(notification)
                        }
                    #endif

                case let .failure(error):
                    SLogActivityTracking("Error encountered while loading current day's steps: \(error)")
                }
            })
        }

        application.beginReceivingRemoteControlEvents()

        // done, send launched analytics event
        services.analytics.track(ApplicationStateEvent.launched)

        return true
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)
    {
        func tabForType(_ type: String) -> TabBarViewControllerItem?
        {
            switch type
            {
            case "com.ringly.Ringly.openAlerts":
                return .notifications
            case "com.ringly.Ringly.openContacts":
                return .contacts
            case "com.ringly.Ringly.openActivity":
                return .activity
            case "com.ringly.Ringly.openSettings":
                return .preferences
            default:
                return nil
            }
        }

        if let tabs = container.childViewController.value as? TabBarViewController,
           let tab = tabForType(shortcutItem.type)
        {
            tabs.selectedTabBarItem = tab
            completionHandler(true)
        }
        else
        {
            completionHandler(false)
        }
    }

    // MARK: - Events
    func applicationWillResignActive(_ application: UIApplication)
    {
        services?.preferences.lastTabSelected.value =
            (container.childViewController.value as? TabBarViewController).flatMap({ $0.selectedTabBarItem })
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        SLogUI("Application entered background")
        services?.analytics.track(ApplicationStateEvent.background)
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        SLogUI("Application entered foreground")
        services?.analytics.track(ApplicationStateEvent.foreground)
        guard let settings = UIApplication.shared.currentUserNotificationSettings?.types else { return }
        services?.preferences.notificationsEnabled.value = !settings.isEmpty
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        SLogUI("Application became active")
        services?.preferences.lastTabSelected.value = nil
    }

    // MARK: - Notifications
    func application(_ application: UIApplication,
                     didRegister notificationSettings: UIUserNotificationSettings)
    {
        // empty implementation required for a RACSignal in Airship extension
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        // empty implementation required for a RACSignal in Airship extension
    }

    // MARK: - URL Parsing
    func application(_ application: UIApplication, open URL: URL, sourceApplication: String?, annotation: Any)
        -> Bool
    {
        if let action = URLAction(url: URL)
        {
            applyURLAction(action)
            return true
        }
        else if let viewController = self.viewController?.childViewController.value as? URLHandler
        {
            return viewController.handleOpen(URL, sourceApplication: sourceApplication, annotation: annotation)
        }
        else
        {
            return false
        }
    }

    // MARK: - Universal Links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool
    {
        if let URL = userActivity.webpageURL, userActivity.activityType == NSUserActivityTypeBrowsingWeb
        {
            if let action = URLAction(universalLinkURL: URL)
            {
                applyURLAction(action)
                return true
            }
            else
            {
                application.openURL(URL)
                return false
            }
        }
        else
        {
            return false
        }
    }

    //MARK: switch tabs
    func switchTab(tab: TabBarViewControllerItem)
    {
        if let tabs = self.container.childViewController.value as? TabBarViewController
        {
            tabs.selectedTabBarItem = tab
        }
    }

    func goToMindfulnessLanding() {
        if let tabs = self.container.childViewController.value as? TabBarViewController
        {
            if let activityTrackingViewController = tabs.contentViewController as? ActivityTrackingViewController {
                activityTrackingViewController.autoPushMindfulness.value = true
            }
        }
    }
}

extension AppDelegate: UrbanAirshipDelegateDelegate
{
    func receivedForegroundNotification(_ notification: UANotificationContent)
    {
        let application = UIApplication.shared
        guard let window = self.window, application.applicationState == .active else { return }

        func present(content: AlertViewControllerContent, actionGroup: AlertViewController.ActionGroup)
        {
            let alert = AlertViewController()
            alert.content = content
            alert.actionGroup = actionGroup
            alert.present(above: window)
        }

        if notification.isLowBattery
        {
            present(
                content: AlertImageTextContent(
                    text: notification.alertTitle ?? tr(.lowBatteryNotificationText),
                    detailText: notification.alertBody ?? tr(.lowBatteryNotificationDetailText("Ringly", 10))
                ),
                actionGroup: .close
            )
        }

        if notification.isActivityNotification || notification.isActivityReminderNotification
        {
            present(
                content: AlertImageTextContent(
                    text: tr(.activity),
                    detailText: notification.alertBody ?? ""
                ),
                actionGroup: AlertViewController.ActionGroup.actionOrClose(title: tr(.openActivity)) { [weak self] in
                    if let tabs = self?.container.childViewController.value as? TabBarViewController
                    {
                        tabs.selectedTabBarItem = .activity
                    }
                }
            )
        }

        if notification.isForNewApplications
        {
            present(
                content: AlertImageTextContent(
                    image: nil,
                    text: notification.alertTitle ?? tr(.applicationsNewSupportAlertTitle),
                    detailText: notification.alertBody ?? tr(.applicationsNewSupportAlertFallbackBody)
                ),
                actionGroup: AlertViewController.ActionGroup.actionOrClose(
                    title: tr(.openAlerts),
                    action: { [weak self] in
                        if let tabs = self?.container.childViewController.value as? TabBarViewController
                        {
                            tabs.selectedTabBarItem = .notifications
                        }
                    }
                )
            )
        }
    }

    func receivedBackgroundNotification(_ notificationContent: UANotificationContent)
    {

    }

    func receivedNotificationResponse(_ response: UANotificationResponse)
    {
        guard response.actionIdentifier == UANotificationDefaultActionIdentifier else { return }

        if let tabs = container.childViewController.value as? TabBarViewController
        {
            let content = response.notificationContent

            if content.isActivityNotification ||
               content.isEngagementNotification(.stayHydrated) ||
               content.isEngagementNotification(.stepGoalEncouragement) ||
               content.isEngagementNotification(.setUpActivity)
            {
                tabs.selectedTabBarItem = .activity
            }
            else if content.isEngagementNotification(.startedBreather) ||
                    content.isEngagementNotification(.startedMeditation)
            {
                tabs.selectedTabBarItem = .activity
                goToMindfulnessLanding()

            }
            else if content.isMindfulNotification(.sunday) || content.isMindfulNotification(.monday) ||
                    content.isMindfulNotification(.tuesday) || content.isMindfulNotification(.wednesday) ||
                    content.isMindfulNotification(.thursday) || content.isMindfulNotification(.friday) ||
                    content.isMindfulNotification(.saturday)
            {
                tabs.selectedTabBarItem = .activity
                goToMindfulnessLanding()
                services?.analytics.track(AnalyticsEvent.mindfulReminderAlertOpened)
            }
            else if content.isForNewApplications ||
                    content.isEngagementNotification(.addRemoveApplications) ||
                    content.isEngagementNotification(.editApplicationBehavior)
            {
                tabs.selectedTabBarItem = .notifications
            }
        }
    }
}

extension AppDelegate
{
    // MARK: - URL Parser Results
    func applyURLAction(_ action: URLAction)
    {
        // services and view controller are necessary to do most things, and should always be present, as they're
        // created when the app finishes launching
        guard let services = self.services, let viewController = self.viewController else { return }

        switch action
        {
        case let .dfu(hardwareVersions, applicationVersion):
            viewController.attemptDFU(
                services: services,
                hardwareVersions: hardwareVersions,
                applicationVersion: applicationVersion
            )

        case .multi(let results):
            results.forEach(applyURLAction)

        case .resetPassword(let tokenString):
            if let authentication = (container.childViewController.value as? AuthenticationViewController)
            {
                authentication.presentPasswordResetWithTokenString(tokenString)
            }
            else if viewController.presentedViewController == nil
            {
                let passwordReset = PasswordResetViewController(services: services)
                passwordReset.tokenString.value = tokenString

                let navigation = AuthenticationNavigationController()
                navigation.navigation.pushViewController(passwordReset, animated: false)
                viewController.present(navigation, animated: true, completion: nil)

                navigation.poppedRoot = { controller in
                    controller.dismiss(animated: true, completion: nil)
                }

                passwordReset.completed = { _ in
                    navigation.dismiss(animated: true, completion: nil)
                }
            }

        case .collectDiagnosticData(let queryItems):
            viewController.collectDiagnosticData(from: services, queryItems: queryItems)

        case .developerMode(let enable):
            #if DEBUG || FUTURE
            services.preferences.developerModeEnabled.value = enable
            #endif

        case .review:
            services.preferences.reviewsState.value = .display(.prompt)
        case .openTab(let tabItem):
            self.switchTab(tab: tabItem)
        case .mindfulness:
            self.goToMindfulnessLanding()
        case .universal(let url):
            if let url = url {
                self.applyURLAction(URLAction.init(universalLinkURL: url)!)
            }
        }
    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension AppDelegate: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
        animationControllerForTransitionFromViewController fromViewController: UIViewController?,
        toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        if let to = toViewController, let from = fromViewController
        {
            if let toProviding = to as? ForegroundBackgroundContentViewProviding,
               let fromProviding = from as? ForegroundBackgroundContentViewProviding
            {
                return ForegroundBackgroundTransitionController(operation: .push, from: fromProviding, to: toProviding)
            }
            else
            {
                return SlideTransitionController(operation: (to is AuthenticationViewController) ? .pop : .push)
            }
        }
        else
        {
            return nil
        }
    }
}

extension UIApplicationState
{
    fileprivate var loggingString: String
        {
        switch self
        {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .background:
            return "Background"
        }
    }
}
