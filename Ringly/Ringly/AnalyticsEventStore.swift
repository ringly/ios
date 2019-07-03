import Mixpanel

/// A protocol describing the subset of Mixpanel API necessary for managing analytics events. This protocol can be
/// used for testing `AnalyticsService`.
protocol AnalyticsEventStore
{
    func timeEvent(_ eventName: String)
    func track(name: String, properties: [String:String]?)
    func flush()
}

extension Mixpanel: AnalyticsEventStore
{
    func track(name: String, properties: [String : String]?)
    {
        #if !FUTURE
        track(name, properties: properties)
        #endif
    }
}
