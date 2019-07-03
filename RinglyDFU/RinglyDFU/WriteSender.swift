import Foundation
import ReactiveSwift
import RinglyKit

/// A `Sender` that writes the DFU command to a peripheral.
internal struct WriteSender
{
    // MARK: - Peripheral

    /// The peripheral to write to.
    let peripheral: RLYPeripheral
}

extension WriteSender: Sender
{
    // MARK: - Sender

    /// Writes a DFU command to `peripheral`.
    func sendProducer() -> SignalProducer<State, NSError>
    {
        return SignalProducer.`defer` {
            // write the DFU command to the peripheral
            self.peripheral.write(command: RLYDFUCommand(timeout: .timeout10))

            return SignalProducer.concat(
                // display an activity interface
                SignalProducer(value: .activity(.waitingForWriteStart)),

                // wait a second for the peripheral to enter DFU mode
                timer(interval: .seconds(1), on: QueueScheduler.main)
                    .take(first: 1)
                    .ignoreValues(State.self)
            ).promoteErrors(NSError.self)
        }
    }
}
