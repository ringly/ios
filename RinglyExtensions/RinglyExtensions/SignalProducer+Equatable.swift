import ReactiveSwift

public extension SignalProducerProtocol where Value: Equatable
{
    /**
     Returns a producer, with all values equal to `value` removed.

     - parameter value: The value to ignore.
     */
    public func ignore(_ value: Value) -> SignalProducer<Value, Error>
    {
        return filter({ next in next != value })
    }

    /**
     Returns a producer, with only values equal to `value` included.

     - parameter value: The value to accept.
     */
    public func accept(_ value: Value) -> SignalProducer<Value, Error>
    {
        return filter({ next in next == value })
    }

    /**
     Returns a producer, which will send no `next` values and complete once the receiver sends a value equal to `value`.

     - parameter value: The value to await.
     */
    public func await(_ value: Value) -> SignalProducer<(), Error>
    {
        return accept(value).take(first: 1).ignoreValues()
    }

    /**
     Returns a producer, which will send a boolean value for each next, `true` if the next is equal to `value`.

     - parameter value: The value to evaluate equality with.
     */
    public func equals(_ value: Value) -> SignalProducer<Bool, Error>
    {
        return map({ next in value == next })
    }
}
