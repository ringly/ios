import ReactiveSwift
import UIKit
import enum Result.NoError

/// The view type used to build `DisconnectViewController` and `NotConnectingViewController`.
final class ConnectPromptView: UIView
{
    // MARK: - Content

    /// The title of the view.
    var title: String?
    {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                UIFont.gothamBook(15).track(250, text)
                    .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 6))
            })
        }
    }

    // MARK: - Subviews

    /// The label displaying `title`.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The button control displaying "Close".
    fileprivate let closeButton = ButtonControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup(_ infoViews: [UIView],
                       infoViewsWidth: CGFloat,
                       minimumInfoViewSpacing: Int,
                       desiredInfoViewSpacing: Int)
    {
        // add the title label
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)

        // add the close button
        closeButton.title = "CLOSE"
        closeButton.font = UIFont.gothamBook(18)
        addSubview(closeButton)

        // add centering containers for info views
        let outerContainer = UIView.newAutoLayout()
        addSubview(outerContainer)

        let innerContainer = UIView.newAutoLayout()
        outerContainer.addSubview(innerContainer)

        let spacers = (0..<(infoViews.count - 1)).map({ _ in UIView.newAutoLayout() })
        spacers.forEach(innerContainer.addSubview)

        // add info views
        infoViews.forEach(innerContainer.addSubview)

        // layout - centering containers
        outerContainer.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: CGFloat(minimumInfoViewSpacing))
        outerContainer.autoPin(edge: .bottom, to: .top, of: closeButton, offset: -CGFloat(minimumInfoViewSpacing))

        outerContainer.autoSet(dimension: .width, to: infoViewsWidth)
        outerContainer.autoAlignAxis(toSuperviewAxis: .vertical)

        innerContainer.autoPinEdgeToSuperview(edge: .left)
        innerContainer.autoPinEdgeToSuperview(edge: .right)
        innerContainer.autoFloatInSuperview(alignedTo: .horizontal)

        // layout - outer fixed components (title and button)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical, inset: 10)
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 25)

        closeButton.autoPinEdgeToSuperview(edge: .bottom, inset: 20)
        closeButton.autoAlignAxis(toSuperviewAxis: .vertical)
        closeButton.autoSetDimensions(to: CGSize(width: 166, height: 46))

        // layout - spacers
        ((minimumInfoViewSpacing + 1)..<(desiredInfoViewSpacing - 1)).forEach({ spacing in
            // we are attempting to get as close to desiredSpacing as possible, using declining priorities for each
            // additional point of layout height - so that minimumSpacing is "required", minimumSpacing + 1 is
            // "required - 1", and so on...
            let priorityOffset = UILayoutPriority(spacing - minimumInfoViewSpacing)

            NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh - priorityOffset, forConstraints: {
                spacers[0].autoSet(dimension: .height, to: CGFloat(spacing), relation: .greaterThanOrEqual)
            })
        })

        // require the spacers to be at least the minimum size
        spacers[0].autoSet(dimension: .height, to: CGFloat(minimumInfoViewSpacing), relation: .greaterThanOrEqual)

        // disallow the spacers becoming any larger than the desired spacing
        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultLow + 1, forConstraints: {
            spacers[0].autoSet(dimension: .height, to: CGFloat(desiredInfoViewSpacing))
        })

        spacers[0].autoSet(dimension: .height, to: CGFloat(desiredInfoViewSpacing), relation: .lessThanOrEqual)

        // ensure that the height of the spacers match
        spacers.dropFirst().forEach({ spacer in
            spacer.autoMatch(dimension: .height, to: .height, of: spacers[0])
        })

        // pin the spacers to the top and bottoms of the info views
        spacers.enumerated().forEach({ index, spacer in
            spacer.autoPin(edge: .top, to: .bottom, of: infoViews[index])
            spacer.autoPin(edge: .bottom, to: .top, of: infoViews[index + 1])
        })

        // layout - component info views
        infoViews.forEach({
            $0.autoPinEdgeToSuperview(edge: .left)
            $0.autoPinEdgeToSuperview(edge: .right)
            $0.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        })

        infoViews.first?.autoPinEdgeToSuperview(edge: .top)
        infoViews.last?.autoPinEdgeToSuperview(edge: .bottom)
    }

    init(frame: CGRect,
         infoViews: [UIView],
         infoViewsWidth: CGFloat,
         minimumInfoViewSpacing: Int,
         desiredInfoViewSpacing: Int)
    {
        super.init(frame: frame)

        setup(
            infoViews,
            infoViewsWidth: infoViewsWidth,
            minimumInfoViewSpacing: minimumInfoViewSpacing,
            desiredInfoViewSpacing: desiredInfoViewSpacing
        )
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }

    // MARK: - Closing

    /// A producer for notifying an observer that the user has tapped the "close" button.
    var closeProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(closeButton.reactive.controlEvents(.touchUpInside)).void
    }
}
