import Mixpanel

/// A protocol describing the subset of Mixpanel API necessary for managing super properties. This protocol can be
/// used for testing `AnalyticsService`.
protocol AnalyticsSuperPropertyStore
{
    func currentSuperProperties() -> [AnyHashable: Any]
    func registerSuperProperties(_ properties: [AnyHashable: Any])
    func unregisterSuperProperty(_ propertyName: String)
}

extension Mixpanel: AnalyticsSuperPropertyStore {}
