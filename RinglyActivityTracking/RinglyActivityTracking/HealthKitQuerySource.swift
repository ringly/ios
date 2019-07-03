import Foundation
import HealthKit
import ReactiveSwift

// MARK: - Query Source

/// A protocol for types that can make HealthKit queries.
public protocol HealthKitQuerySource
{
    // MARK: - Date Boundaries

    /// The earliest date that may be queried for samples.
    
    func earliestPermittedSampleDate() -> Date

    // MARK: - Queries

    /**
     A signal producer for a HealthKit query.

     - parameter sampleType:      The query's sample type.
     - parameter predicate:       The query's predicate.
     - parameter limit:           The maximum number of items to yield.
     - parameter sortDescriptors: The query's sort descriptors.
     */
    
    func queryProducer(sampleType: HKSampleType,
                       predicate: NSPredicate?,
                       limit: Int,
                       sortDescriptors: [NSSortDescriptor]?)
                       -> SignalProducer<[HKSample], NSError>

    /**
     A signal producer for a HealthKit statistics query.

     - parameter quantityType: The quantity type to query statistics for.
     - parameter predicate:    The predicate for querying statistics.
     - parameter options:      The statistics options to use for the query.
     */
    
    func statisticsQueryProducer(quantityType: HKQuantityType,
                                 predicate: NSPredicate,
                                 options: HKStatisticsOptions)
                                 -> SignalProducer<HKStatistics, NSError>

    /**
     A signal producer for a HealthKit observer query.

     - parameter sampleType: The query's sample type.
     - parameter predicate:  The query's predicate.
     */
    
    func observerQueryProducer(sampleType: HKSampleType, predicate: NSPredicate?)
        -> SignalProducer<HKObserverQueryCompletionHandler, NSError>
}

extension HealthKitQuerySource
{
    // MARK: - Updating Queries

    /**
     A utility for observer-query-derived producers.

     - parameter sampleType:        The sample type for the observer query.
     - parameter predicate:         The predicate for the observer query.
     - parameter makeQueryProducer: A function to build an individual query producer.
     */
    
    fileprivate func updatingObserverQueryProducer<Value>(sampleType: HKSampleType,
                                                      predicate: NSPredicate?,
                                                      makeQueryProducer: @escaping (@escaping HKObserverQueryCompletionHandler) -> SignalProducer<Value, NSError>)
                                                      -> SignalProducer<Value, NSError>
    {
        return observerQueryProducer(sampleType: sampleType, predicate: predicate)
            .holdUntilProtectedDataIsAvailable() // prevent HealthKit lookups in background, when data is encrypted
            .flatMap(.latest, transform: makeQueryProducer)
    }

    /**
     A signal producer for a statistics query that automatically updates when new data becomes available.

     This will create an observer query, and execute a query every time new data becomes available. Additionally, it
     will perform an initial query.

     - parameter quantityType: The quantity type to query statistics for.
     - parameter predicate:    The predicate for querying statistics.
     - parameter options:      The statistics options to use for the query.
     */
    
    public func updatingStatisticsQueryProducer(quantityType: HKQuantityType,
                                                predicate: NSPredicate,
                                                options: HKStatisticsOptions)
        -> SignalProducer<HKStatistics, NSError>
    {
        return updatingObserverQueryProducer(sampleType: quantityType, predicate: predicate) { completion in
            self.statisticsQueryProducer(quantityType: quantityType, predicate: predicate, options: options)
                .on(terminated: completion)
        }
    }

    /**
     A signal producer for a query that automatically updates when new data becomes available.
     
     This will create an observer query, and execute a query every time new data becomes available. Additionally, it
     will perform an initial query.

     - parameter sampleType:      The query's sample type.
     - parameter predicate:       The query's predicate.
     - parameter limit:           The maximum number of items to yield.
     - parameter sortDescriptors: The query's sort descriptors.
     */
    
    public func updatingQueryProducer(sampleType: HKSampleType,
                                      predicate: NSPredicate?,
                                      limit: Int,
                                      sortDescriptors: [NSSortDescriptor]?)
                                      -> SignalProducer<[HKSample], NSError>
    {
        return updatingObserverQueryProducer(sampleType: sampleType, predicate: predicate) { completion in
            self.queryProducer(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors
            ).on(terminated: completion)
        }
    }
}
