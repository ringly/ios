import Foundation
import ReactiveSwift

/// A queue of signal producers, which starts the next producer after the previous producer sends its first value, or
/// completes without sending a value.
internal final class ProducerQueue<Value, Error: Swift.Error>
{
    // MARK: - Initialization
    convenience init(producers: [SignalProducer<Value, Error>])
    {
        self.init(content: producers, makeProducer: { $0 })
    }

    init<Sequence: Swift.Sequence>(content: Sequence, makeProducer: (Sequence.Iterator.Element) -> SignalProducer<Value, Error>)
    {
        producerGenerator = AnyIterator(IteratorSequence(content.makeIterator()).lazy.map(makeProducer).makeIterator())
    }

    // MARK: - Producers

    /// If `true`, the queue will start producers.
    var draining = false
    {
        didSet
        {
            if draining
            {
                drainLock.lock()

                if producersStarted < maximumProducersStarted
                {
                    drainProducers()
                }

                drainLock.unlock()
            }
        }
    }

    /// A generator of the producers that this queue will start.
    fileprivate var producerGenerator: AnyIterator<SignalProducer<Value, Error>>

    /// The number of producers that have been started.
    fileprivate var producersStarted = 0

    /// The maximum number of producers that may be started at one time.
    fileprivate let maximumProducersStarted = 1

    /// This lock needs to be recursive, in case a synchronous producer is started.
    fileprivate let drainLock = NSRecursiveLock()

    /// Drains the next producer from the queue.
    fileprivate func drainProducers()
    {
        drainLock.lock()

        while producersStarted < maximumProducersStarted && draining
        {
            if let producer = producerGenerator.next()
            {
                producersStarted += 1

                producer.startWithSignal({ signal, disposable in
                    self.disposable += disposable

                    let callback = { [weak self] in
                        guard let strong = self else { return }

                        strong.drainLock.lock()
                        strong.producersStarted -= 1
                        strong.drainProducers()
                        strong.drainLock.unlock()
                    }

                    self.disposable += signal.take(first: 1).observeCompleted(callback)
                    self.disposable += signal.take(first: 1).observeFailed({ _ in callback() })
                })
            }
            else
            {
                break
            }
        }

        drainLock.unlock()
    }

    // MARK: - Disposing of Producers
    fileprivate let disposable = CompositeDisposable()
    deinit { disposable.dispose() }
}
