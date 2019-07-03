@testable import RinglyExtensions
import Nimble
import ReactiveSwift
import XCTest
import enum Result.NoError

extension Signal
{
    fileprivate typealias Pipe = (Signal<Value, Error>, ReactiveSwift.Observer<Value, Error>)
}

final class SignalProducerHoldTests: XCTestCase
{
    // MARK: - Setup
    fileprivate var sent: [Int] = []
    fileprivate var pipes: (value: Signal<Int, NoError>.Pipe, after: Signal<(), NoError>.Pipe, until: Signal<(), NoError>.Pipe)!
    fileprivate var producer: SignalProducer<Int, NoError>!
    fileprivate var disposable = Disposable?.none

    override func setUp()
    {
        super.setUp()

        pipes = (value: Signal.pipe(), after: Signal.pipe(), until: Signal.pipe())

        producer = SignalProducer(pipes.value.0).hold(
            after: SignalProducer(pipes.after.0),
            until: SignalProducer(pipes.until.0)
        )

        sent = []
        disposable = producer.startWithValues({ self.sent.append($0) })
    }

    override func tearDown()
    {
        super.tearDown()
        disposable?.dispose()
    }

    // MARK: - Tests
    func testNoHold()
    {
        XCTAssertEqual(sent, [])

        pipes.value.1.send(value: 0)
        XCTAssertEqual(sent, [0])
    }

    func testHold()
    {
        pipes.after.1.send(value: ())
        pipes.value.1.send(value: 0)
        XCTAssertEqual(sent, [])

        pipes.until.1.send(value: ())
        XCTAssertEqual(sent, [0])
    }

    func testHoldDrop()
    {
        pipes.after.1.send(value: ())
        pipes.value.1.send(value: 0)
        pipes.value.1.send(value: 1)
        XCTAssertEqual(sent, [])

        pipes.until.1.send(value: ())
        XCTAssertEqual(sent, [1])
    }
}

final class SignalProducerNotificationHoldTests: XCTestCase
{
    class Context
    {
        init(initialHold: Bool)
        {
            disposable = SignalProducer(pipe.0).holdNotification(
                initial: { initialHold },
                after: after,
                until: until,
                from: center,
                object: object
            ).startWithValues({ [weak self] in self?.sent.append($0) })
        }

        deinit { disposable?.dispose() }

        let pipe = Signal<Int, NoError>.pipe()
        var disposable: Disposable?

        let after = NSNotification.Name("after")
        let until = NSNotification.Name("until")

        let center = NotificationCenter()
        let object: AnyObject? = "test" as AnyObject?

        var sent: [Int] = []
    }

    func testInitialHoldReleased()
    {
        let context = Context(initialHold: true)
        context.pipe.1.send(value: 0)
        context.center.post(name: context.until, object: context.object)
        expect(context.sent) == [0]
    }

    func testNotReleasedWithWrongObject()
    {
        let context = Context(initialHold: true)
        context.pipe.1.send(value: 0)
        context.center.post(name: context.until, object: nil)
        expect(context.sent) == []
    }

    func testNotReleasedWithWrongNotification()
    {
        let context = Context(initialHold: true)
        context.pipe.1.send(value: 0)
        context.center.post(name: Notification.Name("wrong"), object: context.object)
        expect(context.sent) == []
    }

    func testHeldAfterNotification()
    {
        let context = Context(initialHold: false)
        context.center.post(name: context.after, object: context.object)
        context.pipe.1.send(value: 1)
        expect(context.sent) == []
    }

    func testNotHeldAfterWrongNotification()
    {
        let context = Context(initialHold: false)
        context.center.post(name: Notification.Name("wrong"), object: context.object)
        context.pipe.1.send(value: 1)
        expect(context.sent) == [1]
    }

    func testNotHeldAfterWrongObject()
    {
        let context = Context(initialHold: false)
        context.center.post(name: context.after, object: nil)
        context.pipe.1.send(value: 1)
        expect(context.sent) == [1]
    }

    func testReleasedAfterNotification()
    {
        let context = Context(initialHold: false)
        context.center.post(name: context.after, object: context.object)
        context.pipe.1.send(value: 1)
        context.center.post(name: context.until, object: context.object)
        expect(context.sent) == [1]
    }

    func testOnlyLatestReleasedAfterNotification()
    {
        let context = Context(initialHold: false)
        context.center.post(name: context.after, object: context.object)
        context.pipe.1.send(value: 1)
        context.pipe.1.send(value: 2)
        context.center.post(name: context.until, object: context.object)
        expect(context.sent) == [2]
    }

    func testSentWithoutInitialHold()
    {
        let context = Context(initialHold: false)
        context.pipe.1.send(value: 1)
        expect(context.sent) == [1]
    }
}

final class SignalProducerInitialHoldTests: XCTestCase
{
    func testInitialHold()
    {
        let value = SignalProducer<Int, NoError>(value: 0)
        let after = SignalProducer<(), NoError>(value: ())
        let until = SignalProducer<(), NoError>.never

        var sent = [Int]()

        let disposable = value.hold(initial: { true }, after: after, until: until).startWithValues({
            sent.append($0)
        })

        XCTAssertEqual(sent, [])

        disposable.dispose()
    }
}

final class SignalProducerDeferHoldTests: XCTestCase
{
    func testInitialHold()
    {
        let until = Signal<(), NoError>.pipe()
        let value = SignalProducer<Int, NoError>(values: 0, 1)
        var sent = [Int]()

        let disposable = value.deferHold(
            initial: { true },
            after: SignalProducer.never,
            until: SignalProducer(until.0)
        ).startWithValues({ sent.append($0) })

        XCTAssertEqual(sent, [])

        until.1.send(value: ())
        XCTAssertEqual(sent, [0, 1])

        disposable.dispose()
    }
}
