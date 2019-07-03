import CoreBluetooth
import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralConnectionInformation, Base: NSObject
{
    // MARK: - Connection
    
    /// Returns a signal producer for the peripheral's CBPeripheralState property.
    public var state: SignalProducer<CBPeripheralState, NoError>
    {
        return producerFor(keyPath: "state", defaultValue: CBPeripheralState.disconnected.rawValue)
            .map({ value in CBPeripheralState(rawValue: value)! })
    }
    
    /// Returns a signal producer for the peripheral's connected property.
    public var connected: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "connected")
    }
    
    /// Returns a signal producer for the peripheral's disconnected property.
    public var disconnected: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "disconnected", defaultValue: true)
    }
    
    /// Returns a signal producer for the peripheral's connecting property.
    public var connecting: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "connecting")
    }

    // MARK: - Shutdown

    /// Returns a signal producer for the peripheral's lastShutdownReason property.
    public var lastShutdownReason: SignalProducer<RLYPeripheralShutdownReason, NoError>
    {
        return producerFor(keyPath: "lastShutdownReason", defaultValue: RLYPeripheralShutdownReason.none.rawValue)
            .map({ value in RLYPeripheralShutdownReason(rawValue: value)! })
    }

    // MARK: - Pairing
    
    /// Returns a signal producer for the peripheral's `pairState` property.
    public var pairState: SignalProducer<RLYPeripheralPairState, NoError>
    {
        return producerFor(keyPath: "pairState", defaultValue: RLYPeripheralPairState.assumedPaired.rawValue)
            .map({ value in RLYPeripheralPairState(rawValue: value)! })
    }
    
    /// Returns a signal producer for the peripheral's paired property.
    public var paired: SignalProducer<Bool, NoError>
    {
        return producerFor(keyPath: "paired")
    }
    
    public var framesState: SignalProducer<RLYPeripheralFramesState, NoError>
    {
        return producerFor(keyPath: "framesState", defaultValue: RLYPeripheralFramesState.notStarted.rawValue)
            .map({ value in RLYPeripheralFramesState(rawValue: value)! })
    }
}
