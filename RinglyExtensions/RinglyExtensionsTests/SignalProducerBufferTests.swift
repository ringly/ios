import Nimble
import ReactiveSwift
import Result
import RinglyExtensions
import XCTest

final class SignalProducerBufferTests: SignalProducerTimingTestCase
{
    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()

        let (signal, observer) = Signal<Int, NoError>.pipe()
        self.observer = observer

        disposable = SignalProducer(signal)
            .buffer(limit: 3, timeout: .seconds(1), on: scheduler)
            .startWithValues({ self.values.append($0) })
    }

    override func tearDown()
    {
        super.tearDown()
        values = []
        observer = nil
    }

    private var values: [[Int]] = []
    private var observer: Observer<Int, NoError>!

    // MARK: - Test Cases
    func testSendingValuesBelowLimitDoesNotSend()
    {
        observer.send(value: 0)
        expect(self.values).to(equal([]))
    }

    func testSendingValuesAndExpiringLimitSends()
    {
        observer.send(value: 0)
        scheduler.advance(by: .seconds(1))
        expect(self.values).to(equal([[0]]))
    }

    func testSendingValuesMatchingLimitSends()
    {
        observer.send(value: 0)
        observer.send(value: 1)
        observer.send(value: 2)
        expect(self.values).to(equal([[0, 1, 2]]))
    }

    func testSendingValuesPastLimitDoesNotSendAdditional()
    {
        observer.send(value: 0)
        observer.send(value: 1)
        observer.send(value: 2)
        observer.send(value: 3)
        expect(self.values).to(equal([[0, 1, 2]]))
    }
}

// MARK: - Matcher for Nested Arrays
final class NestedArraysEqualMatcherTests: XCTestCase
{
    func testEqualArrays()
    {
        let arrays = [[1, 2], [3], [4, 5, 6]]
        expect(arrays).to(equal(arrays))
    }

    func testDifferentCounts()
    {
        expect([[1, 2], [3], [4, 5, 6]]).toNot(equal([[1, 2], [3]]))
    }

    func testDifferentContents()
    {
        expect([[1, 2], [3], [4, 5, 6]]).toNot(equal([[1, 2], [3], [4, 5, 7]]))
    }
}

func equal<Value>(_ expected: [Value], using equate: @escaping (Value, Value) -> Bool) -> NonNilMatcherFunc<[Value]>
{
    return NonNilMatcherFunc { expression, message in
        message.postfixMessage = "equal \(expected)"
        guard let actual = try expression.evaluate() else { return false }
        return expected.count == actual.count && zip(expected, actual).all(equate)
    }
}

func equal<Value: Equatable>(_ expected: [[Value]]) -> NonNilMatcherFunc<[[Value]]>
{
    return equal(expected, using: ==)
}
