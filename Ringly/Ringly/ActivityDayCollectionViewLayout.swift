import UIKit

final class ActivityDayCollectionViewLayout: UICollectionViewLayout
{
    // MARK: - Sections

    /// The sections defined by an activity day collection view.
    enum Section: Int
    {
        case loading = 0
        case graph = 1
        case progress = 2
        case highlights = 3
        case emptyState = 4
    }

    // MARK: - Layout Constants

    /// The top padding for the graph section.
    fileprivate static let graphTopPadding: CGFloat = 10

    /// The minimum height of the graph section.
    fileprivate static let graphMinimumHeight: CGFloat = 50

    /// The maximum height of the graph section.
    fileprivate static let graphMaximumHeight: CGFloat = 120
    
    /// The height of the day steps progress section.
    fileprivate static let progressHeight: CGFloat = 80

    // MARK: - Layout

    /// Defines a prepared layout.
    fileprivate struct Layout
    {
        /// The size of the collection view.
        let size: CGSize

        /// The layout attributes for the collection view, grouped by section.
        let attributes: [[UICollectionViewLayoutAttributes]]
    }

    /// The current prepared layout.
    fileprivate var layout: Layout?

    // MARK: - Implementation
    override var collectionViewContentSize : CGSize
    {
        return layout?.size ?? .zero
    }

    override func prepare()
    {
        super.prepare()

        guard let collectionView = self.collectionView else {
            layout = nil
            return
        }

        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = false
        
        // the current y offset is used to adjust the positioning of the graph cell
        let size = collectionView.frame.size

        // fill with the layout attributes for each section
        var attributes: [[UICollectionViewLayoutAttributes]] = []

        // the activity section, if present, occupies the remaining space
        if collectionView.numberOfItems(inSection: Section.loading.rawValue) == 1
        {
            let activityAttributes = UICollectionViewLayoutAttributes(
                forCellWith: IndexPath(item: 0, section: Section.loading.rawValue)
            )

            activityAttributes.frame = CGRect(
                x: 0,
                y: ActivityDayCollectionViewLayout.graphTopPadding,
                width: size.width,
                height: max(50, size.height/2.0 - ActivityDayCollectionViewLayout.graphTopPadding - ActivityDayCollectionViewLayout.progressHeight)
            )

            attributes.append([activityAttributes])
        }

        // the graph section adjusts and scales down with the collection view offset
        // temporary - graph view full height
        if collectionView.numberOfItems(inSection: Section.graph.rawValue) == 1
        {
            let graphAttributes = UICollectionViewLayoutAttributes(
                forCellWith: IndexPath(item: 0, section: Section.graph.rawValue)
            )

            graphAttributes.frame = CGRect(
                x: 0,
                y: ActivityDayCollectionViewLayout.graphTopPadding,
                width: size.width,
                height: max(50, size.height/2.0 - ActivityDayCollectionViewLayout.graphTopPadding - ActivityDayCollectionViewLayout.progressHeight)
            )

            attributes.append([graphAttributes])
        }
        
        // the progress section sits below the graph view
        let progressAttributes = UICollectionViewLayoutAttributes(
            forCellWith: IndexPath(item: 0, section: Section.progress.rawValue)
        )

        progressAttributes.frame = CGRect(
            x: 0,
            y: size.height/2.0 - ActivityDayCollectionViewLayout.progressHeight,
            width: size.width,
            height: ActivityDayCollectionViewLayout.progressHeight
        )
        
        attributes.append([progressAttributes])
        
        
        // the highlights section sits below the progress control
        if collectionView.numberOfItems(inSection: Section.highlights.rawValue) == 1
        {
            let highlightAttributes = UICollectionViewLayoutAttributes(
                forCellWith: IndexPath(item: 0, section: Section.highlights.rawValue)
            )
            
            highlightAttributes.frame = CGRect(
                x: 0,
                y: size.height/2.0,
                width: size.width,
                height: size.height/2.0
            )
            
            attributes.append([highlightAttributes])
        }
        
        // the empty state section sits below the progress control, shows if no steps recorded
        if collectionView.numberOfItems(inSection: Section.emptyState.rawValue) == 1
        {
            let emptyStateAttributes = UICollectionViewLayoutAttributes(
                forCellWith: IndexPath(item: 0, section: Section.emptyState.rawValue)
            )
            
            emptyStateAttributes.frame = CGRect(
                x: 0,
                y: size.height/2.0,
                width: size.width,
                height: size.height/2.0
            )
            
            attributes.append([emptyStateAttributes])
        }

        let maxY = attributes.joined().lazy.map({ $0.frame.maxY }).max()
        layout = Layout(size: CGSize(width: size.width, height: maxY ?? 0), attributes: attributes)
    }

    // MARK: - Attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return layout?.attributes[safe: indexPath.section]?[safe: indexPath.row]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        guard let attributes = layout?.attributes else { return nil }

        return attributes.joined().filter({ attributes in attributes.frame.intersects(rect) })
    }

    // MARK: - Invalidation
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        return true
    }
}
