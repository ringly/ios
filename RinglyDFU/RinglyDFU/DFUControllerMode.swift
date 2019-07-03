import Foundation
import ReactiveSwift
import RinglyExtensions
import RinglyKit
import Result

/// The behaviors that a `DFUController` can be initialized with.
public enum DFUControllerMode
{
    // MARK: - Cases

    /// The DFU controller will update a normal peripheral.
    case Peripheral(peripheral: RLYPeripheral)

    /// The DFU controller will perform recovery mode on a peripheral.
    case recovery(peripheralIdentifier: UUID, hardwareVersion: RLYKnownHardwareVersion)
}

extension DFUControllerMode
{
    // MARK: - Performing DFU

    /// Creates a producer for performing DFU.
    ///
    /// - Parameters:
    ///   - package: The package to update the peripheral (a reference to which is stored in `self`) with.
    ///   - delegate: The delegate for managing peripheral connections.
    func producer(package: Package, delegate: DFUControllerDelegate)
        -> SignalProducer<State, NSError>
    {
        return firmwareFeaturesResult
            .flatMap({ features in
                producerResult(package: package, features: features, delegate: delegate)
                    .map({ producer in
                        features.modifiesServices
                            ? producer.concat(CBCentralManager.toggleBluetoothProducer().promoteErrors(NSError.self))
                            : producer
                    })
            })
            .analysis(ifSuccess: { $0 }, ifFailure: { SignalProducer(error: $0) })
    }

    fileprivate func producerResult(package: Package, features: FirmwareFeatures, delegate: DFUControllerDelegate)
        -> Result<SignalProducer<State, NSError>, NSError>
    {
        let peripheralIdentifier = self.peripheralIdentifier

        return hardwareVersionResult.flatMap({ hardwareVersion in
            let writeCount = package.bootloader != nil ? 2 : 1

            // a producer to write the application component to the peripheral
            let writeApplication = writeProducer(
                packageComponent: package.application,
                features: features,
                hardwareVersion: hardwareVersion,
                bootloaderIdentifier: nil,
                writeIndex: writeCount - 1,
                writeCount: writeCount,
                retry: hardwareVersion == .version2 ? 2 : 0
            )

            // a function to create a closure to enable or disable service interaction with the peripheral
            func allowInteraction(_ allow: Bool) -> () -> ()
            {
                if let identifier = peripheralIdentifier
                {
                    return { delegate.DFUController(allowInteraction: allow, withPeripheralWithIdentifier: identifier) }
                }
                else
                {
                    return {}
                }
            }

            // the producers to concatenate to perform DFU
            let producers = firstSendProducerResult(delegate: delegate)
                .map({ first in
                    first.on(
                        failed: { _ in allowInteraction(false)() },
                        completed: allowInteraction(false)
                    )
                })
                .flatMap({ first -> Result<[SignalProducer<State, NSError>], NSError> in
                if let bootloader = package.bootloader
                {
                    return secondSendProducerResult.map({ second in
                        // a producer to write the bootloader component to the producer
                        let writeBootloader = writeProducer(
                            packageComponent: bootloader,
                            features: features,
                            hardwareVersion: hardwareVersion,
                            bootloaderIdentifier: bootloaderIdentifier,
                            writeIndex: 0,
                            writeCount: writeCount,
                            retry: 0
                        )

                        return [first, writeBootloader, second, writeApplication]
                    })
                }
                else
                {
                    return .success([first, writeApplication])
                }
            })

            return producers.map({
                SignalProducer.concat($0).on(
                    failed: { _ in allowInteraction(true)() },
                    completed: allowInteraction(true)
                )
            })
        })
    }
}

extension DFUControllerMode
{
    // MARK: - Firmware Features

    /// The firmware features supported by the configuration.
    fileprivate var firmwareFeaturesResult: Result<FirmwareFeatures, NSError>
    {
        switch self
        {
        case .Peripheral(let peripheral):
            return peripheral.DFUFirmwareVersionsResult.map(FirmwareFeatures.init)

        case let .recovery(_, version):
            return .success(FirmwareFeatures.recoveryModeFeatures(knownHardwareVersion: version))
        }
    }

    /// A result for the hardware version of the peripheral to update.
    fileprivate var hardwareVersionResult: Result<RLYKnownHardwareVersion, NSError>
    {
        switch self
        {
        case let .Peripheral(peripheral):
            if let hardwareVersion = peripheral.knownHardwareVersion?.value
            {
                return .success(hardwareVersion)
            }
            else
            {
                let versionString = peripheral.applicationVersion ?? "Empty"

                return .failure(DFUMakeErrorWithReason(
                    .unknownHardwareVersion,
                    "Unknown hardware version for application “\(versionString)”"
                ) as NSError)
            }

        case let .recovery(_, hardwareVersion):
            return .success(hardwareVersion)
        }
    }
}

extension DFUControllerMode
{
    // MARK: - Send Producer

    /// The first producer to send a peripheral into bootloader mode, to be used before a bootloader write or, if there
    /// is no bootloader write, before a .
    fileprivate func firstSendProducerResult(delegate: DFUControllerDelegate)
        -> Result<SignalProducer<State, NSError>, NSError>
    {
        switch self
        {
        case .Peripheral(let peripheral):
            return firmwareFeaturesResult
                .map({ features -> Sender in
                    features.maintainsBondData
                        ? WriteSender(peripheral: peripheral)
                        : ForgetThisDeviceSender(initial: true, peripheral: peripheral, delegate: delegate)
                })
                .map({ sender in
                    sender.sendProducer().on(terminated: { peripheral.invalidateDeviceInformation() })
                })

        case .recovery:
            return .success(SignalProducer.empty)
        }
    }

    /// The second sender for this mode, to be used after a bootloader write.
    fileprivate var secondSendProducerResult: Result<SignalProducer<State, NSError>, NSError>
    {
        switch self
        {
        case let .Peripheral(peripheral):
            return firmwareFeaturesResult.map({ features -> SignalProducer<State, NSError> in
                let identifier = peripheral.identifier

                if features.maintainsBondData
                {
                    return SignalProducer.`defer` {
                        let central = RLYCentral()

                        return central.automaticallyReconnectToPeripheralProducer(identifier: identifier)
                            .promoteErrors(NSError.self)
                            .flatMap(.latest, transform: { peripheral in
                                central.repeatedlyWriteProducer(peripheral: peripheral)
                            })
                    }
                }
                else
                {
                    let sendProducer = SignalProducer<State, NSError>.`defer` {
                        let central = RLYCentral()

                        return central.scanAndPairWithPeripheralProducer(identifier: identifier)
                            .flatMap(.latest, transform: { peripheral in
                                central.forgetThisDeviceProducer(peripheral: peripheral)
                            })
                            .promoteErrors(NSError.self)
                    }

                    let producers = features.changesIdentifierInBootloaderMode
                        ? [sendProducer]
                        : [
                            CBCentralManager.toggleBluetoothProducer().promoteErrors(NSError.self),
                            sendProducer
                        ]

                    return SignalProducer<SignalProducer<State, NSError>, NoError>(producers).flatten(.concat)
                }
            })

        case .recovery:
            return .success(SignalProducer.empty)
        }
    }
}

extension DFUControllerMode
{
    // MARK: - Writers

    /// A producer for writing a package component to a peripheral.
    ///
    /// - Parameters:
    ///   - packageComponent: The package component to write.
    ///   - features: The firmware features of the peripheral to write to.
    ///   - hardwareVersion: The hardware version of the peripheral to write to.
    ///   - bootloaderIdentifier: The bootloader identifier of the peripheral to write to.
    ///   - writeIndex: The index of this write (vs. all total writes).
    ///   - writeCount: The total number of writes to be made.
    ///   - retry: The number of times that a failed write should be retried.
    fileprivate func writeProducer(packageComponent: PackageComponent,
                               features: FirmwareFeatures,
                               hardwareVersion: RLYKnownHardwareVersion,
                               bootloaderIdentifier: UUID?,
                               writeIndex: Int,
                               writeCount: Int,
                               retry: Int)
                               -> SignalProducer<State, NSError>
    {
        let scanProducer = SignalProducer.`defer` {
            Scanner(identifier: bootloaderIdentifier).scanProducer()
        }

        let scheduler = QueueScheduler.main

        let writeProducer = scanProducer
            .timeout(after: 10, raising: DFUMakeError(.scanningTimeout) as NSError, on: scheduler)
            .delay(3, on: scheduler)
            .flatMap(.latest, transform: { centralManager, peripheral in
                Writer(
                    centralManager: centralManager,
                    peripheral: peripheral,
                    packageComponent: packageComponent,
                    notificationMode: features.writerNotificationMode,
                    hardwareVersion: hardwareVersion
                ).writeProducer()
            })
            .map({ progress -> State in
                progress > 99
                    ? .activity(.writeCompleted)
                    : .writing(WriteProgress(progress: progress, index: writeIndex, count: writeCount))
            })

        return SignalProducer(value: .activity(.waitingForWriteStart))
            .concat(writeProducer)
            .retry(upTo: retry)
    }
}

extension DFUControllerMode
{
    // MARK: - Peripherals

    /// The peripheral for the mode, if not using recovery mode.
    public var peripheral: RLYPeripheral?
    {
        switch self
        {
        case .Peripheral(let peripheral):
            return peripheral

        case .recovery:
            return nil
        }
    }

    /// The peripheral's identifier, if `self` is `.Peripheral`.
    var peripheralIdentifier: UUID?
    {
        return peripheral?.identifier
    }

    /// The peripheral's bootloader mode identifier, if `self` is `.Recovery`.
    var bootloaderIdentifier: UUID?
    {
        switch self
        {
        case .Peripheral:
            return nil

        case let .recovery(peripheralIdentifier, _):
            return peripheralIdentifier
        }
    }
}
