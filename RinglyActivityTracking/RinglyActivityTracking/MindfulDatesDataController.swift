import Foundation
import ReactiveSwift
import RinglyExtensions
import Result

public final class MindfulDatesDataController
{
    // MARK: - Initialization
    
    /**
     Initializes an activity tracking mindful minutes dates data controller.
     
     - parameter dataSource:    The data source for mindful minutes data.
     - parameter cache:         The activity cache for mindful minute data.
     - parameter boundaryDates: The boundary dates between which the controller will load data.
     */
    public init(dataSource: MindfulMinuteDataSource, cache: ActivityCache, boundaryDates: [BoundaryDates])
    {
        self.boundaryDates = boundaryDates
        
        let mindfulMinute = MutableProperty(Array(repeating: MindfulMinuteResults?.none, count: boundaryDates.count))
        self.mindfulMinute = Property(mindfulMinute)
        
        // request cached data before loading from primary data source
        let cacheCompleted = MutableProperty(false)
        self.cacheCompleted = cacheCompleted
        
        let startDate = boundaryDates.first?.start
        
        if let start = startDate
        {
            disposable += cache.mindfulMinutesProducer(startDate: start, count: boundaryDates.count)
                .on(value: { cached in
                    if cached.any({ $0 != .zero })
                    {
                        mindfulMinute.value = cached.map({ .success($0) })
                    }
                })
                .take(first: 1)
                .startWithCompleted({
                    cacheCompleted.value = true
                })
        }
        else
        {
            cacheCompleted.value = true
        }
        
        // create producers between boundary dates
        queue = ProducerQueue(
            content: boundaryDates.enumerated().reversed(),
            makeProducer: { item -> SignalProducer<MindfulMinuteResults, NoError> in
                // request from the data source, writing results to the cache
                dataSource.mindfulMinutesProducer(startDate: item.element.start, endDate: item.element.end)
                    .resultify()
                    .on(value: { result in
                        mindfulMinute.modify({ $0[item.offset] = result })
                        
                        if let mindfulMinute = result.value, let start = startDate
                        {
                            cache.write(startDate: start, index: item.offset, mindfulMinutes: mindfulMinute)
                        }
                    })
        }
        )
        
        // enable the queue draining when requested by clients
        cacheCompleted.producer.startWithValues({ [weak queue] in queue?.draining = $0 })
    }
    
    // MARK: - Cleanup
    deinit
    {
        disposable.dispose()
    }
    
    fileprivate let disposable = CompositeDisposable()
    
    // MARK: - Queue
    
    /// The producer queue for loading mindful minute data.
    fileprivate let queue: ProducerQueue<MindfulMinuteResults, NoError>
    
    /// Set to `true` once the cache query has completed.
    fileprivate let cacheCompleted: MutableProperty<Bool>
    
    // MARK: - Current Data
    
    /// The boundary dates between which the controller will load data.
    public let boundaryDates: [BoundaryDates]
    
    /// A result value for mindful minute data.
    public typealias MindfulMinuteResults = Result<MindfulMinute, NSError>
    
    /// The current mindful minute data.
    public let mindfulMinute: Property<[MindfulMinuteResults?]>
}

extension Sequence where Iterator.Element == MindfulDatesDataController.MindfulMinuteResults?
{
    public var mindfulMinuteValues: [MindfulMinute]
    {
        return map({ $0?.value ?? MindfulMinute.zero })
    }
}
