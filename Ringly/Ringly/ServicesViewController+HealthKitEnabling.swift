import ReactiveSwift
import RinglyActivityTracking
import enum Result.NoError

extension ServicesViewController
{
    /// Starts a signal producer that will request HealthKit access when `producer` sends a value.
    ///
    /// - parameter producer: The trigger producer.
    ///
    /// - returns: A disposable to stop the producer.
    @discardableResult
    func startRequestingHealthKitAccess(on producer: SignalProducer<(), NoError>) -> Disposable
    {
        let healthKitEnabledProducer = services.activityTracking.healthKitAuthorization.producer
            .filter({ $0 == .sharingAuthorized })
            .void

        return services.activityTracking.healthKitAuthorization.producer
            .sample(on: producer)
            .take(until: reactive.lifetime.ended)
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] status in
                switch status
                {
                case .notDetermined:
                    self?.services.activityTracking.requestHealthKitAuthorizationProducer()
                        .startWithFailed({ [weak self] error in
                            self?.presentError(error)
                        })

                case .sharingDenied:
                    let controller = OpenHealthViewController()

                    SignalProducer.merge(controller.closeProducer, healthKitEnabledProducer).take(first: 1)
                        .startWithValues({ [weak controller] in
                            _ = controller?.dismiss(animated: false, completion: nil)
                        })

                    self?.present(controller, animated: true, completion: nil)

                case .sharingAuthorized:
                    break
                }
            })
    }
}
