import Foundation
import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

/// A structure containing the start and end dates of a calendar day.
public struct BoundaryDates
{
    /// Initializes a `BoundaryDates` value.
    public init(start: Date, end: Date)
    {
        self.start = start
        self.end = end
    }

    /// The start date.
    public let start: Date

    /// The end date - which is the start date of the next day. Therefore, when making queries, a less-than comparison
    /// should be used, not a less-than-or-equal comparison.
    public let end: Date
    
    public static func today() -> BoundaryDates
    {
        let calendarBoundaryDates = CalendarBoundaryDates.init(calendar: Calendar.current, fromMidnightBefore: Date(), toMidnightAfter: Date())
        return calendarBoundaryDates!.boundaryDates
    }
}

extension BoundaryDates
{
    // MARK: - Comparing to Dates

    /**
     Checks whether or not `date` is within the boundary dates.

     - parameter date: The date to check.
     */
    public func contains(date: Date) -> Bool
    {
        return start.compare(date) != .orderedDescending && end.compare(date) != .orderedAscending
    }
}

extension BoundaryDates
{
    // MARK: - Progress

    /// The progress through the boundary dates for `date`.
    ///
    /// - parameter date: The date.
    
    public func progress(for date: Date) -> Double
    {
        guard date.compare(start) == .orderedDescending else { return 0 }
        guard date.compare(end) == .orderedAscending else { return 1 }

        return date.timeIntervalSince(start) / end.timeIntervalSince(start)
    }


    /// A signal producer for the current date's progress through the boundary dates.
    ///
    /// - parameter updating:  The frequency with which the progress should update.
    /// - parameter scheduler: The scheduler to use.
    
    public func progressProducer(updating: DispatchTimeInterval, on scheduler: DateSchedulerProtocol)
        -> SignalProducer<Double, NoError>
    {
        return SignalProducer.`defer` {
            let date = scheduler.currentDate

            guard date.compare(self.end) == .orderedAscending else { return SignalProducer(value: 1) }

            let timerProducer = timer(interval: updating, on: scheduler)
                .initializeAndReplaceFuture({ self.progress(for: scheduler.currentDate) })
                .take(until: timerUntil(date: self.end, on: scheduler).void)
                .concat(SignalProducer(value: 1))

            if date.compare(self.start) == .orderedDescending
            {
                return timerProducer
            }
            else
            {
                return SignalProducer(value: 0)
                    .concat(timerUntil(date: self.start, on: scheduler).then(timerProducer))
            }
        }
    }
}

extension BoundaryDates: Hashable
{
    public var hashValue: Int
    {
        return start.hashValue ^ end.hashValue
    }
}

public func ==(lhs: BoundaryDates, rhs: BoundaryDates) -> Bool
{
    return lhs.start == rhs.start && lhs.end == rhs.end
}

extension BoundaryDates: CustomStringConvertible
{
    public var description: String { return "\(start) to \(end)" }
}
