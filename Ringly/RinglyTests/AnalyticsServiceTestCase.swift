@testable import Ringly
import ReactiveSwift
import RinglyAPI
import RinglyExtensions
import XCTest
import enum Result.NoError

class AnalyticsServiceTestCase: XCTestCase
{
    /// The service to use for testing. This is created before each test is run.
    fileprivate(set) var service: AnalyticsService!

    /// A collection of all test stores.
    typealias Stores = (
        event: TestEventStore,
        identity: TestIdentityStore,
        notified: TestNotifiedStore,
        superProperty: TestSuperPropertyStore
    )

    /// The test stores to use for testing. These are created before each test is run.
    fileprivate(set) var stores: Stores!

    /// The test scheduler passed to the analytics service.
    fileprivate(set) var scheduler: TestScheduler!

    /// A backing pipe for the service's `authenticationProducer`.
    fileprivate var authenticationPipe: (Signal<Authentication, NoError>, Observer<Authentication, NoError>)!

    /// Send a value to this observer to trigger the service's `authenticationProducer`.
    var authenticationObserver: Observer<Authentication, NoError>
    {
        return authenticationPipe.1
    }

    override func setUp()
    {
        super.setUp()

        stores = (
            event: TestEventStore(),
            identity: TestIdentityStore(),
            notified: TestNotifiedStore(),
            superProperty: TestSuperPropertyStore()
        )

        scheduler = TestScheduler()
        authenticationPipe = Signal<Authentication, NoError>.pipe()

        service = AnalyticsService(
            authenticationProducer: SignalProducer(authenticationPipe.0),
            dateScheduler: scheduler,
            eventStore: stores.event,
            identityStore: stores.identity,
            notifiedStore: stores.notified,
            superPropertyStore: stores.superProperty
        )
    }

    override func tearDown()
    {
        super.tearDown()
        stores = nil
        authenticationPipe = nil
        service = nil
    }
}

// MARK: - Test Event Store
class TestEventStore: AnalyticsEventStore
{
    enum Event: Equatable
    {
        case tracked(String, [String:String]?)
        case time(String)
        case flush
    }

    fileprivate(set) var events: [Event] = []

    func timeEvent(_ eventName: String)
    {
        events.append(.time(eventName))
    }

    func track(name: String, properties: [String:String]?)
    {
        events.append(.tracked(name, properties))
    }

    func flush()
    {
        events.append(.flush)
    }
}

func ==(lhs: TestEventStore.Event, rhs: TestEventStore.Event) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.tracked(lhsName, lhsOptionalProperties), .tracked(rhsName, rhsOptionalProperties)):
        guard lhsName == rhsName else { return false }

        switch (lhsOptionalProperties, rhsOptionalProperties)
        {
        case let (.some(lhsProperties), .some(rhsProperties)):
            return lhsProperties == rhsProperties
        case (.none, .none):
            return true
        default:
            return false
        }
    case let (.time(lhsTime), .time(rhsTime)):
        return lhsTime == rhsTime
    case (.flush, .flush):
        return true
    default:
        return false
    }
}

// MARK: - Test Identity Store
class TestIdentityStore: AnalyticsIdentityStore
{
    fileprivate(set) var distinctId = "default"

    enum Event: Equatable
    {
        case identify(String)
        case alias(alias: String, distinctID: String)
    }

    fileprivate(set) var events: [Event] = []

    func identify(_ identifier: String)
    {
        distinctId = identifier
        events.append(.identify(identifier))
    }

    func createAlias(_ alias: String, forDistinctID: String)
    {
        events.append(.alias(alias: alias, distinctID: forDistinctID))
    }
}

func ==(lhs: TestIdentityStore.Event, rhs: TestIdentityStore.Event) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.identify(lhsIdentifier), .identify(rhsIdentifier)):
        return lhsIdentifier == rhsIdentifier
    case let (.alias(lhsParams), .alias(rhsParams)):
        return lhsParams == rhsParams
    default:
        return false
    }
}

// MARK: - Test Notified Store
class TestNotifiedStore: AnalyticsNotifiedStore
{
    var succeed = true

    func trackNotifiedProducer(parameters: [String : AnyObject]) -> SignalProducer<(), NSError>
    {
        return succeed
            ? SignalProducer.empty
            : SignalProducer(error: NSError(domain: "Test", code: 0, userInfo: nil))
    }
}

// MARK: - Test Super Property Store
class TestSuperPropertyStore: AnalyticsSuperPropertyStore
{
    fileprivate var properties: [AnyHashable: Any] = [:]

    func currentSuperProperties() -> [AnyHashable: Any]
    {
        return properties
    }

    func registerSuperProperties(_ properties: [AnyHashable: Any])
    {
        properties.forEach({ key, value in self.properties[key] = value })
    }

    func unregisterSuperProperty(_ propertyName: String)
    {
        properties.removeValue(forKey: propertyName)
    }
}
