import ReactiveRinglyKit
import ReactiveSwift
import Result
import RinglyExtensions
import RinglyKit

/// Handles ANCS behavior for peripherals using version 2.
extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, will set ANCS v2 application and contact configurations on a peripheral.
    ///
    /// This producer is entirely side-effecting and does not send meaningful events.
    ///
    /// - Parameters:
    ///   - applicationsProducer: A producer for the application configurations to set on the peripheral.
    ///   - contactsProducer: A producer for the contact configurations to set on the peripheral.
    ///   - analyticsService: An analytics service for tracking events.
    ///   - debounceInterval: The interval at which configuration changes should be debounced, to avoid excess writes.
    ///                       The default value of this parameter is `5` seconds.
    ///   - scheduler: The scheduler on which configuration changes should be debounced. The default value of this
    ///                parameter is a scheduler on the main queue.
    func writeANCSV2Configurations
        (applicationsProducer: SignalProducer<[ApplicationConfiguration], NoError>,
         contactsProducer: SignalProducer<[ContactConfiguration], NoError>,
         analyticsService: AnalyticsService,
         debounceInterval: TimeInterval = 5,
         scheduler: DateSchedulerProtocol = QueueScheduler.main)
        -> SignalProducer<(), NoError>
    {
        // yields an event when the application or contacts settings are changed
        let mergedChangedEvents = SignalProducer.merge(
            applicationsProducer.skip(first: 1).void,
            contactsProducer.skip(first: 1).void
        ).debounce(5, on: scheduler)

        // logging when peripherals aren't ready
        let logReadiness = readiness
            .sample(on: mergedChangedEvents.void)
            .on(value: { readiness in
                if case let .unready(reason) = readiness
                {
                    SLogANCS("ANCS configurations changed, but cannot write for reason: \(reason)")
                }
            })

        // when peripherals become ready, ensure that they match the current (non-debounced) configuration
        let writeProducer = SignalProducer.combineLatest(applicationsProducer, contactsProducer)
            .map(ANCSV2ConfigurationSnapshot.init)
            .sample(with: ready.flatMapOptional(.latest, transform: { peripheral in
                SignalProducer(value: peripheral).concat(mergedChangedEvents.map({ _ in peripheral }))
            }))
            .map(unwrap)
            .skipNil()
            .flatMap(.latest, transform: { snapshot, peripheral in
                peripheral.ensureMatches(configurationSnapshot: snapshot)
            })

        // write analytics event when notifications are received
        let analyticsProducer = applicationsProducer.sample(with: ANCSV2NotificationsProducer())
            .map({ configurations, notification in
                unwrap(
                    configurations.configurationMatching(applicationIdentifier: notification.applicationIdentifier),
                    notification
                )
            })
            .skipNil()
            .on(value: { configuration, notification in
                analyticsService.track(NotifiedEvent(
                    applicationIdentifier: notification.applicationIdentifier,
                    sent: true,
                    enabled: true,
                    supported: true,
                    version: notification.version
                ))

                analyticsService.trackNotifiedEventWithLabel(configuration.application.analyticsName)
            })

        return SignalProducer.merge(
            writeProducer.ignoreValues(),
            analyticsProducer.ignoreValues(),
            logReadiness.ignoreValues()
        )
    }
}

struct ANCSV2ConfigurationsWithHash<Value>
{
    let configurations: [Value]
    let hash: UInt32
}

struct ANCSV2ConfigurationSnapshot
{
    let applications: [ApplicationConfiguration]
    let contacts: [ContactConfiguration]
}
