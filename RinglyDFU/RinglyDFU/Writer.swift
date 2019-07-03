import CoreBluetooth
import DFULibrary
import Foundation
import ReactiveSwift
import RinglyKit
import enum Result.NoError

internal final class Writer: NSObject
{
    // MARK: - Initialization
    init(centralManager: CBCentralManager,
         peripheral: CBPeripheral,
         packageComponent: PackageComponent,
         notificationMode: WriterNotificationMode,
         hardwareVersion: RLYKnownHardwareVersion)
    {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.packageComponent = packageComponent
        self.notificationMode = notificationMode
        self.hardwareVersion = hardwareVersion
    }

    // MARK: - Bluetooth

    /// The central manager to use.
    fileprivate let centralManager: CBCentralManager

    /// The peripheral to use.
    fileprivate let peripheral: CBPeripheral

    // MARK: - Package Component

    /// The package component to write to `peripheral`.
    fileprivate let packageComponent: PackageComponent

    // MARK: - Write Information

    /// The notification mode to use.
    fileprivate let notificationMode: WriterNotificationMode

    /// The hardware version that we are using.
    fileprivate let hardwareVersion: RLYKnownHardwareVersion

    // MARK: - Writing
    fileprivate var controller: DFUServiceController?

    func writeProducer() -> SignalProducer<Int, NSError>
    {
        return SignalProducer.`defer` {
            let initiator = DFUServiceInitiator(centralManager: self.centralManager, target: self.peripheral)
                .withFirmwareFile(self.packageComponent.firmware!)

            // use the writer as the delegate for the process - this means that we need to be sure to retain it for
            // the duration of the operation
            initiator.delegate = self
            initiator.progressDelegate = self

            // use the appropriate service and characteristic UUIDs for this hardware platform, this ensures that we
            // do not write incorrect firmware to a peripheral, which would permanently brick it
            let serviceUUID = RLYKnownHardwareVersionRecoverySolicitedServiceUUID(self.hardwareVersion)
            initiator.peripheralSelector = WriterSelector(UUID: serviceUUID)
            initiator.serviceUUID = serviceUUID

            switch self.hardwareVersion
            {
            case .version1:
                break // use the default versions, which are already set on the initiator by default
            case .version2:
                initiator.controlPointCharacteristicUUID = Writer.version2ControlPointUUID
                initiator.packetCharacteristicUUID = Writer.version2PacketUUID
            }

            DFULogFunction("Writer service UUID is \(initiator.serviceUUID), control point \(initiator.controlPointCharacteristicUUID), packet \(initiator.packetCharacteristicUUID)")

            // Newer versions of the firmware use the expanded init packet, but the Nordic DFU framework expects to
            // read the DFU version to determine this, which our firmware doesn't support. Manually override one way
            // or the other.
            if self.notificationMode == .fast
            {
                initiator.allowInitPacketWithoutVersion = true
            }
            else
            {
                initiator.allowNoInitPacket = true
            }

            // go as fast as we can on the current bootloader version
            let interval = self.notificationMode.packetsNotificationInterval
            initiator.packetReceiptNotificationParameter = interval
            DFULogFunction("Setting packets notification interval to \(interval)")

            self.controller = initiator.start()

            // retain self until the producer terminates, to keep delegate alive
            return SignalProducer(self.pipe.output).on(completed: {
                DFULogFunction("Completed DFU write from \(self)")
            })
        }
    }

    // MARK: - Pipes for Events
    fileprivate let pipe = Signal<Int, NSError>.pipe()
}

extension Writer
{
    // MARK: - Hardware Version UUIDs

    /// The control point characteristic UUID for version 2 peripherals.
    @nonobjc static let version2ControlPointUUID = CBUUID(string: "a01f1541-70db-4ce5-952b-873759f85c44")

    /// The packet characteristic UUID for version 2 peripherals.
    @nonobjc static let version2PacketUUID = CBUUID(string: "a01f1542-70db-4ce5-952b-873759f85c44")
}

extension Writer: DFUServiceDelegate
{
    // MARK: - DFU Service Delegate
    func didStateChangedTo(_ state: DFULibrary.State)
    {
        DFULogFunction("Writer state changed to “\(state.loggingDescription)”")

        if state == .completed
        {
            pipe.input.sendCompleted()
        }
    }

    func didErrorOccur(_ error: DFUError, withMessage message: String)
    {
        pipe.input.send(error: NSError(domain: DFUWriteErrorDomain, code: error.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "Write Error",
            NSLocalizedFailureReasonErrorKey: message
        ]))
    }
}

extension Writer: DFUProgressDelegate
{
    // MARK: - DFU Progress Delegate
    func onUploadProgress(_ part: Int,
                          totalParts: Int,
                          progress: Int,
                          currentSpeedBytesPerSecond: Double,
                          avgSpeedBytesPerSecond: Double)
    {
        pipe.input.send(value: progress)
    }
}

// MARK: - Writer Selector

/// A `DFUPeripheralSelector` for use with `Writer`, allowing a variable service UUID to be set.
private final class WriterSelector
{
    // MARK: - Initialization

    /// Initializes a `WriterSelector`.
    ///
    /// - parameter UUID: The solicited service identifier for the selector to filter on.
    init(UUID: CBUUID)
    {
        self.UUID = UUID
    }

    // MARK: - UUID

    /// The solicited service identifier for the selector to filter on.
    fileprivate let UUID: CBUUID
}

extension WriterSelector: DFUPeripheralSelector
{
    // MARK: - DFU Peripheral Selector
    @objc func select(_ peripheral: CBPeripheral, advertisementData: [String:Any], RSSI: NSNumber) -> Bool
    {
        return true
    }

    @objc func filterBy() -> [CBUUID]?
    {
        return [UUID]
    }
}

// MARK: - DFU State Logging
extension DFULibrary.State
{
    /// A description of the state for use in logging - a more readable alternative to an integer raw value.
    fileprivate var loggingDescription: String
    {
        switch self
        {
        case .aborted:
            return "Aborted"
        case .completed:
            return "Completed"
        case .connecting:
            return "Connecting"
        case .disconnecting:
            return "Disconnecting"
        case .enablingDfuMode:
            return "EnablingDFUMode"
        case .starting:
            return "Starting"
        case .uploading:
            return "Uploading"
        case .validating:
            return "Validating"
        }
    }
}

public let DFUWriteErrorDomain = "com.ringly.RinglyDFU.WriteError"
