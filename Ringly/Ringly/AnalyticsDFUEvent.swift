import Foundation
import DFULibrary

enum AnalyticsDFUEvent
{
    case bannerShown
    case bannerTapped
    case cancelled
    case completed
    case downloaded
    case failed
    case phoneCharging
    case requestedForgetThisDevice
    case requestedPhoneCharging
    case requestedRingInCharger
    case requestedToggleBluetooth
    case ringInCharger
    case startTapped
}

extension AnalyticsDFUEvent: AnalyticsEventType
{
    var name: String
    {
        switch self
        {
        case .bannerShown:
            return kAnalyticsDFUBannerShown
        case .bannerTapped:
            return kAnalyticsDFUTapped
        case .cancelled:
            return kAnalyticsDFUCancelled
        case .completed:
            return kAnalyticsDFUCompleted
        case .downloaded:
            return kAnalyticsDFUDownloaded
        case .failed:
            return "DFU Failed"
        case .phoneCharging:
            return kAnalyticsDFUPhoneCharging
        case .requestedForgetThisDevice:
            return kAnalyticsDFURequestedForgetThisDevice
        case .requestedPhoneCharging:
            return kAnalyticsDFUPhoneCharging
        case .requestedRingInCharger:
            return kAnalyticsDFURequestedRingInCharger
        case .requestedToggleBluetooth:
            return kAnalyticsDFURequestedToggleBluetooth
        case .ringInCharger:
            return kAnalyticsDFURingInCharger
        case .startTapped:
            return kAnalyticsDFUStart
        }
    }

    var properties: [String : AnalyticsPropertyValueType]
    {
        return [:]
    }
}

struct AnalyticsDFUWriteEvent
{
    /// Enumerates the type of write events.
    enum EventType: String
    {
        case Started = "Started"
        case Completed = "Completed"
    }

    /// The type of write event.
    let type: EventType

    /// The index of this write.
    let index: Int

    /// The total number of writes.
    let count: Int

    /// The bootloader version of the peripheral being updated.
    let bootloaderVersion: String

    /// The package type being written to the peripheral.
    let packageType: DFUFirmwareType

    /// The package version being written to the peripheral.
    let packageVersion: String
}

extension AnalyticsDFUWriteEvent: AnalyticsEventType
{
    var name: String { return "DFU Write \(type.rawValue)" }
    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            kAnalyticsPropertyIndex: index,
            kAnalyticsPropertyCount: count,
            kAnalyticsPropertyDFUVersion: bootloaderVersion,
            kAnalyticsPropertyPackageType: packageType,
            kAnalyticsPropertyPackageVersion: packageVersion,
        ]
    }
}

extension DFUFirmwareType: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .application:
            return "application"
        case .bootloader:
            return "bootloader"
        case .softdevice:
            return "softdevice"
        case .softdeviceBootloader:
            return "softdevicebootloader"
        case .softdeviceBootloaderApplication:
            return "softdevicebootloaderapplication"
        }
    }
}
