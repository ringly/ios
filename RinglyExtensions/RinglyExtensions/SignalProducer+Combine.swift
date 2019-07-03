import ReactiveSwift

extension SignalProducerProtocol
{
    /// Mimics `combinePrevious`, but uses the first value sent by the producer as the initial value. This means that
    /// the resulting producer will not send a value until the second value is sent.
    public func combinePrevious() -> SignalProducer<(Value, Value), Error>
    {
        return scan((Value?.none, Value?.none), { current, next in
            return (current.1, next)
        }).map(unwrap).skipNil()
    }
}
