import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyAPI
import RinglyKit

public final class DFUController: NSObject
{
    // MARK: - Initialization
    public init(delegate: DFUControllerDelegate, mode: DFUControllerMode, packageSource: PackageSource)
    {
        self.delegate = delegate
        self.mode = mode
        self.packageSource = packageSource
    }

    // MARK: - Delegation

    /// The controller's delegate.
    fileprivate let delegate: DFUControllerDelegate

    // MARK: - Settings

    /// The update mode to use.
    fileprivate var mode: DFUControllerMode?

    /// The package source for the controller.
    fileprivate let packageSource: PackageSource

    // MARK: - Confirmation Pipes

    /// A pipe for performing `confirmPeripheralInCharger()`.
    fileprivate let confirmPeripheralInChargerPipe = Signal<(), NoError>.pipe()

    /// A pipe for performing `confirmPhoneInCharger()`.
    fileprivate let confirmPhoneInChargerPipe = Signal<(), NoError>.pipe()
}

extension DFUController
{
    // MARK: - Performing DFU

    /// A signal producer that, when started, will used the controller to perform DFU
    ///
    /// This producer must be started only once - further attempts to start will yield a failure event.
    public func DFUProducer() -> SignalProducer<State, NSError>
    {
        return SignalProducer { observer, disposable in
            // only allow writing once, and allow mode-referenced objects to deallocate once mode is no longer necessary
            guard let mode = self.mode else {
                observer.send(error: DFUMakeError(.onlyWriteOnce) as NSError)
                return
            }

            self.mode = nil

            // create mode-derived producers
            let peripheralInCharger = mode.peripheral.map(self.peripheralInChargerProducer) ?? SignalProducer.empty

            // start with downloading phase
            observer.send(value: .activity(.downloading))

            // retrieve the package to install
            disposable += self.retrievePackageProducer()
                // show initial charger steps
                .inject(producer: self.phoneInChargerProducer(), observer: observer)
                .inject(producer: peripheralInCharger, observer: observer)

                // perform DFU steps for the mode we are using
                .flatMap(.latest, transform: { package -> SignalProducer<(), NSError> in
                    mode.producer(package: package, delegate: self.delegate)
                        .on(value: observer.send)
                        .ignoreValues()
                })

                // notify the observer when the producer completes or fails
                .ignoreValues(State.self)
                .start(observer)
        }.skipRepeats().concat(SignalProducer(value: .completed))
    }
}

extension DFUController
{
    // MARK: - Confirmation of Steps

    /// If `state` is `.PeripheralInCharger`, advances to the next stage.
    public func confirmPeripheralInCharger()
    {
        DFULogFunction("Confirmed peripheral in charger")
        confirmPeripheralInChargerPipe.1.send(value: ())
    }

    /// If `state` is `.PhoneInCharger`, advances to the next stage.
    public func confirmPhoneInCharger()
    {
        DFULogFunction("Confirmed phone in charger")
        confirmPhoneInChargerPipe.1.send(value: ())
    }

    /**
     A signal producer for a confirmation step.
     
     The producer will immediately yield `state`, when complete when a `next` is sent on `signal`.

     - parameter state:  The state to yield when the producer is started.
     - parameter signal: The signal to observe for a completion event.
     */
    fileprivate func confirmPipeProducer(state: State, signal: Signal<(), NoError>)
        -> SignalProducer<State, NoError>
    {
        return SignalProducer([
            SignalProducer(value: state),
            SignalProducer(signal)
                .take(first: 1)
                .ignoreValues(State.self)
        ]).flatten(.concat)
    }
}

extension DFUController
{
    // MARK: - Retrieving the Package

    /// A producer for retrieving the package from the package source.
    fileprivate func retrievePackageProducer() -> SignalProducer<Package, NSError>
    {
        return packageSource.packageProducer.observe(on: QueueScheduler.main)
    }
}

extension DFUController
{
    // MARK: - Placing Peripheral in Charger

    /// A producer for waiting for the user to place his or her peripheral in the charger.
    fileprivate func peripheralInChargerProducer(_ peripheral: RLYPeripheral) -> SignalProducer<State, NoError>
    {
        // determine the current charger state
        let chargerState = peripheral.reactive.batteryState

        // wait until the peripheral is charging, then wait for the confirmation step - it must be charging to confirm!
        let confirmPipeProducer = SignalProducer(confirmPeripheralInChargerPipe.0)

        let confirmProducer: SignalProducer<(), NoError> = chargerState
            .flatMap(.latest, transform: { (state: RLYPeripheralBatteryState?) -> SignalProducer<(), NoError> in
                (state == .charging || state == .charged) ? confirmPipeProducer : SignalProducer.never
            })

        // wrap in a `State` value
        let confirmed = chargerState.take(until: confirmProducer)
        return confirmed.map({ (chargerState: RLYPeripheralBatteryState?) -> State in
            State.peripheralInCharger(chargerState)
        })
    }
}

extension DFUController
{
    // MARK: - Placing Phone in Charger

    /// A producer for waiting for the user to place his or her phone in the charger, if necessary.
    fileprivate func phoneInChargerProducer() -> SignalProducer<State, NoError>
    {
        let requiredCharge: Float = 0.1

        return SignalProducer.`defer` {
            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true

            if device.batteryLevel > requiredCharge || device.batteryState.charging
            {
                device.isBatteryMonitoringEnabled = false
                return SignalProducer.empty
            }
            else
            {
                return SignalProducer.concat(
                    // notify the client to display a phone-in-charger interface
                    SignalProducer(value: .phoneInCharger(.waiting)),

                    // wait until the phone has begun charging or reached the required charge level
                    device.reactive.battery
                        .filter({ $0.level > requiredCharge || $0.state.charging })
                        .take(first: 1)
                        .then(self.confirmPhoneInChargerProducer())
                ).on(terminated: { device.isBatteryMonitoringEnabled = false })
            }
        }
    }

    /// A producer for confirming that the phone-in-charger phase has completed
    fileprivate func confirmPhoneInChargerProducer() -> SignalProducer<State, NoError>
    {
        return confirmPipeProducer(state: .phoneInCharger(.inCharger), signal: confirmPhoneInChargerPipe.0)
    }
}
