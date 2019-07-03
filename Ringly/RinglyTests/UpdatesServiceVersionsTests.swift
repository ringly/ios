@testable import Ringly
import Nimble
import XCTest

final class UpdatesServiceVersionsTests: XCTestCase
{
    func testImplied0_0_26()
    {
        expect(UpdatesServiceVersions.with(application: "1.2.0", hardware: "V00", bootloader: nil))
            == UpdatesServiceVersions(application: "1.2.0", hardware: "V00", bootloader: "0.0.26")
    }

    func testImplied1_0_0()
    {
        expect(UpdatesServiceVersions.with(application: "1.3.0", hardware: "V00", bootloader: nil))
            == UpdatesServiceVersions(application: "1.3.0", hardware: "V00", bootloader: "1.0.0")
    }

    func testFailsImplied1_1_0()
    {
        expect(UpdatesServiceVersions.with(application: "1.4.0", hardware: "V00", bootloader: nil)).to(beNil())
    }

    func testExplicitVersions()
    {
        expect(UpdatesServiceVersions.with(application: "1.4.0", hardware: "V00", bootloader: "1.1.0"))
            == UpdatesServiceVersions(application: "1.4.0", hardware: "V00", bootloader: "1.1.0")
    }
}
