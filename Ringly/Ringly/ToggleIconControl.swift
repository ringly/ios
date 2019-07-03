import ReactiveSwift
import UIKit

final class ToggleIconControl: UIControl
{
    // MARK: - Colors

    /// Defines the colors used by a toggle icon control.
    struct Colors
    {
        /// The default background color for the control.
        let backgroundColor: UIColor

        /// The highlighted background color to use.
        let highlightedBackgroundColor: UIColor

        /// The default icon color for the control.
        let iconColor: UIColor

        /// The background alpha when selected.
        let selectedAlpha: CGFloat

        /// The background alpha when unselected.
        let unselectedAlpha: CGFloat

        /// The default colors for controls.
        static var defaultColors: Colors
        {
            return Colors(
                backgroundColor: .white,
                highlightedBackgroundColor: UIColor(white: 0.94, alpha: 1),
                iconColor: UIColor(white: 0.3322, alpha: 1),
                selectedAlpha: 1,
                unselectedAlpha: 0.5
            )
        }
    }

    /// The colors used by the control.
    let colors = MutableProperty(Colors.defaultColors)

    // MARK: - Icon

    /// The current icon displayed by the control. This value is transformed to a template image.
    var icon: UIImage? = nil
    {
        didSet { imageView.image = icon?.withRenderingMode(.alwaysTemplate) }
    }

    // MARK: - Subviews

    /// The image view used to display the image.
    fileprivate let imageView = UIImageView.newAutoLayout()

    /// The background view - needs to be separate for independent alpha from `imageView`.
    fileprivate let background = UIView.newAutoLayout()

    // MARK: - State
    fileprivate let highlightedState = MutableProperty(false)
    fileprivate let selectedState = MutableProperty(false)

    // MARK: - Initialization
    fileprivate func setup()
    {
        background.isUserInteractionEnabled = false
        addSubview(background)
        background.autoPinEdgesToSuperviewEdges()

        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        imageView.autoFloatInSuperview()

        // mask the corner radius
        clipsToBounds = true

        // update the colors of the control
        SignalProducer.combineLatest(colors.producer, highlightedState.producer, selectedState.producer)
            .startWithValues({ [weak self] colors, highlighted, selected in
                self?.imageView.tintColor = colors.iconColor

                self?.background.backgroundColor = highlighted
                    ? colors.highlightedBackgroundColor
                    : colors.backgroundColor

                self?.background.alpha = selected ? colors.selectedAlpha : colors.unselectedAlpha
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

    // MARK: - Highlight and Selection
    override var isHighlighted: Bool
    {
        didSet { highlightedState.value = isHighlighted }
    }

    override var isSelected: Bool
    {
        didSet { selectedState.value = isSelected }
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2
    }
}
