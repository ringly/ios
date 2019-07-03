import Foundation

public struct CalendarBoundaryDates
{
    // MARK: - Initialization
    public init(calendar: Calendar, boundaryDates: BoundaryDates)
    {
        self.calendar = calendar
        self.boundaryDates = boundaryDates
        self.dayBoundaryDates = calendar.boundaryDatesForDays(from: boundaryDates.start, to: boundaryDates.end)
    }

    public init?(calendar: Calendar, fromMidnightBefore start: Date, toMidnightAfter end: Date)
    {
        let startBeforeEnd = calendar.startOfDay(for: end)

        guard let endMidnight = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: startBeforeEnd, options: []) else {
            return nil
        }

        self.init(
            calendar: calendar,
            boundaryDates: BoundaryDates(
                start: calendar.startOfDay(for: start),
                end: endMidnight
            )
        )
    }

    // MARK: - Properties

    /// The calendar.
    public let calendar: Calendar

    /// The boundary dates.
    public let boundaryDates: BoundaryDates

    /// The boundary dates for each day in the outer `boundaryDates`.
    public let dayBoundaryDates: [BoundaryDates]
}

extension CalendarBoundaryDates: Hashable
{
    public var hashValue: Int
    {
        return calendar.hashValue ^ boundaryDates.hashValue
    }
}

public func ==(lhs: CalendarBoundaryDates, rhs: CalendarBoundaryDates) -> Bool
{
    return lhs.calendar == rhs.calendar && lhs.boundaryDates == rhs.boundaryDates
}
