import ReactiveSwift

public extension SignalProducerProtocol where Value: OptionalProtocol
{
    /**
    Maps non-nil values of a producer of optional values. `nil` values will be propagated as-is.
    
    - parameter transform: A transformation function.
    
    - returns: A producer of optional transformed values.
    */
    public func mapOptional<R>(_ transform: @escaping (Value.Wrapped) -> R) -> SignalProducer<R?, Error>
    {
        return self.map({ optional in
            if let value = optional.optional
            {
                return transform(value)
            }
            else
            {
                return nil
            }
        })
    }
    
    /**
     Sends non-nil values to `transform` and sends the returned value, while passing `nil` values through, transforming
     only their type.
     
     - parameter transform: The transform function
     */
    public func mapOptionalFlat<R>(_ transform: @escaping (Value.Wrapped) -> R?) -> SignalProducer<R?, Error>
    {
        return self.map({ optional in
            if let value = optional.optional, let transformed = transform(value)
            {
                return transformed
            }
            else
            {
                return nil
            }
        })
    }
    
    /**
    Performs a producer `flatMap` operation on a producer of optional values. This is *not* an optional `flatMap`, so
    transforming to a producer of optional values will result in a doubly-nested optional.
    
    `nil` values will be mapped into a producer of a single `nil` value.
    
    - parameter strategy:  The flatten strategy to use.
    - parameter transform: A transformation function.
    */
    public func flatMapOptional<R>(_ strategy: FlattenStrategy, transform: @escaping (Value.Wrapped) -> SignalProducer<R, Error>) -> SignalProducer<R?, Error>
    {
        return flatMap(strategy, transform: { optional -> SignalProducer<R?, Error> in
            if let value = optional.optional
            {
                return transform(value).map({ x in x })
            }
            else
            {
                return SignalProducer(value: nil)
            }
        })
    }

    /**
     Performs a producer `flatMap` operation on a producer of optional values, flattening the optional results.

     `nil` values will be mapped into a producer of a single `nil` value.

     - parameter strategy:  The flatten strategy to use.
     - parameter transform: A transformation function.
     */
    public func flatMapOptionalFlat<R>(_ strategy: FlattenStrategy, transform: @escaping (Value.Wrapped) -> SignalProducer<R?, Error>)
        -> SignalProducer<R?, Error>
    {
        return flatMapOptional(strategy, transform: transform).map(flattenOptional)
    }

    /**
     A `skipRepeats` utility for optional producers.

     - parameter function: An equality function.
     */
    public func skipRepeatsOptional(_ function: @escaping (Value.Wrapped, Value.Wrapped) -> Bool) -> SignalProducer<Value, Error>
    {
        return skipRepeats({ leftOptional, rightOptional in
            switch (leftOptional.optional, rightOptional.optional)
            {
            case let (.some(leftValue), .some(rightValue)):
                return function(leftValue, rightValue)
            case (.none, .none):
                return true
            default:
                return false
            }
        })
    }
}

extension SignalProducerProtocol where Value: OptionalProtocol
{
    // MARK: - Collecting Combine

    /**
     Collects values of `other` until the receiver sends a non-`nil` value, then yields pairs in sequences. If the
     receiver's most recent next is non-`nil`, pairs will be forwarded immediately.

     - parameter other: The other signal producer.
     */
    public func collectingCombine<Other>(with other: SignalProducer<Other, Error>)
        -> SignalProducer<(Value.Wrapped, Other), Error>
    {
        // merge the two signal producers into a single event stream
        typealias MergeEither = Either<Value.Wrapped?, Other>

        let merged = SignalProducer.merge([
            self.map({ MergeEither.left($0.optional) }),
            other.map(MergeEither.right)
        ])

        // reduce the event stream by scanning on each step
        typealias StateEither = Either<(Value.Wrapped, [Other]), [Other]>

        let eventArraysProducer = merged.scan(StateEither.right([]), { previous, event -> StateEither in
            switch (previous, event)
            {
            case (.left, .left(let optional)):
                return optional.map({ .left($0, []) }) ?? .right([])

            case (.left(let lastState), .right(let otherValue)):
                return .left(lastState.0, [otherValue])

            case (.right(let buffer), .left(let optional)):
                return optional.map({ .left($0, buffer) }) ?? .right(buffer)

            case (.right(let buffer), .right(let otherValue)):
                return .right(buffer + [otherValue])
            }
        }).map({ $0.leftValue }).skipNil()

        // expand the event arrays into a single producer
        return eventArraysProducer.flatMap(.concat, transform: { unwrapped, array in
            SignalProducer(array.map({ (unwrapped, $0) }))
        })
    }
}
