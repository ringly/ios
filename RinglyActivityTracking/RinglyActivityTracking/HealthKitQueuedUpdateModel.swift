import RealmSwift

/// Update model for steps realm object
final class HealthKitQueuedUpdateModel: Object
{
    // MARK: - Initialization

    /**
     Initializes a HealthKit queued update model.

     - parameter timeValue: The time value to use for the model.
     */
    convenience init(timeValue: Int32)
    {
        self.init()
        self.timeValue = timeValue
    }

    // MARK: - Time Value

    /// The time value for the queued update.
    @objc dynamic var timeValue: Int32 = 0
}

extension HealthKitQueuedUpdateModel
{
    // MARK: - Realm
    override static func primaryKey() -> String?
    {
        return "timeValue"
    }
}

/// Update model for mindful minute realm object
final class UpdateMindfulnessSession: Object
{
    // MARK: - Initialization
    
    /**
     Initializes a HealthKit queued mindfulness session model.
     
     - parameter id: The id to use for the model.
     */
    convenience init(id: String)
    {
        self.init()
        self.id = id
    }
    
    /// The id for the queued update.
    @objc dynamic var id: String = NSUUID().uuidString
}

extension UpdateMindfulnessSession
{
    // MARK: - Realm
    override static func primaryKey() -> String?
    {
        return "id"
    }
}
