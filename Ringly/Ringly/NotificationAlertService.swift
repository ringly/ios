import Foundation
import ReactiveCocoa
import RealmSwift
import Result
import class DFULibrary.ZipArchive

final class NotificationAlertService: NSObject
{
    static let sharedNotificationService = NotificationAlertService()
    
    // Realm Configuration
    let configuration: Realm.Configuration
    
    // last notification added that may be pinned
    var lastNotificationAdded: NotificationAlert = NotificationAlert(application: "", title: "", message: "", date: NSDate(), pinned: false)
    
    // Initialization
    override init()
    {
        //For clearing realm database and resetting class structure
//        do { try
//            NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!) }
//        catch { print("Could not delete") }
//        Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true

        self.configuration = Realm.Configuration(objectTypes: [NotificationAlert.self])
        super.init()
    }
    
    // Log a notification
    func log(application:String, title: String, message: String?, date: Date, pinned: Bool)
    {
        do
        {
            let realm = try Realm(configuration: configuration)
            
            try realm.write {
                lastNotificationAdded = NotificationAlert(application: application, title: title, message: message, date: date as NSDate, pinned: pinned)
                realm.add(lastNotificationAdded)
            }
        }
        catch let error as NSError
        {
            print("Error logging notification: ", error)
        }
    }
    
    
    // Clear realm database
    func clearLog()
    {
        do
        {
            let realm = try Realm(configuration: configuration)
            
            try realm.write {
                realm.deleteAll()
            }
        }
        catch
        {
            print("Error deleting all notifications")
        }
    }
    
    
    // Remove specific notification
    func removeEntry(notification: NotificationAlert) {
        do
        {
            let realm = try Realm(configuration: configuration)
            
            try realm.write {
                realm.delete(notification)
            }
        }
        catch let error as NSError
        {
            print("Error removing notification: ", error)
        }
    }
    
    // Pin a notification
    func makePinned() {
        do
        {
            let realm = try Realm(configuration: configuration)
            
            try realm.write {
                lastNotificationAdded.pinned = true
            }
        }
        catch let error as NSError
        {
            print("Error pinning notification: ", error)
        }
    }

}
