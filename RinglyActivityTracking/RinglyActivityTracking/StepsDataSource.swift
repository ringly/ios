import Foundation
import HealthKit
import ReactiveSwift
import enum Result.NoError

// MARK: - Data Source

/// A protocol for types providing data about the user's steps.
public protocol StepsDataSource
{
    // MARK: - Steps Data

    /**
     A producer for the steps data between the specified dates.

     - parameter startDate: The interval start date.
     - parameter endDate:   The interval end date.
     */
    func stepsDataProducer(startDate: Date, endDate: Date)
        -> SignalProducer<StepsData, NSError>

    // MARK: - Date Boundaries

    /**
     A producer for one of the earliest or latest date for which step tracking data is available.

     - parameter ascending: If `true`, will yield the earliest date. If `false`, will yield the latest date.
     */
    func stepsBoundaryDateProducer(ascending: Bool) -> SignalProducer<Date?, NSError>
    
    func stepsBoundaryDateProducer(ascending: Bool, startDate: Date, endDate: Date) -> SignalProducer<Date?, NSError>
}

extension StepsDataSource
{
    // MARK: - Counting Steps

    /**
     A producer for the steps data between the specified dates.

     - parameter startDate: The interval start date.
     - parameter endDate:   The interval end date.
     - parameter sort:      The sorting behavior.
     */
    func stepsProducer(startDate: Date, endDate: Date)
        -> SignalProducer<Steps, NSError>
    {
        return stepsDataProducer(startDate: startDate, endDate: endDate).map({ $0.steps })
    }
}
