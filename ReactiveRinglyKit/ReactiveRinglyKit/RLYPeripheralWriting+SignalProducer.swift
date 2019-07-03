import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralWriting, Base: NSObject
{
    // MARK: - Capabilities
    
    /// Returns a signal producer for the peripheral's `canWriteCommands` property.
    public var canWriteCommands: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "canWriteCommands")
    }
}
