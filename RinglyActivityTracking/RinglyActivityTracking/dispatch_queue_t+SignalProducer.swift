import ReactiveSwift

extension DispatchQueue
{
    /**
     A signal producer that will execute on the queue.

     - parameter startHandler: A signal producer start handler function.
     */
    func producer<Value, Error>(_ startHandler: @escaping (Observer<Value, Error>, CompositeDisposable) -> ())
        -> SignalProducer<Value, Error>
    {
        return SignalProducer { observer, disposable in
            self.async { startHandler(observer, disposable) }
        }
    }

    func deferProducer<Value, Error>(_ producerFunction: @escaping () -> SignalProducer<Value, Error>)
        -> SignalProducer<Value, Error>
    {
        return producer { observer, disposable in
            disposable += producerFunction().start(observer)
        }
    }
}
