import ReactiveSwift
import Result
import RinglyKit

// MARK: Extensions
public extension Reactive where Base: RLYCentral
{
    /**
     Returns a producer that adds a `ReactiveCentralObserver` to the central's observers, and removes it when disposed.

     - parameter configuration: A function for configuring the reactive observer to send events.
     */
    fileprivate func observerProducer<Value, ProducerError: Error>
        (configuration: @escaping (ReactiveCentralObserver, @escaping (Value) -> ()) -> ())
        -> SignalProducer<Value, ProducerError>
    {
        return SignalProducer { sink, disposable in
            let observer = ReactiveCentralObserver()
            self.base.add(observer: observer)

            configuration(observer, sink.send)

            disposable += ActionDisposable {
                self.base.remove(observer: observer)
            }
        }
    }

    /// Sends a `next` event when the user forgets a peripheral in Settings.
    ///
    /// The value of the event is the peripheral that was forgotten.
    public var userDidForgetPeripheral: SignalProducer<RLYPeripheral, NoError>
    {
        return observerProducer { $0.userDidForgetPeripheral = $1 }
    }

    /// Sends a `next` event when a peripherals are restored via Core Bluetooth state restoration.
    public var didRestorePeripherals: SignalProducer<[RLYPeripheral], NoError>
    {
        return observerProducer { $0.didRestorePeripherals = $1 }
    }

    /// Sends a `next` when a peripheral event occurs. These events are documented in `RLYCentralPeripheralEvent`.
    public var peripheralConnectionEvents: SignalProducer<RLYCentralPeripheralConnectionEvent, NoError>
    {
        return observerProducer{ $0.connectionEvent = $1 }
    }
}

// MARK: - Event Enumeration

/// Enumerates peripheral-connection-related events that can be observed via a `RLYCentral` instance.
public enum RLYCentralPeripheralConnectionEvent
{
    /// A peripheral will connect.
    case willConnect(peripheral: RLYPeripheral)

    /// A peripheral did connect.
    case didConnect(peripheral: RLYPeripheral)

    /// A peripheral failed to connect.
    case didFailToConnect(peripheral: RLYPeripheral, error: NSError?)

    /// A peripheral disconnected.
    case didDisconnect(peripheral: RLYPeripheral, error: NSError?)
}

extension RLYCentralPeripheralConnectionEvent
{
    /// The peripheral associated with the event.
    public var peripheral: RLYPeripheral
    {
        switch self
        {
        case .willConnect(let peripheral): return peripheral
        case .didConnect(let peripheral): return peripheral
        case .didFailToConnect(let tuple): return tuple.peripheral
        case .didDisconnect(let tuple): return tuple.peripheral
        }
    }
}

// MARK: - Observer Class
private final class ReactiveCentralObserver: NSObject, RLYCentralObserver
{
    var userDidForgetPeripheral: (RLYPeripheral) -> () = { _ in }
    var didRestorePeripherals: ([RLYPeripheral]) -> () = { _ in }
    var connectionEvent: (RLYCentralPeripheralConnectionEvent) -> () = { _ in }
    
    @objc fileprivate func central(_ central: RLYCentral, userDidForget peripheral: RLYPeripheral)
    {
        userDidForgetPeripheral(peripheral)
    }

    @objc func central(_ central: RLYCentral, didRestore peripherals: [RLYPeripheral])
    {
        didRestorePeripherals(peripherals)
    }

    @objc func central(_ central: RLYCentral, willConnectTo peripheral: RLYPeripheral)
    {
        connectionEvent(.willConnect(peripheral: peripheral))
    }

    @objc func central(_ central: RLYCentral, didConnectTo peripheral: RLYPeripheral)
    {
        connectionEvent(.didConnect(peripheral: peripheral))
    }

    @objc func central(_ central: RLYCentral, didFailToConnect peripheral: RLYPeripheral, withError error: Error?)
    {
        connectionEvent(.didFailToConnect(peripheral: peripheral, error: error as? NSError))
    }

    @objc func central(_ central: RLYCentral, didDisconnectFrom peripheral: RLYPeripheral, withError error: Error?)
    {
        connectionEvent(.didDisconnect(peripheral: peripheral, error: error as? NSError))
    }
}
