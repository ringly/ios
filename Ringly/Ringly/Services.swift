import Foundation
import ReactiveSwift
import Result
import RinglyActivityTracking
import RinglyAPI

import class Mixpanel.Mixpanel
import class DFULibrary.Zip
import class DFULibrary.ZipArchive

final class Services: NSObject
{
    // MARK: - Initialization
    override init()
    {
        let fm = FileManager.default
        preferences = Preferences.shared

        // API
        let api = APIService(authenticationStorage: preferences)
        self.api = api

        // Analytics
        analytics = AnalyticsService(APIService: api, mixpanel: Mixpanel.sharedInstance())

        // Applications
        let supportedApps = SupportedApplication.all
        applicationsPath = fm.rly_documentsFile(withName: ApplicationsService.applicationsFileName)
        let applicationsLoadResult = ApplicationConfiguration.loaded(
            from: applicationsPath,
            supportedApplications: supportedApps,
            makeNewConfiguration: ApplicationConfiguration.defaultMakeNewConfiguration
        )

        let fireDate = Date(timeIntervalSinceNow: 2) // allow interface to appear before firing
        if let notification = applicationsLoadResult.localNotificationForNewApplicationsOnDevice(fireDate: fireDate)
        {
            UIApplication.shared.scheduleLocalNotification(notification)
        }

        applications = ApplicationsService(
            configurations: applicationsLoadResult.configurations,
            supportedApplications: supportedApps
        )

        applications.writeConfigurationsToPropertyListFileProducer(
            path: applicationsPath,
            // write new apps so that notification isn't sent again
            skipFirst: applicationsLoadResult.newApplications.count == 0,
            logFunction: SLogNotifications
        ).start()

        // prevent onboarding if more than four applications have been activated
        if applications.activatedConfigurations.value.count > 4
        {
            preferences.onboardingShown.value = true
        }

        // Contacts
        contactsPath = fm.rly_documentsFile(withName: ContactsService.contactsFilename)
        let contactConfigurations = ContactsService.contactConfigurations(from: contactsPath)
        contacts = ContactsService(configurations: contactConfigurations)

        contacts.automaticContactUpdateProducer.start()
        contacts.writeConfigurationsToPropertyListFileProducer(
            path: contactsPath,
            skipFirst: false,
            logFunction: SLogContacts
        ).start()

        // Keyboard
        keyboard = KeyboardService()

        // Logging
        logging = LoggingService.sharedLoggingService
        
        // Caching
        cache = CacheService(api: api)
        
        // Notification Alerts
        notifications = NotificationAlertService.sharedNotificationService

        // one-time migration of old saved peripherals
        if let saved = preferences.savedPeripheral.value, preferences.savedPeripherals.value.count == 0
        {
            preferences.savedPeripherals.value = [saved]
            preferences.activatedPeripheralIdentifier.value = saved.identifier
        }

        preferences.savedPeripheral.value = nil

        // activity tracking
        activityTracking = ActivityTrackingService.with(healthKitIfAvailable: true)

        activityNotifications = ActivityNotificationsService(
            state: preferences.activityNotificationsState.value ?? ActivityNotificationsState.empty,
            reminderState: preferences.activityReminderNotificationsState.value
                ?? ActivityReminderNotificationsState.empty,
            activityTracking: activityTracking,
            preferences: preferences
        )

        activityNotifications.stepsGoal <~ preferences.activityTrackingStepsGoal.producer
        preferences.activityNotificationsState <~ activityNotifications.state.producer.map({ $0 })
        preferences.activityReminderNotificationsState <~ activityNotifications.reminderState.producer.map({ $0 })
        
        // peripherals
        peripherals = PeripheralsService(
            centralManagerRestoreIdentifier: "ringlyCentralManagerIdentifier",
            savedPeripherals: preferences.savedPeripherals.value,
            activatedIdentifier: preferences.activatedPeripheralIdentifier.value,
            analyticsService: analytics,
            applicationsService: applications,
            contactsService: contacts,
            activityTrackingService: activityTracking,
            preferences: preferences
        )

        analytics.setSuperProperties(producer: SuperPropertySetting.producer(
            activity: activityTracking,
            applications: applications,
            contacts: contacts,
            peripherals: peripherals,
            preferences: preferences
        ))

        preferences.savedPeripherals <~ peripherals.savedPeripheralsProducer.skip(first: 1)
        preferences.activatedPeripheralIdentifier <~ peripherals.activatedIdentifier.signal

        activityTracking.realmService?.writeSourcedUpdatesProducer(peripherals.activityUpdatesProducer).start()
        
        // updates
        updates = UpdatesService(api: api, peripheralsService: peripherals)

        // peripheral registration
        peripheralRegistration = PeripheralRegistrationService(
            APIService: api,
            peripheralsService: peripherals,
            preferences: preferences
        )

        // engagement notifications
        engagementNotifications = EngagementNotificationsService()
        engagementNotifications.reactive.manageAllInitialPairNotifications(
            peripheralCountProducer: peripherals.stateProducer.map({ $0.references.count }),
            stepGoalProducer: preferences.activityTrackingStepsGoal.producer,
            preferences: preferences.engagement
        ).start()

        // mindful notifications
        mindfulNotifications = MindfulNotificationsService()
        mindfulNotifications.reactive.scheduleMindfulNotifications(preferences: preferences)
        
        // show reviews when appropriate
        preferences.reviewsState.transitionReviewsState()

        preferences.reviewsTextFeedback.startUpdating(makeProducer: { feedback in
            api.producer(for: feedback.endpoint).void
        })
    }

    // MARK: - Services

    /// The preferences service.
    let preferences: Preferences

    /// The applications service.
    let applications: ApplicationsService

    /// The analytics service.
    let analytics: AnalyticsService

    /// The API service.
    let api: APIService

    /// The contacts service.
    let contacts: ContactsService

    /// The engagement notifications service.
    let engagementNotifications: EngagementNotificationsService

    /// The logging service.
    let logging: LoggingService?
    
    /// The mindfulness notifications service.
    let mindfulNotifications: MindfulNotificationsService
    
    /// The notification alerts service.
    let notifications: NotificationAlertService

    /// The update service.
    let updates: UpdatesService

    /// The keyboard service.
    let keyboard: KeyboardService

    /// The peripherals service.
    let peripherals: PeripheralsService
    
    // Cached Data service
    let cache: CacheService

    /// The peripheral registration service.
    let peripheralRegistration: PeripheralRegistrationService

    /// The activity tracking service.
    let activityTracking: ActivityTrackingService

    /// The activity notifications service.
    let activityNotifications: ActivityNotificationsService
    
    // MARK: - File Paths

    /// The file path to save applications to.
    let applicationsPath: String

    /// The file path to save contacts to.
    let contactsPath: String
}

extension Services
{
    
    func dailyStepsMultipartFileProducer() -> SignalProducer<MultipartFile?, NoError> {
        let cache = ActivityCache(
            fileURL: FileManager.default.rly_cachesURL
                .appendingPathComponent("activity-week.realm")
            )
        
            return cache.stepsProducer()
                .map({ stepsAndDates in
                    stepsAndDates.map({ (date, steps) in
                       return "\(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)),\(steps.stepCount)"
                    }).joined(separator: "\n")
                })
                .diagnosticFileProducer(name: "daily-activity.csv", mime: "text/csv")
    }
    
    /// A producer yielding a diagnostic data request, to send to the API.
    ///
    /// This includes a CSV of the user's logs, their application, contacts, and user defaults as property lists; and
    /// the user's activity tracking Realm database.
    ///
    /// - Parameter reference: The reference value to include in the endpoint.
    
    @nonobjc func diagnosticDataRequestProducer(queryItems:[URLQueryItem]?) -> SignalProducer<DiagnosticDataRequest, NoError>
    {
        // configuration urls
        let applicationsURL = URL(fileURLWithPath: applicationsPath)
        let contactsURL = URL(fileURLWithPath: contactsPath)

        // perform data loading in background
        let scheduler = QueueScheduler(qos: .userInitiated, name: "diagnostic data")

        // create producers for each file that will be included in the endpoint request
        let fileProducers: [SignalProducer<MultipartFile?, NoError>] = [
            // activity tracking data
            SignalProducer.deferValue({
                (self.activityTracking.realmService?.fileURL).flatMap({ url in
                    MultipartFile(name: "activity.realm", mime: "application/octet-stream", dataFrom: url)
                })
            }).start(on: scheduler),

            // logs
            logging?.csvProducer.diagnosticFileProducer(name: "logs.csv", mime: "text/csv")
                ?? SignalProducer(value: nil),

            // configurations
            SignalProducer.deferValue({
                MultipartFile(name: "applications.plist", mime: "application/xml", dataFrom: applicationsURL)
            }).start(on: scheduler),

            SignalProducer.deferValue({
                MultipartFile(name: "contacts.plist", mime: "application/xml", dataFrom: contactsURL)
            }).start(on: scheduler),

            SignalProducer(result: UserDefaults.standard.dataRepresentation())
                .diagnosticFileProducer(name: "userdefaults.plist", mime: "application/xml"),
            

            self.dailyStepsMultipartFileProducer()
        ]

        // emit an endpoint with all non-nil files
        return SignalProducer.combineLatest(fileProducers).map({ files in
            DiagnosticDataRequest(queryItems: queryItems, files: files.flatMap({ $0 }).flatMap({ file in
                // the API requires that files be gzipped
                do
                {
                    return MultipartFile(
                        name: file.name,
                        mime: file.mime,
                        data: try (file.data as NSData).byGZipCompressing()
                    )
                }
                catch let error as NSError
                {
                    SLogAPI("Error gzip compressing \(file.name): \(error)")
                    return nil
                }
            }))
        })
    }
}

// MARK: - Diagnostic Data Extensions
extension MultipartFile
{
    init?(name: String, mime: String, dataFrom url: URL)
    {
        do
        {
            self.init(name: name, mime: mime, data: try Data(contentsOf: url))
        }
        catch let error as NSError
        {
            SLogAPI("Error loading data from \(url): \(error)")
            self.init(name: name.errorFileName, mime: "text/plain", contents: "\(error)")
        }
    }
}

extension SignalProducerProtocol where Value == Data
{
    fileprivate func diagnosticFileProducer(name: String, mime: String) -> SignalProducer<MultipartFile?, NoError>
    {
        return map({ MultipartFile(name: name, mime: mime, data: $0) }).catchingErrorsToFile(name: name)
    }
}

extension SignalProducerProtocol where Value == MultipartFile?
{
    fileprivate func catchingErrorsToFile(name: String) -> SignalProducer<MultipartFile?, NoError>
    {
        return mapErrorToValue({ MultipartFile(name: name.errorFileName, mime: "text/plain", contents: "\($0)") })
    }
}

extension SignalProducerProtocol where Value == String
{
    fileprivate func diagnosticFileProducer(name: String, mime: String) -> SignalProducer<MultipartFile?, NoError>
    {
        return map({ MultipartFile(name: name, mime: mime, contents: $0) }).catchingErrorsToFile(name: name)
    }
}

extension String
{
    fileprivate var errorFileName: String
    {
        return "\(self).error.txt"
    }
}

extension UserDefaults
{
    @nonobjc fileprivate func defaultsFileURL() -> Result<URL, AnyError>
    {
        return materialize {
            let directory = try ZipArchive.createTemporaryFolderPath("ringly-diagnostic-userdefaults-\(arc4random())")
            let file = URL(fileURLWithPath: directory).appendingPathComponent("userdefaults.plist")
            (dictionaryRepresentation() as NSDictionary).write(to: file, atomically: true)
            return file
        }
    }

    @nonobjc fileprivate func dataRepresentation() -> Result<Data, AnyError>
    {
        return materialize {
            try PropertyListSerialization.data(fromPropertyList: dictionaryRepresentation(), format: .xml, options: 0)
        }
    }
}
