import ReactiveSwift
import Result
import RinglyExtensions
import XCTest

final class SignalProducerErrorRetryOnValueFromTests: XCTestCase
{
    // MARK: - Setup
    fileprivate let fromPipe = Signal<(), NoError>.pipe()
    fileprivate let disposable = SerialDisposable()
    fileprivate var results = [Result<Int, TestError>]()

    override func tearDown()
    {
        disposable.inner = nil
        results = []
    }

    fileprivate func startWithValues(_ values: [Result<Int, TestError>])
    {
        disposable.inner = SignalProducer(values)
            .retryOnValue(from: SignalProducer(fromPipe.0))
            .startWithValues({ self.results.append($0) })
    }

    // MARK: - Cases
    func testNoFailures()
    {
        startWithValues([.success(0), .success(1)])

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0] == .success(0))
        XCTAssertTrue(results[1] == .success(1))
    }

    func testSuccessAfterFailure()
    {
        startWithValues([.success(0), .failure(TestError(value: 1)), .success(2)])

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[0] == .success(0))
        XCTAssertTrue(results[1] == .failure(TestError(value: 1)))
        XCTAssertTrue(results[2] == .success(2))
    }

    func testRetry()
    {
        startWithValues([.success(0), .failure(TestError(value: 1))])
        fromPipe.1.send(value: ())

        XCTAssertEqual(results.count, 4)
        XCTAssertTrue(results[0] == .success(0))
        XCTAssertTrue(results[1] == .failure(TestError(value: 1)))
        XCTAssertTrue(results[2] == .success(0))
        XCTAssertTrue(results[3] == .failure(TestError(value: 1)))
    }

    func testMultipleRetry()
    {
        startWithValues([.success(0), .failure(TestError(value: 1))])
        fromPipe.1.send(value: ())
        fromPipe.1.send(value: ())

        XCTAssertEqual(results.count, 6)
        XCTAssertTrue(results[0] == .success(0))
        XCTAssertTrue(results[1] == .failure(TestError(value: 1)))
        XCTAssertTrue(results[2] == .success(0))
        XCTAssertTrue(results[3] == .failure(TestError(value: 1)))
        XCTAssertTrue(results[4] == .success(0))
        XCTAssertTrue(results[5] == .failure(TestError(value: 1)))
    }
}

// MARK: - Errors
private struct TestError: Error, Equatable
{
    let value: Int
}

private func ==(lhs: TestError, rhs: TestError) -> Bool
{
    return lhs.value == rhs.value
}
