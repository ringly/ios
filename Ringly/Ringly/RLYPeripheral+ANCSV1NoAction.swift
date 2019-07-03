import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheral
{
    /// Sends the "no action" response to the receiver whenever the receiver sends a notification to its central.
    ///
    /// This producer is entirely side-effecting and does not send meaningful events.
    func sendANCSV1NoAction() -> SignalProducer<(), NoError>
    {
        return ANCSNotification.on(value: { [weak base] _ in
            base?.write(command: RLYNoActionCommand())
        }).ignoreValues()
    }
}
