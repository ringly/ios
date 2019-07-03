import Foundation
import HealthKit

// MARK: - Steps

/// A value representing a combination of walking and running steps.
public struct Steps: StepsData
{
    // MARK: - Counts

    /// The count of walking steps.
    public var walkingStepCount: Int

    /// The count of running steps.
    public var runningStepCount: Int

    // MARK: - Initialization

    /**
     Initializes a `Steps` value.

     - parameter walkingStepCount: The count of walking steps.
     - parameter runningStepCount: The count of running steps.
     */
    public init(walkingStepCount: Int, runningStepCount: Int)
    {
        self.walkingStepCount = walkingStepCount
        self.runningStepCount = runningStepCount
    }

    /// Initializes a steps value by selecting the maximum for each timestamp from a sequence of timestamp-grouped
    /// steps.
    static func distinctMaxByMinuteSteps<Data: TimestampedStepsData, S: Sequence>(timestampGroupedSteps: S) -> Steps where S.Iterator.Element == Data

    {
        var optionalPrevious = Data?.none
        var steps = Steps.zero
        
        for next in timestampGroupedSteps
        {
            if let previous = optionalPrevious
            {
                if next.timestamp != previous.timestamp
                {
                    steps = steps + previous.steps
                    optionalPrevious = next
                }
                else if next.stepCount > previous.stepCount
                {
                    optionalPrevious = next
                }
            }
            else
            {
                optionalPrevious = next
            }
        }
        
        if let previous = optionalPrevious
        {
            steps = steps + previous.steps
        }
        
        return steps
    }
}

extension Steps
{
    // MARK: - Zero

    /// A `Steps` value with both counts set to `0`.
    public static var zero: Steps { return Steps(walkingStepCount: 0, runningStepCount: 0) }
}

/**
 Adds two `Steps` values.

 - parameter lhs: The first `Steps` value.
 - parameter rhs: The second `Steps` value.

 - returns: A `Steps` value with the walking and running components of the two input `Steps` values added.
 */
public func +<L: StepsData, R: StepsData>(lhs: L, rhs: R) -> Steps
{
    return Steps(
        walkingStepCount: lhs.walkingStepCount + rhs.walkingStepCount,
        runningStepCount: lhs.runningStepCount + rhs.runningStepCount
    )
}

extension Steps: Hashable
{
    public var hashValue: Int { return walkingStepCount ^ runningStepCount }
}

public func ==<L: StepsData, R: StepsData>(lhs: L, rhs: R) -> Bool
{
    return lhs.walkingStepCount == rhs.walkingStepCount && lhs.runningStepCount == rhs.runningStepCount
}

// MARK: - Steps Data

/// A protocol for types that can provide a step count.
public protocol StepsData
{
    /// The number of walking steps in the data.
    var walkingStepCount: Int { get }

    /// The number of running steps in the data.
    var runningStepCount: Int { get }
}

extension StepsData
{
    /// The number of steps in the data.
    public var stepCount: Int { return walkingStepCount + runningStepCount }

    /// A representation of the receiver as a `Steps` value.
    public var steps: Steps
    {
        return Steps(walkingStepCount: walkingStepCount, runningStepCount: runningStepCount)
    }
}

extension StepsData
{
    // MARK: - Distance and Calorie Estimation

    /**
     Returns the estimated distance that the steps value covered.

     - parameter height: The height of the user, for estimation of stride length.
     - parameter unit:   The unit to return distances in.

     - returns: A tuple of walking and running distance, which can be added for a total distance.
     */
    public func distanceWith(height: HKQuantity, unit: HKUnit) -> StepsDataDistance
    {
        let heightDistance = height.doubleValue(for: unit)

        return StepsDataDistance(
            running: Double(heightDistance) * 0.413 * 1.17 * Double(runningStepCount),
            walking: Double(heightDistance) * 0.413 * Double(walkingStepCount),
            unit: unit
        )
    }
}

/// An extension of `StepsData` with a timestamp.
public protocol TimestampedStepsData: StepsData
{
    /// The timestamp for the steps data.
    var timestamp: Int32 { get }
}

// MARK: - Distance
public struct StepsDataDistance
{
    // MARK: - Properties

    /// The running distance.
    let running: Double

    /// The walking distance.
    let walking: Double

    /// The unit for `running` and `walking`.
    let unit: HKUnit
}

extension StepsDataDistance
{
    // MARK: - Component Double Values

    /// The running distance, in terms of `unit`.
    ///
    /// - parameter unit: The unit to use.
    
    public func runningDoubleValue(unit: HKUnit) -> Double
    {
        return HKQuantity(unit: self.unit, doubleValue: running).doubleValue(for: unit)
    }

    /// The walking distance, in terms of `unit`.
    ///
    /// - parameter unit: The unit to use.
    
    public func walkingDoubleValue(unit: HKUnit) -> Double
    {
        return HKQuantity(unit: self.unit, doubleValue: walking).doubleValue(for: unit)
    }

    /// The total distance, in terms of `unit`.
    ///
    /// - parameter unit: The unit to use.
    
    public func totalDoubleValue(unit: HKUnit) -> Double
    {
        return HKQuantity(unit: self.unit, doubleValue: running + walking).doubleValue(for: unit)
    }
}

extension StepsDataDistance
{
    // MARK: - Caloric Expenditure

    /// Determines the number of calories that were expended for the distance.
    ///
    /// - parameter bodyMass: The user's body mass.
    
    public func calories(bodyMass: HKQuantity) -> Double
    {
        let mile = HKUnit.mile()
        let kilograms = bodyMass.doubleValue(for: HKUnit.gramUnit(with: .kilo))

        return (walkingDoubleValue(unit: mile) * 1.2 + runningDoubleValue(unit: mile) * 1.5) * kilograms
    }

    /// The basal calories expended per-day by a user with the specified attributes.
    ///
    /// - parameter bodyMass:      The user's body mass.
    /// - parameter height:        The user's height.
    /// - parameter age:           The user's age.
    /// - parameter biologicalSex: The user's biological sex.
    
    public static func basalCalories(bodyMass: HKQuantity,
                                         height: HKQuantity,
                                         age: Int,
                                         biologicalSex: HKBiologicalSex)
                                         -> Double
    {
        let kilograms = bodyMass.doubleValue(for: HKUnit.gramUnit(with: .kilo))
        let centimeters = height.doubleValue(for: HKUnit.meterUnit(with: .centi))

        return (10 * kilograms + 6.25 * centimeters - 5 * Double(age) + biologicalSex.basalCaloriesAdjustment)
    }
}

extension HKBiologicalSex
{
    fileprivate var basalCaloriesAdjustment: Double
    {
        switch self
        {
        case .notSet:
            return 0
        case .other:
            return (5 - 161) / 2 // maybe?
        case .male:
            return 5
        case .female:
            return -161
        }
    }
}
