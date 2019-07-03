import ReactiveSwift
import UIKit

final class GraphColumnCell: UICollectionViewCell
{
    /// The selectedness of the view, set by layout attribute objects.
    fileprivate let selectedness = MutableProperty<CGFloat>(0)

    // MARK: - Data

    /// The percentage that the cell's graph should be filled (`0` - `1`).
    var fillAmount: CGFloat = 0 { didSet { setNeedsLayout() } }

    /// The text displayed by the label.
    var labelText: String?
    {
        get { return label.text }
        set { label.text = newValue }
    }

    // MARK: - Subviews

    /// Draws the `fillAmount`.
    fileprivate let fill = UIView.newAutoLayout()

    /// Displays a column label at the bottom of the cell.
    fileprivate let label = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        fill.backgroundColor = .white
        fill.isUserInteractionEnabled = false
        addSubview(fill)

        label.font = UIFont.gothamBold(10)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.isUserInteractionEnabled = false
        addSubview(label)

        selectedness.producer.startWithValues({ [weak self] selectedness in
            self?.fill.alpha = 0.25 + 0.5 * selectedness
            self?.fill.backgroundColor = .white
            
            self?.label.textColor = UIColor(
                red: 1 - 0.59 * selectedness,
                green: 1 - 0.84 * selectedness,
                blue: 1 - 0.58 * selectedness,
                alpha: 1
            )
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

    // MARK: - Layout
    static let fixedBottomHeight: CGFloat = 20

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = bounds.size
        let fixedHeight: CGFloat = 0
        let fillHeight = (size.height - fixedHeight) * fillAmount + fixedHeight

        fill.frame = CGRect(x: 0, y: size.height - fillHeight, width: size.width, height: fillHeight)

        let labelSize = label.sizeThatFits(CGSize.max)
        label.frame = CGRect(
            x: 0,
            y: size.height - GraphColumnCell.fixedBottomHeight / 2 - labelSize.height / 2,
            width: size.width,
            height: labelSize.height
        )
    }

    // MARK: - Layout Attributes
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes)
    {
        super.apply(layoutAttributes)
        self.selectedness.value = (layoutAttributes as? GraphLayoutAttributes)?.selectedness ?? 1
    }
}
