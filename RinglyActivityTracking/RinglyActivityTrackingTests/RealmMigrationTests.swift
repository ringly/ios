@testable import RinglyActivityTracking
import Nimble
import RealmSwift
import XCTest

final class RealmMigrationTests: XCTestCase
{
    // MARK: - Setup
    private var remove: [URL] = []

    override func tearDown()
    {
        super.tearDown()
        try! remove.forEach(FileManager.default.removeItem)
        remove = []
    }

    // MARK: - Initializing Unmigrated Databases
    private func migrationResults(fileName: String) -> Results<UpdateModel>
    {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("realmmigrationtests-\(arc4random())")

        remove.append(temporaryDirectory)

        let realmFile = temporaryDirectory.appendingPathComponent("test.realm")

        try! FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        try! FileManager.default.copyItem(
            at: Bundle(for: RealmMigrationTests.self).url(forResource: fileName, withExtension: "realm")!,
            to: realmFile
        )

        let configuration = RealmService.configuration(fileURL: realmFile, logFunction: nil)
        let realm = try! Realm(configuration: configuration)
        return realm.objects(UpdateModel.self)
    }

    // MARK: - Test Cases
    func testMigrationFromVersion2AddsIdentifiers()
    {
        let results = migrationResults(fileName: "Version2").sorted(byKeyPath: "timestamp", ascending: true)

        expect(results[0]).to(have(
            identifier: UpdateModel.identifier(timestamp: 10, macAddress: 10),
            timestamp: 10,
            macAddress: 10,
            walking: 10,
            running: 10
        ))

        expect(results[1]).to(have(
            identifier: UpdateModel.identifier(timestamp: 11, macAddress: 10),
            timestamp: 11,
            macAddress: 10,
            walking: 11,
            running: 11
        ))

        expect(results[2]).to(have(
            identifier: UpdateModel.identifier(timestamp: 12, macAddress: 10),
            timestamp: 12,
            macAddress: 10,
            walking: 12,
            running: 12
        ))
    }

    func testMigrationFromVersion3UpdatesIdentifiers()
    {
        let results = migrationResults(fileName: "Version3").sorted(byKeyPath: "timestamp", ascending: true)

        expect(results[0]).to(have(
            identifier: UpdateModel.identifier(timestamp: 10, macAddress: 10),
            timestamp: 10,
            macAddress: 10,
            walking: 10,
            running: 10
        ))

        expect(results[1]).to(have(
            identifier: UpdateModel.identifier(timestamp: 11, macAddress: 10),
            timestamp: 11,
            macAddress: 10,
            walking: 11,
            running: 11
        ))

        expect(results[2]).to(have(
            identifier: UpdateModel.identifier(timestamp: 12, macAddress: 10),
            timestamp: 12,
            macAddress: 10,
            walking: 12,
            running: 12
        ))
    }

    func testMigrationFromVersion2HasSameResultsAsVersion3()
    {
        let version2 = migrationResults(fileName: "Version2").sorted(byKeyPath: "timestamp", ascending: true)
        let version3 = migrationResults(fileName: "Version3").sorted(byKeyPath: "timestamp", ascending: true)

        expect(version2).to(equal(version3))
    }
}

private func equal(_ expected: Results<UpdateModel>) -> NonNilMatcherFunc<Results<UpdateModel>>
{
    return NonNilMatcherFunc { expression, message in
        guard let actual = try expression.evaluate() else { return false }
        guard actual.count == expected.count else { return false }

        for (actualModel, expectedModel) in zip(actual, expected)
        {
            guard
                actualModel.identifier == expectedModel.identifier,
                actualModel.timestamp == expectedModel.timestamp,
                actualModel.macAddress == expectedModel.macAddress,
                actualModel.walkingSteps == expectedModel.walkingSteps,
                actualModel.runningSteps == expectedModel.runningSteps
            else { return false }
        }

        return true
    }
}

private func have(identifier: Int64, timestamp: Int32, macAddress: Int64, walking: UInt8, running: UInt8)
    -> NonNilMatcherFunc<UpdateModel>
{
    return NonNilMatcherFunc { expression, message in
        guard let actual = try expression.evaluate() else { return false }

        let requirements = [
            ("identifier", AnyHashable(actual.identifier), AnyHashable(identifier)),
            ("timestamp", AnyHashable(actual.timestamp), AnyHashable(timestamp)),
            ("macAddress", AnyHashable(actual.macAddress), AnyHashable(macAddress)),
            ("walkingSteps", AnyHashable(actual.walkingSteps), AnyHashable(walking)),
            ("runningSteps", AnyHashable(actual.runningSteps), AnyHashable(running)),
        ]

        for (name, actual, expected) in requirements
        {
            if actual != expected
            {
                message.postfixMessage = "have \(name) \(expected)"
                message.actualValue = "\(actual)"
                return false
            }
        }

        return true
    }
}
