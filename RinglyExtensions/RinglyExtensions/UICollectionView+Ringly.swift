import UIKit

public extension UICollectionView
{
    public func registerCellType<T: UICollectionViewCell>(_ type: T.Type)
    {
        register(type, forCellWithReuseIdentifier: "\(type)")
    }
    
    public func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, forIndexPath path: IndexPath) -> T
    {
        return dequeueReusableCell(withReuseIdentifier: "\(type)", for: path) as! T
    }

    public func registerSupplementaryViewOfType<T: UICollectionReusableView>(_ type: T.Type, forKind kind: String)
    {
        register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: "\(type)-supplementary")
    }

    public func dequeueSupplementaryViewOfType<T: UICollectionReusableView>
        (_ type: T.Type, forKind kind: String, indexPath: IndexPath) -> T
    {
        return dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "\(type)-supplementary",
            for: indexPath
        ) as! T
    }
}
