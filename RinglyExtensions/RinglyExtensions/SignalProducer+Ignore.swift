import ReactiveSwift
import Result

public extension SignalProducerProtocol
{

    /**
    Returns a producer that will send no nexts, with type `Void`.
    */
    
    public func ignoreValues() -> SignalProducer<(), Error>
    {
        return ignoreValues(Void.self)
    }
    
    /**
    Returns a producer that ignores values, but constrains the type of the returned producer to `A`.
    */
    
    public func ignoreValues<A>(_ type: A.Type) -> SignalProducer<A, Error>
    {
        return filter({ _ in false }).map({ x in x as! A })
    }

    /// Converts all values in the producer to `()`.
    ///
    /// This is useful for operators that require a void producer, such as `takeUntil` or `sampleOn`.
    public var void: SignalProducer<(), Error>
    {
        return map({ _ in () })
    }
}

public extension SignalProtocol
{
    /// Converts all values in the signal to `()`.
    ///
    /// This is useful for operators that require a void signal, such as `takeUntil` or `sampleOn`.
    public var void: Signal<(), Error>
    {
        return map({ _ in () })
    }
}
