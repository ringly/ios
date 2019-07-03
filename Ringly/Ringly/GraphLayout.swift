import UIKit

/// A collection view layout class for displaying graphs of data. This class defines a few requirements:
/// 
/// - The layout merely arranges full-height columns along the horizontal axis. The cells themselves are responsible for
///   displaying data of the correct height.
/// - Only a single section is valid.
/// - There should be a non-zero number assigned to `columnsPerPage`.
final class GraphLayout: UICollectionViewLayout
{
    // MARK: - Parameters

    /// The number of columns visible on screen once snapped to a column boundary (one more may be visible while the
    /// user is scrolling, since the ends may be only partially visible).
    ///
    /// Setting this property to `0` will cause the layout to be invalid.
    var columnsPerPage = 0 { didSet { invalidateLayout() } }

    /// The settings for the column divider.
    ///
    /// - `width`: the width of the divider.
    /// - `offset`: the offset at which the column divider should begin. Columns bordering the divider are slightly
    ///    smaller.
    ///
    /// If set to `nil`, no column divider will be included in the layout.
    var columnDividerSettings: (width: CGFloat, offset: Int)? = nil { didSet { invalidateLayout() } }

    // MARK: - Invalidation
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        return true
    }

    // MARK: - Content Size
    override var collectionViewContentSize : CGSize
    {
        guard let collectionView = self.collectionView, columnsPerPage > 0 else { return .zero }

        let size = collectionView.bounds.size
        let columnWidth = size.width / CGFloat(columnsPerPage)
        let columns = collectionView.numberOfItems(inSection: 0)

        return CGSize(width: CGFloat(columns) * columnWidth, height: size.height)
    }

    // MARK: - Layout Attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        guard let collectionView = self.collectionView, columnsPerPage > 0 else { return nil }

        let size = collectionView.bounds.size
        let columnWidth = size.width / CGFloat(columnsPerPage)

        return layoutAttributesForItemAt(
            indexPath,
            bounds: collectionView.bounds,
            width: columnWidth,
            height: size.height
        )
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        guard let collectionView = self.collectionView, columnsPerPage > 0 else { return nil }

        let size = collectionView.bounds.size
        let columnWidth = size.width / CGFloat(columnsPerPage)
        guard columnWidth > 0 else { return nil }

        let columns = collectionView.numberOfItems(inSection: 0)

        let firstColumn = max(Int(rect.minX / columnWidth), 0)
        let lastColumn = min(Int(ceil(rect.maxX / columnWidth)), columns)

        return (firstColumn..<lastColumn).map({ column in
            layoutAttributesForItemAt(
                IndexPath(item: column, section: 0),
                bounds: collectionView.bounds,
                width: columnWidth,
                height: size.height
            )
        })
    }

    fileprivate func layoutAttributesForItemAt(_ indexPath: IndexPath,
                                           bounds: CGRect,
                                           width: CGFloat,
                                           height: CGFloat)
                                           -> UICollectionViewLayoutAttributes
    {
        let attributes = GraphLayoutAttributes(forCellWith: indexPath)

        var frame = CGRect(
            x: CGFloat(indexPath.item) * width,
            y: 0,
            width: width,
            height: height
        )

        if let (width, offset) = columnDividerSettings, (indexPath.item - offset) % columnsPerPage == 0
        {
            frame.size.width -= width
            frame.origin.x += width
        }

        attributes.frame = frame
        attributes.selectedness = 1 - min(1, abs(frame.midX - bounds.midX) / frame.size.width)

        return attributes
    }
}

final class GraphLayoutAttributes: UICollectionViewLayoutAttributes
{
    //

    /// How much the cell should appear "selected" in a scroll-selection mode.
    @nonobjc var selectedness: CGFloat = 0

    // MARK: - Objective-C Compatibility
    override func copy(with zone: NSZone?) -> Any
    {
        let copy = super.copy(with: zone) as! GraphLayoutAttributes
        copy.selectedness = selectedness
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool
    {
        return super.isEqual(object) && selectedness == (object as? GraphLayoutAttributes)?.selectedness
    }
}
