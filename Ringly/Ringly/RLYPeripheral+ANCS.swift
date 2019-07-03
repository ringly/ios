import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, automatically performs all ANCS behavior for the peripheral.
    ///
    /// - Parameters:
    ///   - activatedProducer: A producer describing whether or not the peripheral should be active (perform actions) or
    ///                        should ignore notifications sent to it by ANCS.
    ///   - applicationsProducer: A producer for the application configurations to use.
    ///   - contactsProducer: A producer for the contact configurations to use.
    ///   - innerRingProducer: A producer describing the user's current preference for Inner Ring.
    ///   - analyticsService: An analytics service for tracking notification events.    
    func performANCSActions(activatedProducer: SignalProducer<Bool, NoError>,
                            applicationsProducer: SignalProducer<[ApplicationConfiguration], NoError>,
                            contactsProducer: SignalProducer<[ContactConfiguration], NoError>,
                            innerRingProducer: SignalProducer<Bool, NoError>,
                            analyticsService: AnalyticsService)
        -> SignalProducer<(), NoError>
    {
        return activatedProducer.producer.combineLatest(with: ANCSNotificationMode)
            .filter({ (activated, _) in activated })
            .skipRepeats(==)
            .flatMap(.latest, transform: { activated, mode -> SignalProducer<(), NoError> in
                switch mode
                {
                case .automatic:
                    return self.writeANCSV2Configurations(
                            applicationsProducer: applicationsProducer,
                            contactsProducer: contactsProducer,
                            analyticsService: analyticsService
                        )
                case .phone:
                    return self.sendANCSV1Notifications(
                            applicationsProducer: applicationsProducer,
                            contactsProducer: contactsProducer,
                            innerRingProducer: innerRingProducer,
                            signatureCache: RLYPeripheral.sharedSignatureCache,
                            analyticsService: analyticsService
                        )
                case .unknown:
                    return SignalProducer.empty
                }
            })
    }
}
