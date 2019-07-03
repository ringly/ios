import Foundation
import RinglyKit

extension Date
{
    // MARK: - HealthKit Dates

    /**
     Initializes a date with a HealthKit time value.

     - parameter healthKitTimeValue: The HealthKit time value.
     */
    init(healthKitTimeValue: Int32)
    {
        let timestamp = RLYActivityTrackingMinuteToTimestamp(
            UInt32(healthKitTimeValue) * UInt32(UpdateModel.healthKitTimestampFactor)
        )

        self = Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    init(mindfulHealthKitTimeValue: Int32)
    {
        let timestamp = RLYActivityTrackingMinuteToTimestamp(
            UInt32(mindfulHealthKitTimeValue)
        )
        
        self = Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
