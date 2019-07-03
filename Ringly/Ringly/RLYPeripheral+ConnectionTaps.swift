import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheralDeviceInformation, Base: NSObject
{
    /// A producer that yields boolean values describing whether or not the peripheral supports the connection LED
    /// response behavior.
    ///
    /// - Parameter fallback: A fallback application version, to use for feature detection if the peripheral's
    ///                       application version has not been read yet.
    func applicationVersionSupportsConnectionLEDResponse(fallback: String?) -> SignalProducer<Bool, NoError>
    {
        return applicationVersion.map({ version in
            let selected: String? = version ?? fallback

            return selected.map({
                $0.rly_compareVersionNumbers("1.4.3") == .orderedDescending
                    && $0.rly_compareVersionNumbers("2") == .orderedAscending
            }) ?? false
        })
    }
}

extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, writes connection LED responses to the peripheral.
    ///
    /// - Parameters:
    ///   - activatedProducer: A producer describing whether or not the behavior should be active.
    ///   - fallbackApplicationVersion: A fallback application version, to use for feature detection if the peripheral's
    ///                                 application version has not been read yet.
    func writeConnectionLEDResponse(activatedProducer: SignalProducer<Bool, NoError>,
                                    fallbackApplicationVersion: String?)
        -> SignalProducer<(), NoError>
    {
        return activatedProducer
            .and(applicationVersionSupportsConnectionLEDResponse(fallback: fallbackApplicationVersion))

            // send connection taps whenever two taps are received
            .sample(on: receivedTaps.filter({ $0 == 2 }).void)

            // send connection taps when the peripheral is activated and the setting is enabled
            .ignore(false).void

            // write connection confirmations to the peripheral
            .on(value: { [weak base] in
                base?.write(command: RLYColorVibrationCommand(azureColorAndVibration: .none))
            })
    }

    /// A producer that, once started, enables the connection LED response feature on the peripheral.
    func enableConnectionLEDResponse() -> SignalProducer<(), NoError>
    {
        // write the connection LED response command if necessary
        return ready.flatMapOptional(.latest, transform: { peripheral in
            // whenever the peripheral becomes ready, write the connection led response command if necessary
            peripheral.reactive.applicationVersion
                // ensure that the firmware is in the correct range
                .skipNil()
                .filter({ firmware in
                    (firmware.rly_compareVersionNumbers("1.4.3") == ComparisonResult.orderedDescending)
                        && (firmware.rly_compareVersionNumbers("2") == ComparisonResult.orderedAscending)
                })
                .take(first: 1)

                // write the command to enable connection LED
                .on(completed: { peripheral.write(command: RLYConnectionLEDResponseCommand(enabled: true)) })
        }).ignoreValues()
    }
}
