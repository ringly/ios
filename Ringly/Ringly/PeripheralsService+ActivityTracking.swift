import ReactiveSwift
import ReactiveRinglyKit
import RinglyActivityTracking
import RinglyKit
import enum Result.NoError

extension PeripheralsService
{
    /// A producer for the activity tracking updates of the peripherals tracked by the updates service.
    var activityUpdatesProducer: SignalProducer<SourcedUpdate, NoError>
    {
        return activatedPeripheral.producer.skipNil()
            // observe all activity tracking events of current peripherals
            .flatMap(.latest, transform: { peripheral in
                peripheral.reactive.activityUpdatesProducer
            })

            // log errors and completion
            .on(value: { name, _, event in
                switch event
                {
                case .value:
                    break
                case .completed:
                    SLogActivityTracking("Received activity tracking completion event on peripheral \(name)")
                case .failed(let error):
                    SLogActivityTracking("Activity tracking error on peripheral \(name): \(error)")
                }
            })

            // attach the source to the update
            .map({ (name: String, macAddress: Int64, event: RLYPeripheralActivityTrackingEvent) -> SourcedUpdate? in
                event.update.map({ trackingUpdate -> SourcedUpdate in
                    SourcedUpdate(macAddress: macAddress, update: trackingUpdate)
                })
            })
            .skipNil()
    }
}

extension Reactive where Base: RLYPeripheral
{
    fileprivate var activityUpdatesProducer:
        SignalProducer<(name: String, macAddress: Int64, event: RLYPeripheralActivityTrackingEvent), NoError>
    {
        // retain the logging name throughout
        let loggingName = base.loggingName
        let macProducer = MACAddress.mapOptionalFlat({ Int64($0, radix: 16) })

        return macProducer.collectingCombine(with: activityTrackingEvents).map({ macAddress, event in
            (name: loggingName, macAddress: macAddress, event: event)
        })
    }
}
