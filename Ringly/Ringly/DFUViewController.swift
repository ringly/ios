import ReactiveSwift
import Result
import RinglyDFU
import UIKit

final class DFUViewController: ServicesViewController
{
    // MARK: - Callbacks
    
    /// A completion callback for the view controller.
    var completion: (DFUViewController) -> () = { _ in }
    var failed: (DFUViewController) -> () = { _ in }
    
    // MARK: - State

    /// The current DFU controller
    fileprivate let controller = MutableProperty(DFUController?.none)

    /// The current DFU state.
    fileprivate let state = MutableProperty(State?.none)

    /// The style for the peripheral being updated.
    fileprivate var peripheralStyle: RLYPeripheralStyle?

    // MARK: - View Controllers
    fileprivate let container = ContainerViewController()

    // MARK: - View Loading
    override func loadView()
    {
        let view = GradientView.blueGreenGradientView
        self.view = view

        // add container view controller
        container.childTransitioningDelegate = self
        addChildViewController(container)
        view.addSubview(container.view)
        container.view.autoPinEdgesToSuperviewEdges()
        container.didMove(toParentViewController: self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // a pipe for cancellation
        let cancelPipe = Signal<(), NoError>.pipe()

        // automatically start the DFU process once we have a DFU controller
        state <~ controller.producer.skipNil().take(first: 1)
            .promoteErrors(NSError.self)
            .flatMap(.latest, transform: { controller in controller.DFUProducer() })

            // allow cancellation
            .take(until: cancelPipe.0)

            // this affects UI, so move to main thread
            .observe(on: QueueScheduler.main)

            // track analytics events for errors
            .on(failed: { [weak self] error in
                self?.services.analytics.track(AnalyticsEvent.applicationError(error: error))
                self?.services.analytics.track(AnalyticsDFUEvent.failed)
                SLogDFU("Error during DFU update: \(error)")
            })

            // show an error alert if DFU fails
            .flatMapError({ [weak self] error in
                (self?.presentDFUErrorProducer(error) ?? SignalProducer.empty).ignoreValues(State.self)
            })

            // delay after completion for 10 seconds
            .flatMap(.latest, transform: { state -> SignalProducer<State, NoError> in
                switch state
                {
                case .completed:
                    return SignalProducer(value: .completed).concat(
                        timer(interval: .seconds(10), on: QueueScheduler.main).take(first: 1).ignoreValues(State.self)
                    )

                default:
                    return SignalProducer(value: state)
                }
            })

            // send completion callback
            .on(completed: { [weak self] in
                guard let strong = self else { return }
                strong.completion(strong)
                strong.services.preferences.deviceInRecovery.value = false
            })
            
            // else if dfu failed, send failed callback
            .on(interrupted: { [weak self] in
                guard let strong = self else { return }
                strong.failed(strong)
            })
            
            // convert to optional for binding
            .map({ $0 })

        // display interface
        let container = self.container

        state.producer.skipNil()
            .map({ [weak self] state in
                DFUViewController.updateContainerFunction(state, peripheralStyle: self?.peripheralStyle)
            })
            .startWithValues({ updateContainer in
                updateContainer(container)
            })

        // a producer of starting view controllers, when the child is a starting view controller
        let startingViewControllerProducer = container.childViewController.producer
            .map({ $0 as? DFUStartingViewController })

        // send DFU controller to starting controller
        startingViewControllerProducer.skipNil().startWithValues({ [weak self] controller in
            controller.DFUController = self?.controller.value
        })
        
        // update device in recovery to true once switches to progress view controller
        container.childViewController.producer.map({ $0 as? DFUProgressViewController }).skipNil().startWithValues({ _ in self.services.preferences.deviceInRecovery.value = true})

        // allow cancellation from starting controller
        startingViewControllerProducer
            .flatMapOptional(.latest, transform: { controller in
                SignalProducer(controller.cancel.reactive.controlEvents(.touchUpInside)).void
            })
            .skipNil()
            .start(cancelPipe.1)

        // track analytics events
        let stateEventProducers = state.producer.skipNil().skipRepeats().map({ state -> AnalyticsDFUEvent? in
            switch state
            {
            case .completed:
                return AnalyticsDFUEvent.completed

            case let .phoneInCharger(chargerState):
                switch chargerState
                {
                case .waiting:
                    return AnalyticsDFUEvent.requestedPhoneCharging
                case .inCharger:
                    return AnalyticsDFUEvent.phoneCharging
                }

            case let .peripheralInCharger(batteryState):
                return batteryState == .charging || batteryState == .charged
                    ? AnalyticsDFUEvent.ringInCharger
                    : nil

            case .waitingForForgetThisDevice:
                return AnalyticsDFUEvent.requestedForgetThisDevice

            default:
                return nil
            }
        }).skipNil()

        let requestedRingInChargerProducer = state.producer.skipNil().map({ state -> AnalyticsDFUEvent? in
            switch state
            {
            case .peripheralInCharger:
                return AnalyticsDFUEvent.requestedRingInCharger
            default:
                return nil
            }
        }).skipNil().take(first: 1)

        let cancelledEvents = SignalProducer(
            cancelPipe.0.map({ _ -> AnalyticsDFUEvent in AnalyticsDFUEvent.cancelled })
        )

        let events = SignalProducer.merge(stateEventProducers, requestedRingInChargerProducer, cancelledEvents)

        events.observe(on: QueueScheduler.main)
            .startWithValues({ [weak self] in self?.services.analytics.track($0) })
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }

    // MARK: - Configuration

    /// Configures the DFU view controller.
    ///
    /// - parameter mode:          The DFU mode to use.
    /// - parameter packageSource: The package source to use.
    func configure(mode: DFUControllerMode, packageSource: PackageSource)
    {
        // read the battery characteristics as a safe fallback for ring-in-charger phase
        do
        {
            try mode.peripheral?.readBatteryCharacteristics()
        }
        catch let error as NSError
        {
            SLogDFU("Error reading battery characteristic at start of DFU: \(error)")
        }

        controller.value = DFUController(
            delegate: services.peripherals,
            mode: mode,
            packageSource: packageSource
        )

        peripheralStyle = mode.peripheral?.style
    }
}

extension DFUViewController
{
    // MARK: - Container View Controller

    /// Returns a container view controller update function for the specified DFU state.
    ///
    /// - Parameters:
    ///   - state: The DFU state.
    ///   - peripheralStyle: The style of the peripheral being updated, if available.
    fileprivate static func updateContainerFunction(_ state: State, peripheralStyle: RLYPeripheralStyle?)
        -> (ContainerViewController) -> ()
    {
        switch state
        {
        case .activity(let reason):
            switch reason
            {
            case .downloading:
                return DFUActivityViewController.updateContainer
            default:
                return DFUProgressViewController.updateContainer(state: nil)
            }

        case .completed:
            return DFUCompleteViewController.updateContainer(state: peripheralStyle)

        case .writing(let progress):
            let update = DFUProgressViewUpdateNumber(current: UInt(progress.index + 1), total: UInt(progress.count))
            return DFUProgressViewController.updateContainer(state: (progress.progress, update))

        case .waitingForBluetoothToggle:
            return DFUToggleBluetoothViewController.updateContainer

        case .waitingForForgetThisDevice(let initial):
            return initial
                ? DFUStartingViewController.updateContainer(state: .waitingForForgetThisDevice)
                : DFUOpenSettingsViewController.updateContainer(state: .second)

        case .peripheralInCharger(let chargerState):
            return DFUStartingViewController.updateContainer(state: .peripheralInCharger(chargerState))

        case .phoneInCharger(let chargerState):
            return DFUStartingViewController.updateContainer(state: .phoneInCharger(chargerState))
        }
    }
}

extension DFUViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        return ScaleTransitionController()
    }
}

// MARK: - Stateless Child View Controllers
protocol DFUStatelessChildViewController
{
    init()
}

extension DFUStatelessChildViewController where Self: UIViewController
{
    static var updateContainer: (ContainerViewController) -> ()
    {
        return { container in
            if !(container.childViewController.value is Self)
            {
                container.childViewController.value = Self()
            }
        }
    }
}

// MARK: - Child View Controllers
protocol DFUChildViewController
{
    /// The state type for this view controller.
    associatedtype State

    /// Updates the view controller's state.
    func update(_ state: State)
}

extension DFUChildViewController where Self: UIViewController
{
    /**
     Returns a function that will update a container view controller with the specified state value.

     - parameter state: The view controller state value.
     */
    static func updateContainer(state: State) -> (ContainerViewController) -> ()
    {
        return { container in
            if let child = container.childViewController.value as? Self
            {
                child.update(state)
            }
            else
            {
                let viewController = Self()
                viewController.update(state)
                container.childViewController.value = viewController
            }
        }
    }
}

// MARK: - Child View Controllers with Properties
protocol DFUPropertyChildViewController: DFUChildViewController
{
    var state: MutableProperty<State> { get }
}

extension DFUPropertyChildViewController
{
    func update(_ state: State)
    {
        self.state.value = state
    }
}
