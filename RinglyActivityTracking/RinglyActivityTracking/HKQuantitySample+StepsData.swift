import HealthKit

extension HKQuantitySample
{
    // MARK: - User Info Keys
    
    /// A user info key for the number of walking steps in the update.
    @nonobjc static let ringlyWalkingStepsUserInfoKey = "Walking Steps"

    /// A user info key for the number of running steps in the update.
    @nonobjc static let ringlyRunningStepsUserInfoKey = "Running Steps"
}

extension HKQuantitySample: StepsData
{
    // MARK: - Steps Data
    public var walkingStepCount: Int
    {
        return metadata?[HKQuantitySample.ringlyWalkingStepsUserInfoKey] as? Int
            ?? Int(quantity.doubleValue(for: HKUnit.count()))
    }

    public var runningStepCount: Int
    {
        return metadata?[HKQuantitySample.ringlyRunningStepsUserInfoKey] as? Int
            ?? 0
    }
}

extension HKCategorySample
{
    // MARK: - User Info Key
    
    /// A user info key for mindful minutes performed.
    @nonobjc static let ringlyMindfulMinuteUserInfoKey = "Mindful Minutes"
    
    @nonobjc static let ringlyMeditationUserInfoKey = "Meditation Type"
}

extension HKCategorySample: MindfulMinuteData
{
    // MARK: - Mindful Minute Data
    public var minuteCount: Int
    {
        return metadata?[HKCategorySample.ringlyMindfulMinuteUserInfoKey] as? Int
            ?? 0
    }
}
