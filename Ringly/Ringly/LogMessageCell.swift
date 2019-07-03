import UIKit

#if DEBUG || FUTURE

final class LogMessageCell: UITableViewCell
{
    // MARK: - Message
    var message: LoggingMessage?
    {
        didSet
        {
            dateLabel.text = (message?.date).map(LogMessageCell.dateFormatter.string)
            typeLabel.text = (message?.type).map(RLogTypeToString)
            messageLabel.text = message?.text
        }
    }

    // MARK: - Subviews
    private let dateLabel = UILabel()
    private let typeLabel = UILabel()
    private let messageLabel = UILabel()

    // MARK: - Initialization
    private func setup()
    {
        dateLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
        dateLabel.font = .gothamBook(10)
        contentView.addSubview(dateLabel)

        typeLabel.textColor = dateLabel.textColor
        typeLabel.font = dateLabel.font
        typeLabel.textAlignment = .right
        contentView.addSubview(typeLabel)

        messageLabel.font = UIFont(name: "Menlo-Regular", size: 11)
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)
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
    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        let fitSize = CGSize(width: size.width - 10, height: .greatestFiniteMagnitude)

        return CGSize(
            width: size.width,
            height: 15 + dateLabel.sizeThatFits(fitSize).height + messageLabel.sizeThatFits(fitSize).height
        )
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let rect = contentView.bounds.insetBy(dx: 5, dy: 5)
        let dateSize = dateLabel.sizeThatFits(.max)

        dateLabel.frame = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: dateSize.width, height: dateSize.height
        )

        typeLabel.frame = CGRect(
            x: rect.origin.x + dateSize.width + 5,
            y: rect.origin.y,
            width: rect.size.width - dateSize.width - 5,
            height: typeLabel.sizeThatFits(rect.size).height
        )

        messageLabel.frame = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + dateSize.height + 5,
            width: rect.size.width,
            height: messageLabel.sizeThatFits(rect.size).height
        )
    }

    // MARK: - Date Formatting
    private static let dateFormatter = DateFormatter(format: "MM-dd kk:mm:ss.SSSS")
}

#endif
