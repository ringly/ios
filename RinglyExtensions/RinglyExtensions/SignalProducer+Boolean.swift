import ReactiveSwift

extension SignalProducerProtocol where Value == Bool
{
    /// Returns a producer of inverted booleans.
    public var not: SignalProducer<Value, Error>
    {
        return self.map({ bool in !bool })
    }
    
    /**
    Returns a producer that performs a logical 'and' on two boolean producers, with `combineLatest` behavior.
    
    - parameter other: The other producer.
    */
    
    public func and(_ other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return self.combineLatest(with: other).map({ a, b in a && b })
    }
    
    /**
    Returns a producer that performs a logical 'or' on two boolean producers, with `combineLatest` behavior.
    
    - parameter other: The other producer.
    */
    
    public func or(_ other: SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return self.combineLatest(with: other).map({ a, b in a || b })
    }
}
