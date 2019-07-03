@testable import RinglyDFU
import XCTest

final class FirmwareFeaturesTests: XCTestCase
{
    // MARK: - Modifies Services
    func testModifiesServicesVersion1()
    {
        XCTAssertFalse(FirmwareFeatures(application: "1.5.3", bootloader: "1.0.0").modifiesServices)
    }

    func testModifiesServicesVersion2Below2()
    {
        XCTAssertTrue(FirmwareFeatures(application: "2.1.1", bootloader: "3.0.0").modifiesServices)
    }

    func testModifiesServicesVersion2Equal2()
    {
        XCTAssertFalse(FirmwareFeatures(application: "2.2.0", bootloader: "3.0.0").modifiesServices)
    }

    func testModifiesServicesVersion2Above2()
    {
        XCTAssertFalse(FirmwareFeatures(application: "2.3.0", bootloader: "3.0.0").modifiesServices)
    }
}
