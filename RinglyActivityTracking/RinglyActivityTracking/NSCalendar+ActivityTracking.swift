import Foundation

extension Calendar
{
    // MARK: - Hourly Boundary Dates

    /**
     Yields an array of the hourly boundary dates within the specified dates.

     - parameter start: The start date.
     - parameter end:   The end date.
     */
    public func boundaryDatesForHours(from start: Date, to end: Date) -> [BoundaryDates]
    {
        var components = DateComponents()
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        return boundaryDatesMatching(components: components, from: start, to: end)
    }

    // MARK: - Daily Boundary Dates

    /**
     Yields an array of the daily boundary dates within the specified dates.

     - parameter start: The start date.
     - parameter end:   The end date.
     */
    public func boundaryDatesForDays(from start: Date, to end: Date) -> [BoundaryDates]
    {
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        return boundaryDatesMatching(components: components, from: start, to: end)
    }

    // MARK: - Component Matching Boundary Dates

    /**
     Yields an array of the boundary dates within the specified dates, matching `components`.

     - parameter components: The components to match.
     - parameter start:      The start date.
     - parameter end:        The end date.
     */
    fileprivate func boundaryDatesMatching(components: DateComponents, from start: Date, to end: Date)
        -> [BoundaryDates]
    {
        var boundaryDates = [BoundaryDates]()

        enumerateDates(
            startingAfter: start,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            using: { optionalDate, _, stop in
                guard let date = optionalDate, date.compare(end) != .orderedDescending else {
                    stop = true
                    return
                }

                boundaryDates.append(BoundaryDates(start: boundaryDates.last?.end ?? start, end: date))
            }
        )

        return boundaryDates
    }
}

extension Calendar
{
    // MARK: - Symbols

    /**
     The amount that `veryShortWeekdaySymbols` needs to be shifted so that index `0` is the appropriate symbol for
     `date`.

     - parameter date: The date for the first symbol.
     */
    public func weekdayOffsetFor(date: Date) -> Int
    {
        var offset = -component(.weekday, from: date) + 1

        while offset < 0
        {
            offset += range(of: .weekday, in: .weekOfYear, for: date)?.count ?? 0
        }

        return offset
    }
}
