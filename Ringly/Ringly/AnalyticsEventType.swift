import enum RinglyKit.RLYPeripheralBatteryState

/// A protocol for analytics events.
protocol AnalyticsEventType
{
    // MARK: - Name

    /// The name of the analytics event.
    var name: String { get }

    // MARK: - Properties

    /// The properties of the analytics event.
    var properties: [String:AnalyticsPropertyValueType] { get }

    // MARK: - Event Limit

    /// The maximum number of events for this type to send per-hour.
    static var eventLimit: Int { get }
}

extension AnalyticsEventType
{
    /// The default implementation returns an empty dictionary of parameters.
    var properties: [String:AnalyticsPropertyValueType] { return [:] }

    /// The default implementation returns `100`.
    static var eventLimit: Int { return 100 }
}

/// A protocol for types that can be converted to strings for use in analytics properties.
protocol AnalyticsPropertyValueType
{
    /// An analytics string representation of the value.
    var analyticsString: String { get }
}

extension String: AnalyticsPropertyValueType
{
    /// The string ifself.
    var analyticsString: String { return self }
}

extension Date: AnalyticsPropertyValueType
{
    var analyticsString: String {
        let dateFormatter = DateFormatter(format: "yyyy-MM-dd")
        return dateFormatter.string(from: self)
    }
}

extension Bool: AnalyticsPropertyValueType
{
    /// `"true"` or `"false"`
    var analyticsString: String { return self ? "true" : "false" }
}

extension Int: AnalyticsPropertyValueType
{
    /// A string representation of the integer.
    var analyticsString: String { return "\(self)" }
}

extension RawRepresentable where Self: AnalyticsPropertyValueType, RawValue: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        return rawValue.analyticsString
    }
}

extension RLYPeripheralBatteryState: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .notCharging, .error:
            return "0"
        case .charging:
            return "1"
        case .charged:
            return "2"
        }
    }
}
