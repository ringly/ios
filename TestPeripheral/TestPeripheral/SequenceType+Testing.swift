import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Sequence where Iterator.Element == TestCase
{
    
    func testResultProducers(central: RLYCentral,
                             peripheral: RLYPeripheral,
                             hardwareVersion: RLYKnownHardwareVersion)
        -> [SignalProducer<(Int, TestResult), NoError>]
    {
        return enumerated().map({ index, testCase in
            SignalProducer { observer, _ in
                do
                {
                    try testCase.run(
                        central: central,
                        peripheral: peripheral,
                        hardwareVersion: hardwareVersion,
                        completion: { result in
                            observer.send(value: (index, result))
                            observer.sendCompleted()
                        }
                    )
                }
                catch let error as NSError
                {
                    observer.send(value: (index, .failure("Threw error \(error)")))
                    observer.sendCompleted()
                }
            }.observe(on: UIScheduler())
        })
    }
}
