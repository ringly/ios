import CoreBluetooth
import RinglyKit
import ReactiveSwift
import Result

// MARK: Extension
public extension Reactive where Base: RLYCentral
{    
    // MARK: - Manager State

    /// A producer for the central's `managerState` property.
    public var managerState: SignalProducer<CBCentralManagerState, NoError>
    {
        return producerFor(keyPath: "managerState", defaultValue: CBCentralManagerState.unknown.rawValue)
            .map({ value in CBCentralManagerState(rawValue: value)! })
    }

    /// A producer for the central's `poweredOff` property.
    public var poweredOff: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "poweredOff")
    }

    /// A producer for the central's `unsupported` property.
    public var unsupported: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "unsupported")
    }
    
    // MARK: - Discovery

    /// A producer for the central's `discovery` property.
    public var discovery: SignalProducer<RLYCentralDiscovery?, NoError>
    {
        return producerFor(keyPath: "discovery")
    }
}
