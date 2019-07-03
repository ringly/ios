import HealthKit
import PureLayout
import ReactiveSwift
import Result
import RinglyAPI
import RinglyExtensions
import UIKit

/// Displays a single peripheral reference, used as a page in `PeripheralsViewController`.
final class PeripheralReferenceViewController: ServicesViewController
{
    // MARK: - Subviews

    /// The view containing labels displaying the peripheral's name and current state.
    fileprivate let referenceView = PeripheralReferenceView.newAutoLayout()

    // MARK: - View State

    /// Whether or not the "remove" interface should be displayed.
    fileprivate let removing = MutableProperty(false)

    /// Whether or not the displayed peripheral has updates available.
    fileprivate let firmwareResult = MutableProperty(FirmwareResult?.none)

    // MARK: - Peripheral Reference

    /// The current peripheral reference displayed by this view controller.
    let peripheralReference = MutableProperty(PeripheralReference?.none)

    /// A producer for the current peripheral.
    fileprivate var peripheralProducer: SignalProducer<RLYPeripheral?, NoError>
    {
        return peripheralReference.producer.map({ $0?.peripheralValue })
    }

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add a container to center all main content
        let container = UIView.newAutoLayout()
        view.addSubview(container)
        container.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0))

        // add reference view
        container.addSubview(referenceView)
        let peripheralOffset:CGFloat = DeviceScreenHeight.current.select(four: 0, five: 50, six: 100, sixPlus: 120, preferred: 120)
        referenceView.autoPinEdgeToSuperview(edge: .top, inset: peripheralOffset)
        referenceView.autoAlignAxis(toSuperviewAxis: .vertical)

        // determine the current firmware updates state
        firmwareResult <~ services.updates.firmwareResults.producer
            .combineLatest(with: peripheralProducer.flatMapOptional(.latest, transform: { $0.reactive.identifier }))
            .map(unwrap)
            .mapOptionalFlat({ updates, identifier -> FirmwareResult? in updates[identifier]?.value.flatten() })

        let hasUpdates = firmwareResult.producer.map({ $0 != nil })

        // observe if the current peripheral is activated
        let activatedIdentifier = services.peripherals.activatedIdentifier.producer
        let removingProducer = removing.producer


        // update the view model of the peripheral reference view
        peripheralReference.producer.flatMapOptional(.latest, transform: { reference -> SignalProducer<PeripheralReferenceView.Model, NoError> in
            let style = reference.style

            let connected = reference.peripheralValue.map({ peripheral in
                // when the peripheral disconnects, we wait for a little while before reporting it as disconnected
                // this is because the peripheral restarts and disconnects briefly when placed in the charger, and the
                // ui would flash back and forth in that case
                SignalProducer(value: peripheral.isConnected)
                    .concat(peripheral.reactive.connected
                        .skipRepeats()
                        .debounce(0.75, on: QueueScheduler.main, valuesPassingTest: { !$0 })
                    )
                    .skipRepeats()
            }) ?? SignalProducer(value: false)

            let activated = activatedIdentifier.map({ $0 == reference.identifier })
            
            let validated = reference.peripheralValue.map({ peripheral in
                SignalProducer(value: peripheral.isValidated)
                    .concat(peripheral.reactive.validated
                        .skipRepeats()
                        .debounce(0.75, on: QueueScheduler.main, valuesPassingTest: { !$0 })
                    )
                    .skipRepeats()
            }) ?? SignalProducer(value: false)


            // producers for the battery components of the peripheral
            let batteryCharge = reference.peripheralValue.map({ $0.reactive.batteryCharge }) ?? SignalProducer(value: nil)
            let batteryState = reference.peripheralValue.map({ $0.reactive.batteryState }) ?? SignalProducer(value: nil)

            return SignalProducer.combineLatest(connected, activated, validated, hasUpdates, removingProducer, batteryCharge, batteryState)
                .map({ connected, activated, validated, hasUpdates, removing, batteryCharge, batteryState in
                    PeripheralReferenceView.Model(
                        content: PeripheralReferenceContentView.Model(
                            connected: connected,
                            activated: activated,
                            validated: validated,
                            updateAvailable: connected && hasUpdates,
                            style: style,
                            batteryCharge: batteryCharge,
                            batteryState: batteryState
                        ),
                        removing: removing
                    )
                }).on(value: { model in
                    SLogUI("Displaying a peripheral, battery \(model.content.batteryCharge) \(model.content.batteryState?.rawValue)")
                })
        }).start(animationDuration: 0.25, action: { [weak referenceView] model in
            referenceView?.model.value = model
            referenceView?.superview?.layoutIfInWindowAndNeeded()
        })

        removing <~ referenceView.requestRemoveProducer
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        
        // activate peripherals
        referenceView.selectTapped.startWithValues({ [weak self] in
            guard let reference = self?.peripheralReference.value else { return }
            self?.services.peripherals.activate(identifier: reference.identifier)
            self?.presentActivitySupportModalIfNecessary()
        })

        
        referenceView.reconnectTapped.startWithValues { [weak self] in
            guard let reference = self?.peripheralReference.value else { return }

            if let peripheral = reference.peripheralValue {
                self?.services.peripherals.reconnect(with: peripheral)
            }
        }

        // vibrate on peripheral tap
        referenceView.peripheralTapped.startWithValues({ [weak self] in
            self?.sendBuzz($0)
        })

        // enable DFU when updates button is tapped
        referenceView.updateTapped.startWithValues({ [weak self] in self?.launchDFU() })

        // track DFU banner shown events
        referenceView.model.producer.map({ $0?.content.updateAvailable ?? false })
            .skipRepeats()
            .ignore(false)
            .startWithValues({ [weak self] _ in
                self?.services.analytics.track(AnalyticsDFUEvent.bannerShown)
            })
    }

    // MARK: - Actions

    /// Notifies an observer that the user has tapped the "not connecting" button.
    var notConnectingButtonProducer: SignalProducer<(), NoError>
    {
        return referenceView.notConnectedTapped
    }

    /// Notifies an observer that the user has tapped the "remove" button.
    var removeButtonProducer: SignalProducer<(), NoError>
    {
        return referenceView.removeProducer
    }

    // MARK: - Buzzing / Glowing
    fileprivate func sendBuzz(_ sender: UIControl)
    {
        let producer: SignalProducer<(), NoError>

        if let peripheral = peripheralReference.value?.peripheralValue, peripheral.canWriteCommands
        {
            producer = referenceView.peripheralControl.producerForVibrating(peripheral: peripheral)
        }
        else
        {
            producer = producerForDisconnectedWiggle()
        }

        sender.isUserInteractionEnabled = false
        producer.startWithCompleted({
            sender.isUserInteractionEnabled = true
        })
    }

    /// A signal producer that shakes the "disconnected" label, to explain why the peripheral isn't vibrating.
    fileprivate func producerForDisconnectedWiggle() -> SignalProducer<(), NoError>
    {
        return referenceView.producerForDisconnectedWiggle
    }

    // MARK: - DFU
    fileprivate func launchDFU()
    {
        if let peripheral = peripheralReference.value?.peripheralValue, let firmwareResult = firmwareResult.value
        {
            DispatchQueue.main.async(execute: {
                self.presentDFU(peripheral: peripheral, firmwareResult: firmwareResult)
            })
        }
        else
        {
            SLogUI("Attempted to launch DFU, but can't \(peripheralReference.value?.peripheralValue) \(firmwareResult.value)")
        }
    }

    // MARK: - Activity Unsupported
    func presentActivitySupportModalIfNecessary()
    {
        // determine the application version of the peripheral
        let availabilityProducer = peripheralProducer
            .skipNil()
            .flatMap(.latest, transform: { $0.reactive.activityTrackingAvailability })

        // determine which dialog presentation to make
        enum Presentation
        {
            case unsupported
            case update
        }

        let firmwareResultProducer = firmwareResult.producer.skipNil()
        let presentationProducer = availabilityProducer
            .flatMap(.latest, transform: { availability -> SignalProducer<Presentation, NoError> in
                switch availability
                {
                case .available, .undetermined:
                    return SignalProducer.empty
                case .unavailable:
                    return SignalProducer(value: .unsupported)
                case .updateRequired:
                    return firmwareResultProducer.map({ _ in .update })
                }
            })

        // limit the popup to a few seconds
        presentationProducer
            .timeoutAndComplete(afterInterval: 5, on: QueueScheduler.main)
            .startWithValues({ [weak self] presentation in
                switch presentation
                {
                case .unsupported:
                    self?.presentActivityUnsupported()
                case .update:
                    self?.presentActivityUpdateRequired()
                }
            })
    }


    /// Presents a specific activity support prompt.
    ///
    /// - Parameters:
    ///   - showAction: Whether or not the action button should be displayed.
    ///   - reason: The unsupported reason to display in the prompt.
    ///   - completion: A completion function to evaluate iff the user taps the action button.
    fileprivate func presentActivitySupportPrompt(_ showAction: Bool,
                                                  reason: PeripheralActivityUnsupportedReason,
                                                  completion: @escaping () -> ())
    {
        let alert = AlertViewController()
        alert.actionGroup = reason.alertActionGroup(showAction: showAction, action: completion)
        alert.content = reason
        alert.transitioningDelegate = self
        alert.modalPresentationStyle = .overFullScreen

        present(alert, animated: true, completion: nil)
    }

    fileprivate func presentActivityUnsupported()
    {
        // only show this alert once, forever
        guard !services.preferences.presentedActivityUnsupportedAlert.value else { return }
        services.preferences.presentedActivityUnsupportedAlert.value = true

        presentActivitySupportPrompt(
            services.activityTracking.healthKitAuthorization.value != .sharingAuthorized,
            reason: .unavailable,
            completion: { [weak self] in self?.presentHealthKitPrompt() }
        )
    }

    fileprivate func presentHealthKitPrompt()
    {
        switch services.activityTracking.healthKitAuthorization.value
        {
        case .notDetermined:
            services.activityTracking.requestHealthKitAuthorizationProducer().startWithFailed({ [weak self] in
                self?.presentError($0)
            })

        case .sharingAuthorized:
            // this will only occur if the user switches apps and activates Health while the prompt is active
            break

        case .sharingDenied:
            connectHealthPipe.1.send(value: ())
        }
    }

    fileprivate func presentActivityUpdateRequired()
    {
        presentActivitySupportPrompt(
            true,
            reason: .updateRequired,
            completion: { [weak self] in self?.launchDFU() }
        )
    }

    fileprivate let connectHealthPipe = Signal<(), NoError>.pipe()
    var connectHealthProducer: SignalProducer<(), NoError> { return SignalProducer(connectHealthPipe.0) }
}

extension PeripheralReferenceViewController: UIViewControllerTransitioningDelegate
{
    func animationController(forPresented presented: UIViewController,
                                                   presenting: UIViewController,
                                                   source: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        if let transitioning = presented as? ForegroundBackgroundContentViewProviding
        {
            return OverlayPresentationTransition(presentedProvider: transitioning, presenting: true)
        }
        else
        {
            return nil
        }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if let transitioning = dismissed as? ForegroundBackgroundContentViewProviding
        {
            return OverlayPresentationTransition(presentedProvider: transitioning, presenting: false)
        }
        else
        {
            return nil
        }
    }
}
