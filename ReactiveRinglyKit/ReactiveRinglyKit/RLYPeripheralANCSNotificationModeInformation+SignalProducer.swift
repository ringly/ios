import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralANCSNotificationModeInformation, Base: NSObject
{
    // MARK: - Notification Mode
    
    /// Returns a signal producer for the peripheral's `ANCSNotificationMode` property.
    public var ANCSNotificationMode: SignalProducer<RLYPeripheralANCSNotificationMode, NoError>
    {
        let value = RLYPeripheralANCSNotificationMode.unknown.rawValue
        
        return producerFor(keyPath: "ANCSNotificationMode", defaultValue: value)
            .skipRepeats(==)
            .map({ value in RLYPeripheralANCSNotificationMode(rawValue: value) ?? .unknown })
    }
}
