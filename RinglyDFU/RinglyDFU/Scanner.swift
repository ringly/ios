import CoreBluetooth
import Foundation
import ReactiveSwift
import RinglyKit.RLYRecoveryPeripheral

/// A class that scans for peripherals in bootloader mode.
internal final class Scanner: NSObject
{
    // MARK: - Initialization

    /**
     Initializes a scanner.

     - parameter identifier: The identifier to filter to, if any.
     */
    init(identifier: UUID?)
    {
        self.identifier = identifier

        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue.global(qos: .userInitiated),
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }

    // MARK: - Properties

    /// The identifier to filter to, if any.
    fileprivate let identifier: UUID?

    /// The central manager the scanner will use to scan.
    fileprivate var centralManager: CBCentralManager?

    // MARK: - Events

    /// The value yielded by a successful scan.
    typealias ScanResult = (CBCentralManager, CBPeripheral)

    /// The discovered peripheral.
    fileprivate let parameters = MutableProperty(ScanResult?.none)

    /// The current central manager state.
    fileprivate let state = MutableProperty(CBCentralManagerState.unknown)
}

extension Scanner
{
    /// Starts scanning for producer, yielding the first peripheral found and an associated central manager.
    func scanProducer() -> SignalProducer<ScanResult, NSError>
    {
        let startScanning = state.producer
            .promoteErrors(NSError.self)
            .filter({ $0 != .unknown })
            .attempt(operation: { state in
                switch state
                {
                case .poweredOff:
                    return .failure(DFUMakeError(.centralManagerPoweredOff) as NSError)
                case .unsupported:
                    return .failure(DFUMakeError(.centralManagerUnsupported) as NSError)
                case .unauthorized:
                    return .failure(DFUMakeError(.centralManagerUnauthorized) as NSError)
                default:
                    return .success(())
                }
            })
            .on(value: { state in
                switch state
                {
                case .poweredOn:
                    DFULogFunction("Starting scan for DFU peripherals")

                    self.centralManager?.scanForPeripherals(withServices: nil, options: [
                        CBCentralManagerRestoredStateScanServicesKey: serviceUUIDs
                    ])

                default:
                    self.centralManager?.stopScan()
                }
            })

        return parameters.producer
            // start scanning automatically
            .promoteErrors(NSError.self)
            .combineLatest(with: startScanning)
            .map({ $0.0 })

            // wait until we have a central and peripheral
            .skipNil()
            .take(first: 1)

            // once completed, stop scanning
            .on(value: { central, _ in central.stopScan() })

            // delay to avoid errors
            .delay(0.1, on: QueueScheduler.main)
    }
}

extension Scanner: CBCentralManagerDelegate
{
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        state.value = CBCentralManagerState(rawValue: central.state.rawValue)!
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)
    {
        // if we are filtering on identifier, check the peripheral's identifier
        guard identifier.map({ $0 == peripheral.identifier }) ?? true else { return }

        // unpack the service identifiers from the advertisement data
        guard let serviceIdentifiers = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
            else { return }

        // ensure that the peripheral implements the correct service
        guard serviceIdentifiers.any({ serviceUUIDs.contains($0) }) else { return }

        // this peripheral is a valid DFU peripheral
        DFULogFunction("Found DFU peripheral \(peripheral.loggingName)")
        self.parameters.value = (central, peripheral)
    }
}

private let serviceUUIDs = [
    RLYRecoveryPeripheral.version1SolicitedServiceUUID(),
    RLYRecoveryPeripheral.version2SolicitedServiceUUID()
]
