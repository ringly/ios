import Foundation
import ReactiveSwift
import enum Result.NoError

final class TicksViewController: UIViewController
{
    // MARK: - Selected Ticks

    /// A property backing `selectedTickProducer` and `fractionalSelectedTickProducer`.
    fileprivate let fractionalSelectedTick = MutableProperty<CGFloat>(0)

    /// A producer for the currently selected tick.
    var selectedTickProducer: SignalProducer<Int, NoError>
    {
        return fractionalSelectedTick.producer.map({ Int(round($0)) }).skipRepeats()
    }

    /// A producer for the currently selected tick, including fractions.
    var fractionalSelectedTickProducer: SignalProducer<CGFloat, NoError>
    {
        return fractionalSelectedTick.producer.skipRepeats()
    }

    // MARK: - Ticks

    /// The appearance of the ticks interface.
    var ticksAppearance: TicksAppearance?
    {
        get { return layout.appearance }
        set { layout.appearance = newValue }
    }

    /// The color of ticks.
    let tickColor = MutableProperty(UIColor.white)

    /// The number of ticks to display.
    var ticksData: TicksData? = nil
    {
        didSet
        {
            collectionView.reloadData()
        }
    }

    // MARK: - View Loading
    fileprivate let layout = TicksCollectionViewLayout()

    fileprivate lazy var collectionView: UICollectionView = { [unowned self] () -> UICollectionView in
        UICollectionView(frame: .zero, collectionViewLayout: self.layout)
    }()
    
    override func loadView()
    {
        super.loadView()

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        collectionView.registerCellType(UICollectionViewCell.self)
        collectionView.registerSupplementaryViewOfType(
            TickTitleSupplementaryView.self,
            forKind: TicksCollectionViewLayout.titleSupplementaryViewKind
        )

        // automatically scroll to the selected tick when the collection view resizes
        collectionView.reactive.producerFor(keyPath: "contentSize")
            .mapOptionalFlat({ (value: NSValue?) in value?.cgSizeValue })
            .skipNil()
            .skipRepeats()
            .startWithValues({ [weak self] size in
                guard let strong = self, let appearance = strong.ticksAppearance else { return }

                let x = appearance.totalTickWidth * CGFloat(round(strong.fractionalSelectedTick.value))
                strong.collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
            })
    }

    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()

        let inset = view.bounds.size.width / 2
        collectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }

    // MARK: - Scrolling
    var didScroll: ((_ offset: CGFloat, _ size: CGFloat) -> ())? = nil
}

extension TicksViewController
{
    /**
     Selects the specified tick.

     - parameter tick:     The tick to select.
     - parameter animated: Whether or not the selection should be animated.
     */
    func select(tick: Int, animated: Bool)
    {
        collectionView.scrollToItem(
            at: IndexPath(item: tick, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    /// Scrolls to the specific content offset.
    ///
    /// - parameter offset:   The x content ofset.
    /// - parameter animated: Whether or not the scroll should be animated.
    func scroll(to offset: CGFloat, animated: Bool)
    {
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
    }
}

extension TicksViewController: UICollectionViewDataSource
{
    // MARK: - Collection View Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return ticksData?.tickCount ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueCellOfType(UICollectionViewCell.self, forIndexPath: indexPath)

        tickColor.producer.take(until: SignalProducer(cell.reactive.prepareForReuse)).startWithValues({ [weak cell] color in
            cell?.backgroundColor = color
        })

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath)
        -> UICollectionReusableView
    {
        let view = collectionView.dequeueSupplementaryViewOfType(
            TickTitleSupplementaryView.self,
            forKind: TicksCollectionViewLayout.titleSupplementaryViewKind,
            indexPath: indexPath
        )

        view.title = ticksData?.titleForTickAtIndex(indexPath.item)

        return view
    }
}

extension TicksViewController: UICollectionViewDelegate
{
    // MARK: - Collection View Delegate
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        guard let appearance = self.ticksAppearance else { return }

        // the left and right insets are the same
        let inset = scrollView.contentInset.left

        // the current target x offset
        let offset = targetContentOffset.pointee.x

        // determine the snapping interval
        let interval = appearance.totalTickWidth

        // adjust target content offset
        let adjusted = round((offset + inset) / interval) * interval - inset + appearance.tickWidth / 2
        targetContentOffset.pointee.x = adjusted
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        // require layout data for assigning selected tick
        guard let appearance = self.ticksAppearance, let tickCount = ticksData?.tickCount else { return }

        // information required for index calculation
        let totalTickSize = appearance.tickWidth + appearance.tickSpacing
        let offset = scrollView.contentOffset.x + scrollView.contentInset.left

        // determine the index for the scroll offset, and constrain to the allowable range
        let calculatedFractionalTick = offset / totalTickSize
        let constrainedFractionalTick = max(min(calculatedFractionalTick, CGFloat(tickCount) - 1), 0)

        fractionalSelectedTick.value = constrainedFractionalTick

        didScroll?(scrollView.contentOffset.x, scrollView.contentSize.width)
    }
}

protocol TicksData
{
    /// The number of ticks displayed.
    var tickCount: Int { get }

    /// A function to provide tick titles.
    func titleForTickAtIndex(_ index: Int) -> String?
}

struct LazyTitleTicksData
{
    /// The number of ticks displayed.
    let tickCount: Int

    /// A function to provide tick titles.
    let titleFunction: (Int) -> String?
}

extension LazyTitleTicksData: TicksData
{
    /// A function to provide tick titles.
    func titleForTickAtIndex(_ index: Int) -> String?
    {
        return titleFunction(index)
    }
}
