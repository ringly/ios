import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheral
{
    // MARK: - Notifications

    /// A producer for the peripheral's ANCS v2 notifications.
    
    func ANCSV2NotificationsProducer() -> SignalProducer<RLYANCSNotification, NoError>
    {
        return ANCSNotification.filter({ $0.version == .version2 })
    }
}

extension RLYPeripheral
{
    // MARK: - Matching Configuration Snapshots

    /**
     A signal producer that reads the peripheral's current configuration hash, then updates the peripheral to match a
     new configuration, if necessary.
     
     If the configuration hash read fails, the producer logs the error.

     - parameter snapshot: The configuration snapshot to match.
     */
    
    func ensureMatches(configurationSnapshot snapshot: ANCSV2ConfigurationSnapshot) -> SignalProducer<(), NoError>
    {
        return reactive.readConfigurationHash()
            .map(ANCSV2PackedHash.init)
            .on(value: { [weak self] currentHash in
                self?.ensure(configurationSnapshot: snapshot, matchesCurrentHash: currentHash)
            })
            .ignoreValues()
            .flatMapError({ [weak self] error -> SignalProducer<(), NoError> in
                SLogBluetooth("Error reading configuration hash from \(self?.loggingName ?? "unknown"): \(error)")
                return SignalProducer.empty
            })
    }

    /**
     A side-effecting function that writes commands and a configuration hash to the peripheral.

     - parameter snapshot:    The configuration snapshot to match.
     - parameter currentHash: The current hash, previously read from the peripheral.
     */
    fileprivate func ensure(configurationSnapshot snapshot: ANCSV2ConfigurationSnapshot,
                            matchesCurrentHash currentHash: ANCSV2PackedHash)
    {
        if let (commands, hash) = commandsToEnsure(configurationSnapshot: snapshot, matchesCurrentHash: currentHash)
        {
            write(commands: commands, thenHash: hash.packed)
        }
    }

    /**
     If the current hash does not match the desired configuration snapshot's hash, yields the commands necessary to
     alter the peripheral's configuration to match.

     - parameter snapshot:    The configuration snapshot to match.
     - parameter currentHash: The current hash, previously read from the peripheral.

     - returns: An array of commands, or `nil` if the hash values already match.
     */
    
    fileprivate func commandsToEnsure(configurationSnapshot snapshot: ANCSV2ConfigurationSnapshot,
                                      matchesCurrentHash currentHash: ANCSV2PackedHash)
        -> (commands: [RLYCommand], hash: ANCSV2PackedHash)?
    {
        let correctHash = ANCSV2PackedHash(applications: snapshot.applications, contacts: snapshot.contacts)

        // always log the hashes, before aborting if they match
        SLogBluetooth("Read configuration hashes from \(loggingName), results are:\n" +
            "Current Application Hash: \(String(currentHash.first, radix: 16))\n" +
            "Correct Application Hash: \(String(correctHash.first, radix: 16))\n" +
            "   Current Contacts Hash: \(String(currentHash.second, radix: 16))\n" +
            "   Correct Contacts Hash: \(String(correctHash.second, radix: 16))\n"
        )

        // if the hashes already match
        guard currentHash != correctHash else { return nil }

        var commands = [RLYCommand]()

        // make sure that the current application settings are correct
        if currentHash.first != correctHash.first
        {
            commands.append(RLYClearApplicationSettingsCommand())

            commands += snapshot.applications.flatMap({ configuration in
                configuration.commands(for: .add) as [RLYCommand]
            })
        }

        // make sure that the current contact settings are correct
        if currentHash.second != correctHash.second
        {
            commands.append(RLYClearContactSettingsCommand())

            commands += snapshot.contacts.flatMap({ configuration -> [RLYCommand] in
                configuration.commands(for: .add)
            })
        }

        return (commands: commands, hash: correctHash)
    }
}
