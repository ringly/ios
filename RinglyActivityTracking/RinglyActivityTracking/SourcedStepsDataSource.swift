import Foundation
import ReactiveSwift
import enum Result.NoError

/// A protocol for types that can provide steps filtered by source.
public protocol SourcedStepsDataSource
{
    // MARK: - Sourced Steps Data

    /**
     A producer for the steps data between the specified dates.

     - parameter startDate:        The interval start date.
     - parameter endDate:          The interval end date.
     - parameter sourceMACAddress: The source MAC address to filter on.
     */
    func stepsDataProducer(startDate: Date, endDate: Date, sourceMACAddress: Int64)
        -> SignalProducer<StepsData, NSError>

    // MARK: - Date Boundaries

    /**
     A producer for one of the earliest or latest date for which step tracking data is available.

     - parameter ascending: If `true`, will yield the earliest date. If `false`, will yield the latest date.
     - parameter sourceMACAddress: The source MAC address to filter on.
     */
    func stepsBoundaryDateProducer(ascending: Bool, sourceMACAddress: Int64)
        -> SignalProducer<Date?, NSError>
}
