import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

/// A view controller that displays a bar graph of data.
final class GraphViewController: UIViewController
{
    // MARK: - Data

    /// The data displayed by the graph.
    let data = MutableProperty(GraphData?.none)

    // MARK: - Columns

    /// The number of columns displayed by the graph view controller.
    let columns = MutableProperty(7)

    /// The offset before a break in the columns.
    let columnOffset = MutableProperty(0)

    /// A backing property for `selectedColumnIndexProducer`.
    fileprivate let selectedIndexPath = MutableProperty(IndexPath?.none)

    /// Yields the index of the selected column.
    var selectedColumnIndexProducer: SignalProducer<Int, NoError>
    {
        let offset = columns.producer.map(extraColumnsFor)

        return selectedIndexPath.producer
            .combineLatest(with: offset)
            .map(unwrap)
            .mapOptional({ $0.item - $1 })
            .map({ $0 ?? 0 })
            .skipRepeats()
    }

    /// A backing pipe for `tappedSelectedColumnSignal`.
    fileprivate let tappedSelectedColumnPipe = Signal<Int, NoError>.pipe()

    /// A signal indicating when the user taps an already-selected column.
    var tappedSelectedColumnSignal: Signal<Int, NoError> { return tappedSelectedColumnPipe.0 }

    // MARK: - Collection View

    /// The collection view layout used for `collectionView`.
    fileprivate let layout = GraphLayout()

    /// The collection view used to display graph data.
    fileprivate lazy var collectionView: UICollectionView = { [unowned self] in
        UICollectionView(frame: .zero, collectionViewLayout: self.layout)
    }()

    // MARK: - View Loading
    override func loadView()
    {
        super.loadView()

        let containerView = UIView.newAutoLayout()
        view.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 24, left: 0, bottom: 0, right: 0))
        
        // add collection view
        collectionView.backgroundColor = UIColor.clear
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        containerView.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
        
        
        // display goal view overlay
        let goalContainer = UIView.newAutoLayout()
        goalContainer.isUserInteractionEnabled = false
        containerView.addSubview(goalContainer)
        goalContainer.autoPinEdgesToSuperviewEdges()
        
        let goalView = GraphGoalView.newAutoLayout()
        goalView.goalValue <~ data.producer.mapOptional({ $0.goal.goalString })
        goalContainer.addSubview(goalView)
        
        // pin the goal view to the edges of the screen
        goalView.autoPinEdgeToSuperview(edge: .leading)
        goalView.autoPinEdgeToSuperview(edge: .trailing)
        
        // align the goal view correctly relative to the graph
        data.producer
            .mapOptional({ data in
                NSLayoutConstraint(
                    item: goalView,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: goalContainer,
                    attribute: .bottom,
                    multiplier: 1 - CGFloat(data.goal) / data.maximumValue,
                    constant: 0
                )
            })
            .combinePrevious(nil)
            .startWithValues({ optionalPrevious, optionalCurrent in
                if let previous = optionalPrevious
                {
                    goalContainer.removeConstraint(previous)
                }
                
                if let current = optionalCurrent
                {
                    goalContainer.addConstraint(current)
                }
            })

    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // register cell types
        collectionView.registerCellType(GraphColumnCell.self)

        // reload the collection view whenever the number of columns changes
        data.producer.skip(first: 1)
            .map({ $0?.columns.count })
            .skipRepeats(==)
            .startWithValues({ [weak self] _ in
                self?.collectionView.reloadData()
                self?.collectionView.layoutIfNeeded()
                self?.scrollToLastColumn(animated: false)
            })

        // update the collection view layout's number of columns as data changes
        SignalProducer.combineLatest(columns.producer, columnOffset.producer).startWithValues({ [weak layout] columns, offset in
            layout?.columnsPerPage = columns
            layout?.columnDividerSettings = (width: 4, offset: (columns - offset) + extraColumnsFor(columns))
        })
    }

    /// A flag for avoiding setting the initial content offset more than once.
    fileprivate var performedInitialOffset = false

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        // only perform this once, not if returning from a deeper navigation controller, etc.
        guard !performedInitialOffset else { return }
        performedInitialOffset = true

        // required to set up collection view frame
        view.layoutIfNeeded()

        // adjust the content offset to select the last column
        scrollToLastColumn(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.contentInset = UIEdgeInsets.zero // this is set by the navigation controller...?
    }

    /**
     Scrolls the graph such that the last column is centered.

     - parameter animated: Whether or not the scrolling should be animated.
     */
    func scrollToLastColumn(animated: Bool)
    {
        if let count = data.value?.columns.count
        {
            let columns = self.columns.value
            let columnWidth = collectionView.bounds.size.width / CGFloat(columns)
            collectionView.setContentOffset(CGPoint(x: CGFloat(count - 1) * columnWidth, y: 0), animated: animated)
        }
    }
}

extension GraphViewController: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        precondition(section == 0)

        return (data.value?.columns.count).map({ dataColumns in
            totalColumnsFor(dataColumns, visibleColumns: columns.value)
        }) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        precondition(indexPath.section == 0)

        let cell = collectionView.dequeueCellOfType(GraphColumnCell.self, forIndexPath: indexPath)
        let index = indexPath.item

        SignalProducer.combineLatest(data.producer, columns.producer)
            .take(until: SignalProducer(cell.reactive.prepareForReuse))
            .map(unwrap)
            .mapOptionalFlat({ data, columns -> (value: CGFloat?, label: String?) in
                let extra = extraColumnsFor(columns)
                let labelIndex = (index - extra)

                return (
                    data.columns[safe: index - extra].flatten().map({ data.maximumValue > 0 ? $0 / data.maximumValue : 0 }),
                    data.labelForColumn?(labelIndex)
                )
            })
            .skipRepeatsOptional(==)
            .start(animationDuration: 0.25, action: { [weak cell] values in
                cell?.fillAmount = values?.0 ?? 0
                cell?.labelText = values?.1
                cell?.layoutIfInWindowAndNeeded()
            })

        return cell
    }
}

extension GraphViewController: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        collectionView.deselectItem(at: indexPath, animated: false)

        if let selectedIndex = selectedIndexPath.value?.item, selectedIndex == indexPath.item
        {
            tappedSelectedColumnPipe.1.send(value: selectedIndex)
        }
        else if let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        {
            let viewWidth = collectionView.bounds.size.width
            let offset = attributes.frame.midX - viewWidth / 2

            collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    {
        let extra = extraColumnsFor(columns.value)
        return indexPath.item - extra >= 0 && indexPath.item < collectionView.numberOfItems(inSection: 0) - extra
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let bounds = collectionView.bounds
        let midpoint = CGPoint(x: bounds.midX, y: bounds.midY)

        if let indexPath = collectionView.indexPathForItem(at: midpoint)
        {
            selectedIndexPath.value = indexPath
        }
        else
        {
            print("No index path at \(midpoint) in \(scrollView.contentSize)")
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        let columns = self.columns.value
        let columnWidth = scrollView.bounds.size.width / CGFloat(columns)
        let targetX = targetContentOffset.pointee.x
        targetContentOffset.pointee.x = round(targetX / columnWidth) * columnWidth
    }
}

extension GraphViewController
{
    // MARK: - Frames

    /// The frame for the selected column, relative to this view controller's view's bounds.
    var selectedColumnFrame: CGRect?
    {
        return selectedIndexPath.value
            .flatMap(collectionView.cellForItem)
            .map({ view.convert($0.bounds, from: $0) })
    }
}

private func extraColumnsFor(_ visibleColumns: Int) -> Int
{
    return visibleColumns / 2
}

private func totalColumnsFor(_ dataColumns: Int, visibleColumns: Int) -> Int
{
    return dataColumns + extraColumnsFor(visibleColumns) * 2
}

extension Int
{
    /// A string representing the integer as a steps goal.
    fileprivate var goalString: String
    {
        if self % 1000 == 0
        {
            return "\(self / 1000)K"
        }
        else if self % 500 == 0
        {
            return "\(self / 1000).5K"
        }
        else
        {
            return String(self)
        }
    }
}

