import Foundation
import ReactiveSwift
import class RinglyKit.RLYPeripheral

// MARK: - Forget This Device Sender
internal struct ForgetThisDeviceSender
{
    let initial: Bool
    let peripheral: RLYPeripheral
    let delegate: DFUControllerDelegate
}

extension ForgetThisDeviceSender: Sender
{
    // MARK: - Sender

    /// Waits for the user to perform a "forget this device".
    func sendProducer() -> SignalProducer<State, NSError>
    {
        return SignalProducer { observer, disposable in
            observer.send(value: .waitingForForgetThisDevice(initial: self.initial))

            self.delegate.DFUController(
                startPerformingDFUForgetThisDeviceOnPeripheral: self.peripheral,
                update: { update in
                    switch update
                    {
                    case .started:
                        observer.send(value: .activity(.forgettingDevice))
                    case .completed:
                        observer.sendCompleted()
                    }
                }
            )

            disposable += ActionDisposable {
                self.delegate.DFUController(stopPerformingDFUForgetThisDeviceOnPeripheral: self.peripheral)
            }
        }
    }
}
