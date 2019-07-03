import ReactiveSwift
import enum Result.NoError

// MARK: - Enumeration

/// The state of connected peripherals and HealthKit access.
enum ActivityTrackingConnectivity: Equatable
{
    /// A step tracking peripheral (or HealthKit access) and a non-step tracking peripheral are connected.
    case haveTrackingAndNoTracking

    /// A step tracking peripheral (or HealthKit access) is connected.
    case haveTracking

    /// A step tracking peripheral is not connected, and HealthKit access is denied or not determined, but a peripheral
    /// that could support activity tracking if updated is connected.
    case updateRequired(identifier: UUID?, name: String?)

    /// A step tracking peripheral is not connected, and HealthKit access is denied or not determined. If a non-step
    /// tracking peripheral is connected, its name will be included as the parameter to this case.
    case noTracking(identifier: UUID?, name: String?)
    
    // No peripherals at all
    case noPeripheralsNoHealth
}

func ==(lhs: ActivityTrackingConnectivity, rhs: ActivityTrackingConnectivity) -> Bool
{
    switch (lhs, rhs)
    {
    case (.haveTrackingAndNoTracking, .haveTrackingAndNoTracking):
        return true
    case (.haveTracking, .haveTracking):
        return true
    case (.noPeripheralsNoHealth, .noPeripheralsNoHealth):
        return true
    case let (.updateRequired(lhsIdentifier, lhsName), .updateRequired(rhsIdentifier, rhsName)):
        return lhsIdentifier == rhsIdentifier && lhsName == rhsName
    case let (.noTracking(lhsIdentifier, lhsName), .noTracking(rhsIdentifier, rhsName)):
        return lhsIdentifier == rhsIdentifier && lhsName == rhsName
    default:
        return false
    }
}

// MARK: - Producers
extension PeripheralsService
{
    /// A producer for the activity tracking connectivity of the service's peripherals.
    var activityTrackingConnectivityProducer: SignalProducer<ActivityTrackingConnectivity, NoError>
    {
        return peripherals.producer
            .flatMap(.latest, transform: { $0.activityTrackingConnectivityProducer })
            .skipRepeats()
    }
}

extension Collection where Iterator.Element == RLYPeripheral
{
    fileprivate var activityTrackingConnectivityProducer: SignalProducer<ActivityTrackingConnectivity, NoError>
    {
        return count > 0
            ? SignalProducer.combineLatest(map({ peripheral in
                peripheral.reactive.activityTrackingAvailability.map({ (peripheral, $0) })
            })).activityTrackingConnectivityProducer
            : SignalProducer(value: .noPeripheralsNoHealth)
    }
}

extension SignalProducerProtocol where
    Value: Sequence,
    Value.Iterator.Element == (RLYPeripheral, ActivityTrackingAvailability),
    Error == NoError
{
    fileprivate var activityTrackingConnectivityProducer: SignalProducer<ActivityTrackingConnectivity, NoError>
    {
        return map({ peripheralSupport -> ActivityTrackingConnectivity in
            
            let unavailable = peripheralSupport.first(where: { (_: RLYPeripheral, a: ActivityTrackingAvailability) in
                a == .unavailable
            })?.0

            if peripheralSupport.first(where: { _, a in a == .available }) != nil
            {
                return unavailable == nil ? .haveTrackingAndNoTracking : .haveTracking
            }
            else if let update = peripheralSupport.first(where: { _, a in a == .updateRequired })?.0
            {
                return .updateRequired(identifier: update.identifier, name: RLYPeripheralStyleName(update.style))
            }
            else
            {
                if let unavailableIdentifer = unavailable?.identifier {
                    return .noTracking(
                        identifier: unavailableIdentifer,
                        name: (unavailable?.style).flatMap(RLYPeripheralStyleName)
                    )
                } else {
                    return .noPeripheralsNoHealth
                }
            }
        })
    }
}
