import ReactiveSwift
import RinglyKit

public extension Reactive where Base: RLYPeripheralConfigurationHashing
{
    /// Reads the current configuration hash, translating callbacks to a signal producer.
    public func readConfigurationHash() -> SignalProducer<UInt64, NSError>
    {
        return SignalProducer { observer, disposable in
            self.base.readConfigurationHash(
                completion: { hash in
                    observer.send(value: hash)
                    observer.sendCompleted()
                },
                failure: { error in
                    observer.send(error: error as NSError)
                }
            )
        }
    }
}

