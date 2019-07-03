import RinglyKit

struct PeripheralApplicationErrorEvent
{
    // MARK: - Initialization
    init(peripheral: RLYPeripheralDeviceInformation, code: Int, line: Int, file: String)
    {
        self.applicationVersion = peripheral.applicationVersion ?? "unknown"
        self.bootloaderVersion = peripheral.bootloaderVersion ?? "unknown"
        self.hardwareVersion = peripheral.hardwareVersion ?? "unknown"
        self.code = code
        self.line = line
        self.file = file
    }

    init(applicationVersion: String,
         bootloaderVersion: String,
         hardwareVersion: String,
         code: Int,
         line: Int,
         file: String)
    {
        self.applicationVersion = applicationVersion
        self.bootloaderVersion = bootloaderVersion
        self.hardwareVersion = hardwareVersion
        self.code = code
        self.line = line
        self.file = file
    }

    // MARK: - Peripheral Versions
    let applicationVersion: String
    let bootloaderVersion: String
    let hardwareVersion: String

    // MARK: - Error Information
    let code: Int
    let line: Int
    let file: String
}

extension PeripheralApplicationErrorEvent: AnalyticsEventType
{
    var name: String { return "Peripheral Application Error" }
    var properties: [String : AnalyticsPropertyValueType]
    {
        return [
            "ErrorApplicationVersion": applicationVersion,
            "ErrorBootloaderVersion": bootloaderVersion,
            "ErrorHardwareVersion": hardwareVersion,
            "ErrorCode": code,
            "ErrorLine": line,
            "ErrorFile": file
        ]
    }

    static var eventLimit: Int { return 5 }
}
