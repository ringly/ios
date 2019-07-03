import Foundation
import ReactiveCocoa
import ReactiveSwift
import Result

public extension Reactive where Base: NSObject
{
    // MARK: - KVO
    
    /**
     Returns a producer for the specified key path. Values that cannot be converted to `T` will be sent as `nil`.
     
     - parameter keyPath: The key path.
     */
    public func producerFor<T>(keyPath: String) -> SignalProducer<T?, NoError>
    {
        return values(forKeyPath: keyPath).map({ any in
            any.flatMap({ some in some as? T })
        })
    }

    /**
     Returns a producer for the specified key path, replacing `nil` values with `defaultValue`.
     
     - parameter keyPath:      The key path.
     - parameter defaultValue: The default value.
     */
    public func producerFor<T>(keyPath: String, defaultValue: T) -> SignalProducer<T, NoError>
    {
        return producerFor(keyPath: keyPath).map({ (optional: T?) -> T in
            return optional ?? defaultValue
        })
    }
    
    /**
     Returns a producer for the specified key path, replacing `nil` values with `false`, converted to `T`.
     
     - parameter keyPath: The key path.
     */
    public func producerFor<T: ExpressibleByBooleanLiteral>(keyPath: String) -> SignalProducer<T, NoError>
    {
        return producerFor(keyPath: keyPath, defaultValue: false)
    }
    
    /**
     Returns a producer for the specified key path, replacing `nil` values with `0`, converted to `T`.
     
     - parameter keyPath: The key path.
     */
    public func producerFor<T: ExpressibleByIntegerLiteral>(keyPath: String) -> SignalProducer<T, NoError>
    {
        return producerFor(keyPath: keyPath, defaultValue: 0)
    }
}

