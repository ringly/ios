@testable import Ringly
import Nimble
import ReactiveSwift
import RinglyActivityTracking
import XCTest

final class ActivityNotificationsServiceTests: XCTestCase
{
    // MARK: - Setup
    override func setUp()
    {
        super.setUp()

        notifications = []

        service = ActivityNotificationsService(
            state: ActivityNotificationsState.empty,
            reminderState: ActivityReminderNotificationsState.empty,
            localNotificationScheduler: TestLocalNotificationScheduler(),
            sendNotification: sendNotification
        )

        service.stepsGoal.value = 10000
    }

    fileprivate var service: ActivityNotificationsService!
    fileprivate var notifications: [ActivityNotification] = []

    func sendNotification(_ notification: ActivityNotification) -> Bool
    {
        notifications.append(notification)
        return true
    }

    // MARK: - Met Goal Notifications
    func testMetGoalNotificationSent()
    {
        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 2),
                steps: Steps(walkingStepCount: 5000, runningStepCount: 0)
            )
        )

        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 2),
                steps: Steps(walkingStepCount: 11000, runningStepCount: 0)
            )
        )

        XCTAssertEqual(notifications, [.metGoal(steps: 11000)])
    }

    func testMetGoalNotificationSentOnlyOnce()
    {
        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 2),
                steps: Steps(walkingStepCount: 11000, runningStepCount: 0)
            )
        )

        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 2),
                steps: Steps(walkingStepCount: 12000, runningStepCount: 0)
            )
        )

        XCTAssertEqual(notifications, [.metGoal(steps: 11000)])
    }

    func testMetGoalNotificationSentForNextDay()
    {
        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 2),
                steps: Steps(walkingStepCount: 11000, runningStepCount: 0)
            )
        )

        service.updateState(
            calendar: Calendar.current,
            currentDate: Date(),
            currentDateSteps: DateSteps(
                components: DateComponents(year: 2016, month: 10, day: 3),
                steps: Steps(walkingStepCount: 12000, runningStepCount: 0)
            )
        )

        XCTAssertEqual(notifications, [.metGoal(steps: 11000), .metGoal(steps: 12000)])
    }

    // MARK: - State Storage
    func testStateCodingWithDateSteps()
    {
        let state = ActivityNotificationsState(
            current: DateSteps(
                components: DateComponents(year: 2016, month: 1, day: 1, hour: 1),
                steps: Steps(walkingStepCount: 11000, runningStepCount: 0)
            ),
            sentMetGoalToday: true,
            sentMetPartGoalToday: true
        )

        expect(try ActivityNotificationsState.decode(state.encoded)) == state
    }

    func testStateCodingWithNilDateSteps()
    {
        let state = ActivityNotificationsState(current: nil, sentMetGoalToday: true, sentMetPartGoalToday: true)
        expect(try ActivityNotificationsState.decode(state.encoded)) == state
    }
}

// MARK: - Utilities
extension DateComponents
{
    init(year: Int, month: Int, day: Int, hour: Int = 0)
    {
        self.init()

        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }
}

extension Calendar
{
    func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date
    {
        return self.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
