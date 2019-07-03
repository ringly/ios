import ReactiveSwift
import RinglyAPI
import UIKit
import enum Result.NoError

/// A view controller displaying the onboarding process for activity tracking.
final class ActivityOnboardingViewController: ServicesViewController
{
    // MARK: - Callbacks

    /// A callback executed on completion of onboarding.
    var completion: (() -> ())?

    // MARK: - Phases

    /// The phases to display. To take effect correctly, this property must be set before the view has loaded.
    var phases: [ActivityOnboardingPhase] = [
        .intro,
        .height,
        .bodyMass,
        .birthDate,
        //.healthKit,
        .stepGoal,
        .mindfulnessGoal,
        .complete
    ]

    /// Whether or not skipping is be allowed.
    let allowSkipping = MutableProperty(true)

    /// The phase that we'll go back to if the back button is tapped.
    fileprivate let backPhase = MutableProperty(ActivityOnboardingPhase?.none)

    // MARK: - Required Phases for Calculations

    /// The phases that need to be completed to calculate distance statistics.
    var requiredPhasesForDistance: [ActivityOnboardingPhase]
    {
        return [
            services.preferences.activityTrackingHeight.value?.value == nil ? .height : nil,
        ].flatMap({ $0 })
    }

    /// The phases that need to be completed to calculate kilocalorie statistics.
    var requiredPhasesForCalories: [ActivityOnboardingPhase]
    {
        return [
            services.preferences.activityTrackingHeight.value?.value == nil ? .height : nil,
            services.preferences.activityTrackingBodyMass.value?.value == nil ? .bodyMass : nil,
            services.preferences.activityTrackingBirthDateComponents.value?.value == nil ? .birthDate : nil
        ].flatMap({ $0 })
    }

    // MARK: - Subviews

    /// The topbar view, displaying the title and navigation buttons.
    fileprivate let navigationBar = NavigationBar.newAutoLayout()

    /// The container view controller displaying the current step.
    fileprivate let container = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        navigationBar.title.value = .text("ACTIVITY")
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        navigationBar.autoSet(dimension: .height, to: 80)

        // add container view controller
        addChildViewController(container)
        view.addSubview(container.view)

        container.view.autoPin(edge: .top, to: .bottom, of: navigationBar)
        container.view.autoPinEdgeToSuperview(edge: .left)
        container.view.autoPinEdgeToSuperview(edge: .right)
        container.view.autoPinEdgeToSuperview(edge: .bottom)

        container.didMove(toParentViewController: self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // lock in the phases
        let phases = self.phases
        let allowSkipping = self.allowSkipping

        func passed<Value>(_ property: MutableProperty<Skippable<Value>?>) -> Bool
        {
            return allowSkipping.value
                ? property.value != nil
                : property.value?.value != nil
        }

        // we may or may not create a HealthKit view controller - it is not possible to request again if we already have
        // a HealthKit authorization status, so there's no reason to display the view controller
        let startingPhase: ActivityOnboardingPhase = {
            if services.activityTracking.healthKitAuthorization.value == .notDetermined
            {
                return .intro
            }

            if !passed(services.preferences.activityTrackingHeight) && phases.contains(.height)
            {
                return .height
            }

            if !passed(services.preferences.activityTrackingBodyMass) && phases.contains(.bodyMass)
            {
                return .bodyMass
            }

            if !passed(services.preferences.activityTrackingBirthDateComponents) && phases.contains(.birthDate)
            {
                return .birthDate
            }

            return .complete
        }()

        displayViewController(for: startingPhase, forward: true)

        // Whether or not the user is permitted to navigate backwards to the HealthKit prompt. This is only allowed if
        // the user skipped the HealthKit prompt initially.
        let allowBackToHealthKitProducer = services.activityTracking.healthKitAuthorization.producer
            .map({ $0 == .notDetermined })

        // determine the back phase
        backPhase <~ allowBackToHealthKitProducer.combineLatest(with: phase.producer.skipNil())
            .map({ allowBackToHealthKit, phase -> ActivityOnboardingPhase? in
                guard phase != .complete else { return nil }

                return phases.index(of: phase).flatMap({ phases[safe: $0 - 1] }).flatMap({ previous in
                    previous != .healthKit || allowBackToHealthKit ? previous : nil
                })
            })

        // use the back button to go back
        backPhase.producer.sample(on: navigationBar.backProducer)
            .skipNil()
            .startWithValues({ [weak self] phase in
                self?.displayViewController(for: phase, forward: false)
            })

        // show and hide the back and skip buttons
        let skipActionProducer = phase.producer.skipNil()
            .map({ phase -> Bool in
                switch phase
                {
                case .mindfulnessGoal:
                    return false
                case .stepGoal:
                    return false
                case .intro:
                    return false
                case .healthKit:
                    return false
                default:
                    return true
                }
            })
            .skipRepeats()
            .combineLatest(with: allowSkipping.producer)
            .map({ canSkip, allowSkipping -> NavigationBar.Title? in
                canSkip ? .text(allowSkipping ? "SKIP" : "CANCEL") : nil
            })

        backPhase.producer.map({ $0 != nil }).skipRepeats()
            .combineLatest(with: skipActionProducer)
            .start(animationDuration: 0.25, action: { [weak navigationBar] showBack, skipAction in
                navigationBar?.backAvailable.value = showBack
                navigationBar?.action.value = skipAction
                navigationBar?.layoutIfInWindowAndNeeded()
            })

        // if skipping is disallowed, the skip button will cancel
        let skipButtonProducer = navigationBar.actionProducer

        allowSkipping.producer
            .flatMap(.latest, transform: { allowSkipping in
                allowSkipping ? SignalProducer.empty : skipButtonProducer
            })
            .take(first: 1)
            .startWithValues({ [weak self] _ in
                self?.displayViewController(for: .complete, forward: true)
            })
    }

    // MARK: - Displaying View Controllers

    /// The current displayed onboarding phase.
    fileprivate let phase = MutableProperty(ActivityOnboardingPhase?.none)

    /// Displays a view controller in the container view controller.
    ///
    /// - parameter viewController: The view controller to display.
    /// - parameter forward:        Whether or not this is a forward transition.
    fileprivate func display(_ viewController: UIViewController, forward: Bool)
    {
        container.setViewControllers(
            [viewController],
            direction: forward ? .forward : .reverse,
            animated: (container.viewControllers?.count ?? 0) > 0,
            completion: nil
        )
    }

    /// Displays a view controller for a new phase in the container view controller.
    ///
    /// - parameter phase:    The phase to display.
    /// - parameter forward:  Whether or not this is a forward transition.
    fileprivate func displayViewController(for phase: ActivityOnboardingPhase, forward: Bool)
    {
        let nextPhase = phases.index(of: phase).flatMap({ phases[safe: $0 + 1] }) ?? .complete
        
        let goalFormatter = NumberFormatter()
        goalFormatter.usesGroupingSeparator = true
        goalFormatter.numberStyle = .decimal

        switch phase
        {
        case .healthKit:
            break
        case .intro:
            let intro = ActivityIntroViewController(services: services)

            self.services.preferences.activityTrackingMindfulnessOnboardingSet.value = false

            SignalProducer(intro.buttonTapSignal)
                .promoteErrors(NSError.self)
                .take(first: 1)
                .observe(on: UIScheduler())

                // advance to the body data steps
                .on(completed: { [weak self] in
                    self?.displayViewController(for: nextPhase, forward: true)
                })

                // display errors above the view controller
                .startWithFailed({ [weak self] error in
                    self?.presentError(error)
                })

            display(intro, forward: forward)

        case .height:
            let services = self.services

            displayBodyDataController(
                make: { SelectHeightViewController(services: services) },
                property: services.preferences.activityTrackingHeight,
                next: nextPhase,
                forward: forward
            )

        case .bodyMass:
            let services = self.services

            displayBodyDataController(
                make: { SelectBodyMassViewController(services: services) },
                property: services.preferences.activityTrackingBodyMass,
                next: nextPhase,
                forward: forward
            )

        case .birthDate:
            let controller = SelectBirthDateViewController()

            skippableProducer(controller.selectedDateComponentsProducer).startWithValues({ [weak self] skippable in
                self?.services.preferences.activityTrackingBirthDateComponents.value = skippable
                self?.displayViewController(for: nextPhase, forward: true)
            })

            display(controller, forward: true)

        case .complete:
            services.engagementNotifications.cancel(.setUpActivity)
            completion?()
        case .stepGoal:
            let services = self.services
            
            let makeController:(() -> SelectGoalViewController) = {
                let selectGoal = SelectGoalViewController(services: services)
                selectGoal.displayConfiguration = SelectGoalDisplayConfiguration(
                    title: "STAY ACTIVE GOAL",
                    description: "Track your steps, everyday. Most people start with a 7k daily goal.",
                    confirmTitle: "SET GOAL"
                )
                
                selectGoal.dataConfiguration = SelectGoalDataConfiguration(
                    range: Range(uncheckedBounds: (500, 100000)),
                    stepSize: 500,
                    defaultValue: 7000,
                    unitOfMeasureString: { _ in "STEPS" },
                    valueString: { goalFormatter.string(from: NSNumber(value: $0))!.attributedOnboardingTitleString }
                )
                
                return selectGoal
            }
            
            displayGoalSetController(make: makeController,
                                     property: services.preferences.activityTrackingStepsGoal,
                                     next: nextPhase,
                                     forward: forward
                                    )
        case .mindfulnessGoal:
            let services = self.services
            
            let makeController:(() -> SelectGoalViewController) = {
                let selectGoal = SelectGoalViewController(services: services)
                selectGoal.displayConfiguration = SelectGoalDisplayConfiguration(
                    title: "STAY MINDFUL",
                    description: "Set a goal to de-stress each day with short mindfulness exercises.",
                    confirmTitle: "SET GOAL"
                )
                
                selectGoal.dataConfiguration = SelectGoalDataConfiguration(
                    range: Range(uncheckedBounds: (5, 30)),
                    stepSize: 1,
                    defaultValue: 5,
                    unitOfMeasureString: { _ in "MINUTES" },
                    valueString: { goalFormatter.string(from: NSNumber(value: $0))!.attributedOnboardingTitleString }
                )
                
                return selectGoal
            }

            displayGoalSetController(make: makeController,
                                     property: services.preferences.activityTrackingMindfulnessGoal,
                                     next: nextPhase,
                                     forward: forward
            )
        }

        self.phase.value = phase
    }

    /// Displays a select body data controller, and sets a property to its confirmed value.
    ///
    /// - parameter make:     A function to create the body data view controller.
    /// - parameter property: The property to set.
    /// - parameter next:     The next phase to display.
    /// - parameter forward:  Whether or not this is a forward transition.
    fileprivate func displayBodyDataController(make: () -> SelectBodyDataViewController,
                                               property: MutableProperty<Skippable<PreferencesHKQuantity>?>,
                                               next: ActivityOnboardingPhase,
                                               forward: Bool)
    {
        let controller = make()

        let valueProducer = SignalProducer(controller.confirmedValueSignal)

        skippableProducer(valueProducer).startWithValues({ [weak self] skippable in
            property.value = skippable
            self?.displayViewController(for: next, forward: true)
        })

        display(controller, forward: forward)
    }
    
    fileprivate func displayGoalSetController(make: () -> SelectGoalViewController,
                                              property: MutableProperty<Int>,
                                              next: ActivityOnboardingPhase,
                                              forward: Bool)
    {
        let controller = make()
        let valueProducer = SignalProducer(controller.confirmedValueSignal)
        
        valueProducer.startWithValues({ [weak self] value in
            property.value = value
            self?.displayViewController(for: next, forward: true)
        })
        
        display(controller, forward: forward)
    }

    /// Creates a producer for the skippable UI.
    ///
    /// - parameter valueProducer: The value producer.
    fileprivate func skippableProducer<Value: Coding>(_ valueProducer: SignalProducer<Value, NoError>)
        -> SignalProducer<Skippable<Value>, NoError>
    {
        let skippableValueProducer = valueProducer.map({ Skippable<Value>.Value($0) })

        return SignalProducer.merge(skippedProducer(), skippableValueProducer)
            .take(first: 1)
            .take(until: navigationBar.backProducer)
    }

    /// A producer for skipping data entry. If skipping is disallowed, this producer will be empty.
    fileprivate func skippedProducer<Value>() -> SignalProducer<Skippable<Value>, NoError>
    {
        let skipButtonProducer = navigationBar.actionProducer

        return allowSkipping.producer
            .flatMap(.latest, transform: { allowSkipping in
                allowSkipping ? skipButtonProducer : SignalProducer.empty
            })
            .map({ _ in .skipped })
    }
}

enum ActivityOnboardingPhase
{
    case intro
    case height
    case bodyMass
    case birthDate
    case healthKit
    case stepGoal
    case mindfulnessGoal
    case complete
}
