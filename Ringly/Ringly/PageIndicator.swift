import ReactiveSwift
import UIKit

/// A custom "page indicator" view.
final class PageIndicator: UIView
{
    // MARK: - Constants
    
    /// The width and height of each indicator view.
    fileprivate static let indicatorSize: CGFloat = 8
    
    /// The padding between each indicator view.
    fileprivate static let indicatorPadding: CGFloat = 22
    
    /// The maximum alpha value of an indicator view.
    fileprivate static let maxAlpha: CGFloat = 1.0
    
    /// The minimum alpha value of an indicator view.
    fileprivate static let minAlpha: CGFloat = 0.5
    
    // MARK: - Model

    /// Describes the appearance of a `PageIndicator`.
    struct Model
    {
        /// The number of pages displayed by the page indicator.
        let pages: Int

        /// The progress through the page indicator's pages, as a value from 0 to `pages`.
        let progress: CGFloat

        /// The image to use for the last progress icon.
        let lastImage: UIImage?
    }

    /// The current model to display.
    let model = MutableProperty(Model?.none)
    
    // MARK: - Subviews
    
    /// The indicator views currently contained by the page indicator.
    fileprivate let indicators = MutableProperty<[UIView]>([])
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        let pageInfo = model.producer.map({ ($0?.pages ?? 0, $0?.lastImage) }).skipRepeats({ lhs, rhs in
            lhs.0 == rhs.0 && lhs.1 === rhs.1
        })

        // create indicator views for each property
        indicators <~ pageInfo.skip(first: 1).map({ count, optionalImage in
            (0..<count).map({ index -> UIView in
                if let image = optionalImage, index == count - 1
                {
                    let view = UIImageView.newAutoLayout()
                    view.image = image
                    view.autoConstrainSize()
                    return view
                }
                else
                {
                    let view = UIView.newAutoLayout()
                    
                    view.autoSet(dimension: .width, to: PageIndicator.indicatorSize)
                    view.autoSet(dimension: .height, to: PageIndicator.indicatorSize)
                    
                    view.backgroundColor = UIColor.white
                    view.layer.cornerRadius = PageIndicator.indicatorSize / 2
                    
                    return view
                }
            })
        })
        
        // add and remove the indicator views
        indicators.producer
            .combinePrevious([])
            .skip(first: 1)
            .startWithValues({ [weak self] previous, current in
                previous.forEach({ view in view.removeFromSuperview() })
                current.forEach({ view in self?.addSubview(view) })
                
                current.first?.autoPinEdgesToSuperviewEdges(insets: .zero, excluding: .trailing)
                current.last?.autoPinEdgesToSuperviewEdges(insets: .zero, excluding: .leading)

                (current as NSArray).autoDistributeViews(
                    along: .horizontal,
                    alignedTo: .top,
                    fixedSpacing: PageIndicator.indicatorPadding,
                    insetSpacing: false
                )
            })
        
        // fade the indicators in and out
        indicators.producer.combineLatest(with: model.producer).startWithValues({ indicators, optionalModel in
            let progress = optionalModel?.progress ?? 0
            
            zip(indicators, 0..<(indicators.count)).forEach({ indicator, index in
                // the total distance from fully selectedness
                let distance = abs(progress - CGFloat(index))

                // the visibility of this indicator, from 0 to 1
                let visibility = 1 - min(1, distance)
                
                indicator.alpha =
                    PageIndicator.minAlpha + visibility * (PageIndicator.maxAlpha - PageIndicator.minAlpha)
            })
        })
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
}
