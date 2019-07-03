import CoreBluetooth

extension CBPeripheral
{
    var loggingName: String
    {
        return identifier.uuidString
    }
}
