import Foundation
import HealthKit

struct PreferredUnits
{
    // MARK: - Units

    /// The preferred unit for measuring distance.
    let distance: HKUnit

    /// The preferred unit for measuring height.
    let height: HKUnit

    /// The preferred unit for measuring body mass.
    let bodyMass: HKUnit
    
    /// The preferred unit for step goal
    let stepGoal: HKUnit
    
    /// The preferred unit for mindfulness goal
    let mindfulnessMinutesGoal: HKUnit
    

    // MARK: - Formatters

    /// A function to format a unit value as an array of unit string components.
    typealias Formatter = (_ quantity: HKQuantity) -> [UnitStringComponent]

    /// Formats height quantities as unit string components.
    let heightFormatter: Formatter

    func goalFormatter(_ quantity: HKQuantity) -> [UnitStringComponent]
    {
        let goalFormatter = NumberFormatter()
        goalFormatter.usesGroupingSeparator = true
        goalFormatter.numberStyle = .decimal
        
        return [UnitStringComponent.init(string: goalFormatter.string(from: NSNumber(value: quantity.doubleValue(for: HKUnit.count())))!, part: .value)]
    }
    
    /// Formats body mass quantities as unit string components.
    func bodyMassFormatter(_ quantity: HKQuantity) -> [UnitStringComponent]
    {
        let value = Int(quantity.doubleValue(for: bodyMass))

        return [
            UnitStringComponent(string: String(value), part: .value),
            UnitStringComponent(string: bodyMass.unitString, part: .unitSuffix)
        ]
    }

    // MARK: - Initialization

    /**
     Initializes a preferred units value.

     - parameter metric: If `true`, metric units will be selected. Otherwise, imperial units will be selected.
     */
    init(metric: Bool)
    {
        stepGoal = HKUnit.count()
        mindfulnessMinutesGoal = HKUnit.count()
        
        if metric
        {
            let centimeter = HKUnit.meterUnit(with: .centi)

            distance = HKUnit.meterUnit(with: .kilo)
            height = centimeter
            bodyMass = HKUnit.gramUnit(with: .kilo)

            heightFormatter = { quantity in
                let centimeters = Int(quantity.doubleValue(for: centimeter))

                return [
                    UnitStringComponent(string: String(centimeters), part: .value),
                    UnitStringComponent(string: centimeter.unitString, part: .unitSuffix)
                ]
            }
        }
        else
        {
            let inch = HKUnit.inch()

            distance = HKUnit.mile()
            height = inch
            bodyMass = HKUnit.pound()

            heightFormatter = { quantity in
                let inches = Int(quantity.doubleValue(for: inch))

                return [
                    UnitStringComponent(string: String(inches / 12), part: .value),
                    UnitStringComponent(string: "'", part: .unitInline),
                    UnitStringComponent(string: String(inches % 12), part: .value),
                    UnitStringComponent(string: "\"", part: .unitInline)
                ]
            }
        }
    }
}

/// A component of a string representing a value with units.
///
/// These values can be used to construct attributed strings with different attributes for different component types.
struct UnitStringComponent
{
    // MARK: - String

    /// The string value of the component.
    let string: String

    // MARK: - Parts

    /// The possible parts of unit component strings.
    enum Part
    {
        /// A numerical value.
        case value

        /// A unit that is represented "inline", i.e. feet/inches (`5'11"`).
        case unitInline

        /// A unit that is represented as a suffix.
        case unitSuffix
    }

    /// The part of the unit string that this unit is.
    let part: Part
}

extension Locale
{
    /// Returns the preferred units for the locale.
    var preferredUnits: PreferredUnits
    {
        return PreferredUnits(metric: ((self as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool ?? false))
    }
}
