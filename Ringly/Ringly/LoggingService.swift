import Foundation
import ReactiveSwift
import RealmSwift
import Result
import RinglyActivityTracking
import class DFULibrary.ZipArchive

final class LoggingService: NSObject
{
    // MARK: - Singleton
    static let sharedLoggingService = try? LoggingService(
        storeURL: LoggingService.directoryURL.appendingPathComponent("l.realm"),
        cutoff: 604800,
        dateScheduler: QueueScheduler.main
    )

    fileprivate static var directoryURL: URL
    {
        return FileManager.default.rly_documentsURL.appendingPathComponent("l")
    }

    // MARK: - Initialization
    init(storeURL: URL, cutoff: TimeInterval, dateScheduler: DateSchedulerProtocol) throws
    {
        // create logs path if necessary
        let fm = FileManager.default
        let path = storeURL.deletingLastPathComponent().path

        if !fm.rly_directoryExists(atPath: path)
        {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }

        // assign properties
        self.cutoff = cutoff
        self.configuration = Realm.Configuration(fileURL: storeURL, objectTypes: [LoggingMessage.self])
        self.dateScheduler = dateScheduler

        super.init()
    }

    // MARK: - Logging
    var NSLogTypes: RLogType = []
    fileprivate let cutoff: TimeInterval
    let configuration: Realm.Configuration
    fileprivate let dateScheduler: DateSchedulerProtocol

    func log(_ string: String, type: RLogType)
    {
        let date = dateScheduler.currentDate

        if NSLogTypes.contains(type)
        {
            print("\(RLogTypeToString(type)): \(string)")
        }

        do
        {
            let realm = try Realm(configuration: configuration)

            try realm.write {
                // delete anything before the cutoff date
                let cutoffDate = NSDate(timeIntervalSinceNow: -cutoff)
                realm.delete(realm.objects(LoggingMessage.self).filter(NSPredicate(format: "date < %@", cutoffDate)))

                // add the new message
                realm.add(LoggingMessage(text: string, type: type, date: date))
            }
        }
        catch let error as NSError
        {
            print("Error saving logging context: ", error)
        }
    }
}

extension LoggingService
{
    /// A signal producer that will yield the service's logging messages.
    var csvProducer: SignalProducer<String, NSError>
    {
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)

        return configuration.realmProducer(queue: queue) { realm, observer, _ in
            let messages = realm.objects(LoggingMessage.self).sorted(byKeyPath: "date", ascending: true)
            observer.send(value: messages.commaSeparatedValueRepresentation)
            observer.sendCompleted()
        }
    }

    /// Attempts to write the logging service's message to a temporary file URL.
    var csvDataURLProducer: SignalProducer<URL, NSError>
    {
        return csvProducer.attemptMap({ csv -> Result<URL, NSError> in
            guard let data = csv.data(using: String.Encoding.utf8) else {
                return .failure(MailComposeError(
                    errorDescription: "Error",
                    failureReason: "Error converting to data representation. Please contact support@ringly.com."
                ) as NSError)
            }

            do
            {
                let directory = try ZipArchive.createTemporaryFolderPath("ringly-diagnostics-\(arc4random())")

                guard let fileURL = NSURL(fileURLWithPath: directory).appendingPathComponent("logs.csv") else {
                    return .failure(MailComposeError(
                        errorDescription: "Error",
                        failureReason: "Error creating temporary path. Please contact support@ringly.com."
                    ) as NSError)
                }

                try data.write(to: fileURL, options: .atomic)

                return .success(fileURL)
            }
            catch let error as NSError
            {
                return .failure(error)
            }
        })
    }

    /// All messages stored in the service. Probably slow.
    func messages() throws -> [LoggingMessage]
    {
        return Array(try Realm(configuration: configuration).objects(LoggingMessage.self))
    }
}
