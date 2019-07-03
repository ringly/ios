import ReactiveSwift

extension SignalProducerProtocol
{
    /**
     An implementation of `RACSignal`'s `+defer:`.
     
     - parameter function: The defer function.
     */
    
    public static func `defer`(_ function: @escaping () -> SignalProducer<Value, Error>) -> SignalProducer<Value, Error>
    {
        return SignalProducer { observer, disposable in
            disposable += function().start(observer)
        }
    }

    /**
     Defers evaluation of `function` until the returned producer is started, yielding its result as a single value.

     - parameter function: The deferred value function.
     */
    
    public static func deferValue(_ function: @escaping () -> Value) -> SignalProducer<Value, Error>
    {
        return `defer` { SignalProducer(value: function()) }
    }
}
