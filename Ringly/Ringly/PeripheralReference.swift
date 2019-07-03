import ReactiveSwift
import enum Result.NoError

// MARK: - Peripheral References

protocol PeripheralReferenceType
{
    var peripheralReference: PeripheralReference { get }
}

/// A peripheral reference is our current knowledge of a peripheral - ideally, the peripheral itself, but, if not, a
/// saved state from a previous run of the application.
enum PeripheralReference
{
    case peripheral(RLYPeripheral)
    case saved(SavedPeripheral)
}

extension PeripheralReference: PeripheralReferenceType
{
    var peripheralReference: PeripheralReference { return self }
}

extension PeripheralReferenceType
{
    /// The identifier for the peripheral reference. This value will always be present.
    var identifier: UUID
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.identifier

        case .saved(let saved):
            return saved.identifier
        }
    }

    /// The name of the peripheral reference.
    var name: String?
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.name

        case .saved(let saved):
            return saved.name
        }
    }
    
    //Activity tracking support
    var activityTrackingSupport: RLYPeripheralFeatureSupport?
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.activityTrackingSupport
            
        case .saved(let saved):
            return saved.activityTrackingSupport
        }
    }

    /// The short name of the peripheral reference.
    var shortName: String?
    {
        switch peripheralReference
        {
        case let .peripheral(peripheral):
            return peripheral.shortName

        case let .saved(saved):
            return saved.shortName
        }
    }

    /// The peripheral reference's style.
    var style: RLYPeripheralStyle
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.style

        case .saved(let saved):
            return (saved.shortName as String?).map(RLYPeripheralStyleFromShortName) ?? .invalid
        }
    }

    /// A producer for the peripheral reference's style.
    ///
    /// If the reference is a saved peripheral, this will yield only one value (the equivalent of `style`). However, if
    /// the reference is a peripheral, it will forward the peripheral's `styleProducer`.
    var styleProducer: SignalProducer<RLYPeripheralStyle, NoError>
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.reactive.style

        case .saved:
            return SignalProducer(value: style)
        }
    }

    /// The referenced peripheral, if available.
    var peripheralValue: RLYPeripheral?
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral

        case .saved:
            return nil
        }
    }

    var savedPeripheral: SavedPeripheral
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return SavedPeripheral(
                identifier: peripheral.identifier,
                name: peripheral.name,
                applicationVersion: peripheral.applicationVersion,
                activityTrackingSupport: peripheral.activityTrackingSupport
            )

        case .saved(let saved):
            return saved
        }
    }

    var applicationVersion: String?
    {
        switch peripheralReference
        {
        case .peripheral(let peripheral):
            return peripheral.applicationVersion

        case .saved(let saved):
            return saved.applicationVersion
        }
    }
}

extension PeripheralReference: Equatable {}
func ==(lhs: PeripheralReference, rhs: PeripheralReference) -> Bool
{
    switch (lhs, rhs)
    {
    case (.peripheral(let lhsPeripheral), .peripheral(let rhsPeripheral)):
        return lhsPeripheral == rhsPeripheral
    case (.saved(let lhsSaved), .saved(let rhsSaved)):
        return lhsSaved == rhsSaved
    default:
        return false
    }
}
