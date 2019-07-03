import UIKit

class ColorSliderCell: UITableViewCell
{
    // MARK: - Subviews
    let colorSliderContentView = UIView.newAutoLayout()
    let colorSliderView = ColorSliderView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        colorSliderContentView.clipsToBounds = true
        contentView.addSubview(colorSliderContentView)

        colorSliderContentView.autoPinEdgeToSuperview(edge: .top)
        colorSliderContentView.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        colorSliderContentView.autoPinEdgeToSuperview(edge: .left, inset: ColorSliderCell.sideInset)
        colorSliderContentView.autoPinEdgeToSuperview(edge: .right, inset: ColorSliderCell.sideInset)

        colorSliderContentView.addSubview(colorSliderView)
        colorSliderView.autoPinEdgesToSuperviewEdges()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Layout
    @nonobjc static let sideInset: CGFloat = 10
}
