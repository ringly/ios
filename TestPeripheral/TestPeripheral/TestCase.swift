import RinglyKit

/// Defines the possible results of test cases.
enum TestResult
{
    /// The test succeeded.
    case success

    /// The test failed. A string description of the failure should be provided.
    case failure(String)
}

extension TestResult
{
    /// If the result is a failure, the reason for the failure.
    var failureReason: String?
    {
        guard case let .failure(reason) = self else { return nil }
        return reason
    }
}

/// Defines the interface for concrete test cases.
protocol TestCase
{
    /// The test's title.
    var title: String { get }

    /// `true` if the test can be run on the specified hardware version.
    func supports(_ hardwareVersion: RLYKnownHardwareVersion) -> Bool

    /// Runs the test on `central` and `peripheral`. Call `completion` to terminate the test.
    func run(central: RLYCentral,
             peripheral: RLYPeripheral,
             hardwareVersion: RLYKnownHardwareVersion,
             completion: @escaping (TestResult) -> ()) throws
}
