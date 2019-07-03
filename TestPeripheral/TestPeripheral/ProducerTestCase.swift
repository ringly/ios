import ReactiveSwift
import RinglyKit
import enum Result.NoError

struct ProducerTestCase
{
    init(title: String,
         supportedHardwareVersions: Set<RLYKnownHardwareVersion>,
         timeout: TimeInterval = 10,
         producer: @escaping (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion) throws -> SignalProducer<TestResult, NoError>)
    {
        self.title = title
        self.supportedHardwareVersions = supportedHardwareVersions
        self.timeout = timeout
        self.producer = producer
    }

    let title: String
    let supportedHardwareVersions: Set<RLYKnownHardwareVersion>
    let timeout: TimeInterval
    let producer: (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion) throws -> SignalProducer<TestResult, NoError>
}

extension ProducerTestCase: TestCase
{
    func supports(_ hardwareVersion: RLYKnownHardwareVersion) -> Bool
    {
        return supportedHardwareVersions.contains(hardwareVersion)
    }

    func run(central: RLYCentral,
             peripheral: RLYPeripheral,
             hardwareVersion: RLYKnownHardwareVersion,
             completion: @escaping (TestResult) -> ()) throws
    {
        struct Timeout: Error {}
        let timeout = self.timeout

        try producer(central, peripheral, hardwareVersion)
            .promoteErrors(Timeout.self)
            .timeout(after: timeout, raising: Timeout(), on: QueueScheduler.main)
            .flatMapError({ _ in
                SignalProducer<TestResult, NoError>(value: .failure("Timeout after \(timeout) seconds"))
            })
            .startWithValues(completion)
    }
}
