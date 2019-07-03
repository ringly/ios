enum ApplicationStateEvent
{
    case launched
    case foreground
    case background
}

extension ApplicationStateEvent: AnalyticsEventType
{
    var name: String
    {
        switch self
        {
        case .launched:
            return kAnalyticsApplicationLaunched
        case .foreground:
            return kAnalyticsApplicationForeground
        case .background:
            return kAnalyticsApplicationBackground
        }
    }
}
