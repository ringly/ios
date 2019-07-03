import Foundation
import RinglyExtensions

final class TicksCollectionViewLayout: UICollectionViewLayout
{
    // MARK: - Supplementary View Kinds
    static let titleSupplementaryViewKind = "titleSupplementaryViewKind"

    // MARK: - Appearance
    var appearance: TicksAppearance? = nil
//    {
//        didSet
//        {
//            invalidateLayout()
//        }
//    }

    /// The current state of the layout.
    fileprivate var attributes: [TickAttributes]? = nil

    override func prepare()
    {
        super.prepare()

        guard let collectionView = self.collectionView, let appearance = self.appearance else {
            attributes = nil
            return
        }

        // we need a pattern to proceed
        let patternCount = appearance.pattern.count
        precondition(patternCount > 0)

        // only one section is supported for tick collection views
        precondition(collectionView.numberOfSections == 1)

        // collection view attributes
        let collectionViewHeight = collectionView.bounds.size.height
        let items = collectionView.numberOfItems(inSection: 0)

        // start with empty arrays and build up to the total number of items
        let titleYOffset = collectionViewHeight * appearance.heightFraction

        attributes = (0..<items).map({ item -> TickAttributes in
            // create the cell attributes object
            let indexPath = IndexPath(item: item, section: 0)
            let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            // determine where we are in the pattern
            let patternIndex = item % patternCount
            let isMajorTick = patternIndex == 0
            let heightFraction = appearance.pattern[patternIndex]

            // determine the frame for the attributes object
            let height = collectionViewHeight * appearance.heightFraction * heightFraction

            cellAttributes.frame = CGRect(
                x: appearance.totalTickWidth * CGFloat(item),
                y: collectionViewHeight - height,
                width: appearance.tickWidth,
                height: height
            )

            cellAttributes.alpha = isMajorTick ? appearance.alpha.major : appearance.alpha.minor

            // for major ticks, create title attributes
            if patternIndex == 0
            {
                // create the attributes object
                let titleAttributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: TicksCollectionViewLayout.titleSupplementaryViewKind,
                    with: IndexPath(item: item, section: 0)
                )

                // determine the frame for the attributes object
                titleAttributes.frame = CGRect(
                    x: appearance.totalTickWidth * CGFloat(item) + appearance.tickWidth / 2 - 30,
                    y: collectionViewHeight - titleYOffset,
                    width: 60, // hard code width and height such that used labels will fit, tweak as is necessary
                    height: 20
                )

                titleAttributes.alpha = appearance.alpha.major

                return TickAttributes.major(cell: cellAttributes, title: titleAttributes)
            }
            else
            {
                return TickAttributes.minor(cell: cellAttributes)
            }
        })
    }

    // MARK: - Content Size
    override var collectionViewContentSize : CGSize
    {
        if let appearance = self.appearance, let count = attributes?.count, let collectionView = self.collectionView
        {
            return CGSize(
                width: (appearance.tickWidth + appearance.tickSpacing) * CGFloat(count) - appearance.tickSpacing,
                height: collectionView.bounds.size.height
            )
        }
        else
        {
            return .zero
        }
    }

    // MARK: - Layout Attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return attributes.map({ $0[indexPath.item].cellAttributes })
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        // ensure this it the title supplementary view kind
        guard elementKind == TicksCollectionViewLayout.titleSupplementaryViewKind else { return nil }

        return attributes?[indexPath.item].titleAttributes
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        // ensure that we have an appearance, which is necessary to make this calculation
        guard let appearance = self.appearance else { return nil }

        // we also require the arrays we'll be using
        guard let attributes = self.attributes, attributes.count > 0 else { return nil }

        // the distance in which ticks should transition from minimum to maximum alpha
        let totalTickWidth = appearance.totalTickWidth

        // the current effective content offset
        let offset = rect.minX
        let maxOffset = rect.maxX

        let rangeEnd = max(min(attributes.count - 1, Int(maxOffset / totalTickWidth) + 1), 0)
        let rangeStart = min(max(0, Int(offset / totalTickWidth)), rangeEnd)

        return attributes[rangeStart...rangeEnd].flatMap({ $0.attributeValues })
    }
}

extension TicksCollectionViewLayout
{
    fileprivate enum TickAttributes
    {
        case major(cell: UICollectionViewLayoutAttributes, title: UICollectionViewLayoutAttributes)
        case minor(cell: UICollectionViewLayoutAttributes)

        var attributeValues: [UICollectionViewLayoutAttributes]
        {
            switch self
            {
            case .major(let cell, let title):
                return [cell, title]

            case .minor(let cell):
                return [cell]
            }
        }

        var cellAttributes: UICollectionViewLayoutAttributes
        {
            switch self
            {
            case .major(let t):
                return t.cell

            case .minor(let cell):
                return cell
            }
        }

        var titleAttributes: UICollectionViewLayoutAttributes?
        {
            switch self
            {
            case .major(let t):
                return t.title

            case .minor:
                return nil
            }
        }
    }
}

// MARK: - Appearance
struct TicksAppearance
{
    // MARK: - Sizing

    /// The relative maximum height of ticks, relative to the total collection view height.
    let heightFraction: CGFloat

    /// The width of each tick.
    let tickWidth: CGFloat

    /// The amount of space between each tick.
    let tickSpacing: CGFloat

    /// The total width allocated to a tick, including the width of the tick and the padding to the next tick.
    var totalTickWidth: CGFloat
    {
        return tickWidth + tickSpacing
    }

    /// The alpha behavior.
    let alpha: (major: CGFloat, minor: CGFloat)

    /// The layout pattern for the ticks, defining the height fraction of each tick.
    let pattern: [CGFloat]
}
