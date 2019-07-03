import Mixpanel

/// A protocol describing the subset of Mixpanel API necessary for managing user identity. This protocol can be
/// used for testing `AnalyticsService`.
protocol AnalyticsIdentityStore
{
    var distinctId: String { get }
    func identify(_ identifier: String)
    func createAlias(_ alias: String, forDistinctID: String)
}

extension Mixpanel: AnalyticsIdentityStore {}
