import ReactiveRinglyKit
import ReactiveSwift
import Result
import RinglyExtensions

extension Reactive where Base: RLYPeripheral
{
    /// A producer that, once started, will perform actions for ANCS notifications received from the peripheral.
    ///
    /// This producer is entirely side-effecting and does not send meaningful events.
    ///
    /// - Parameters:
    ///   - applicationsProducer: A producer for the current application configurations.
    ///   - contactsProducer: A producer for the current contact configurations.
    ///   - innerRingProducer: A producer for the user's inner ring setting.
    ///   - signatureCache: Stores signatures of sent notifications to prevent duplicate sends.
    ///   - analyticsService: The analytics service to notify of events.
    func sendANCSV1Notifications
        (applicationsProducer: SignalProducer<[ApplicationConfiguration], NoError>,
         contactsProducer: SignalProducer<[ContactConfiguration], NoError>,
         innerRingProducer: SignalProducer<Bool, NoError>,
         signatureCache: MutableProperty<[String]>,
         analyticsService: AnalyticsService)
        -> SignalProducer<(), NoError>
    {
        // observe and respond to the peripheral's notifications
        let configuration = SignalProducer.combineLatest(applicationsProducer, contactsProducer, innerRingProducer)

        // determine whether or not we should handle this notification
        let testResults = configuration.sample(with: ANCSNotification).map(append)
            .map({ applications, contacts, innerRing, notification in
                notification.ANCSV1TestResult(
                    sentSignatures: signatureCache.value,
                    applicationConfigurations: applications,
                    contactConfigurations: contacts,
                    innerRingEnabled: innerRing
                )
            })

        // when we receive an ANCS notification, handle it
        return testResults.on(value: { [weak base] result in
            guard let strong = base else { return }

            switch result
            {
            case .success(let ANCSNotification, let configurations):
                // do not send this notification again
                signatureCache.insertSignature(for: ANCSNotification)

                // extract configurations
                let application = configurations.application
                let contact = configurations.contact

                // create the notification
                var notification = application.notification
                notification.secondaryColor = (contact?.color).map(DefaultColorToLEDColor) ?? RLYColorNone
                
                // send the notification
                strong.writeNotification(notification)

                // track notification sent
                SLogANCS("Sending \(notification) for ANCS notification \(ANCSNotification)")

                analyticsService.track(NotifiedEvent(
                    applicationIdentifier: ANCSNotification.applicationIdentifier,
                    sent: true,
                    enabled: true,
                    supported: true,
                    version: ANCSNotification.version
                ))

                analyticsService.trackNotifiedEventWithLabel(application.application.analyticsName)

            case .failure(let rejection):
                // log rejection error
                SLogANCS("\(rejection)")
                
                // notify the peripheral that we won't be performing an action, but we received the notification
                strong.write(command: RLYNoActionCommand())
                
                // don't write notifications to the signature cache multiple times
                if rejection.reason != .alreadySent
                {
                    // write the notification to the signature cache, since we've already reached a decision on it
                    signatureCache.insertSignature(for: rejection.notification)
                }
                
                // track notification not sent
                if let event = rejection.notifiedEvent
                {
                    analyticsService.track(event)
                }
            }
        }).ignoreValues()
    }
}

extension RLYPeripheral
{
    /// The file that notification signatures are written to.
    @nonobjc fileprivate static let signatureCacheFileName = "notificationSigCache"

    /// A shared cache of notification signatures, to prevent duplicates.
    @nonobjc static let sharedSignatureCache = MutableProperty(
        filePath: FileManager.default.rly_documentsFile(withName: signatureCacheFileName),
        contentDescription: "notification signature cache",
        loggingTo: SLogANCS
    )
}

extension ModifiableMutablePropertyType where Value == [String]
{
    /// Writes a notification to the shared signature cache.
    ///
    /// - Parameter notification: The notification to write
    /// - Parameter count: The maximum number of signatures to store. The default value of this parameter is `300`.
    func insertSignature(for notification: RLYANCSNotification, limitingTo count: Int = 300)
    {
        pureModify({ current in
            var mutable = current
            mutable.insert(notification.ANCSV1Signature, at: 0)

            while mutable.count > count
            {
                mutable.removeLast()
            }

            return mutable
        })
    }
}

extension InitializableMutablePropertyProtocol where Value == [String]
{
    /// Creates a property that reads an array of strings from a property list file, then writes modifications to the
    /// same file.
    ///
    /// - Parameters:
    ///   - filePath: The file path to read from and write to.
    ///   - contentDescription: A description of the file content, which will be logged to `logFunction`.
    ///   - logFunction: A function to log errors to.
    init(filePath: String, contentDescription: String, loggingTo logFunction: @escaping (String) -> ())
    {
        self.init({ () -> [String] in
            if let array = NSArray(contentsOfFile: filePath) as? [String]
            {
                return array
            }
            else
            {
                logFunction("Could not load \(contentDescription) from property list file at “\(filePath)”")
                return []
            }
        }())

        // write the signature cache to disk after each change
        let scheduler = QueueScheduler(qos: .userInitiated, name: "Writing Configurations", targeting: nil)

        signal.observe(on: scheduler).observeValues({ signatures in
            do
            {
                let data = try PropertyListSerialization.data(fromPropertyList: signatures, format: .xml, options: 0)
                try data.write(to: URL(fileURLWithPath: filePath), options: .atomicWrite)
            }
            catch let error as NSError
            {
                logFunction("Error writing \(contentDescription) to property list file at “\(filePath)”: \(error)")
            }
        })
    }
}
