import ReactiveSwift
import RinglyKit

struct ReadFlashTestCase
{
    // MARK: - Initialization

    /// Initializes a read flash test case.
    ///
    /// - Parameters:
    ///   - title: The title of the test case.
    ///   - delay: The amount of time to wait before reading the data.
    ///   - timeout: The amount of time to wait after reading before failing the test due to timeout.
    ///   - versions: For each hardware version, the length and address of the data to read, and the expected result.
    ///   - setup: A function to set up the test.
    init(title: String,
         delay: DispatchTimeInterval = defaultDelay,
         timeout: TimeInterval = defaultTimeout,
         versions: [RLYKnownHardwareVersion:Expectation],
         setup: @escaping (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion) throws -> ())
    {
        self.title = title
        self.delay = delay
        self.timeout = timeout
        self.versions = versions
        self.setup = setup
    }

    /// Describes the expected results for a test, for a specific hardware version.
    struct Expectation
    {
        /// The length of the expected data.
        let length: UInt16

        /// The address to read on the peripheral.
        let address: UInt32

        /// The expected data.
        let data: Data
    }

    // MARK: - Properties

    /// The title of the test cases.
    let title: String

    /// The amount of time to wait before reading the data.
    let delay: DispatchTimeInterval

    /// The amount of time to wait after reading before failing the test due to timeout.
    let timeout: TimeInterval

    /// For each hardware version, the length and address of the data to read, and the expected result.
    let versions: [RLYKnownHardwareVersion:Expectation]

    /// A function to set up the test.
    let setup: (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion) throws -> ()
}

extension ReadFlashTestCase
{
    // MARK: - Command Test Cases

    /// Initializes a read flash test case that will write a single command prior to reading the flash data.
    ///
    /// - Parameters:
    ///   - title: The title of the test case.
    ///   - delay: The amount of time to wait before reading the data.
    ///   - timeout: The amount of time to wait after reading before failing the test due to timeout.
    ///   - versions: For each hardware version, the length and address of the data to read, and the expected result.
    ///   - command: The command to write.
    init(title: String,
         delay: DispatchTimeInterval = defaultDelay,
         timeout: TimeInterval = defaultTimeout,
         versions: [RLYKnownHardwareVersion:Expectation],
         command: RLYCommand)
    {
        self.init(title: title, delay: delay, timeout: timeout, versions: versions, commands: [command])
    }

    /// Initializes a read flash test case that will write multiple commands prior to reading the flash data.
    ///
    /// - Parameters:
    ///   - title: The title of the test case.
    ///   - delay: The amount of time to wait before reading the data.
    ///   - timeout: The amount of time to wait after reading before failing the test due to timeout.
    ///   - versions: For each hardware version, the length and address of the data to read, and the expected result.
    ///   - commands: The commands to write.
    init(title: String,
         delay: DispatchTimeInterval = defaultDelay,
         timeout: TimeInterval = defaultTimeout,
         versions: [RLYKnownHardwareVersion:Expectation],
         commands: [RLYCommand])
    {
        self.init(title: title, delay: delay, timeout: timeout, versions: versions, setup: { _, peripheral, _ in
            commands.forEach(peripheral.write)
        })
    }
}

extension ReadFlashTestCase: TestCase
{
    func supports(_ hardwareVersion: RLYKnownHardwareVersion) -> Bool
    {
        return versions[hardwareVersion] != nil
    }

    func run(central: RLYCentral,
             peripheral: RLYPeripheral,
             hardwareVersion: RLYKnownHardwareVersion,
             completion: @escaping (TestResult) -> ()) throws
    {
        try setup(central, peripheral, hardwareVersion)

        let expectation = versions[hardwareVersion]!

        let readFlashProducer = SignalProducer<Data, ReadFlashError> { observer, disposable in
            disposable += peripheral.reactive.accumulatedFlashLog.promoteErrors(ReadFlashError.self)
                .take(first: 1)
                .start(observer)

            do
            {
                try peripheral.readFlashLog(length: expectation.length, address: expectation.address)
            }
            catch let error as NSError
            {
                observer.send(error: .error(error))
            }
        }.timeout(after: timeout, raising: .timeout(timeout), on: QueueScheduler.main)

        timer(interval: delay, on: QueueScheduler.main).take(first: 1)
            .promoteErrors(ReadFlashError.self)
            .then(readFlashProducer)
            .startWithResult({ result in
                switch result
                {
                case let .success(data):
                    if data == expectation.data
                    {
                        completion(.success)
                    }
                    else
                    {
                        completion(.failure("expected “\(expectation.data)”, read \(data)"))
                    }

                case let .failure(error):
                    completion(.failure("\(error)"))
                }
            })
    }
}

private enum ReadFlashError: Error
{
    case error(NSError)
    case timeout(TimeInterval)
}

extension ReadFlashError: CustomStringConvertible
{
    fileprivate var description: String
    {
        switch self
        {
        case let .error(error):
            return "\(error)"
        case let .timeout(interval):
            return "timeout after \(interval) seconds"
        }
    }
}

private let defaultDelay: DispatchTimeInterval = .seconds(1)
private let defaultTimeout: TimeInterval = 10
