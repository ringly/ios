import UIKit

public extension UITableView
{
    public func registerCellType<T: UITableViewCell>(_ type: T.Type)
    {
        register(type, forCellReuseIdentifier: "\(type)")
    }
    
    public func dequeueCellOfType<T: UITableViewCell>(_ type: T.Type, forIndexPath path: IndexPath) -> T
    {
        return dequeueReusableCell(withIdentifier: "\(type)", for: path) as! T
    }
}
