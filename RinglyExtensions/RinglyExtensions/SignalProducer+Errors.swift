import ReactiveSwift
import Result

extension SignalProducerProtocol where Value: ResultProtocol
{
    /// When the receiver yields a `Failure` result, restarts the receiver after `producer` sends a value. If a new
    /// `Success` value is sent before `producer` sends a value, the restart is cancelled.
    ///
    /// - parameter producer: The producer after which to restart a failed producer.
    public func retryOnValue(from producer: SignalProducer<(), NoError>) -> SignalProducer<Value, Error>
    {
        return flatMap(.latest, transform: { result in
            return result.analysis(
                ifSuccess: { _ in SignalProducer(value: result) },
                ifFailure: { _ in
                    SignalProducer(value: result)
                        .concat(producer.take(first: 1)
                            .promoteErrors(Error.self)
                            .then(self.retryOnValue(from: producer))
                        )
                }
            )
        })
    }
}

extension SignalProducerProtocol
{
    /// Transform `failed` events into `value` events.
    ///
    /// - Parameter transform: A transform function.
    public func mapErrorToValue(_ transform: @escaping (Error) -> Value) -> SignalProducer<Value, NoError>
    {
        return flatMapError({ SignalProducer(value: transform($0)) })
    }
}

extension SignalProducerProtocol where Value: Swift.Error, Error == NoError
{
    /// When a `value` event is sent on the receiver, converts it to a `failure` event.
    public func promoteValuesToErrors() -> SignalProducer<(), Value>
    {
        return promoteErrors(Value.self).flatMap(.concat, transform: SignalProducer.init)
    }
}

extension SignalProducerProtocol
{
    /// Converts an erroring producer into a producer that yields result values and will not error.
    public func resultify() -> SignalProducer<Result<Value, Error>, NoError>
    {
        return map(Result.success).flatMapError({ error in
            SignalProducer(value: .failure(error))
        })
    }
}

extension SignalProducerProtocol where Value: ResultProtocol, Error == NoError
{
    /// Converts a non-erroring producer of results to an erroring producer of values.
    public func deresultify() -> SignalProducer<Value.Value, Value.Error>
    {
        return promoteErrors(Value.Error.self).attemptMap({
            $0.analysis(ifSuccess: Result.success, ifFailure: Result.failure)
        })
    }
}
