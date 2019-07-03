@testable import Ringly
import Nimble
import ReactiveSwift
import XCTest

final class AnalyticsServiceSuperPropertyTests: AnalyticsServiceTestCase
{
    func testRegisteringSuperProperty()
    {
        service.setSuperProperties(producer: SignalProducer(value: SuperPropertySetting(key: "test", value: "1")))
        expect(self.stores.superProperty.currentSuperProperties() as? [String:String]) == ["test": "1"]
    }

    func testUnregisteringSuperProperty()
    {
        service.setSuperProperties(producer: SignalProducer([
            SuperPropertySetting(key: "test", value: "1"),
            SuperPropertySetting(key: "test", value: nil)
        ]))

        expect(self.stores.superProperty.currentSuperProperties() as? [String:String]) == [:]
    }

    func testUpdatingSuperProperty()
    {
        service.setSuperProperties(producer: SignalProducer([
            SuperPropertySetting(key: "test", value: "1"),
            SuperPropertySetting(key: "test", value: "2")
        ]))

        expect(self.stores.superProperty.currentSuperProperties() as? [String:String]) == ["test": "2"]
    }
}
