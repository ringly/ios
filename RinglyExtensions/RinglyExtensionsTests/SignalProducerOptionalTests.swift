import ReactiveSwift
import Result
import RinglyExtensions
import XCTest

final class SignalProducerOptionalTests: XCTestCase
{
    var disposable: CompositeDisposable!

    override func setUp()
    {
        super.setUp()
        disposable = CompositeDisposable()
    }

    override func tearDown()
    {
        disposable.dispose()
    }

    func testCollectingCombineWith()
    {
        // create signal pipes for test
        let (optionalSignal, optionalObserver) = Signal<Int?, NoError>.pipe()
        let (combineSignal, combineObserver) = Signal<String, NoError>.pipe()

        var results = [(Int, String)]()

        disposable += SignalProducer(optionalSignal)
            .collectingCombine(with: SignalProducer(combineSignal))
            .startWithValues({ integer, string in
                results.append((integer, string))
            })

        // assume empty to start
        XCTAssertEqual(results.count, 0)

        // send to combine observer, no yield
        combineObserver.send(value: "a")
        XCTAssertEqual(results.count, 0)

        combineObserver.send(value: "b")
        XCTAssertEqual(results.count, 0)

        // send to optional observer, yield
        optionalObserver.send(value: 1)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0] == (1, "a"))
        XCTAssertTrue(results[1] == (1, "b"))

        // send another string
        combineObserver.send(value: "c")

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[2] == (1, "c"))

        // revert to nil
        optionalObserver.send(value: nil)
        XCTAssertEqual(results.count, 3)

        combineObserver.send(value: "d")
        XCTAssertEqual(results.count, 3)

        // back to an integer
        optionalObserver.send(value: 2)

        XCTAssertEqual(results.count, 4)
        XCTAssertTrue(results[3] == (2, "d"))
    }
}
