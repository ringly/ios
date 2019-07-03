import RinglyKit

struct ActionTestCase
{
    init(title: String,
         supportsHardwareVersion: @escaping (RLYKnownHardwareVersion) -> Bool = { _ in true },
         run: @escaping (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion, (TestResult) -> ()) throws -> ())
    {
        self.title = title
        self.supportsHardwareVersion = supportsHardwareVersion
        self.run = run
    }

    let title: String
    let supportsHardwareVersion: (RLYKnownHardwareVersion) -> Bool
    let run: (RLYCentral, RLYPeripheral, RLYKnownHardwareVersion, (TestResult) -> ()) throws -> ()
}

extension ActionTestCase: TestCase
{
    func supports(_ hardwareVersion: RLYKnownHardwareVersion) -> Bool
    {
        return supportsHardwareVersion(hardwareVersion)
    }

    func run(central: RLYCentral,
             peripheral: RLYPeripheral,
             hardwareVersion: RLYKnownHardwareVersion,
             completion: @escaping (TestResult) -> ()) throws
    {
        try run(central, peripheral, hardwareVersion, completion)
    }
}
