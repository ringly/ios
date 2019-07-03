import UIKit

final class ApplicationsEditPromptCell: UITableViewCell
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let font: (String) -> NSAttributedString = { $0.attributes(font: .gothamBook(15), tracking: 250) }

        let attachment = NSTextAttachment()
        attachment.image = UIImage(asset: .addButtonSmall)
        attachment.bounds = (attachment.image?.size).map({ size in
            CGRect(x: 0, y: -2, width: size.width, height: size.height)
        }) ?? attachment.bounds

        let attributedText = [
            font(tr(.applicationsEditPromptStarting)),
            NSAttributedString(attachment: attachment),
            font(tr(.applicationsEditPromptEnding))
        ].join().attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))

        let label = UILabel.newAutoLayout()
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textColor = UIColor.white
        contentView.addSubview(label)

        label.autoCenterInSuperview()
        label.autoSet(dimension: .width, to: 205, relation: .lessThanOrEqual)

        backgroundColor = .clear
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
