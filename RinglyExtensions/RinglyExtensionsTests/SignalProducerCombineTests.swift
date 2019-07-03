import Nimble
import ReactiveSwift
import RinglyExtensions
import XCTest
import enum Result.NoError

final class SignalProducerCombineTests: XCTestCase
{
    func testSingleValueDoesNotSend()
    {
        let actual = SignalProducer<Int, NoError>([1]).combinePrevious().collect().first()
        expect(actual?.value).to(equal([], using: ==))
    }

    func testTwoValuesSendOnce()
    {
        let actual = SignalProducer<Int, NoError>([1, 2]).combinePrevious().collect().first()
        expect(actual?.value).to(equal([(1, 2)], using: ==))
    }

    func testThreeValuesSendTwice()
    {
        let actual = SignalProducer<Int, NoError>([1, 2, 3]).combinePrevious().collect().first()
        expect(actual?.value).to(equal([(1, 2), (2, 3)], using: ==))
    }
}
