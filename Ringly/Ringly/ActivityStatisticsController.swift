import HealthKit
import ReactiveSwift
import RinglyActivityTracking
import RinglyExtensions

/// Calculates distance and kcal expenditure for steps values, and creates data and value texts for display in
/// statistics views.
final class ActivityStatisticsController
{
    // MARK: - Initialization
    init(distanceUnit: HKUnit)
    {
        // prerequisites
        haveDistancePrerequisites = height.map({ $0 != nil })
        haveKilocaloriePrerequisites = Property.combineLatest(height, bodyMass, age)
            .map({ $0 != nil && $1 != nil && $2 != nil })

        // calculate distance and kcal
        distance = Property.combineLatest(steps, height).map(unwrap).map({ optional in
            optional.map({ steps, height in steps.distanceWith(height: height, unit: distanceUnit) })
        })

        calories = Property.combineLatest(distance, height, bodyMass, biologicalSex, age, dayProgress)
            .map(unwrap)
            .map({ optional in
                optional.map({ distance, height, bodyMass, biologicalSex, age, dayProgress in
                    Calories(
                        basal: distance.calories(bodyMass: bodyMass),
                        steps: StepsDataDistance.basalCalories(
                            bodyMass: bodyMass,
                            height: height,
                            age: age,
                            biologicalSex: biologicalSex
                        ) * dayProgress
                    )
                })
            })

        // a number formatter that uses the localized grouping separator, used for steps and calories
        let integerFormatter = NumberFormatter()
        integerFormatter.usesGroupingSeparator = true
        integerFormatter.numberStyle = .decimal
        integerFormatter.maximumFractionDigits = 0

        // a number formatter that rounds decimals to one place, used for calculating distances
        let distanceFormatter = NumberFormatter()
        distanceFormatter.maximumFractionDigits = 1

        // bind data/value text properties
        stepsControlData = Property.combineLatest(steps.map({ $0?.stepCount }), stepsGoal)
            .map(unwrap)
            .map({ optional in
                optional.map({ (steps: Int, goal: Int) -> ActivityControlData in
                    ActivityControlData(
                        progress: min(1, CGFloat(steps) / CGFloat(goal)),
                        valueText: .standalone(
                            integerFormatter.string(from: NSNumber(value: steps)) ?? String(describing: steps)
                        )
                    )
                })
            })
        
        // bind data/value text properties
        mindfulnessControlData = Property.combineLatest(mindfulMinutes.map({ $0?.minuteCount }), mindfulnessGoal)
            .map(unwrap)
            .map({ optional in
                optional.map({ (minutes: Int, goal: Int) -> ActivityControlData in
                    ActivityControlData(
                        progress: min(1, CGFloat(minutes) / CGFloat(goal)),
                        valueText: .standalone(
                            integerFormatter.string(from: NSNumber(value: minutes)) ?? String(describing: minutes)
                        )
                    )
                })
            })

        distanceValueText = distance.map({ distance in
            guard let distance = distance else {
                return nil
            }
            
            let value = distance.totalDoubleValue(unit: distanceUnit)
            return .withUnit(
                distanceFormatter.string(from: NSNumber(value: value))
                    ?? String(describing: distance),
                distanceUnit.unitString.uppercased()
            )
        })
        
        caloriesValueType = Property.init(value: "CAL")
        
        distanceValueType = Property.init(value: distanceUnit.unitString.uppercased())

        caloriesValueText = calories.map({ calories in
            guard let calories = calories else {
                return nil
            }
            let value = calories.total
            return .withUnit((integerFormatter.string(from: NSNumber(value: value)) ?? String(value)), "CAL")
        })
    }

    // MARK: - Steps Inputs

    /// The steps data to generate statistics for.
    let steps = MutableProperty(StepsData?.none)
    
    /// The mindfulness data to generate statistics for.
    let mindfulMinutes = MutableProperty(MindfulMinuteData?.none)

    /// The steps goal to use for `stepsControlData`.
    let stepsGoal = MutableProperty(Int?.none)
    
    /// The mindfulness goal to use for `mindfulnessControlData`.
    let mindfulnessGoal = MutableProperty(Int?.none)

    // MARK: - Body Inputs

    /// The user's height.
    let height = MutableProperty(HKQuantity?.none)

    /// The user's body mass.
    let bodyMass = MutableProperty(HKQuantity?.none)

    /// The user's biological sex, which is used to add basal calories.
    let biologicalSex = MutableProperty(HKBiologicalSex.female)

    /// The user's age, which is used to add basal calories.
    let age = MutableProperty(Int?.none)

    // MARK: - Timing Inputs

    /// The progress through the day, which is used to add basal calories.
    let dayProgress = MutableProperty(Double(0))

    // MARK: - Body Data Calculated Values

    /// The distance, calculated from `steps` and `height`.
    let distance: Property<StepsDataDistance?>

    /// The calorie values calculated by the statistics controller.
    struct Calories
    {
        init(basal: Double, steps: Double)
        {
            self.basal = basal
            self.steps = steps
            self.total = basal + steps
        }

        /// The calories from the user's BMR.
        let basal: Double

        /// The calories from the user's steps.
        let steps: Double

        /// The total calories.
        let total: Double
    }

    /// The calories expended, calculated from `distance` and `bodyMass`.
    let calories: Property<Calories?>

    // MARK: - Verifying Data Access

    /// `true` if the prerequisites for calculating distance, _excluding_ `steps`, are available.
    let haveDistancePrerequisites: Property<Bool>

    /// `true` if the prerequisites for calculating calories, _excluding_ `steps`, are available.
    let haveKilocaloriePrerequisites: Property<Bool>

    // MARK: - Control Data & Text

    /// The steps control data to display.
    let stepsControlData: Property<ActivityControlData?>
    
    /// The mindfulness control data to display.
    let mindfulnessControlData: Property<ActivityControlData?>

    /// The value text for the distance control.
    let distanceValueText: Property<ActivityControlValueText?>

    /// The value text for the calories control.
    let caloriesValueText: Property<ActivityControlValueText?>
    
    let distanceValueType: Property<String>
    
    let caloriesValueType: Property<String>
}

enum ActivityStatisticsCalculation
{
    case distance
    case calories
}
