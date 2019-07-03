import AirshipKit
import UIKit

protocol LocalNotification
{
    var userInfo: [AnyHashable: Any]? { get }
}

extension UILocalNotification: LocalNotification {}

extension UANotificationContent: LocalNotification
{
    var userInfo: [AnyHashable: Any]? { return notificationInfo }
}
