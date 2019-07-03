import Foundation
import ReactiveCocoa
import ReactiveSwift
import Result
import RinglyKit

// MARK: - Peripheral Extensions
extension RLYPeripheral
{
    func verifyPaired()
    {
        if pairState == .assumedPaired
        {
            reactive.readBondCharacteristicSupport
                .promoteErrors(VerifyPairedError.self)

                // determine whether or not the peripheral actually supports bond state reading
                .attemptMap({ support in
                    support == .unsupported
                        ? .failure(VerifyPairedError.unsupported)
                        : .success(support)
                })
                .await(.supported)

                // try to read the bond characteristic
                .then(SignalProducer.`defer` { () -> SignalProducer<(), VerifyPairedError> in
                    return SignalProducer(result: materialize(self.readBondCharacteristic).mapError({ error in
                        VerifyPairedError.readError(error.error as NSError)
                    }))
                })

                // observer the peripheral's pair state, terminating after it is paired
                .then(reactive.pairState.promoteErrors(VerifyPairedError.self))
                .accept(.paired)
                .take(first: 1)

                // terminate if the peripheral disconnects, since the process won't complete
                .take(until: reactive.disconnected.await(true))

                // terminate if this goes on for too long, if not paired, the peripheral will disconnect anyways
                .timeout(after: 10, raising: .timeout, on: QueueScheduler.main)

                // log the result of this operation
                .on(failed: { error in
                    SLogBluetooth("Error reading paired state: \(error)")
                }, value: { _ in
                    SLogBluetooth("Peripheral was verified to be paired")
                })
                .start()
        }
    }
}

private enum VerifyPairedError: Error
{
    case unsupported, timeout, readError(NSError)
}

extension VerifyPairedError: Equatable {}
private func ==(lhs: VerifyPairedError, rhs: VerifyPairedError) -> Bool
{
    switch (lhs, rhs)
    {
    case (.unsupported, .unsupported):
        return true
    case (.timeout, .timeout):
        return true
    case (.readError(let lhsError), .readError(let rhsError)):
        return lhsError == rhsError
    default:
        return false
    }
}

