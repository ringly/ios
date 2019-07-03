import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralReading, Base: NSObject
{
    // MARK: - Reading Information
    
    /// Returns a signal producer for the peripheral's `readBondCharacteristicSupport` property.
    public var readBondCharacteristicSupport: SignalProducer<RLYPeripheralFeatureSupport, NoError>
    {
        return producerFor(keyPath: "readBondCharacteristicSupport", defaultValue: RLYPeripheralFeatureSupport.undetermined.rawValue)
            .map({ value in RLYPeripheralFeatureSupport(rawValue: value)! })
    }
}
