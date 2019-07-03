import CoreBluetooth
import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

extension CBCentralManager
{
    // MARK: - State

    /// A signal producer for the current Bluetooth state.
    static func stateProducer(scheduler: DateSchedulerProtocol) -> SignalProducer<CBCentralManagerState, NoError>
    {
        return SignalProducer.`defer` {
            // create a central manager
            let options = [CBCentralManagerOptionShowPowerAlertKey: false]
            let central = CBCentralManager(delegate: nil, queue: nil, options: options)

            // we just poll this really really quickly - instead of using a delegate approach - might want to switch
            // back to delegate approach if people are going too fast
            return timer(interval: .milliseconds(50), on: scheduler)
                .map({ _ in CBCentralManagerState(rawValue: central.state.rawValue)! })
                .skipRepeats()
        }
    }
}

extension CBCentralManager
{
    // MARK: - Toggling Bluetooth

    /// A signal producer that waits for the user to toggle the Bluetooth state.
    static func toggleBluetoothProducer() -> SignalProducer<State, NoError>
    {
        return SignalProducer.concat(
            // set initial state to waiting for toggle off
            SignalProducer(value: .waitingForBluetoothToggle(haveToggledOff: false)),

            // wait until the bluetooth state is powered off
            CBCentralManager.stateProducer(scheduler: QueueScheduler.main)
                .await(.poweredOff)
                .then(SignalProducer(value: .waitingForBluetoothToggle(haveToggledOff: true))),

            // wait unil the bluetooth state is powered on before completing
            CBCentralManager.stateProducer(scheduler: QueueScheduler.main)
                .await(.poweredOn)
                .ignoreValues(State.self)
        )
    }
}
