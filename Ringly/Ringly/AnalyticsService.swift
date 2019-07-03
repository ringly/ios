import Foundation
import Mixpanel
import ReactiveSwift
import RinglyAPI
import RinglyDFU
import enum Result.NoError

// MARK: - Analytics Service
final class AnalyticsService: NSObject
{
    // MARK: - Stores

    /// A date scheduler used to determine the current date, for setting event quotas.
    fileprivate let dateScheduler: DateSchedulerProtocol

    /// Used to track events.
    fileprivate let eventStore: AnalyticsEventStore

    /// Used to track notified events.
    fileprivate let notifiedStore: AnalyticsNotifiedStore

    /// Used to store super property values.
    fileprivate let superPropertyStore: AnalyticsSuperPropertyStore

    // MARK: - Initialization

    /// Initializes an analytics service.
    ///
    /// - Parameters:
    ///   - authenticationProducer: A producer for the authentication value to store in `identityStore`.
    ///   - dateScheduler: A date scheduler used to determine the current date, for setting event quotas.
    ///   - eventStore: The store to track events with.
    ///   - identityStore: The store to track user identity with.
    ///   - notifiedStore: The store to track notified events with.
    ///   - superPropertyStore: The store to track super properties with.
    init(authenticationProducer: SignalProducer<Authentication, NoError>,
         dateScheduler: DateSchedulerProtocol,
         eventStore: AnalyticsEventStore,
         identityStore: AnalyticsIdentityStore,
         notifiedStore: AnalyticsNotifiedStore,
         superPropertyStore: AnalyticsSuperPropertyStore)
    {
        self.dateScheduler = dateScheduler
        self.eventStore = eventStore
        self.notifiedStore = notifiedStore
        self.superPropertyStore = superPropertyStore

        super.init()

        authenticationProducer
            .map({ $0.user?.identifier })
            .combinePrevious(.some(identityStore.distinctId))
            .map(AnalyticsIdentifyAction.actions)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ actions in actions.forEach({ $0.apply(to: identityStore) }) })
    }

    convenience init(APIService: RinglyAPI.APIService, mixpanel: Mixpanel)
    {
        self.init(
            authenticationProducer: APIService.authentication.producer,
            dateScheduler: QueueScheduler.main,
            eventStore: mixpanel,
            identityStore: mixpanel,
            notifiedStore: APIService,
            superPropertyStore: mixpanel
        )
    }

    // MARK: - Super Properties

    /// Starts setting Mixpanel super properties.
    ///
    /// - parameter producer: A producer for Mixpanel super property settings.
    func setSuperProperties(producer: SignalProducer<SuperPropertySetting, NoError>)
    {
        producer.take(until: reactive.lifetime.ended).startWithValues({ [weak self] setting in
            SLogAnalytics("Setting super property \(setting.key) to \(setting.value ?? "<null>")")

            if let value = setting.value
            {
                self?.superPropertyStore.registerSuperProperties([setting.key: value])
            }
            else
            {
                self?.superPropertyStore.unregisterSuperProperty(setting.key)
            }
        })
    }

    // MARK: - Tracking Events
    func time(event: String)
    {
        eventStore.timeEvent(event)
    }

    func track(event: String, properties: [String:String]? = nil, eventLimit: Int)
    {
        eventCounts.modify({ eventCounts in
            // get the current amount of events for this name that have occurred in the past bucket time
            let currentDate = dateScheduler.currentDate
            let (startDate, eventCount) = eventCounts[event].flatMap({ startDate, eventCount in
                currentDate.timeIntervalSince(startDate) < AnalyticsService.eventQuotaInterval.timeInterval
                    ? (startDate, eventCount)
                    : nil
            }) ?? (currentDate, 0)

            // if we haven't surpassed the limit, track the event
            if eventCount < eventLimit
            {
                SLogAnalytics("Tracked event “\(event)” with properties \(properties ?? [:])")
                eventStore.track(name: event, properties: properties)
            }
            else if eventCount == eventLimit
            {
                SLogAnalytics("Exceeded event quota for “\(event)”")
                eventStore.track(name: "Exceeded Event Quota", properties: ["Name": event])
            }

            // increase the tracked event count
            eventCounts[event] = (startDate, eventCount + 1)
        })

        // Flush events in background, if necessary. Mixpanel will not do this automatically (they check for active), so
        // it's up to our app code to ensure that notifications actually reach Mixpanel for users that do not actually
        // foreground the app.
        if UIApplication.shared.applicationState == .background
        {
            Preferences.shared.backgroundMixpanelEventCount.modify({ count in
                count += 1

                if count >= AnalyticsService.eventsPerFlushInBackground
                {
                    SLogAnalytics("Flushing events in background")
                    eventStore.flush()
                    count = 0
                }
            })
        }
    }

    func trackError(_ error: NSError)
    {
        track(AnalyticsEvent.applicationError(error: error))
    }

    // MARK: - Limiting Events
    static let eventQuotaInterval: DispatchTimeInterval = .seconds(60 * 60)
    fileprivate static let eventsPerFlushInBackground = 20
    fileprivate let eventCounts = Atomic<[String:(Date, Int)]>([:])

    // MARK: - Notified Events

    /// The number of notified events required to flush `notifiedQueue`.
    fileprivate static let notifiedEventsPerFlush = 5

    /// The randomly generated UUID string sent with each request. This is stored in user defaults, so it will be the
    /// same unless the user reinstalls the application.
    fileprivate static let notifiedUUIDString: String = { () -> String in
        if let string = UserDefaults.standard.string(forKey: "Notified-UUID")
        {
            return string
        }
        else
        {
            let string = UUID().uuidString
            UserDefaults.standard.set(string, forKey: "Notified-UUID")
            return string
        }
    }()

    /// The file path where queued notified events are stored.
    fileprivate static let notifiedFile = FileManager.default.rly_documentsFile(withName: "notified-events.plist")

    /// The current queue of notified events, waiting to go out.
    fileprivate var notifiedQueue = (NSArray(contentsOfFile: AnalyticsService.notifiedFile) as? [[String:AnyObject]]) ?? []
    {
        didSet
        {
            let safe = notifiedQueue.map({ dictionary in
                (dictionary as NSDictionary).rly_dictionaryByRemovingNSNull()
            })

            if !(safe as NSArray).write(toFile: AnalyticsService.notifiedFile, atomically: true)
            {
                SLogAnalytics("Failed to write notified events to file “\(AnalyticsService.notifiedFile)”")
            }
        }
    }

    fileprivate var notifiedDisposable = Disposable?.none

    fileprivate func flushNotifiedEvents()
    {
        // do not proceed if we already have a disposable!
        guard notifiedDisposable == nil else { return }

        // build the JSON body that we will send
        let mobileVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        let events = notifiedQueue

        let dictionary: [String:AnyObject] = [
            "name": 0 as AnyObject,
            "operating_system": 0 as AnyObject,
            "person_id": AnalyticsService.notifiedUUIDString as AnyObject,
            "mobile_version": mobileVersion as AnyObject? ?? NSNull(),
            "events": events as AnyObject
        ]

        notifiedDisposable = notifiedStore.trackNotifiedProducer(parameters: dictionary)
            .observe(on: QueueScheduler.main)
            .on(failed: { error in
                // TODO: keep events for errors that aren't bad?
                SLogAnalytics("Failed to upload notified events: \(error)")
            }, completed: {
                SLogAnalytics("Successfully uploaded \(events.count) notified events")
            }, terminated: { [weak self] in
                // update the notified queue
                guard let strongSelf = self else { return }
                strongSelf.notifiedQueue = Array(strongSelf.notifiedQueue.dropFirst(events.count))

                // remove the disposable, so that we can run this again
                strongSelf.notifiedDisposable = nil
            })
            .start()
    }

    /// The date formatter for notified events.
    fileprivate let notifiedFormatter: DateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()
}

// MARK: - Notified Events

/// A protocol for types that can receive analytics notified events.
protocol AnalyticsNotifiedEventSink
{
    /**
     Tracks a notified event with the specified label.

     - parameter label: The label.
     */
    func trackNotifiedEventWithLabel(_ label: String)
}

extension AnalyticsService: AnalyticsNotifiedEventSink
{
    /**
     Tracks a notified event with the specified label.

     - parameter label: The label.
     */
    func trackNotifiedEventWithLabel(_ label: String)
    {
        let event: [String:AnyObject] = [
            "label": label as AnyObject,
            "application_version": (superPropertyStore.currentSuperProperties()["Firmware Revision"] as? String as AnyObject?) ?? NSNull(),
            "hardware_version": (superPropertyStore.currentSuperProperties()["Hardware Revision"] as? String as AnyObject?) ?? NSNull(),
            "created": notifiedFormatter.string(from: Date()) as AnyObject? ?? NSNull()
        ]

        SLogAnalytics("Adding notified event to queue: \(event)")
        notifiedQueue.append(event)

        if notifiedQueue.count > AnalyticsService.notifiedEventsPerFlush
        {
            flushNotifiedEvents()
        }
    }
}

extension AnalyticsService
{
    func track<Event: AnalyticsEventType>(_ event: Event)
    {
        let properties = event.properties.mapToDictionary({ key, value in
            (key, value.analyticsString)
        })

        track(event: event.name, properties: properties, eventLimit: Event.eventLimit)
    }
}

/// Actions to apply to `Mixpanel` objects when identification changes.
enum AnalyticsIdentifyAction: Equatable
{
    /// No user is authenticated. A random identifier should be used.
    case random

    /// A user has been authenticated, and her identifier should be used.
    case identify(String)

    /// A previous identifier should be linked to the current identifier.
    case alias(identifier: String, alias: String)
}

extension AnalyticsIdentifyAction
{
    /// Yields the actions for moving from one identifier to another.
    ///
    /// - Parameters:
    ///   - previous: The previous identifier.
    ///   - current: The current identifier.
    static func actions(from previous: String?, to current: String?) -> [AnalyticsIdentifyAction]
    {
        if let identifier = current
        {
            if let previousIdentifier = previous, previousIdentifier != identifier
            {
                return [.identify(identifier), .alias(identifier: identifier, alias: previousIdentifier)]
            }
            else
            {
                return [.identify(identifier)]
            }
        }
        else
        {
            return [.random]
        }
    }

    /// Applies the action to the specified `AnalyticsIdentityStore` value.
    ///
    /// - Parameter identityStore: The `AnalyticsIdentityStore` value to apply the action to.
    func apply(to identityStore: AnalyticsIdentityStore)
    {
        switch self
        {
        case .random:
            identityStore.identify(UUID().uuidString)
        case let .identify(identifier):
            identityStore.identify(identifier)
        case let .alias(identifier, alias):
            identityStore.createAlias(alias, forDistinctID: identifier)
        }
    }
}

func ==(lhs: AnalyticsIdentifyAction, rhs: AnalyticsIdentifyAction) -> Bool
{
    switch (lhs, rhs)
    {
    case (.random, .random):
        return true
    case let (.identify(lhsIdentifier), .identify(rhsIdentifier)):
        return lhsIdentifier == rhsIdentifier
    case let (.alias(lhsIdentifier, lhsAlias), .alias(rhsIdentifier, rhsAlias)):
        return lhsIdentifier == rhsIdentifier && lhsAlias == rhsAlias
    default:
        return false
    }
}
