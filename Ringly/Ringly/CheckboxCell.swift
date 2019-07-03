import UIKit

final class CheckboxCell: UITableViewCell
{
    // MARK: - Properties
    var checked: Bool
    {
        get { return checkbox.checked }
        set { checkbox.checked = newValue }
    }

    var caption: String?
    {
        get { return label.text }
        set { label.text = newValue }
    }

    // MARK: - Subviews
    fileprivate let checkbox = Checkbox.newAutoLayout()
    fileprivate let label = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .clear
        selectionStyle = .none

        checkbox.isUserInteractionEnabled = false
        contentView.addSubview(checkbox)

        checkbox.autoAlignAxis(toSuperviewAxis: .horizontal)
        checkbox.autoPinEdgeToSuperview(edge: .leading, inset: 20)

        label.font = .gothamBook(12)
        label.textColor = .white
        label.numberOfLines = 0
        contentView.addSubview(label)

        label.autoAlignAxis(toSuperviewAxis: .horizontal)
        label.autoPinEdgeToSuperview(edge: .trailing, inset: 20)
        label.autoPin(edge: .leading, to: .trailing, of: checkbox, offset: 20)
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
}
