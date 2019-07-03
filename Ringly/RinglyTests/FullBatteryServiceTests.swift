@testable import Ringly
import ReactiveSwift
import Result
import XCTest

// MARK: - Data Source Type
private struct DataSource
{
    let charge = MutableProperty(Int?.none)
    let state = MutableProperty(RLYPeripheralBatteryState?.none)
}

extension DataSource: BatteryServiceDataSource
{
    var batteryChargeProducer: SignalProducer<Int?, NoError> { return charge.producer }
    var batteryStateProducer: SignalProducer<RLYPeripheralBatteryState?, NoError> { return state.producer }
}

// MARK: - State Source Type
private struct StateSource: BatteryServiceStateSource
{
    let lowBatterySentIdentifiers = MutableProperty(Set<UUID>())
    let fullBatterySentIdentifiers = MutableProperty(Set<UUID>())
    let chargeBatterySentIdentifiers = MutableProperty(Set<UUID>())
    let chargeNotificationState = MutableProperty(ChargeNotificationState.unscheduled)
    let batteryAlertsEnabled = MutableProperty(true)
}

class FullBatteryServiceTests: XCTestCase
{
    // MARK: - Properties
    fileprivate var dataSource: DataSource!
    fileprivate var stateSource: StateSource!
    fileprivate var disposable: Disposable?
    
    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()
        
        dataSource = DataSource()
        stateSource = StateSource()
        
        // check initial state
        XCTAssertNil(dataSource.charge.value)
        XCTAssertNil(dataSource.state.value)
        XCTAssertEqual(stateSource.fullBatterySentIdentifiers.value.count, 0)
    }
    
    override func tearDown()
    {
        super.tearDown()
        
        disposable?.dispose()
        disposable = nil
        dataSource = nil
        stateSource = nil
    }
    
    // MARK: - Test Cases
    func testBatteryRiseAndFall()
    {
        // create full battery service
        var sentCount = 0
        
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
        ).start()
        
        XCTAssertEqual(sentCount, 0)
        
        // set to high battery
        dataSource.state.value = .notCharging
        dataSource.charge.value = 60
        XCTAssertEqual(sentCount, 0)
        
        // set to low battery
        dataSource.charge.value = 5
        XCTAssertEqual(sentCount, 0)
        
        // set to full battery
        dataSource.state.value = .charging
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 0)
        
        // set to full, charged battery
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 1)
        
        // set to lower battery
        dataSource.state.value = .charging
        dataSource.charge.value = 80
        XCTAssertEqual(sentCount, 1)
        
        // set to full battery, but shouldn't send, since hasn't dipped low enough
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 1)
        
        // set to lower battery again
        dataSource.charge.value = 60
        XCTAssertEqual(sentCount, 1)
        
        // set to full battery again, should send now
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 2)
    }
    
    func testStateUnknown()
    {
        // create full battery service
        var sentCount = 0
        
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        XCTAssertEqual(sentCount, 0)
        
        // set to high battery, but no state
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 0)
        
        // set to low battery, no state
        dataSource.charge.value = 5
        XCTAssertEqual(sentCount, 0)
    }
    
    func testStateCharging()
    {
        // create Full battery service
        var sentCount = 0
        
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        XCTAssertEqual(sentCount, 0)
        
        // set to high battery, with state charging
        dataSource.state.value = .charging
        dataSource.charge.value = 90
        XCTAssertEqual(sentCount, 0)
        
        // set to full battery
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 0)
        
        // set to full battery, with state charged
        dataSource.state.value = .charged
        XCTAssertEqual(sentCount, 1)
    }
    
    func testInitialSend()
    {
        // set initial state to full battery
        dataSource.state.value = .notCharging
        dataSource.charge.value = 100
        
        // create full battery service
        var sentCount = 0
        
        let peripheralIdentifier = UUID()
        
        // should not send, conditions not met
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        XCTAssertEqual(sentCount, 0)
    }
    
    func testDisabled()
    {
        // create full battery service
        var sentCount = 0
        
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        XCTAssertEqual(sentCount, 0)
        
        // disable full battery notifications
        stateSource.batteryAlertsEnabled.value = false
        XCTAssertEqual(sentCount, 0)
        
        // set to full battery
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        XCTAssertEqual(sentCount, 0)
    }

    
    func testSendAt1After0()
    {
        var sentCount = 0
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        dataSource.charge.value = 97
        dataSource.charge.value = 100
        
        XCTAssertEqual(sentCount, 1)
    }
    
    func testFullButCharging()
    {
        var sentCount = 0
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            activatedProducer: SignalProducer(value: true),
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        dataSource.state.value = .charging
        dataSource.charge.value = 100
        
        XCTAssertEqual(sentCount, 0)
    }
    
    func testNotActivated()
    {
        var sentCount = 0
        let peripheralIdentifier = UUID()
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            activatedProducer: SignalProducer(value: false),
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        
        XCTAssertEqual(sentCount, 0)
    }
    
    func testDoNotSendAfterActivation()
    {
        var sentCount = 0
        let peripheralIdentifier = UUID()
        let activated = MutableProperty(false)
        
        disposable = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier,
            dataSource: dataSource,
            stateSource: stateSource,
            activatedProducer: activated.producer,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCount += 1 }
            ).start()
        
        dataSource.state.value = .charged
        dataSource.charge.value = 100
        activated.value = true
        
        XCTAssertEqual(sentCount, 0)
    }
    
}

class MultiPeripheralFullBatteryTests: XCTestCase
{
    // MARK: - Identifiers
    fileprivate let peripheralIdentifier1 = UUID()
    fileprivate let peripheralIdentifier2 = UUID()
    
    // MARK: - Properties
    fileprivate var stateSource: StateSource!
    
    fileprivate var dataSource1: DataSource!
    fileprivate var disposable1: Disposable?
    
    fileprivate var dataSource2: DataSource!
    fileprivate var disposable2: Disposable?
    
    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()
        
        dataSource1 = DataSource()
        dataSource2 = DataSource()
        stateSource = StateSource()
        
        // check initial state
        XCTAssertNil(dataSource1.charge.value)
        XCTAssertNil(dataSource1.state.value)
        XCTAssertNil(dataSource2.charge.value)
        XCTAssertNil(dataSource2.state.value)
        XCTAssertEqual(stateSource.fullBatterySentIdentifiers.value.count, 0)
    }
    
    override func tearDown()
    {
        super.tearDown()
        
        disposable1?.dispose()
        disposable2?.dispose()
        disposable1 = nil
        disposable2 = nil
        dataSource1 = nil
        dataSource2 = nil
        stateSource = nil
    }
    
    // MARK: - Test Cases
    func testMultiPeripheral()
    {
        // create Full battery services
        var sentCounts = (0, 0)
        
        disposable1 = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier1,
            dataSource: dataSource1,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCounts.0 += 1 }
            ).start()
        
        disposable2 = RLYPeripheral.sendFullBatteryNotifications(
            peripheralIdentifier: peripheralIdentifier2,
            dataSource: dataSource2,
            stateSource: stateSource,
            sendAt: 100,
            sendAgainAt: 75,
            send: { _ in sentCounts.1 += 1 }
            ).start()
        
        XCTAssertEqual(sentCounts.0, 0)
        XCTAssertEqual(sentCounts.1, 0)
        
        // set to full battery
        dataSource1.state.value = .notCharging
        dataSource1.charge.value = 60
        
        dataSource2.state.value = .notCharging
        dataSource2.charge.value = 60
        
        XCTAssertEqual(sentCounts.0, 0)
        XCTAssertEqual(sentCounts.1, 0)
        
        // set first to full battery
        dataSource1.state.value = .charged
        dataSource1.charge.value = 100
        XCTAssertEqual(sentCounts.0, 1)
        XCTAssertEqual(sentCounts.1, 0)
        XCTAssertTrue(stateSource.fullBatterySentIdentifiers.value == Set([peripheralIdentifier1]))
        
        // set second to full battery, charging state
        dataSource2.state.value = .charging
        dataSource2.charge.value = 100
        XCTAssertEqual(sentCounts.0, 1)
        XCTAssertEqual(sentCounts.1, 0)
        XCTAssertTrue(stateSource.fullBatterySentIdentifiers.value == Set([peripheralIdentifier1, peripheralIdentifier2]))
        
        // set second to full, charged battery to allow a notification
        dataSource1.charge.value = 25
        dataSource2.state.value = .charged
        XCTAssertEqual(sentCounts.0, 1)
        XCTAssertEqual(sentCounts.1, 1)
        XCTAssertTrue(stateSource.fullBatterySentIdentifiers.value == Set([peripheralIdentifier2]))
        
        // set first to full battery again
        dataSource1.charge.value = 100
        XCTAssertEqual(sentCounts.0, 2)
        XCTAssertEqual(sentCounts.1, 1)
        XCTAssertTrue(stateSource.fullBatterySentIdentifiers.value == Set([peripheralIdentifier1, peripheralIdentifier2]))
    }
}
