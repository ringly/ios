import ReactiveSwift
import RinglyKit
import enum CoreBluetooth.CBPeripheralState

extension RLYCentral
{
    /**
     Attempts to send a peripheral to bootloader mode by repeating writing DFU commands to it.
     
     This is necessary as a workaround, because some firmware versions do not successfully re-enter DFU mode after
     previously completing a DFU operation.

     - parameter peripheral:               The peripheral to write DFU commands to.
     - parameter pollInterval:             The interval at which the peripheral's connection state should be checked.
     - parameter requiredConnectingStates: The required number of sequential `Connecting` states to consider a success.
     - parameter timeoutInterval:          The amount of time to wait before failing the operation.
     */
    internal func repeatedlyWriteProducer(peripheral: RLYPeripheral,
                                          pollInterval: DispatchTimeInterval = .seconds(2),
                                          requiredConnectingStates: Int = 2,
                                          timeoutInterval: TimeInterval = 30)
                                          -> SignalProducer<State, NSError>
    {
        // a producer to observe the peripheral's state every few seconds
        let producer = timer(interval: pollInterval, on: QueueScheduler.main)
            .map({ _ in peripheral.state })
            .on(value: { (state: CBPeripheralState) in
                switch state
                {
                case .disconnected:
                    self.connect(to: peripheral)
                case .connected:
                    peripheral.write(command: RLYDFUCommand(timeout: .timeout30))
                case .connecting:
                    break
                case .disconnecting:
                    break
                }
            })

            // track the most recent states
            .scan([CBPeripheralState](), { (current: [CBPeripheralState], state: CBPeripheralState) -> [CBPeripheralState] in
                Array(([state] + current).prefix(requiredConnectingStates))
            })
            .on(value: { states in
                DFULogFunction("Current peripheral states are \(states.map({ $0.logDescription }))")
            })
            .take(while: { states in
                states.any({ $0 != .connecting })
            })
            .ignoreValues(State.self)
            .promoteErrors(NSError.self)

        return SignalProducer(value: .activity(.waitingForWriteStart))
            .concat(producer)
            .on(started: { DFULogFunction("Starting repeating write process at \(CFAbsoluteTime())") })
            .timeout(
                after: timeoutInterval,
                raising: DFUTimeoutError.repeatedlyWriting as NSError,
                on: QueueScheduler.main
            )
            .on(failed: { error in
                DFULogFunction("Failed repeating write process at \(CFAbsoluteTime())")
            })
    }
}

extension CBPeripheralState
{
    public var logDescription: String
    {
        switch self
        {
        case .disconnected: return "Disconnected"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        }
    }
}
