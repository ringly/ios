extension Sequence where Iterator.Element == SourcedUpdate
{
    /**
     Buckets the updates into dictionaries keyed by timestamp, after dividing by a value.

     - parameter minutesDenominator: The value to divide by.
     */
    func bucketed(minutesDenominator: UInt32) -> [UInt32:Set<SourcedUpdate>]
    {
        var buckets = [UInt32:Set<SourcedUpdate>]()

        for update in self
        {
            let healthKitInterval = update.update.date.minute / minutesDenominator
            buckets[healthKitInterval] = buckets[healthKitInterval]?.union([update]) ?? [update]
        }

        return buckets
    }
}
