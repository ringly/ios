import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyActivityTracking
import RinglyDFU
import RinglyExtensions
import RinglyKit

/// Controls a set of connected peripherals.
final class PeripheralsService: NSObject
{
    // MARK: - Peripherals

    /// The current state of the service (and the peripherals it is tracking).
    @nonobjc fileprivate let state: MutableProperty<PeripheralsServiceState>

    /// A producer for the current state of the service (and the peripherals it is tracking).
    @nonobjc var stateProducer: SignalProducer<PeripheralsServiceState, NoError>
    {
        return state.producer
    }

    /// The current peripheral references.
    @nonobjc let references: Property<[PeripheralReference]>

    /// The currently activated peripheral identifier, if any.
    @nonobjc let activatedIdentifier: Property<UUID?>

    /// The current referenced peripherals. Some items in `references` may refer to a saved peripheral, these are not
    /// included in this property's value.
    @nonobjc let peripherals: Property<[RLYPeripheral]>

    /// The activated peripheral, if any.
    ///
    /// This value may be `nil` is there is not an activated peripheral, or if the activated identifier matches a
    /// saved peripheral, but not an actual peripheral.
    @nonobjc let activatedPeripheral: Property<RLYPeripheral?>

    // MARK: - Activity Tracking
    @nonobjc let readingActivityTrackingData: Property<Bool>

    // MARK: - DFU Integration

    /// The peripherals registered for DFU forget this device, and their update functions.
    @nonobjc fileprivate var DFUForgetThisDevicePeripherals: [RLYPeripheral:((ForgetThisDeviceUpdate) -> ())] = [:]
    
    // The peripherals that are disconnected because you selected a different peripheral
    @nonobjc fileprivate var deselectedPeripherals: [RLYPeripheral] = []
    
    // The peripherals that are disconnected because you are trying to reconnect to it
    @nonobjc fileprivate var reconnectingPeripherals: [RLYPeripheral] = []

    /// The peripheral identifiers that are currently blacklisted for DFU.
    @nonobjc fileprivate let DFUBlacklistedIdentifiers = MutableProperty(Set<UUID>())

    // MARK: - Central

    /// The RinglyKit central controlled by this service.
    let central: RLYCentral

    /// The current Core Bluetooth state.
    @nonobjc let managerState: Property<CBCentralManagerState>

    // MARK: - Other Services

    /// An analytics service for tracking peripheral events.
    @nonobjc fileprivate let analyticsService: AnalyticsService

    /// An applications service for pulling current application settings from.
    @nonobjc fileprivate let applicationsService: ApplicationsService

    /// A contacts service for pulling current contact settings from.
    @nonobjc fileprivate let contactsService: ContactsService

    /// An activity tracking service.
    @nonobjc fileprivate let activityTrackingService: ActivityTrackingService

    /// The preferences store to use with the service.
    @nonobjc fileprivate let preferences: Preferences

    // MARK: - Initialization
    init(centralManagerRestoreIdentifier: String?,
         savedPeripherals: [SavedPeripheral],
         activatedIdentifier: UUID?,
         analyticsService: AnalyticsService,
         applicationsService: ApplicationsService,
         contactsService: ContactsService,
         activityTrackingService: ActivityTrackingService,
         preferences: Preferences)
    {
        // store child services
        self.analyticsService = analyticsService
        self.applicationsService = applicationsService
        self.contactsService = contactsService
        self.activityTrackingService = activityTrackingService
        self.preferences = preferences

        // create the state property, initialized from the passed-in saved data
        let initialPeripheralStates = savedPeripherals.map({ saved in
            PeripheralState(backingPeripheralReference: .saved(saved), disconnectErrors: [])
        })

        let initialActivatedIdentifier = initialPeripheralStates
            .first(where: { $0.identifier == activatedIdentifier })?
            .identifier

        let initialState = PeripheralsServiceState(
            activatedIdentifier: initialActivatedIdentifier,
            states: initialPeripheralStates
        )

        state = MutableProperty(initialState)

        // create derived properties, skipping any repeated values caused by state changes that do not affect them
        references = state.map({ $0.references }).skipRepeats(==)
        peripherals = references.map({ references in references.flatMap({ $0.peripheralValue }) }).skipRepeats(==)
        self.activatedIdentifier = state.map({ $0.activatedIdentifier }).skipRepeats(==)

        activatedPeripheral = Property.combineLatest(peripherals, self.activatedIdentifier)
            .map(unwrap)
            .map({ optional in
                optional.flatMap({ peripherals, identifier in
                    peripherals.first(where: { $0.identifier == identifier })
                })
            })
            .skipRepeats(==)



        // initialize central
        self.central = RLYCentral(cbCentralManagerRestoreIdentifier: centralManagerRestoreIdentifier)
        self.managerState = Property(initial: central.managerState, then: central.reactive.managerState)

        // observe activity tracking state
        readingActivityTrackingData = Property(
            initial: false,
            then: peripherals.producer.flatMap(.latest, transform: { peripherals -> SignalProducer<Bool, NoError> in
                let timeoutProducer = SignalProducer.merge(peripherals.map({ peripheral in
                    peripheral.reactive.activityTrackingEvents
                        .map({ event -> TimeInterval? in
                            switch event
                            {
                            case .completed:
                                return 2
                            case .value:
                                return 5
                            case .failed:
                                return 2
                            }
                        })
                        .skipNil()
                }))

                return timeoutProducer
                    .flatMap(.latest, transform: { timeout in
                        SignalProducer.concat(
                            SignalProducer(value: true),
                            SignalProducer(value: false).delay(timeout, on: QueueScheduler.main)
                        )
                    })
                    // SIDE-EFFECT: set latest completion event timestamp
                    .on(value: { _ in
                        preferences.activityEventLastReadCompletionDate.value = Date()
                    })
            })
        )

        super.init()

        // observe central state
        central.add(observer: self)

        central.reactive.managerState.startWithValues({ [weak self] state in
            SLogBluetooth("Bluetooth state updated to “\(state.loggingDescription)”")

            guard let strong = self, state == .poweredOn else { return }


            //connect to activated peripheral
            if let peripheral = strong.activatedPeripheral.value {
                strong.central.connect(to: peripheral)
            }
            
            // only retrieve UUIDs that we do not already have a peripheral for - although this isn't a big deal, as
            // `registerPeripheralAsReference` will not add a redundant peripheral.
            let unretrieved = strong.references.value
                .filter({ reference in reference.peripheralValue == nil })
                .map({ reference in reference.identifier })

            // retrieve and register each peripheral
            for peripheral in strong.central.retrievePeripheralsWith(identifiers: unretrieved as [UUID], assumedPaired: true)
            {
                strong.register(peripheral: peripheral)

                if peripheral.isConnected
                {
                    // We need to verify the pair state because this peripheral is already connected, so the central
                    // callback that usually performs this operation will not occur.
                    peripheral.verifyPaired()
                }
            }
        })
        
        activatedPeripheral
            .producer
            .skipNil()
            .on(value: { [weak self] peripheral in
                self?.central.connect(to: peripheral)
                
                self?.central.retrieveConnectedPeripherals()
                    .filter({ $0.identifier != peripheral.identifier })
                    .forEach({ peripheral in
                        self?.deselectedPeripherals.append(peripheral)
                        
                        peripheral.reactive.ANCSNotificationMode.skipRepeats().flatMap(.latest, transform: { mode -> SignalProducer<(), NoError> in
                            switch mode {
                            case .automatic:
                                return peripheral.reactive.clearANCSV2Settings()
                            case .phone:
                                return peripheral.reactive.sendANCSV1NoAction()
                            default:
                                return SignalProducer.empty
                            }
                        
                        }).start()
                        
                        
                        self?.central.cancelConnection(to: peripheral)
                    })
            }).start()
    }

    deinit
    {
        central.remove(observer: self)
    }
}

extension PeripheralsService
{
    // MARK: - Discovering Peripherals

    /**
     Registers any unregistered connected peripherals.

     - returns: Peripheral references for the peripherals that were registered.
     */
    func discoverAndRegisterConnectedPeripherals() -> [PeripheralReference]
    {
        let identifiers = Set(state.value.states.map({ $0.identifier }))

        let unregistered = central.retrieveConnectedPeripherals()
            .filter({ !identifiers.contains($0.identifier) })

        let references = unregistered.map(register)
        unregistered.forEach(central.connect)
        return references
    }
}

extension PeripheralsService
{
    // MARK: - Current States

    /// A flattened array of the current peripheral states.
    fileprivate var statesProducer: SignalProducer<[PeripheralState], NoError>
    {
        return state.producer.map({ $0.states })
    }
}

extension PeripheralsService
{
    // MARK: - Current Saved Peripherals

    /// A producer of the saved peripheral representations of the service's current peripherals.
    var savedPeripheralsProducer: SignalProducer<[SavedPeripheral], NoError>
    {
        return statesProducer.flatMap(.latest, transform: { states -> SignalProducer<[SavedPeripheral], NoError> in
            switch states.count
            {
            case 0:
                return SignalProducer(value: []) // combineLatest with an empty array yields an empty producer
            default:
                return SignalProducer.combineLatest(states.map({ state -> SignalProducer<SavedPeripheral, NoError> in
                    switch state.backingPeripheralReference
                    {
                    case .peripheral(let controller):
                        return controller.savedPeripheralProducer
                    case .saved(let saved):
                        return SignalProducer(value: saved)
                    }
                }))
            }
        })
    }
}

extension PeripheralsService
{
    func reconnect(with peripheral: RLYPeripheral) {
        self.reconnectingPeripherals.append(peripheral)
        self.central.cancelConnection(to: peripheral)
    }
    
    // MARK: - Pairing

    /**
     Creates a signal producer for pairing with the specified peripheral.

     If the peripheral is successfully paired, the signal producer will send the newly added peripheral reference
     property for the peripheral.

     - parameter peripheral: The peripheral to pair with.
     */
    func pair(with peripheral: RLYPeripheral) -> SignalProducer<PeripheralReference, NSError>
    {
        // describes the failure condition - the peripheral disconnects or fails to connect
        let failureProducer = central.reactive.peripheralConnectionEvents
            .filter({ event in event.peripheral == peripheral })
            .map({ event -> NSError? in
                switch event
                {
                case .didDisconnect(let params):
                    return params.error
                case .didFailToConnect(let params):
                    return params.error
                default:
                    return nil
                }
            })
            .skipNil()
            .promoteValuesToErrors()

        // if possible, repeatedly reads the peripheral's pair state
        let readBondCharacteristic = peripheral.reactive.readBondCharacteristicSupport
            .flatMap(.latest, transform: { support -> SignalProducer<(), NoError> in
                switch support
                {
                case .supported:
                    return immediateTimer(interval: .milliseconds(500), on: QueueScheduler.main).on(value: { _ in
                        do
                        {
                            try peripheral.readBondCharacteristic()
                        }
                        catch let error as NSError
                        {
                            SLogBluetooth("Error reading bond characteristic while pairing with \(peripheral.loggingName): \(error)")
                        }
                    }).ignoreValues()

                default:
                    return SignalProducer.empty
                }
            })

        // Create two producers that we will merge - one for success, and one for failure. We will only take one
        // event in total (from either), since errors will automatically terminate the outer signal, and we
        // will apply `await` to the merged producer to catch successful pairs.
        let producers = [
            peripheral.reactive.pairState.promoteErrors(NSError.self),
            failureProducer.ignoreValues(RLYPeripheralPairState.self),
            readBondCharacteristic.ignoreValues(RLYPeripheralPairState.self).promoteErrors(NSError.self)
        ]

        // wait until the peripheral is paired
        return SignalProducer.merge(producers)
            .await(.paired)
            .then(SignalProducer<PeripheralReference, NSError>.`defer` { [weak self] in
                guard let strong = self else { return SignalProducer.empty }

                // register and activate the peripheral
                let reference = strong.register(peripheral: peripheral)
                strong.activate(identifier: reference.identifier)
                return SignalProducer(value: reference)
            })
            .on(started: { [weak central] in
                // attempt to connect to the peripheral
                
                central?.connect(to: peripheral)
            })
    }
}

extension PeripheralsService
{
    // MARK: - Peripheral Handling

    /**
     Activates the peripheral with the specified identifier.

     - parameter identifier: The identifier to activate.
     */
    func activate(identifier: UUID)
    {
        state.pureModify({ current in
            PeripheralsServiceState(
                activatedIdentifier: identifier,
                states: current.states
            )
        })
    }
    
    /// A producer for the activation state of the specified identifier producer.
    ///
    /// - parameter identifierProducer: A producer that yields identifiers.
    ///
    /// - returns: A producer that yields `true` when the latest value sent by `identifierProducer` is the activated
    ///            identifier.
    func activatedProducer(identifierProducer: SignalProducer<UUID, NoError>)
        -> SignalProducer<Bool, NoError>
    {
        return activatedIdentifier.producer.combineLatest(with: identifierProducer).map({ $0 == $1 })
    }

    /// Creates a peripheral controller for the specified peripheral.
    ///
    /// - parameter peripheral:      The peripheral to create a controller for.
    /// - parameter savedPeripheral: A saved peripheral to bootstrap with (optional).
    fileprivate func peripheralController(for peripheral: RLYPeripheral, savedPeripheral: SavedPeripheral?)
        -> PeripheralController
    {
        return PeripheralController(
            peripheral: peripheral,
            savedPeripheral: savedPeripheral,
            activatedProducer: activatedProducer(identifierProducer: peripheral.reactive.identifier),
            applicationsProducer: applicationsService.activatedConfigurations.producer,
            contactsProducer: contactsService.activatedConfigurations.producer,
            analyticsService: analyticsService,
            activityTracking: activityTrackingService,
            preferences: preferences
        )
    }

    /**
     Registers the specified peripheral as a reference.

     This makes the peripheral available in `peripheralStates` and `peripheralReferences`, and should be done once a
     peripheral is paired. Peripherals that have already been added will not be added twice, but this should be avoided
     regardless for efficiency's sake.

     - parameter peripheral: The peripheral to register as a reference.
     */
    @discardableResult
    func register(peripheral: RLYPeripheral) -> PeripheralReference
    {
        var returnState: PeripheralState?

        state.pureModify({ state in
            var mutable = state

            if let index = mutable.states.index(where: { $0.identifier == peripheral.identifier })
            {
                let currentState = mutable.states[index]

                if currentState.peripheralValue != peripheral
                {
                    let controller = peripheralController(
                        for: peripheral,
                        savedPeripheral: currentState.savedPeripheral
                    )

                    let state = PeripheralState(
                        backingPeripheralReference: .peripheral(controller),
                        disconnectErrors: currentState.disconnectErrors
                    )

                    returnState = state
                    mutable.states[index] = state
                }
                else
                {
                    returnState = currentState
                }
            }
            else
            {
                let controller = peripheralController(for: peripheral, savedPeripheral: nil)

                let state = PeripheralState(
                    backingPeripheralReference: .peripheral(controller),
                    disconnectErrors: []
                )

                returnState = state
                mutable.states.append(state)
            }

            return mutable
        })

        return returnState!.peripheralReference
    }

    /**
     Removes the peripheral from the service.

     This does not perform any post-disconnect actions.

     - parameter peripheral: The peripheral to remove.
     */
    func remove(_ peripheral: RLYPeripheral)
    {
        state.modify({ current in
            if let index = current.states.index(where: { $0.identifier == peripheral.identifier })
            {
                current.states.remove(at: index)
            }
        })
    }
}

extension PeripheralsService: RLYCentralObserver
{
    // MARK: - Central Observer - State Restoration
    func central(_ central: RLYCentral, didRestore peripherals: [RLYPeripheral])
    {
        peripherals.forEach({ register(peripheral: $0) })
    }

    // MARK: - Central Observer - Connection
    func central(_ central: RLYCentral, didConnectTo peripheral: RLYPeripheral)
    {
        // ensure that this is a registered peripheral
        guard let reference = state.value.references.first(where: { $0.identifier == peripheral.identifier }) else { return }

        // if this peripheral was connected but a controller hasn't been created, create the controller
        // this will typically happen post-DFU, since the identifier is blacklisted during DFU
        if reference.peripheralValue == nil && !DFUBlacklistedIdentifiers.value.contains(reference.identifier)
        {
            state.modify({ current in
                if let index = current.states.index(where: { $0.identifier == peripheral.identifier })
                {
                    current.states[index].backingPeripheralReference = .peripheral(
                        peripheralController(
                            for: peripheral,
                            savedPeripheral: current.states[index].savedPeripheral
                        )
                    )
                }
            })
        }

        peripheral.verifyPaired()
    }

    func central(_ central: RLYCentral,
                 didDisconnectFrom peripheral: RLYPeripheral,
                 withError maybeError: Error?)
    {
        if let error = maybeError
        {
            SLogBluetooth("Did Disconnect from \(peripheral) error: \(error)")
            
            state.pureModify({ current -> PeripheralsServiceState in
                guard let index = current.states.index(where: { $0.peripheralValue == peripheral })
                    else { return current }

                var mutable = current

                // update the disconnect errors for the peripheral
                let disconnectError = DisconnectError(error: error as NSError, time: CFAbsoluteTimeGetCurrent())
                let disconnectErrors = Array(([disconnectError] + current.states[index].disconnectErrors).prefix(4))
                mutable.states[index].disconnectErrors = disconnectErrors

                let allDisconnected = disconnectErrors.all({ (disconnect: DisconnectError) -> Bool in
                    return disconnect.error.domain == CBErrorDomain
                        && disconnect.error.code == CBError.peripheralDisconnected.rawValue
                })

                let intervalShortEnough: Bool = unwrap(disconnectErrors.first, disconnectErrors.last)
                    .map({ first, last -> Bool in first.time - last.time < 15 }) ?? false

                if intervalShortEnough && allDisconnected && disconnectErrors.count >= 4
                {
                    SLogBluetooth("Will not reconnect, probably a bond issue")
                }
                else
                {
                    // This is less than ideal, as it can cause the bouncing connection state if we’re legitimately not
                    // bonded. However, it’s necessary to change this as the ring will occasionally disconnect with a
                    // code 7 when:
                    //
                    // - it has just reconnected (out of range, sleep)
                    // - it cannot find the ANCS service in a specific time interval
                    //
                    // Following this, it will reconnect. However, for some reason, we don’t get notified of that
                    // reconnection, so we consider the ring still to be disconnected, and nothing works. It’s
                    // interesting, because retrieving the connected peripherals does include the ring.
                    central.connect(to: peripheral)
                }

                return mutable
            })
        }
        else
        {
            struct Interrupt: Error {}

            central.reactive.managerState
                .timeoutAndComplete(afterInterval: 2, on: QueueScheduler.main)
                .flatMap(.concat, transform: { state -> SignalProducer<(), Interrupt> in
                    switch state
                    {
                    case .poweredOn:
                        return SignalProducer.empty
                    default:
                        return SignalProducer(error: Interrupt())
                    }
                })
                .startWithCompleted({ [weak self] in
                    guard let strong = self else { return }

                    strong.state.modify({ current in
                        guard let index = current.states.index(where: { $0.peripheralValue == peripheral })
                            else { return }
                        
                        if let deselectedIndex = strong.deselectedPeripherals.index(where: { $0.identifier == peripheral.identifier }) {
                            guard deselectedIndex < 0 else {
                                strong.deselectedPeripherals.remove(at: deselectedIndex)
                                return
                            }
                        }
                        
                        if let reconnectingIndex = strong.reconnectingPeripherals.index(where: { $0.identifier == peripheral.identifier }) {
                            guard reconnectingIndex < 0 else {
                                strong.central.connect(to: peripheral)
                                strong.reconnectingPeripherals.remove(at: reconnectingIndex)
                                return
                            }
                        }

                        // perform the post-disconnect process for that peripheral
                        let DFUUpdate = strong.DFUForgetThisDevicePeripherals[peripheral]
                        
                        current.states.remove(at: index)
                        
                        let mode = DFUUpdate == nil ? RLYCentralPostDisconnectMode.clearBonds : .dfu

                        DFUUpdate?(.started)

                        central.postDisconnectProducer(peripheral: peripheral, mode: mode)
                            .startWithCompleted({
                                DFUUpdate?(.completed)
                        })
                    })
                })
        }
    }
}

// MARK: - State Structure
struct PeripheralsServiceState
{
    /// The currently activated peripheral identifier, if any.
    fileprivate(set) var activatedIdentifier: UUID?

    /// The current peripheral states.
    fileprivate var states: [PeripheralState]
}

extension PeripheralsServiceState
{
    /// The current peripheral references.
    var references: [PeripheralReference]
    {
        return states.map({ $0.peripheralReference })
    }

    var peripherals: [RLYPeripheral]
    {
        return states.flatMap({ $0.peripheralValue })
    }
}

// MARK: - Peripheral Pair Errors
enum PeripheralPairError: Int, Error
{
    case unknown
}

extension PeripheralPairError: CustomNSError
{
    static let errorDomain = "com.ringly.PeripheralPairError"
}

extension PeripheralPairError: LocalizedError
{
    var errorDescription: String?
    {
        switch self
        {
        case .unknown:
            return "Unknown Error"
        }
    }
}

// MARK: - Peripheral States

/// The current state of a peripheral reference that a `PeripheralsService` is tracking.
private struct PeripheralState
{
    /// The peripheral reference.
    var backingPeripheralReference: BackingPeripheralReference

    /// An array of disconnect errors for this peripheral.
    var disconnectErrors: [DisconnectError]
}

extension PeripheralState: PeripheralReferenceType
{
    var peripheralReference: PeripheralReference
    {
        return backingPeripheralReference.peripheralReference
    }
}

// MARK: - Backing Peripheral Reference

/// The backing storage for `PeripheralReference` values exposed by `PeripheralsService`.
private enum BackingPeripheralReference
{
    case saved(SavedPeripheral)
    case peripheral(PeripheralController)
}

extension BackingPeripheralReference
{
    var controller: PeripheralController?
    {
        switch self
        {
        case let .peripheral(controller):
            return controller
        case .saved:
            return nil
        }
    }
}

extension BackingPeripheralReference: PeripheralReferenceType
{
    var peripheralReference: PeripheralReference
    {
        switch self
        {
        case .saved(let saved):
            return .saved(saved)
        case .peripheral(let peripheralController):
            return .peripheral(peripheralController.peripheral)
        }
    }
}

extension BackingPeripheralReference: Equatable {}
private func ==(lhs: BackingPeripheralReference, rhs: BackingPeripheralReference) -> Bool
{
    switch (lhs, rhs)
    {
    case (.peripheral(let lhsPeripheral), .peripheral(let rhsPeripheral)):
        return lhsPeripheral == rhsPeripheral
    case (.saved(let lhsSaved), .saved(let rhsSaved)):
        return lhsSaved == rhsSaved
    default:
        return false
    }
}

// MARK: - DFU Controller Delegate
extension PeripheralsService: DFUControllerDelegate
{
    func DFUController(allowInteraction: Bool, withPeripheralWithIdentifier identifier: UUID)
    {
        if allowInteraction
        {
            DFUBlacklistedIdentifiers.value.remove(identifier)

            // TODO: don't assume paired for forget-this-device
            central.retrievePeripheralsWith(identifiers: [identifier], assumedPaired: true).forEach({ peripheral in
                SLogDFU("Peripherals service is registering and connecting to \(peripheral.loggingName)")
                register(peripheral: peripheral)
                central.connect(to: peripheral)
            })
        }
        else
        {
            SLogDFU("Peripherals service is blacklisting identifier \(identifier)")

            DFUBlacklistedIdentifiers.value.insert(identifier)
            let blacklisted = DFUBlacklistedIdentifiers.value

            // when peripherals are blacklisted for DFU, remove their controllers
            state.pureModify({ current in
                PeripheralsServiceState(
                    activatedIdentifier: current.activatedIdentifier,
                    states: current.states.map({ state in
                        (blacklisted.contains(state.identifier) && state.peripheralValue != nil)
                            ? PeripheralState(
                                backingPeripheralReference: .saved(state.savedPeripheral),
                                disconnectErrors: state.disconnectErrors
                            )
                            : state
                    })
                )
            })
        }
    }

    func DFUController(startPerformingDFUForgetThisDeviceOnPeripheral peripheral: RLYPeripheral,
                       update: @escaping (ForgetThisDeviceUpdate) -> ())
    {
        DFUForgetThisDevicePeripherals[peripheral] = update
    }

    func DFUController(stopPerformingDFUForgetThisDeviceOnPeripheral peripheral: RLYPeripheral)
    {
        DFUForgetThisDevicePeripherals.removeValue(forKey: peripheral)
    }

}

extension CBCentralManagerState
{
    var loggingDescription: String
    {
        switch self
        {
        case .poweredOff:
            return "Powered Off"
        case .poweredOn:
            return "Powered On"
        case .resetting:
            return "Resetting"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        }
    }
}
