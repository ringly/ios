import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class PreferencesActivityPickerView: UIView
{
    // MARK: - Content

    /// The title of the view.
    var title: String?
    {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue?.preferencesActivityControlTitleString
            addControl.title = title
        }
    }

    /// The quantity text displayed by the view.
    let quantityComponents = MutableProperty([UnitStringComponent]?.none)
    

    // MARK: - Subviews

    /// A control to add a quantity, if one has not been set before.
    fileprivate let addControl = PreferencesActivityAddControl.newAutoLayout()

    /// A label displaying `title`.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// A label displaying `quantity`, as modified by `formatter`.
    fileprivate let quantityLabel = UILabel.newAutoLayout()

    /// The control to increase the `quantity`.
    fileprivate let increaseControl = UIButton.newAutoLayout()

    /// The control to decrease the `quantity`.
    fileprivate let decreaseControl = UIButton.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(addControl)

        // add labels
        titleLabel.textColor = .white
        addSubview(titleLabel)

        quantityLabel.textColor = .white
        quantityLabel.adjustsFontSizeToFitWidth = true
        addSubview(quantityLabel)

        // add buttons
        let normalPixel = UIImage.rly_pixel(with: ButtonControl.defaultFillColor)
        let highlightedPixel = UIImage.rly_pixel(with: ButtonControl.defaultHighlightedFillColor)

        increaseControl.accessibilityLabel = "Increase"
        increaseControl.setImage(UIImage(asset: .preferencesActivityPlus), for: UIControlState())
        increaseControl.setBackgroundImage(normalPixel, for: .normal)
        increaseControl.setBackgroundImage(highlightedPixel, for: .highlighted)
        addSubview(increaseControl)

        decreaseControl.accessibilityLabel = "Decrease"
        decreaseControl.setImage(UIImage(asset: .preferencesActivityMinus), for: UIControlState())
        decreaseControl.setBackgroundImage(normalPixel, for: .normal)
        decreaseControl.setBackgroundImage(highlightedPixel, for: .highlighted)
        addSubview(decreaseControl)

        // add decorative lines
        let decorations = (
            left: UIView.newAutoLayout(),
            right: UIView.newAutoLayout()
        )

        [decorations.left, decorations.right].forEach({ decoration in
            decoration.backgroundColor = UIColor(white: 1, alpha: 0.5)
            addSubview(decoration)
        })

        addSubview(decorations.left)
        addSubview(decorations.right)

        // center add control
        let addControlConstraints = (
            top: addControl.autoPinEdgeToSuperview(edge: .top),
            bottom: addControl.autoPinEdgeToSuperview(edge: .bottom),
            horizontal: addControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        )

        addControl.autoAlignAxis(toSuperviewAxis: .vertical)

        // align views to add control
        [increaseControl, decreaseControl, decorations.left, decorations.right].forEach({
            addControl.autoAlign(axis: .horizontal, toSameAxisOf: $0)
        })

        // center title at the top of the view
        let titleTopConstraint = titleLabel.autoPinEdgeToSuperview(edge: .top)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical)

        // horizontally center quantity label, between the controls
        quantityLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        quantityLabel.autoPin(edge: .leading, to: .trailing, of: decreaseControl, offset: 15, relation: .greaterThanOrEqual)
        quantityLabel.autoPin(edge: .trailing, to: .leading, of: increaseControl, offset: -15, relation: .lessThanOrEqual)
        decreaseControl.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 12)

        // fix size of controls
        let controlSize = CGSize(width: 41, height: 41)
        [decreaseControl, increaseControl].forEach({
            $0.autoSetDimensions(to: controlSize)
            $0.layer.cornerRadius = controlSize.width / 2
            $0.clipsToBounds = true
        })

        // place controls on the sides
        decreaseControl.autoPinEdgeToSuperview(edge: .leading)
        increaseControl.autoPinEdgeToSuperview(edge: .trailing)

        // vertically align all lower content
        decreaseControl.autoAlign(axis: .horizontal, toSameAxisOf: increaseControl)
        decreaseControl.autoAlign(axis: .horizontal, toSameAxisOf: quantityLabel)

        var decorationSizeConstraints:[[NSLayoutConstraint]] = []
        // set position of decorations
        [decorations.left, decorations.right].forEach({ decoration in
            let sizeConstraints = decoration.autoSetDimensions(to: CGSize(width: 32, height: 1))
            decorationSizeConstraints.append(sizeConstraints)
            decoration.autoAlign(axis: .horizontal, toSameAxisOf: increaseControl)
        })

        decorations.left.autoPin(edge: .left, to: .right, of: decreaseControl, offset: 15)
        decorations.right.autoPin(edge: .right, to: .left, of: increaseControl, offset: -15)

        // pin all lower views to the bottom, allowing them to float upwards if necessary
        [quantityLabel, decreaseControl, increaseControl].forEach({
            $0.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        })

        // update quantity label text
        quantityComponents.producer.startWithValues({ [weak self] components in
            guard let strong = self else { return }

            strong.quantityLabel.attributedText = components?.unitAttributedString

            let haveComponents = components != nil

            // hide title label or add control, depending on whether or not we have components
            strong.titleLabel.isHidden = !haveComponents
            strong.addControl.isHidden = haveComponents

            // enable interaction with modification controls only if we have components - these cannot be hidden, since
            // they are shown in partial alpha
            strong.increaseControl.isUserInteractionEnabled = haveComponents
            strong.decreaseControl.isUserInteractionEnabled = haveComponents

            // fade out increase and decrease controls
            let controlAlpha: CGFloat = haveComponents ? 1 : 0.2
            strong.increaseControl.alpha = controlAlpha
            strong.decreaseControl.alpha = controlAlpha

            NSLayoutConstraint.conditionallyActivateConstraints([
                (titleTopConstraint, haveComponents),
                (addControlConstraints.top, !haveComponents),
                (addControlConstraints.bottom, !haveComponents),
                (addControlConstraints.horizontal, !haveComponents)
            ])
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

    // MARK: - Actions
    enum Action { case increase, decrease }

    var actionsProducer: SignalProducer<Action, NoError>
    {
        return SignalProducer.merge(
            decreaseControl.repeatedTouchProducer.map({ _ in .decrease }),
            increaseControl.repeatedTouchProducer.map({ _ in .increase })
        )
    }

    var addProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(addControl.reactive.controlEvents(.touchUpInside)).void
    }
}

extension Sequence where Iterator.Element == UnitStringComponent
{
    var unitAttributedString: NSAttributedString
    {
        return map({ component -> AttributedStringProtocol in
            let size: CGFloat

            switch component.part
            {
            case .value, .unitInline:
                size = 21
            case .unitSuffix:
                size = 11
            }

            return component.string.attributes(font: .gothamBook(size), tracking: 250)
        }).join().attributedStringRemovingFinalKerning
    }
}

extension UIControl
{
    var repeatedTouchProducer: SignalProducer<(), NoError>
    {
        let touchUp = SignalProducer(reactive.controlEvents([.touchUpInside, .touchUpOutside, .touchCancel])).void

        return SignalProducer(reactive.controlEvents(.touchDown))
            .flatMap(.latest, transform: { _ in
                immediateTimer(interval: .milliseconds(500), on: QueueScheduler.main)
                    .take(first: 4)
                    .concat(timer(interval: .milliseconds(250), on: QueueScheduler.main))
                    .take(first: 4)
                    .concat(timer(interval: .milliseconds(125), on: QueueScheduler.main))
                    .void
                    .take(until: touchUp)
            })
    }
}
