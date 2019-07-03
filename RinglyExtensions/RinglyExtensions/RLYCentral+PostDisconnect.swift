import ReactiveRinglyKit
import ReactiveSwift
import RinglyKit
import enum Result.NoError

/// Enumerates possible post-disconnect actions for the central.
@objc public enum RLYCentralPostDisconnectMode: Int
{
    /// Clears the peripheral's bonds.
    case clearBonds

    /// Sends the peripheral into DFU mode.
    case dfu
}

extension RLYCentral
{
    public func postDisconnectProducer(peripheral: RLYPeripheral, mode: RLYCentralPostDisconnectMode)
        -> SignalProducer<(), NoError>
    {
        struct TimeoutError: Error {}

        // initial delay after disconnection
        return timer(interval: .milliseconds(1), on: QueueScheduler.main)
            .take(first: 1)

            // connect to the peripheral
            .on(completed: {
                self.connect(to: peripheral)
            })
            .then(peripheral.reactive.connected.await(true))
            .delay(mode == .dfu ? 1 : 3, on: QueueScheduler.main)

            // write command/clear bonds to the peripheral
            .on(completed: {
                switch mode
                {
                case .clearBonds:
                    peripheral.writeClearBond()
                case .dfu:
                    peripheral.write(command: RLYDFUCommand(timeout: .timeout30))
                }
            })
            .delay(1, on: QueueScheduler.main)

            // disconnect from the peripheral
            .on(completed: {
                self.cancelConnection(to: peripheral)
            })

            // allow silent timeout
            .promoteErrors(TimeoutError.self)
            .timeout(after: 10, raising: TimeoutError(), on: QueueScheduler.main)

            // ignore timeout errors
            .flatMapError({ _ in SignalProducer.empty })
            .ignoreValues()
    }
}
