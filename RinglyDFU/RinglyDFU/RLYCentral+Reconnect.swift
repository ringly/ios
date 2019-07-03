import Foundation
import ReactiveSwift
import Result
import RinglyExtensions
import RinglyKit

extension RLYCentral
{
    // MARK: - Reconnecting

    /**
     A producer that waits for the central to retrieve a connected peripheral with the specified identifier.

     - parameter identifier: The peripheral identifier.
     */
    internal func automaticallyReconnectToPeripheralProducer(identifier: UUID)
        -> SignalProducer<RLYPeripheral, NoError>
    {
        return timer(interval: .milliseconds(500), on: QueueScheduler.main)
            .map({ _ in self.retrieveConnectedPeripherals() })
            .map({ peripherals in peripherals.first(where: { $0.identifier == identifier }) })
            .skipNil()
            .take(first: 1)
    }

    internal func scanAndPairWithPeripheralProducer(identifier: UUID)
        -> SignalProducer<RLYPeripheral, NoError>
    {
        return SignalProducer { observer, disposable in
            // observe the central's discovery state
            disposable += self.reactive.discovery
                .skipNil()

                // wait until we discover a peripheral with the specified identifier
                .map({ discovery in
                    discovery.peripherals.first(where: { $0.identifier == identifier as UUID })
                })
                .skipNil()
                .take(first: 1)

                // wait until the peripheral is paired
                .flatMap(.latest, transform: { peripheral -> SignalProducer<RLYPeripheral, NoError> in
                    // connect to the peripheral
                    self.connect(to: peripheral)

                    // wait until the peripheral is paired, then yield the peripheral
                    return peripheral.reactive.paired
                        .await(true)
                        .then(SignalProducer(value: peripheral))
                })
                .start(observer)

            disposable += ActionDisposable {
                self.stopDiscoveringPeripherals()
            }

            self.startDiscoveringPeripherals()
        }
    }
}

extension RLYCentral
{
    // MARK: - Forget This Device

    /**
     A producer that performs a forget-this-device on a specific peripheral.

     - parameter peripheral: The peripheral to perform “forget-this-device” on.
     */
    internal func forgetThisDeviceProducer(peripheral: RLYPeripheral) -> SignalProducer<State, NoError>
    {
        return SignalProducer.concat(
            SignalProducer(value: .waitingForForgetThisDevice(initial: false)),
            reactive.userDidForgetPeripheral.map({ $0 == peripheral })
                .await(true)
                .ignoreValues(State.self),
            SignalProducer(value: .activity(.forgettingDevice)),
            postDisconnectProducer(peripheral: peripheral, mode: .dfu).ignoreValues(State.self)
        )
    }
}
