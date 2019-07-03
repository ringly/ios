import RealmSwift

final class NotificationAlert: Object
{
    // Properties
    
    /// The application of the notification.
    dynamic var application: String?
    
    /// The title of the notification.
    dynamic var title: String?
    
    /// The message of the notification.
    dynamic var message: String?

    /// The date that the log message was recorded.
    dynamic var date: NSDate?
    
    /// Whether or not notification is pinned.
    dynamic var pinned: Bool = false
    
    /// Whether or not notification is 'activated' to become deleted.
    dynamic var activated: Bool = false
    
    
    // Initialization
    
    /// Initializes a notification message with all properties.
    ///
    /// Parameters:   
    ///   - application: The application of the notification.
    ///   - title: The title of the notification.
    ///   - message: The message of notification.
    ///   - date: The date of the notification.
    ///   - pinned: Whether or not notification is pinned.
    ///   - activated: Whether or not notification is 'activated' to become deleted.
    convenience init(application: String, title: String, message: String?, date: NSDate, pinned: Bool)
    {
        self.init()
        self.application = application
        self.title = title
        self.message = message
        self.date = date
        self.pinned = pinned
        self.activated = false
    }
    
    
    // Equality
    
    /// Notifications are equal if their `application`, `title`, `message`, `date`, and `pinned` properties are equal.
    ///
    /// - Parameter object: The other object.
    /// - Returns: `true` if the objects are equal, otherwise `false`.
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? NotificationAlert else { return false }
        return application == other.application && title == other.title &&
            message == other.message && date == other.date && pinned == other.pinned
    }
    
    
    func primaryKey() -> String {
        return "\(title!)\(message!)\(application!)"
    }
    
}
