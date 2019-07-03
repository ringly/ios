import Foundation

extension Bundle
{
    /// The short (or "app") version of the bundle.
    @nonobjc var shortVersion: String?
    {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// The ("build") version of the bundle. 
    @nonobjc var version: String?
    {
        return infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}
