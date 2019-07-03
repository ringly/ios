import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    @objc func application(_ application: UIApplication,
                           didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool
    {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = UINavigationController(rootViewController: SelectPeripheralViewController())

        window.makeKeyAndVisible()

        return true
    }
}

