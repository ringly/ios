import Foundation
import ReactiveSwift
import UIKit
import enum Result.NoError

extension SignalProducerProtocol
{
    /**
    Returns a producer that will not send a next until at least `interval` from the last next. Additional nexts sent
    before the interval has elapsed will reset the timer, sending the latest next when the timer completes.
    
    - parameter interval:    The debounce interval.
    - parameter on:  The scheduler to use for debounced values.
    - parameter test:        A test. Values that fail the test will be sent immediately.
    */
    
    public func debounce(_ interval: TimeInterval,
                on scheduler: DateSchedulerProtocol,
                valuesPassingTest test: @escaping (Value) -> Bool)
        -> SignalProducer<Value, Error>
    {
        return flatMap(.latest, transform: { value -> SignalProducer<Value, Error> in
            let producer = SignalProducer<Value, Error>(value: value)
            return test(value) ? producer.delay(interval, on: scheduler) : producer
        })
    }

    /**
     Forwards the receiver for a specified interval. If the interval is less than or equal to zero, yields an empty
     producer.

     - parameter interval:  The interval.
     - parameter scheduler: The scheduler to interrupt the receiver on.
     */
    
    public func takeFor(interval: DispatchTimeInterval, on scheduler: DateSchedulerProtocol) ->
        SignalProducer<Value, Error>
    {
        if interval.nanoseconds > 0
        {
            return take(until: timer(interval: interval, on: scheduler).take(first: 1).ignoreValues())
        }
        else
        {
            return SignalProducer.empty
        }
    }
}

extension SignalProducerProtocol
{
    /**
     Times out by completing the producer.

     - parameter interval:  The timeout interval.
     - parameter scheduler: The scheduler to time out on.
     */
    
    public func timeoutAndComplete(afterInterval interval: TimeInterval, on scheduler: DateSchedulerProtocol)
        -> SignalProducer<Value, Error>
    {
        return materialize()
            .promoteErrors(TimeoutError.self)
            .timeout(after: interval, raising: TimeoutError(), on: scheduler)
            .flatMapError({ error in SignalProducer(value: .completed) })
            .dematerialize()
    }
}

private struct TimeoutError: Error {}

extension SignalProducerProtocol
{
    // MARK: - Buffering
    
    /**
     Buffers values sent to the receiver, with a cutoff limit and time interval.

     - parameter limit:     A buffer size limit, after which elements will be forwarded.
     - parameter timeout:   A timeout, after which elements will be forwarded.
     - parameter scheduler: The scheduler to apply the time interval on. It will _not_ apply to nexts sent due to the
                            limit.
     */
    public func buffer(limit: Int, timeout: DispatchTimeInterval, on scheduler: DateSchedulerProtocol)
        -> SignalProducer<[Value], Error>
    {
        return SignalProducer { observer, disposable in
            let buffer = Atomic([Value]())

            disposable += self
                .on(value: { value in
                    buffer.modify({ current in
                        current.append(value)

                        if current.count >= limit
                        {
                            observer.send(value: current)
                            current = []
                        }
                    })
                })
                .flatMap(.latest, transform: { _ in
                    timer(interval: timeout, on: scheduler).take(first: 1).promoteErrors(Error.self)
                })
                .on(value: { _ in
                    buffer.modify({ current in
                        if current.count > 0
                        {
                            observer.send(value: current)
                        }

                        current = []
                    })
                })
                .start()
        }
    }
}

extension SignalProducerProtocol where Value == Bool
{
    /**
     Depending on the most recent value sent by the receiver, yields an `immediateTimer` of varying intervals.

     - parameter trueInterval:  The interval to use if the most recent value is `true`.
     - parameter falseInterval: The interval to use if the most recent value is `false`.
     - parameter scheduler:     The scheduler to use for the timer.
     */
    public func variableImmediateTimer(trueInterval: DispatchTimeInterval,
                                       falseInterval: DispatchTimeInterval,
                                       on scheduler: DateSchedulerProtocol)
                                       -> SignalProducer<Date, Error>
    {
        return flatMap(.latest, transform: { value in
            immediateTimer(interval: value ? trueInterval : falseInterval, on: scheduler)
        })
    }
}

/**
 Starts a timer that yields immediately, then repeatedly, after `interval`.

 - parameter interval:  The timer interval.
 - parameter scheduler: The scheduler to use.
 */
public func immediateTimer(interval: DispatchTimeInterval, on scheduler: DateSchedulerProtocol)
    -> SignalProducer<Date, NoError>
{
    return SignalProducer.`defer` {
        return SignalProducer([
            SignalProducer(value: scheduler.currentDate),
            timer(interval: interval, on: scheduler)
        ]).flatten(.concat)
    }
}


public func timerUntil(date: Date, on scheduler: DateSchedulerProtocol) -> SignalProducer<Date, NoError>
{
    return SignalProducer.`defer` {
        let currentDate = scheduler.currentDate
        let interval = date.timeIntervalSince(currentDate) // TODO: better dispatch time conversion?

        if interval > 0
        {
            var reasonableLeeway:DispatchTimeInterval = .milliseconds(500)
            
            if interval > 86400 * 100 {
                reasonableLeeway = .seconds(86400)
            } else if interval > 86400 {
                reasonableLeeway = .seconds(60)
            } else if interval > 60 {
                reasonableLeeway = .seconds(1)
            }
            
            return timer(interval: .milliseconds(Int(interval * 1000)), on: scheduler, leeway: reasonableLeeway).take(first: 1)
        }
        else
        {
            return SignalProducer(value: currentDate).observe(on: scheduler)
        }
    }
}

extension DispatchTimeInterval
{
    public var nanoseconds: Int64
    {
        switch self
        {
        case let .nanoseconds(value):
            return Int64(value)
        case let .microseconds(value):
            return Int64(value * 1000)
        case let .milliseconds(value):
            return Int64(value) * 1000000
        case let .seconds(value):
            return Int64(value) * Int64(NSEC_PER_SEC)
        }
    }

    public var timeInterval: TimeInterval
    {
        switch self
        {
        case let .nanoseconds(value):
            return TimeInterval(value) / TimeInterval(NSEC_PER_SEC)
        case let .microseconds(value):
            return TimeInterval(value / 1000000)
        case let .milliseconds(value):
            return TimeInterval(value) / 1000
        case let .seconds(value):
            return TimeInterval(value)
        }
    }
}
