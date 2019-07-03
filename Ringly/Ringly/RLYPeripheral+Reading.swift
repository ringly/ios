import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyKit

/// Handles reading information from the peripheral.
extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, automatically reads device and battery information from the peripheral.
    func readInformation() -> SignalProducer<(), NoError>
    {
        // read device information once we pair with the peripheral
        return readiness
            .on(value: { [weak base] readiness in
                if case let .unready(reason) = readiness, let peripheral = base
                {
                    let errors = peripheral.validationErrors.map({ " \($0)" }) ?? ""
                    SLogBluetooth("Can't read device information of \(peripheral.loggingName): \(reason)\(errors)")
                }
            })
            .map({ [weak base] readiness -> RLYPeripheral? in readiness == .ready ? base : Optional.none })
            .skipRepeats(==)
            .on(value: { (optional: RLYPeripheral?) in
                guard let peripheral = optional else { return }

                do
                {
                    SLogBluetooth("Reading device information of \(peripheral.loggingName)");
                    try peripheral.readDeviceInformationCharacteristics()
                }
                catch let error as NSError
                {
                    SLogBluetooth("Error reading device information of \(peripheral.loggingName): \(error)")
                }
            })

            // read battery information
            .debounce(1, on: QueueScheduler.main)
            .flatMapOptional(.latest, transform: { (peripheral: RLYPeripheral) -> SignalProducer<(), NoError> in
                // create a producer for every time the application enters the foreground
                let application = UIApplication.shared

                let becameActive = NotificationCenter.default.reactive
                    .notifications(forName: .UIApplicationWillEnterForeground, object: application)
                    .map({ _ in "Application entered foreground" })
                
                return SignalProducer.merge(SignalProducer(value: "Initial Read"), SignalProducer(becameActive))
                    .on(value: { reason in
                        do
                        {
                            try peripheral.readBatteryCharacteristics()
                            SLogBluetooth("Read battery state of \(peripheral.loggingName) because: \(reason)")
                        }
                        catch let error as NSError
                        {
                            SLogBluetooth("Error reading battery state of \(peripheral.loggingName): \(error)")
                        }
                    })
                    .ignoreValues()
            })
            .ignoreValues()
    }
}
