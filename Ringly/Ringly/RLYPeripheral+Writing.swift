import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyExtensions

/// Automatically writes configuration settings to peripherals.
///
/// This extension is not used for writing manual commands, such as LED commands.
extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, writes settings changes to the peripheral.
    ///
    /// - Parameter preferences: The preferences store to read settings from.
    func writeSettings(from preferences: Preferences) -> SignalProducer<(), NoError>
    {
        // write the settings when the peripheral is ready
        return ready
            // allow a timeout when peripherals disconnect and reconnect, without writing the settings
            .debounce(5, on: QueueScheduler.main, valuesPassingTest: { $0 == nil })
            .skipRepeats(==)
            .flatMapOptional(.latest, transform: { peripheral -> SignalProducer<(), NoError> in
                var producers: [SignalProducer<RLYCommand, NoError>] = [
                    // confirm iOS with this peripheral - is this necessary?
                    SignalProducer(value: RLYMobileOSCommand(type: .typeiOS)),

                    // enable connection LED response
                    SignalProducer(value: RLYConnectionLEDResponseCommand(enabled: true)),

                    // write the sleep time setting to the peripheral
                    preferences.sleepMode.producer.map({ enabled in
                        RLYSleepModeCommand(
                            sleepTime: enabled
                                ? RLYSleepModeCommandDefaultSleepTime
                                : RLYSleepModeCommandDisabledSleepTime
                        )
                    }),

                    // write the disconnect vibration setting to the peripheral
                    preferences.disconnectVibrations.producer.map(RLYDisconnectVibrationCommand.init),

                    // write the connection LED setting to the peripheral
                    preferences.connectionTaps.producer.map(RLYConnectionLEDCommand.init),

                    // write the inner ring setting to the peripheral
                    SignalProducer.combineLatest(preferences.innerRing.producer, peripheral.reactive.ANCSNotificationMode)
                        .filter({ _, mode in mode == .automatic })
                        .map({ enabled, _ in
                            RLYContactsModeCommand(mode: enabled ? .contactsOnly : .additionalColor)
                        })
                ]

                // write the ANCS timeout alert setting to the peripheral
                #if DEBUG || FUTURE
                producers.append(preferences.ANCSTimeout.producer.map(RLYANCSTimeoutAlertCommand.init))
                #endif

                return SignalProducer.merge(producers)
                    .on(value: peripheral.write)
                    .ignoreValues()
            })
            .ignoreValues()
    }
}
