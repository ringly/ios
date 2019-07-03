import ReactiveSwift
import enum Result.NoError

enum ActivitySwitch
{
    // MARK: - Settings    
    case encouragement
}

extension ActivitySwitch
{
    // MARK: - Grouping
    
    /// All preferences, in presentation order.
    static var all: [ActivitySwitch]
    {
        return  [
            .encouragement ]
    }
    
    /// All preferences, in presentation order, grouped into sections.
    static var sections: [(title: String, switches: [ActivitySwitch])]
    {
        return [
            (title: "Activity Settings", switches: [
                .encouragement
                ])
        ]
    }
    
}

extension ActivitySwitch
{
    // MARK: - Display Attributes
    
    /// The title for the preference.
    var title: String
    {
        switch self
        {
        case .encouragement:
            return "Encouragement"
        }
    }
    
    /// An icon representing the preference.
    var iconImage: UIImage?
    {
        switch self
        {
        case .encouragement:
            return UIImage(asset: .settingsLight)
        }
    }
}

extension ActivitySwitch
{
    // MARK: - Preferences
    
    /**
     Returns the property in the specified preferences object that is associated with the preference.
     
     - parameter preferences: The preferences object.
     */
    func property(in preferences: Preferences) -> MutableProperty<Bool>
    {
        switch self
        {
        case .encouragement:
            return preferences.activityEncouragementEnabled
        }
    }
    
    func propertyBacking(in preferences: Preferences) -> MutableProperty<Bool>
    {
        switch self
        {
        case .encouragement:
            return preferences.activityEncouragementBacking
        }
    }
}

extension ActivitySwitch
{
    // MARK: - Analytics
    var analyticsSetting: AnalyticsSetting
    {
        switch self
        {
        case .encouragement:
            return .activityEncouragement
        }
    }
}
