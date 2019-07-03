import ReactiveSwift
import enum Result.NoError

enum MindfulSwitch
{
    // MARK: - Reminder Settings
    case dailyReminders
}

extension MindfulSwitch
{
    // MARK: - Grouping
    
    /// All preferences, in presentation order.
    static var all: [MindfulSwitch]
    {
        return  [.dailyReminders]
    }
    
    /// All preferences, in presentation order, grouped into sections.
    static var sections: [(title: String, switches: [MindfulSwitch])]
    {
        return [
            (title: "Reminder", switches: [
                .dailyReminders
                ])
        ]
    }
    
}

extension MindfulSwitch
{
    // MARK: - Display Attributes
    
    /// The title for the preference.
    var title: String
    {
        switch self
        {
        case .dailyReminders:
            return "Daily Reminder"
        }
    }
    
    /// More information about the preference's purpose.
    var information: String
    {
        switch self
        {
        case .dailyReminders:
            return "Receive a daily notification on your phone to meditate."
        }
    }
    
    /// An icon representing the preference.
    var iconImage: UIImage?
    {
        switch self
        {
        case .dailyReminders:
            return UIImage(asset: .mindfulnessBreath)
        }
    }
}

extension MindfulSwitch
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
        case .dailyReminders:
            return preferences.mindfulRemindersEnabled
        }
    }
    
    func propertyBacking(in preferences: Preferences) -> MutableProperty<Bool>
    {
        switch self
        {
        case .dailyReminders:
            return preferences.mindfulRemindersBacking
        }
    }
}

extension MindfulSwitch
{
    // MARK: - Analytics
    var analyticsSetting: AnalyticsSetting
    {
        switch self
        {
        case .dailyReminders:
            return .dailyReminders
        }
    }
}
