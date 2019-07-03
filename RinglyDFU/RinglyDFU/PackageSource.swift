import DFULibrary
import Foundation
import RinglyAPI
import RinglyKit
import ReactiveSwift
import Result

/// Sources from which a `Package` can be acquired.
public enum PackageSource
{
    /// A package should be downloaded from the firmware result.
    case firmwareResult(result: RinglyAPI.FirmwareResult, APIService: RinglyAPI.APIService)

    /// The producer will provide a firmware result.
    case futureFirmwareResult(
        producer: SignalProducer<RinglyAPI.FirmwareResult, NSError>,
        APIService: RinglyAPI.APIService
    )

    /// The latest package for the hardware version should be downloaded.
    case latestForHardware(version: RLYKnownHardwareVersion, APIService: RinglyAPI.APIService)
}

extension PackageSource
{
    /// A signal producer for loading a package from the source.
    var packageProducer: SignalProducer<RinglyDFU.Package, NSError>
    {
        switch self
        {
        case .firmwareResult(let result, let API):
            // an application is required
            guard let application = result.applications.first else {
                return SignalProducer(error: DFUMakeError(.noApplication) as NSError)
            }

            let applicationProducer = API.packageComponentProducer(firmware: application)

            // the bootloader component is optional, if there isn't a bootloader, just send `nil` onwards
            let bootloaderProducer = result.bootloaders.first
                .map({ API.packageComponentProducer(firmware: $0).map(Optional.some) })
                ?? SignalProducer(value: nil)

            return SignalProducer.combineLatest(applicationProducer, bootloaderProducer).map(RinglyDFU.Package.init)

        case let .futureFirmwareResult(producer, api):
            return producer.take(first: 1).flatMap(.concat, transform: { result in
                PackageSource.firmwareResult(result: result, APIService: api).packageProducer
            })

        case .latestForHardware(let version, let API):
            let endpoint = FirmwareRequest.versions(
                hardware: RLYKnownHardwareVersionDefaultVersionString(version),
                application: nil,
                bootloader: nil,
                softdevice: nil,
                forceResults: false
            )

            return API.resultProducer(for: endpoint).flatMap(.latest, transform: { (result: FirmwareResult) in
                PackageSource.firmwareResult(result: result, APIService: API).packageProducer
            })
        }
    }
}

extension APIService
{
    fileprivate func packageComponentProducer(firmware: Firmware)
        -> SignalProducer<PackageComponent, NSError>
    {
        return dataProducer(request: URLRequest(url: firmware.URL)).attemptMap({ data in
            data.packageComponent(version: firmware.version, type: firmware.type)
        })
    }
}

extension Data
{
    fileprivate func packageComponent(version: String, type: DFUFirmwareType)
        -> Result<PackageComponent, NSError>
    {
        return unzippedToTemporaryDirectory(prefix: "\(version)-\(type.baseFilename)-")
            .flatMap({ URL in PackageComponent.with(directoryURL: URL, version: version, type: type) })
    }
}
