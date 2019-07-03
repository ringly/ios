import RinglyAPI

extension APIService
{
    // MARK: - Initialization
    
    /// A bridge for Objective-C.
    convenience init(preferences: Preferences)
    {
        self.init(authenticationStorage: preferences)
    }
}

// MARK: - API Storage Type
extension Preferences: APIServiceAuthenticationStorage {}
