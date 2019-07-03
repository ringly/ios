import HealthKit
import RinglyAPI

// MARK: - Quantities

/// A HealthKit quantity and unit, encodable for storage in `Preferences`.
struct PreferencesHKQuantity
{
    /// The unit of the quantity.
    let baseUnit: HKUnit

    /// The quantity.
    let quantity: HKQuantity
}

extension PreferencesHKQuantity
{
    init(unit: HKUnit, doubleValue: Double)
    {
        self = PreferencesHKQuantity(
            baseUnit: unit,
            quantity: HKQuantity(unit: unit, doubleValue: doubleValue)
        )
    }
    
    init(quantity: HKQuantity, unit: HKUnit)
    {
        self = PreferencesHKQuantity(
            baseUnit: unit,
            quantity: quantity
        )
    }
}

extension PreferencesHKQuantity: Coding
{
    typealias Encoded = [String:Any]

    static func decode(_ encoded: Encoded) throws -> PreferencesHKQuantity
    {
        let unitString: String = try encoded.decode("baseUnitString")
        let baseUnit = HKUnit(from: unitString)
        let quantity = HKQuantity(unit: baseUnit, doubleValue: try encoded.decode("quantityValue"))

        return PreferencesHKQuantity(baseUnit: baseUnit, quantity: quantity)
    }

    var encoded: Encoded
    {
        return [
            "quantityValue": quantity.doubleValue(for: baseUnit) as AnyObject,
            "baseUnitString": baseUnit.unitString as AnyObject
        ]
    }
}

extension PreferencesHKQuantity: CustomStringConvertible
{
    var description: String
    {
        return "(\(quantity), base unit \(baseUnit))"
    }
}
