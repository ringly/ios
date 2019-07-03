import ReactiveSwift
import enum Result.NoError

extension SignalProducerProtocol
{
    func inject<T>(producer: SignalProducer<T, NoError>, observer: Observer<T, Error>)
        -> SignalProducer<Value, Error>
    {
        return flatMap(.concat, transform: { value in
            return producer.on(value: observer.send)
                .then(SignalProducer(value: value))
                .promoteErrors(Error.self)
        })
    }

    func inject<Other: SignalProducerProtocol>
        (producer: Other, observer: Observer<Other.Value, Error>)
        -> SignalProducer<Value, Error> where Other.Error == Error
    {
        return flatMap(.concat, transform: { value in
            return producer.on(value: observer.send).then(SignalProducer(value: value))
        })
    }
}
