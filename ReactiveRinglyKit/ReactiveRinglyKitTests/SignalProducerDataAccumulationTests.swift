@testable import ReactiveRinglyKit
import Nimble
import ReactiveSwift
import XCTest
import enum Result.NoError

final class SignalProducerDataAccumulationTests: XCTestCase
{
    fileprivate let firstTestData = Data(base64Encoded: "0000".data(using: String.Encoding.utf8)!, options: [])!
    fileprivate let secondTestData = Data(base64Encoded: "1111".data(using: String.Encoding.utf8)!, options: [])!

    func testEmptyProducerSendsNothing()
    {
        let producer = SignalProducer<Data, NoError>.empty
        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == []
    }

    func testEmptyDataSendsNothing()
    {
        let producer = SignalProducer<Data, NoError>(value: Data())
        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == []
    }

    func testValueWithoutEmptyDataSendsNothing()
    {
        let producer = SignalProducer<Data, NoError>(value: firstTestData)
        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == []
    }

    func testValueWithEmptyDataSendsValue()
    {
        let producer = SignalProducer<Data, NoError>(values: firstTestData, Data())
        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == [firstTestData]
    }

    func testValuesConcatenated()
    {
        let producer = SignalProducer<Data, NoError>(values: firstTestData, secondTestData, Data())

        var expected = Data()
        expected.append(firstTestData)
        expected.append(secondTestData)

        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == [expected]
    }

    func testMultipleValuesSent()
    {
        let producer = SignalProducer<Data, NoError>(values: firstTestData, Data(), secondTestData, Data())
        expect(producer.producerByAccumulatingUntilEmpty.collect().first()?.value) == [firstTestData, secondTestData]
    }

    func testErrorForwarded()
    {
        let error = NSError(domain: "test", code: 0, userInfo: nil)
        let producer = SignalProducer<Data, NSError>(error: error)

        let first = producer.materialize().collect().first()
        expect(first?.value?.first?.error) == error
    }
}
