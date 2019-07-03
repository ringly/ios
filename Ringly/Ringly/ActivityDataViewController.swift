import ReactiveSwift
import Result
import RinglyActivityTracking
import RinglyExtensions
import UIKit

final class ActivityDataViewController: ServicesViewController
{
    // MARK: - Day Range
    let calendarBoundaryDatesResult = MutableProperty(Result<CalendarBoundaryDates?, NSError>?.none)

    // MARK: - Subviews

    /// A label displaying the currently selected date.
    fileprivate let navigationBar = NavigationBar.newAutoLayout()

    /// The height of the navigation bar for this view controller.
    @nonobjc static var navigationBarHeight: CGFloat
    {
        return DeviceScreenHeight.current.select(four: 30, five: 50, preferred: 79)
    }
    
    fileprivate let connectivityIndicator = ConnectivityIndicatorControl.newAutoLayout()


    // MARK: - Child View Controllers

    /// The container view controller at the root of the navigation controller.
    fileprivate let root = ContainerViewController()

    /// A navigation controller, used to display content for individual days.
    fileprivate let navigation = UINavigationController()

    /// The layout constraint pinning the navigation controller to the top of the view.
    fileprivate var navigationBarTopConstraint: NSLayoutConstraint?

    /// `true` if the view controller is showing `root`.
    fileprivate let showingRoot = MutableProperty(true)
    
    let (mindfulnessSectionChangeSignal, mindfulnessSectionChangeObserver) = Signal<Bool, NoError>.pipe()

    let autoPushMindfulness = MutableProperty(false)
    
    let currentTranslationOffset = MutableProperty<Bool>(false)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add navigation bar
        navigationBar.animateTitleChanges = false
        view.addSubview(navigationBar)

        navigationBarTopConstraint = navigationBar.autoPinToTopLayoutGuide(of: self, inset: 0)
        navigationBar.autoPinEdgeToSuperview(edge: .leading)
        navigationBar.autoPinEdgeToSuperview(edge: .trailing)
        navigationBar.autoSet(dimension: .height, to: ActivityDataViewController.navigationBarHeight)

        // add the navigation controller
        navigation.isNavigationBarHidden = true
        navigation.automaticallyAdjustsScrollViewInsets = false
        navigation.delegate = self

        root.childTransitioningDelegate = self
        navigation.pushViewController(root, animated: false)

        addChildViewController(navigation)
        view.addSubview(navigation.view)
        navigation.view.autoPin(edge: .top, to: .bottom, of: navigationBar)
        navigation.view.autoPinEdgesToSuperviewEdges(excluding: .top)

        // commented to allow tooltip to appear over navigation bar
//        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
//            navigation.view.autoPinToTopLayoutGuide(of: self, inset: 0)
//        })

        navigation.didMove(toParentViewController: self)
        
        view.addSubview(connectivityIndicator)
        connectivityIndicator.autoAlign(axis: .horizontal, toSameAxisOf: navigationBar)
        connectivityIndicator.autoPinEdgeToSuperview(edge: .left, inset: 24)
        connectivityIndicator.autoSetDimensions(to: CGSize(width: 44, height: 44))
        
        
        let peripheralHealthProducer = SignalProducer.combineLatest(
            self.services.peripherals.activatedPeripheral.producer,
            self.services.peripherals.peripherals.producer.map({ $0.count > 0 }),
            self.services.activityTracking.healthKitAuthorization.producer.map({ $0 == .sharingAuthorized })
        )
        
        let connectivityStatusProducer = peripheralHealthProducer.flatMap(.latest, transform: { peripheral, hasPeripherals, healthKitIsAuthorized -> SignalProducer<ConnectivityStatus?, NoError> in
            if let peripheral = peripheral {
                return SignalProducer.combineLatest(
                    peripheral.reactive.connected,
                    peripheral.reactive.validated,
                    peripheral.reactive.batteryCharge
                    ).map({
                        return ConnectivityStatus(
                            hasPeripherals: hasPeripherals,
                            peripheralConnected: $0 && $1,
                            batteryPercentage: $2,
                            healthConnected: healthKitIsAuthorized
                        )
                    })
            } else {
                return SignalProducer(value: ConnectivityStatus(
                    hasPeripherals: hasPeripherals,
                    peripheralConnected: false,
                    batteryPercentage: nil,
                    healthConnected: healthKitIsAuthorized
                ))
            }
        })
        connectivityIndicator.reactive.isHidden <~ showingRoot.producer.not
        connectivityIndicator.reactive.controlEvents(.touchUpInside).observeValues({ _ in
            self.presentAlert(setup: { controller in
                controller.backgroundDismissable = true
                
                let connectAction:((SignalProducer<(), NoError>) -> Void)? = { triggerProducer in
                    triggerProducer.startWithValues {
                        controller.dismiss()

                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            appDelegate.switchTab(tab: .connection)
                        }
                    }
                }
                
                let healthkitAction:((SignalProducer<(), NoError>) -> Void)? = { triggerProducer in
                    
                    self.startRequestingHealthKitAccess(on: triggerProducer.on(value: {
                        controller.dismiss()
                    }))
                }
                
                let connectivityDetailView = ConnectivityDetailView()
                connectivityDetailView.peripheralDatasource.connectivityModel <~ connectivityStatusProducer.map({ status in
                    if let status = status {
                        return DataSourceConnectivityModel(
                            title: "RINGLY",
                            isConnected: status.peripheralConnected,
                            icon: status.peripheralConnected ? Asset.peripheralConnected.image : Asset.peripheralDisconnected.image,
                            action: status.peripheralConnected ? nil : connectAction
                        )
                    } else {
                        return DataSourceConnectivityModel(
                            title: "RINGLY",
                            isConnected: false,
                            icon:  Asset.peripheralDisconnected.image,
                            action: connectAction
                        )
                    }
                })
                
                connectivityDetailView.healthkitDatasource.connectivityModel <~ self.services.activityTracking.healthKitAuthorization.producer.map({ $0 == .sharingAuthorized }).map({ isHealthConnected in
                    return DataSourceConnectivityModel(
                        title: "HEALTH APP",
                        isConnected: isHealthConnected,
                        icon: isHealthConnected ? Asset.healthAppConnected.image : Asset.healthAppDisconnected.image,
                        action: isHealthConnected ? nil : healthkitAction
                    )
                })
                
    
                controller.content = connectivityDetailView
            })
        })

        connectivityIndicator.connectivityStatus <~ connectivityStatusProducer
        

        // this is a workaround, so it could break on future iOS versions
        navigation.view.subviews.forEach({ $0.clipsToBounds = false })

        // perform mindfulness migration
        if !self.services.preferences.mindfulnessMigrationPerformed.value {
            self.services.activityTracking.realmService?.performMindfulnessMigration()
                .take(until: self.services.activityTracking.reactive.lifetime.ended)
                .start()
            self.services.activityTracking.realmService?.dequeueMindfulUpdate(store: self.services.activityTracking.healthStore)
                .take(until: self.services.activityTracking.reactive.lifetime.ended)
                .start()
            self.services.preferences.mindfulnessMigrationPerformed.value = true
        }
        
        self.services.preferences.notificationsEnabled.producer
            .skip(first: 1)
            .skipRepeats()
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] value in
                guard let preferences = self?.services.preferences else { return }
                let alerts = [preferences.mindfulRemindersEnabled,
                              preferences.activityEncouragementEnabled,
                              preferences.batteryAlertsEnabled]
                let alertsBacking = [preferences.mindfulRemindersBacking,
                                     preferences.activityEncouragementBacking,
                                     preferences.batteryAlertsBacking]
                
                // if notifications turned on, foo-enabled takes last foo-backing setting
                if value
                {
                    zip(alerts, alertsBacking).forEach({ alert, backing in
                        alert.value = backing.value
                    })
                }
                // if notifications turned off, foo-enabled settings turned off.
                // user prompted to turn on notifications if trying to turn back on.
                else
                {
                    alerts.forEach({ $0.value = false })
                }
            })
        
        /*
        // add control for entering camera
        let camera = UIButton.newAutoLayout()
        camera.setImage(UIImage(asset: .cameraButton), for: .normal)
        camera.showsTouchWhenHighlighted = true
        view.addSubview(camera)

        camera.autoPinEdgeToSuperview(edge: .top)
        camera.autoPinEdgeToSuperview(edge: .right, inset: 22)
        camera.autoSet(dimension: .height, to: ActivityDataViewController.navigationBarHeight)

        // TODO: move out of loadView, into extension?
        camera.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            guard let strong = self else { return }

            let navigation = UINavigationController()
            navigation.delegate = CrossDissolveTransitionController.sharedDelegate
            navigation.isNavigationBarHidden = true
            navigation.transitioningDelegate = SlideTransitionController.sharedDelegate.vertical

            if strong.services.preferences.cameraOnboardingShown.value
            {
                let cameraVC = CameraViewController(services: strong.services)
                cameraVC.mode.value = .camera
                navigation.pushViewController(cameraVC, animated: false)
            }
            else
            {
                strong.services.preferences.cameraOnboardingShown.value = true
                let onboarding = CameraOnboardingViewController(services: strong.services)
                navigation.pushViewController(onboarding, animated: false)
            }

            strong.present(navigation, animated: true, completion: nil)
        })

        camera.reactive.isHidden <~ showingRoot.producer.not 
        */
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // once the initial day range is loaded, show a week view controller
        
        SignalProducer.combineLatest(
            calendarBoundaryDatesResult.producer,
            UIApplication.shared.activeProducer
        )
        .filter({ $1 })
        .observe(on: UIScheduler())
        .startWithValues { [weak self] (boundaryDatesResult, _) in
            self?.updateChildViewController(boundaryDatesResult)
        }
        
        root.childViewController.producer
            .map({ $0 as? ActivityWeekViewController })
            .flatMapOptional(.latest, transform: { controller in
                SignalProducer(controller.tappedSelectedBoundaryDatesSignal).map({ (controller, $0) })
            })
            .skipNil()
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] controller, boundaryDates in
                self?.pushDayViewController(controller, boundaryDates: boundaryDates)
            })
        
        root.childViewController.producer
            .map({ $0 as? ActivityWeekViewController })
            .flatMapOptional(.latest, transform: { controller in
                let tappedMindfulnessDates = SignalProducer(controller.tappedMindfulnessDatesSignal)
                let autoLaunchMindfulness = self.autoPushMindfulness.producer.filter({ $0 }).map({ _ in BoundaryDates.init(start: Date(), end: Date()) })
                return SignalProducer.merge([tappedMindfulnessDates, autoLaunchMindfulness]).map({ (controller, $0) })
            })
            .skipNil()
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] controller, boundaryDates in
                self?.pushMindfulnessViewController(controller, boundaryDates: boundaryDates)
            })

        navigationBar.title <~ root.childViewController.producer
            .flatMap(.latest, transform: { controller in
                (controller as? ActivityWeekViewController)?.titleProducer
                    ?? SignalProducer(value: NavigationBar.Title.text("ACTIVITY"))
            })
            .observe(on: UIScheduler())

        
        navigationBar.backProducer.startWithValues({ [weak navigation] in
            self.mindfulnessSectionChangeObserver.send(value: false)
            _ = navigation?.popViewController(animated: true)

        })
        
        self.services.preferences.mindfulRemindersEnabled.producer
            .skip(first: 1)
            .ignore(false)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] _ in
                guard let strong = self else { return }
                
                let app = UIApplication.shared
                
                app.registerForNotificationsProducer(strong.services.analytics).startWithCompleted({ [weak self] in
                    // if alerts were not enabled, tell the user that they must be
                    guard let strong = self else { return }
                    guard app.currentUserNotificationSettings?.types.contains(.alert) == false else { return }
                    
                    // reset the preference
                    strong.services.preferences.mindfulRemindersEnabled.value = false
                    
                    let bundle = Bundle.main
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Ringly"
                    
                    let aboveVC = strong.presentedViewController ?? strong
                    
                    AlertViewController(
                        openSettingsText: tr(.settingsEnableAlerts),
                        openSettingsDetailText: tr(.settingsEnableMindfulnessAlertsPrompt(name))
                        ).present(above: aboveVC)
                })
            })
        
        self.services.preferences.activityEncouragementEnabled.producer
            .skip(first: 1)
            .ignore(false)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] _ in
                guard let strong = self else { return }
                
                let app = UIApplication.shared
                
                app.registerForNotificationsProducer(strong.services.analytics).startWithCompleted({ [weak self] in
                    // if alerts were not enabled, tell the user that they must be
                    guard let strong = self else { return }
                    guard app.currentUserNotificationSettings?.types.contains(.alert) == false else { return }
                    
                    // reset the preference
                    strong.services.preferences.activityEncouragementEnabled.value = false
                    
                    let bundle = Bundle.main
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Ringly"
                    
                    let aboveVC = strong.presentedViewController ?? strong
                    
                    AlertViewController(
                        openSettingsText: tr(.settingsEnableAlerts),
                        openSettingsDetailText: tr(.settingsEnableActivityEncouragementPrompt(name))
                        ).present(above: aboveVC)
                })
            })
    }
}

extension ActivityDataViewController
{
    // MARK: - Displaying an Updated Child View Controller
    fileprivate func updateChildViewController(_ optionalResult: Result<CalendarBoundaryDates?, NSError>?)
    {
        if let result = optionalResult
        {
            root.updateServicesChild(
                type: ActivityWeekViewController.self,
                services: services,
                update: { $0.calendarBoundaryDatesResult.value = result }
            )
        }
        else
        {
            root.updateChild(type: ActivityLoadingViewController.self)
        }
    }
}

extension ActivityDataViewController
{
    // MARK: - Forwarding Week View Controller Producers
    var requestedStatisticsCalculationOnboardingProducer: SignalProducer<ActivityStatisticsCalculation, NoError>
    {
        return root.childViewController.producer
            .map({ $0 as? ActivityWeekViewController })
            .flatMapOptional(.latest, transform: { $0.requestedStatisticsCalculationOnboardingProducer })
            .skipNil()
    }
    
}

extension ActivityDataViewController
{
    // MARK: - Pushing Day View Controllers
    fileprivate func pushDayViewController(_ controller: ActivityWeekViewController, boundaryDates: BoundaryDates)
    {
        // create the day view controller
        let dayController = ActivityDayViewController(services: services)
        dayController.dayBoundaryDates.value = boundaryDates
        self.currentTranslationOffset <~ dayController.currentTranslationOffset

        if let calendar = calendarBoundaryDatesResult.value?.value??.calendar
        {
            dayController.calendar.value = calendar

            let days = calendar.dateComponents([.day], from: boundaryDates.start, to: Date()).day ?? 0
            services.analytics.track(ViewedActivityDayEvent(daysAgo: days, date: boundaryDates.start))
        }

        // bind daily statistics properties
        dayController.stepsProgressText <~ controller.statisticsController.stepsControlData.producer.observe(on: UIScheduler())
        dayController.stepsCount <~ controller.statisticsController.steps.producer.skipNil().map({ $0.stepCount }).observe(on: UIScheduler())

        navigation.pushViewController(dayController, animated: true)
    }
    
    fileprivate func pushMindfulnessViewController(_ controller: ActivityWeekViewController, boundaryDates: BoundaryDates)
    {
        let mindfulnessLandingViewController = MindfulnessLandingViewController(services: self.services, guidedAudioModels: self.services.cache.mindfulnessAudioSessions)
        mindfulnessLandingViewController.mindfulnessControlData <~ controller.statisticsController.mindfulnessControlData.producer
        mindfulnessLandingViewController.mindfulMinutes <~ controller.statisticsController.mindfulMinutes.producer.observe(on: UIScheduler())
        mindfulnessLandingViewController.mindfulSessionEndSignal.observeValues({ mindfulnessChange in
            if mindfulnessChange {
                self.updateChildViewController(self.calendarBoundaryDatesResult.value)
            }
        })
        
        navigation.pushViewController(mindfulnessLandingViewController, animated: true)
        if mindfulnessLandingViewController.presentingViewController is MindfulnessSettingsViewController
        {
            mindfulnessLandingViewController.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        self.mindfulnessSectionChangeObserver.send(value: true)
    }
    
    fileprivate func presentSettingsViewController()
    {
        guard let presenting = self.navigation.childViewControllers.last else { return }
        if presenting is ActivityDayViewController {
            let activitySettings = ActivitySettingsViewController(services: self.services)
            navigation.present(activitySettings, animated: true, completion: nil)
        }
        else {
            let mindfulSettings = MindfulnessSettingsViewController(services: self.services)
            navigation.present(mindfulSettings, animated: true, completion: nil)
        }
    }
}

extension ActivityDataViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        guard let from = fromViewController, let to = toViewController else { return nil }

        if to is ActivityWeekViewController
        {
            return SlideTransitionController(operation: .push, axis: .vertical)
        }
        else if from is ActivityWeekViewController
        {
            return SlideTransitionController(operation: .pop, axis: .vertical)
        }
        else
        {
            return CrossDissolveTransitionController(duration: 0.25)
        }
    }
}

extension ActivityDataViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        if navigation.viewControllers.count > 1
        {
            self.mindfulnessSectionChangeObserver.send(value: false)
            navigation.popViewController(animated: true)
        }
        else
        {
            root.tabBarViewControllerDidTapSelectedItem()
        }
    }
}

extension ActivityDataViewController: UINavigationControllerDelegate
{
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool)
    {
        UIView.animate(if: animated, duration: DayToWeekTransitionController.transitionDuration, animations: {
            let controllerIsPrompt = viewController is OpenHealthViewController
            
            self.navigationBar.backAvailable.value = viewController != self.root && !controllerIsPrompt
            self.navigationBar.action.value = nil

            if controllerIsPrompt == self.navigationBarTopConstraint?.isActive
            {
                self.navigationBarTopConstraint?.isActive = !controllerIsPrompt
                self.view.layoutIfInWindowAndNeeded()
            }
            
            else if viewController is MindfulnessLandingViewController || viewController is ActivityDayViewController
            {
                self.navigationBar.action.value = .image(image: UIImage(asset: .settingsLight).image(alpha: 0.7), accessibilityLabel: "Edit")
                self.navigationBar.actionProducer.startWithValues({ [weak self] _ in
                        self?.presentSettingsViewController()
                })
            }
        })

        showingRoot.value = viewController == root
    }

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController)
                              -> UIViewControllerAnimatedTransitioning?
    {
        return DayToWeekTransitionController(operation: operation)
    }
}

// MARK: - Analytics
struct ViewedActivityDayEvent
{
    let daysAgo: Int
    let date: Date
}

extension ViewedActivityDayEvent: AnalyticsEventType
{
    var name: String { return "Viewed Activity Day" }

    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            "Days ago": daysAgo,
            "Date": date
        ]
    }
}

extension UIImage {
    func image(alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
