@testable import Ringly
import Nimble
import XCTest

final class AnalyticsServiceEventsTests: AnalyticsServiceTestCase
{
    func testTracksEventWithoutProperties()
    {
        struct Event: AnalyticsEventType
        {
            let name = "test"
        }

        service.track(Event())
        expect(self.stores.event.events) == [.tracked("test", [:])]
    }

    func testTracksEventWithProperties()
    {
        struct Event: AnalyticsEventType
        {
            let name = "test"
            let properties: [String:AnalyticsPropertyValueType] = ["foo": "bar"]
        }

        service.track(Event())
        expect(self.stores.event.events) == [.tracked("test", ["foo": "bar"])]
    }

    func testExceedingEventQuota()
    {
        struct Event: AnalyticsEventType
        {
            let name = "test"
            static let eventLimit = 1
        }

        service.track(Event())
        service.track(Event())
        service.track(Event())

        expect(self.stores.event.events) == [
            .tracked("test", [:]),
            .tracked("Exceeded Event Quota", ["Name": "test"])
        ]
    }

    func testExceedingEventQuotaMultipleEvents()
    {
        struct Event1: AnalyticsEventType
        {
            let name = "test1"
            static let eventLimit = 1
        }

        struct Event2: AnalyticsEventType
        {
            let name = "test2"
            static let eventLimit = 1
        }

        service.track(Event1())
        service.track(Event1())
        service.track(Event2())
        service.track(Event2())

        expect(self.stores.event.events) == [
            .tracked("test1", [:]),
            .tracked("Exceeded Event Quota", ["Name": "test1"]),
            .tracked("test2", [:]),
            .tracked("Exceeded Event Quota", ["Name": "test2"])
        ]
    }

    func testResettingEventQuota()
    {
        struct Event: AnalyticsEventType
        {
            let name = "test"
            static let eventLimit = 1
        }

        service.track(Event())
        scheduler.advance(by: AnalyticsService.eventQuotaInterval)
        service.track(Event())

        expect(self.stores.event.events) == [
            .tracked("test", [:]),
            .tracked("test", [:])
        ]
    }

    func testExceedingPeripheralApplicationErrorEventQuota()
    {
        (0..<6).map({ (index: Int) -> PeripheralApplicationErrorEvent in
            PeripheralApplicationErrorEvent(
                applicationVersion: "\(index)",
                bootloaderVersion: "\(index)",
                hardwareVersion: "\(index)",
                code: index,
                line: index,
                file: "\(index)"
            )
        }).forEach(service.track)

        expect(self.stores.event.events) == (0..<5).map({ (index: Int) -> TestEventStore.Event in
            .tracked("Peripheral Application Error", [
                "ErrorApplicationVersion": "\(index)",
                "ErrorBootloaderVersion": "\(index)",
                "ErrorHardwareVersion": "\(index)",
                "ErrorCode": "\(index)",
                "ErrorLine": "\(index)",
                "ErrorFile": "\(index)"
            ])
        }) + [.tracked("Exceeded Event Quota", ["Name": "Peripheral Application Error"])]
    }
}
