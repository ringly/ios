import HealthKit
import ReactiveSwift
import Result
import RinglyActivityTracking
import RinglyExtensions
import UIKit

final class ActivityTrackingViewController: ServicesViewController
{
    // MARK: - Pull-to-Reveal Updated

    /// The height of the updated section.
    fileprivate static let updatedContainerHeight: CGFloat = 75

    /// The background container for the updated section.
    fileprivate let updatedContainer = UIView.newAutoLayout()

    /// The text label for the updated section.
    fileprivate let updatedLabel = UILabel.newAutoLayout()

    /// The pull-down shadow for the updated section.
    fileprivate let updatedShadow = GradientView.shadowGradientView(alpha: 0.25)

    /// The current translation offset, which is used to offset the tab bar.
    fileprivate let currentTranslationOffset = MutableProperty<Bool>(false)

    // MARK: - Containers
    fileprivate var background = GradientView.activityTrackingGradientView
    fileprivate let container = ContainerViewController()

    // MARK: - State

    /// Causes the view controller to display an onboarding view controller for the specific calculation.
    fileprivate let onboardingOverride = MutableProperty(ActivityStatisticsCalculation?.none)
    fileprivate let onboardingComplete = MutableProperty(false)
    
    let autoPushMindfulness = MutableProperty(false)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add pull-to-reveal updated section
        view.addSubview(updatedContainer)

        updatedContainer.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        updatedContainer.autoSet(dimension: .height, to: ActivityTrackingViewController.updatedContainerHeight)

        updatedLabel.textColor = .white
        updatedContainer.addSubview(updatedLabel)

        updatedLabel.autoCenterInSuperview()

        // add background and container
        view.addSubview(background)
        background.autoPinEdgesToSuperviewEdges()

        container.childTransitioningDelegate = self
        container.addAsEdgePinnedChild(of: self, in: background)

        // add shadow for updated section
        view.addSubview(updatedShadow)

        updatedShadow.autoSet(dimension: .height, to: 20)
        updatedShadow.autoPinEdgeToSuperview(edge: .left)
        updatedShadow.autoPinEdgeToSuperview(edge: .right)
        updatedShadow.autoPin(edge: .bottom, to: .top, of: background)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let preferences = services.preferences
        let scheduler = UIScheduler()

        // a producer that sends a value when onboarding has been completed
        let onboardingCompleteProducer =
            services.activityTracking.activityOnboardingCompletedProducer(preferences: preferences)

        // the parameters used to determine which type of child view controller should be displayed
        let childParametersProducer = SignalProducer.combineLatest(
            onboardingCompleteProducer,
            onboardingOverride.producer
        )

        // binds the child view controller displayed by this view controller
        container.childViewController <~ childParametersProducer
            .map({ onboardingComplete, onboardingOverride -> Content in
                return onboardingOverride.map(Content.onboarding)
                    ?? (onboardingComplete ? .data : .onboarding(nil))
            })
            .skipRepeats()
            .observe(on: scheduler)
            .map({ [weak self] update in self?.childViewController(for: update) })


        let connectivityProducer = services.peripherals.activityTrackingConnectivityProducer
        let authorizationProducer = services.activityTracking.healthKitAuthorization.producer

        services.peripherals.readingActivityTrackingData.producer
            .combineLatest(with: services.preferences.activityEventLastReadCompletionDate.producer)
            .flatMap(.latest, transform: { updating, optionalDate -> SignalProducer<String, NoError> in
                if updating
                {
                    return SignalProducer(value: "Updating")
                }
                else if let readDate = optionalDate
                {
                    // TODO: optimize to required time interval, instead of running continuously
                    return immediateTimer(interval: .seconds(1), on: QueueScheduler.main).map({ date in
                        date.relativeString(since: readDate)
                    })
                }
                else
                {
                    return connectivityProducer.combineLatest(with: authorizationProducer).map({ connectivity, auth in
                        switch connectivity
                        {
                        case .haveTracking, .haveTrackingAndNoTracking, .updateRequired:
                            return tr(.activityWaitingForUpdates)
                        case .noTracking, .noPeripheralsNoHealth:
                            switch auth
                            {
                            case .sharingAuthorized:
                                return tr(.activityPoweredByHealth)
                            case .sharingDenied, .notDetermined:
                                return tr(.activityPleaseConnectHealth)
                            }
                        }
                    })
                }
            })
            .observe(on: scheduler)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak updatedLabel] text in
                updatedLabel?.attributedText = UIFont.gothamBook(11).track(150, text).attributedString
            })
        
        //if you land here and you havent prompted for healthkit, show the dialog
        services.activityTracking.healthKitAuthorization.producer
            .combineLatest(with: onboardingCompleteProducer).startWithValues { [weak self] (status, onboardingComplete) in
                if status == .notDetermined && onboardingComplete {
                    if let strong = self,
                        strong.services.activityTracking.mindfulType == nil && strong.healthKitPromptTimesSeen() < 2 {
                        strong.presentHealthkitPrompt()
                        strong.incrementHealthkitPromptSeen()
                    }
                }
        }
    }
    
    func healthKitPromptTimesSeen() -> Int {
        return UserDefaults.standard.integer(forKey: "HealthKitPromptSeen")
    }
    
    func incrementHealthkitPromptSeen() {
        let currentVal = self.healthKitPromptTimesSeen()
        UserDefaults.standard.set(currentVal + 1, forKey: "HealthKitPromptSeen")
    }

    
    /// Presents a healthkit prompt
    ///
    fileprivate func presentHealthkitPrompt()
    {
        let alert = AlertViewController()
        let actionTitle = tr(.connect)
        let dismissTitle = tr(.notNow)
        
        let dismiss = (title: dismissTitle, dismiss: true, action: { })
        let action:(()->Void) = {
            [weak self] in
            self?.services.activityTracking.requestHealthKitAuthorizationProducer().startWithFailed({ [weak self] in
                self?.presentError($0)
            })
        }
        
        
        alert.actionGroup = .double(action: (title: actionTitle, dismiss: true, action: action), dismiss: dismiss)
        alert.content = AlertImageTextContent(image: Asset.healthKitConnect.image ,text: "CONNECT TO HEALTH KIT", detailText: "Connecting syncs data tracked by your phone (even from before you got your Ringly) to Ringly for more accurate tracking.", tinted: false)
        alert.modalPresentationStyle = .overFullScreen
        
        
        present(alert, animated: true, completion: nil)
    }


    // MARK: - Child View Controller Content
    fileprivate enum Content: Equatable
    {
        case data
        case onboarding(ActivityStatisticsCalculation?)
    }

    fileprivate func childViewController(for content: Content) -> UIViewController
    {
        switch content
        {
        case .data:
            let controller = ActivityDataViewController(services: services)
            self.currentTranslationOffset <~ controller.currentTranslationOffset
            controller.autoPushMindfulness <~ self.autoPushMindfulness.producer
            controller.calendarBoundaryDatesResult <~ services.activityTracking.calendarBoundaryDatesResult.producer
            controller.requestedStatisticsCalculationOnboardingProducer.startWithValues({ [weak self] calculation in
                self?.onboardingOverride.value = calculation
            })
            controller.mindfulnessSectionChangeSignal.observeValues({ mindfulnessChange in
                if mindfulnessChange {
                    self.background.gradient = GradientView.mindfulnessGradientView.gradient
                } else {
                    self.background.gradient = GradientView.activityTrackingGradientView.gradient
                }
            })
            

            return controller

        case .onboarding(let optionalCalculation):
            let controller = ActivityOnboardingViewController(services: services)
            controller.completion = { [weak self] in
                self?.onboardingOverride.value = nil
                self?.services.preferences.activityTrackingMindfulnessOnboardingSet.value = true
            }

            if let calculation = optionalCalculation
            {
                controller.allowSkipping.value = false

                switch calculation
                {
                case .distance:
                    controller.phases = controller.requiredPhasesForDistance
                case .calories:
                    controller.phases = controller.requiredPhasesForCalories
                }
            }

            return controller
        }
    }
}

extension ActivityTrackingViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        // only transition to and from non-nil view controllers, nil only occurs at startup
        guard fromViewController != nil && toViewController != nil else { return nil }

        return SlideTransitionController(operation: .push)
    }
}

extension ActivityTrackingViewController: TabBarViewControllerOffsetting
{
    var tabBarOffsettingProducer: SignalProducer<Bool, NoError>
    {
        return currentTranslationOffset.producer
    }
}

extension ActivityTrackingViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        container.tabBarViewControllerDidTapSelectedItem()
    }
}

extension Date
{
    func dayRelativeString(since date: Date) -> String
    {
        let today = tr(.today)
        let time = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        let fullDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        
        if NSCalendar.current.isDate(self, inSameDayAs: date) {
            return "\(today) \(time)"
        } else {
            return fullDate
        }
    }
    
    func relativeString(since date: Date) -> String
    {
        func relativeString(_ count: Int, singular: L10n, plural: (Int) -> L10n) -> String
        {
            return tr(count == 1 ? singular : plural(count))
        }

        let seconds = Int(timeIntervalSince(date))

        if seconds == 0
        {
            return tr(.activityUpdatedJustNow)
        }
        else if seconds < 60
        {
            return relativeString(
                seconds,
                singular: .activityUpdatedOneSecondAgo,
                plural: L10n.activityUpdatedSecondsAgo
            )
        }
        else if seconds < 60 * 60
        {
            return relativeString(
                seconds / 60,
                singular: .activityUpdatedOneMinuteAgo,
                plural: L10n.activityUpdatedMinutesAgo
            )
        }
        else
        {
            return relativeString(
                seconds / 60 / 60,
                singular: .activityUpdatedOneHourAgo,
                plural: L10n.activityUpdatedHoursAgo
            )
        }
    }
}

private func ==(lhs: ActivityTrackingViewController.Content, rhs: ActivityTrackingViewController.Content) -> Bool
{
    switch (lhs, rhs)
    {
    case (.data, .data):
        return true
    case let (.onboarding(lhsCalc), .onboarding(rhsCalc)):
        return lhsCalc == rhsCalc
    default:
        return false
    }
}

extension ActivityTrackingService
{
    func activityOnboardingCompletedProducer(preferences: Preferences) -> SignalProducer<Bool, NoError>
    {
        return preferences.activityTrackingBodyMass.producer.map({ $0 != nil })
            .and(preferences.activityTrackingHeight.producer.map({ $0 != nil }))
            .and(preferences.activityTrackingBirthDateComponents.producer.map({ $0 != nil }))
            .and(preferences.activityTrackingMindfulnessOnboardingSet.producer)
            .skipRepeats()
    }
}
