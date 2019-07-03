import Foundation
import RinglyKit

let allTestCases: [TestCase] = [
    ActionTestCase(title: "Always Passes", run: { _, _, _, completion in completion(.success) }),
    
    ReadFlashTestCase(
        title: "Enable Sleep Mode",
        versions: [
            .version2: ReadFlashTestCase.Expectation(
                length: 1,
                address: 0x0003B400,
                data: Data(bytes: [10], count:1)
            )
        ],
        command: RLYSleepModeCommand(sleepTime: 10)
    ),
    
    ReadFlashTestCase(
        title: "Enable Connection Taps",
        versions: [
            .version2: ReadFlashTestCase.Expectation(
                length: 1,
                address: 0x0003B408,
                data: Data(bytes: [1], count:1)
            )
        ],
        command: RLYConnectionLEDCommand(enabled: true)
    )
]
