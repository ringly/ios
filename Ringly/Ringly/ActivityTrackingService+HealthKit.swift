import HealthKit
import RinglyActivityTracking
import ReactiveSwift
import Result

extension ActivityTrackingService
{
    // MARK: - Creating Services

    /// Creates an activity tracking service, using HealthKit if available.
    static func with(healthKitIfAvailable: Bool) -> ActivityTrackingService
    {
        let healthKitServiceResult: Result<(HKHealthStore, HealthKitService), HealthKitServiceCreateError>?

        if healthKitIfAvailable
        {
            // attempt to create a HealthKit service, if available
            let store: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil

            healthKitServiceResult = store.map({ store in
                HealthKitService.with(healthStore: store).map({ (store, $0) })
            })
        }
        else
        {
            healthKitServiceResult = nil
        }

        if let error = healthKitServiceResult?.error
        {
            SLogActivityTracking("HealthKit is available, but there was an error creating a HealthKitService \(error)")
        }

        // attempt to create a Realm service
        let fm = FileManager.default
        let realmURL = NSURL(fileURLWithPath: fm.rly_documentsFile(withName: "ActivityTrackingData-1.realm"))
        let realmService = RealmService(fileURL: realmURL as URL, logFunction: SLogActivityTracking)

        // create the activity tracking service
        let activityTrackingService = ActivityTrackingService(
            healthKitService: healthKitServiceResult?.value?.1,
            backupStepsDataSource: realmService,
            backupMindfulMinuteDataSource: realmService,
            retryBoundaryDateErrorsProducer: SignalProducer(
                NotificationCenter.default.reactive.notifications(
                    forName: NSNotification.Name.UIApplicationDidBecomeActive,
                    object: UIApplication.shared
                )
            ).void,
            errorLogFunction: SLogActivityTrackingError
        )

        // start writing values to HealthKit, if possible
        if let store = healthKitServiceResult?.value?.0
        {
            store.mindfulMinuteAuthorizationStatusProducer.skipRepeats().startWithValues({ status in
                if status == .sharingAuthorized {
                    realmService.dequeueMindfulUpdate(store: store).take(until: activityTrackingService.reactive.lifetime.ended).start()
                }
            })
            
            realmService.writeProducer(to: store, logFunction: SLogActivityTracking)
                .take(until: activityTrackingService.reactive.lifetime.ended)
                .on(value: { error in
                    SLogActivityTracking("Non-fatal error while writing steps to HealthKit: \(error)")
                })
                .on(failed: { error in
                    SLogActivityTracking("Fatal error while writing steps to HealthKit: \(error)")
                })
                .start()
        }

        return activityTrackingService
    }
}
