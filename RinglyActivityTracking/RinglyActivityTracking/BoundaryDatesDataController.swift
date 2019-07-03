import Foundation
import ReactiveSwift
import RinglyExtensions
import Result

public final class BoundaryDatesDataController
{
    // MARK: - Initialization

    /**
     Initializes an activity tracking boundary dates data controller.

     - parameter dataSource:    The data source for steps data.
     - parameter cache:         A cache for the steps data.
     - parameter boundaryDates: The boundary dates between which the controller will load data.
     */
    public init(dataSource: StepsDataSource, cache: ActivityCache, boundaryDates: [BoundaryDates])
    {
        self.boundaryDates = boundaryDates

        let steps = MutableProperty(Array(repeating: StepsResult?.none, count: boundaryDates.count))
        self.steps = Property(steps)

        // request cached data before loading from primary data source
        let cacheCompleted = MutableProperty(false)
        self.cacheCompleted = cacheCompleted

        let startDate = boundaryDates.first?.start

        if let start = startDate
        {
            disposable += cache.stepsProducer(startDate: start, count: boundaryDates.count)
                .on(value: { cached in
                    if cached.any({ $0 != .zero })
                    {
                        steps.value = cached.map({ .success($0) })
                    }
                })
                .take(first: 1)
                .startWithCompleted({ cacheCompleted.value = true })
        }
        else
        {
            cacheCompleted.value = true
        }

        // create producers between boundary dates
        queue = ProducerQueue(
            content: boundaryDates.enumerated().reversed(),
            makeProducer: { item -> SignalProducer<StepsResult, NoError> in
                // request from the data source, writing results to the cache
                dataSource.stepsProducer(startDate: item.element.start, endDate: item.element.end)
                    .resultify()
                    .on(value: { result in
                        steps.modify({ $0[item.offset] = result })

                        if let steps = result.value, let start = startDate
                        {
                            cache.write(startDate: start, index: item.offset, steps: steps)
                        }
                    })
            }
        )

        // enable the queue draining when requested by clients
        queriesEnabled.producer.and(cacheCompleted.producer).startWithValues({ [weak queue] in queue?.draining = $0 })
    }

    // MARK: - Cleanup
    deinit
    {
        disposable.dispose()
    }

    fileprivate let disposable = CompositeDisposable()

    // MARK: - Queue

    /// The producer queue for loading steps data.
    fileprivate let queue: ProducerQueue<StepsResult, NoError>

    /// While `true`, the data controller will dequeue steps producers.
    public let queriesEnabled = MutableProperty(false)

    /// Set to `true` once the cache query has completed.
    fileprivate let cacheCompleted: MutableProperty<Bool>

    // MARK: - Current Data

    /// The boundary dates between which the controller will load data.
    public let boundaryDates: [BoundaryDates]

    /// A result value for steps data.
    public typealias StepsResult = Result<Steps, NSError>

    /// The current steps data.
    public let steps: Property<[StepsResult?]>
}

extension Sequence where Iterator.Element == BoundaryDatesDataController.StepsResult?
{
    public var stepsValues: [Steps]
    {
        return map({ $0?.value ?? Steps.zero })
    }
}
