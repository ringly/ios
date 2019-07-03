import RinglyKit

// MARK: - Write Sink

/// Describes the functionality needed to write ANCS v2 changes to peripherals.
protocol ANCSV2WriteSink
{
    // MARK: - Writing

    /**
     Writes a command to the sink.

     - parameter command: The command to write.
     */
    func write(command: RLYCommand)

    /**
     Writes a configuration hash to the sink.

     - parameter configurationHash: The configuration hash to write.
     */
    func writeConfigurationHash(_ configurationHash: UInt64) throws

    // MARK: - Logging

    /// A logging name for the value.
    var loggingName: String { get }
}

extension ANCSV2WriteSink
{
    // MARK: - Writing Multiple Commands

    /**
     Writes the specified commands, then writes the configuration hash change.

     - parameter commands: The commands to write.
     - parameter hash:     The hash to write.
     */
    func write(commands: [RLYCommand], thenHash hash: UInt64)
    {
        commands.forEach(write)

        do
        {
            try writeConfigurationHash(hash)
        }
        catch let error as NSError
        {
            SLogBluetooth("Error writing configuration hash to peripheral \(loggingName): \(error)")
        }
    }
}

// MARK: - Peripheral Extension

/// `RLYPeripheral` is extended to conform to `ANCSV2WriteSink`, which it does without additions.
extension RLYPeripheral: ANCSV2WriteSink {}
