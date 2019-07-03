import Nimble
import ReactiveSwift
import Result
import RinglyExtensions
import XCTest

final class SignalProducerImmediateTimerTests: SignalProducerTimingTestCase
{
    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()
        disposable = immediateTimer(interval: .seconds(1), on: scheduler).startWithValues({ self.values.append($0) })
    }

    override func tearDown()
    {
        super.tearDown()
        values = []
    }

    private var values: [Date] = []

    // MARK: - Test Cases
    func testImmediatelySendsValue()
    {
        expect(self.values) == [schedulerStartDate]
    }

    func testPassingIntervalSendsValue()
    {
        scheduler.advance(by: .seconds(1))
        expect(self.values) == [schedulerStartDate, schedulerStartDate.addingTimeInterval(1)]
    }

    func testPassingMultipleIntervalSendsMultipleValues()
    {
        scheduler.advance(by: .seconds(2))

        expect(self.values) == [
            schedulerStartDate,
            schedulerStartDate.addingTimeInterval(1),
            schedulerStartDate.addingTimeInterval(2)
        ]
    }
}

final class SignalProducerVariableImmediateTimerTests: SignalProducerTimingTestCase
{
    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()

        let (signal, observer) = Signal<Bool, NoError>.pipe()
        self.observer = observer

        disposable = SignalProducer(signal).variableImmediateTimer(
            trueInterval: .seconds(1),
            falseInterval: .seconds(2),
            on: scheduler
        ).startWithValues({ self.values.append($0) })
    }

    override func tearDown()
    {
        super.tearDown()
        values = []
        observer = nil
    }

    private var values: [Date] = []
    private var observer: Observer<Bool, NoError>!

    // MARK: - Test Cases
    func testNoTimerWithoutValue()
    {
        expect(self.values) == []
    }

    func testSendingTrueImmediatelySendsDate()
    {
        observer.send(value: true)
        expect(self.values) == [schedulerStartDate]
    }

    func testSendingFalseImmediatelySendsDate()
    {
        observer.send(value: false)
        expect(self.values) == [schedulerStartDate]
    }

    func testAdvancingTrueBelowIntervalSendsValue()
    {
        observer.send(value: true)
        scheduler.advance(by: .milliseconds(1))
        expect(self.values) == [schedulerStartDate]
    }

    func testAdvancingFalseBelowIntervalSendsValue()
    {
        observer.send(value: false)
        scheduler.advance(by: .seconds(1))
        expect(self.values) == [schedulerStartDate]
    }

    func testAdvancingTrueToIntervalSendsValue()
    {
        observer.send(value: true)
        scheduler.advance(by: .seconds(1))
        expect(self.values) == [schedulerStartDate, schedulerStartDate.addingTimeInterval(1)]
    }

    func testAdvancingFalseToIntervalSendsValue()
    {
        observer.send(value: false)
        scheduler.advance(by: .seconds(2))
        expect(self.values) == [schedulerStartDate, schedulerStartDate.addingTimeInterval(2)]
    }

    func testAdvancingTrueMultipleTimesSendsValues()
    {
        observer.send(value: true)
        scheduler.advance(by: .seconds(2))
        expect(self.values) == [
            schedulerStartDate,
            schedulerStartDate.addingTimeInterval(1),
            schedulerStartDate.addingTimeInterval(2)
        ]
    }

    func testAdvancingFalseMultipleTimesSendsValues()
    {
        observer.send(value: false)
        scheduler.advance(by: .seconds(4))
        expect(self.values) == [
            schedulerStartDate,
            schedulerStartDate.addingTimeInterval(2),
            schedulerStartDate.addingTimeInterval(4)
        ]
    }

    func testSwitchingInterval()
    {
        observer.send(value: false)
        scheduler.advance(by: .seconds(2))
        observer.send(value: true)
        scheduler.advance(by: .seconds(1))

        expect(self.values) == [
            schedulerStartDate,
            schedulerStartDate.addingTimeInterval(2),
            schedulerStartDate.addingTimeInterval(2),
            schedulerStartDate.addingTimeInterval(3)
        ]
    }
}
