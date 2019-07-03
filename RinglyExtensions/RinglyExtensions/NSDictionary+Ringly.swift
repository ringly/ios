import Foundation

extension NSDictionary
{
    @nonobjc public convenience init(dictionary: [String:Any])
    {
        self.init(dictionary: dictionary.mapToDictionary({ (NSString(string: $0.0), $0.1) }))
    }
}
