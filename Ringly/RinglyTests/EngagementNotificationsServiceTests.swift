@testable import Ringly
import Nimble
import ReactiveCocoa
import ReactiveSwift
import XCTest

class EngagementNotificationsServiceTestCase: XCTestCase
{
    // MARK: - Service
    private(set) fileprivate var service: EngagementNotificationsService!

    // MARK: - Schedulers
    private(set) fileprivate var dateScheduler: TestScheduler!
    private(set) fileprivate var dateSchedulerStart = Date()
    private(set) fileprivate var notificationScheduler: TestLocalNotificationScheduler!

    // MARK: - State Property
    private(set) fileprivate var state: MutableProperty<EngagementNotificationState>!

    // MARK: - Setup and Teardown
    fileprivate var disposable: Disposable?

    override func setUp()
    {
        super.setUp()

        service = EngagementNotificationsService()
        dateScheduler = TestScheduler(startDate: dateSchedulerStart)
        notificationScheduler = TestLocalNotificationScheduler()
        state = MutableProperty(.unscheduled)

    }

    override func tearDown()
    {
        super.tearDown()

        disposable?.dispose()
        disposable = nil
    }
}

final class EngagementNotificationsServiceInitialPairTests: EngagementNotificationsServiceTestCase
{
    // MARK: - Setup
    private var peripheralCount: MutableProperty<Int>!
    private let dateTimeInterval: TimeInterval = 10

    override func setUp()
    {
        super.setUp()
        peripheralCount = MutableProperty(0)
    }

    private func start()
    {
        disposable = service.reactive.manageInitialPairNotification(
            notification: .addRemoveApplications,
            dateScheduler: dateScheduler,
            determineFireDate: { $0.addingTimeInterval(self.dateTimeInterval) },
            notificationScheduler: notificationScheduler,
            peripheralCountProducer: peripheralCount.producer,
            stepGoalProducer: SignalProducer(value: 10000),
            stateProperty: state
        ).start()
    }

    // MARK: - Test Cases
    func testNotScheduledFor0Peripherals()
    {
        start()
        expect(self.state.value) == EngagementNotificationState.unscheduled
    }

    func testCancelledIfUnscheduledWith1Peripheral()
    {
        peripheralCount.value = 1
        start()
        expect(self.state.value) == EngagementNotificationState.cancelled
    }

    func testNotCancelledIfScheduledWith1Peripheral()
    {
        peripheralCount.value = 1
        state.value = .scheduled
        start()
        expect(self.state.value) == EngagementNotificationState.scheduled
    }

    func testScheduledWhenChangingTo1Peripheral()
    {
        start()
        peripheralCount.value = 1

        expect(self.state.value) == EngagementNotificationState.scheduled
        expect(self.notificationScheduler.scheduledLocalNotifications ?? []) == [
            UILocalNotification(
                engagementNotification: .addRemoveApplications,
                fireDate: dateSchedulerStart.addingTimeInterval(dateTimeInterval)
            )
        ]
    }

    func testCancelledManually()
    {
        start()
        peripheralCount.value = 1
        service.cancel(.addRemoveApplications)

        expect(self.state.value) == EngagementNotificationState.cancelled
        expect(self.notificationScheduler.scheduledLocalNotifications ?? []) == []
    }
}

final class EngagementNotificationsServiceFireDateTests: XCTestCase
{
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    func testFireDateWithinBounds()
    {
        expect(EngagementNotificationsService.notificationFireDate(
            days: 1,
            after: self.calendar.date(year: 2016, month: 1, day: 1, hour: 10),
            in: self.calendar
        )) == calendar.date(year: 2016, month: 1, day: 2, hour: 10)
    }

    func testFireDateOnLowerBound()
    {
        expect(EngagementNotificationsService.notificationFireDate(
            days: 1,
            after: self.calendar.date(year: 2016, month: 1, day: 1, hour: 8),
            in: self.calendar
        )) == calendar.date(year: 2016, month: 1, day: 2, hour: 8)
    }

    func testFireDateOnUpperBound()
    {
        expect(EngagementNotificationsService.notificationFireDate(
            days: 1,
            after: self.calendar.date(year: 2016, month: 1, day: 1, hour: 18),
            in: self.calendar
        )) == calendar.date(year: 2016, month: 1, day: 2, hour: 18)
    }

    func testFireDateBeforeBounds()
    {
        expect(EngagementNotificationsService.notificationFireDate(
            days: 1,
            after: self.calendar.date(year: 2016, month: 1, day: 1, hour: 1),
            in: self.calendar
        )) == calendar.date(year: 2016, month: 1, day: 2, hour: 8)
    }

    func testFireDateAfterBounds()
    {
        expect(EngagementNotificationsService.notificationFireDate(
            days: 1,
            after: self.calendar.date(year: 2016, month: 1, day: 1, hour: 22),
            in: self.calendar
        )) == calendar.date(year: 2016, month: 1, day: 3, hour: 8)
    }
}
