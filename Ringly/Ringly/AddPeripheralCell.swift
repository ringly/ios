import Foundation
import ReactiveSwift
import RinglyKit

final class AddPeripheralCell: UITableViewCell
{
    // MARK: - Peripheral
    let labelContent = MutableProperty((name: String, lastFour: String)?.none)
    let styleContent = MutableProperty(RLYPeripheralStyle?.none)

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundView = nil
        backgroundColor = .clear
        selectionStyle = .none

        // add subviews
        let peripheralControl = PeripheralImageControl.newAutoLayout()
        peripheralControl.isUserInteractionEnabled = false
        peripheralControl.layoutMode = .shadowOutside
        contentView.addSubview(peripheralControl)

        let labelsContainer = UIView.newAutoLayout()
        contentView.addSubview(labelsContainer)

        let nameLabel = UILabel.newAutoLayout()
        nameLabel.textColor = .white
        labelsContainer.addSubview(nameLabel)

        let lastFourLabel = UILabel.newAutoLayout()
        lastFourLabel.textColor = .white
        labelsContainer.addSubview(lastFourLabel)

        // layout subviews
        peripheralControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        peripheralControl.autoPinEdgeToSuperview(edge: .leading)
        peripheralControl.autoSetDimensions(to: CGSize(width: 165, height: 40))

        labelsContainer.autoAlignAxis(toSuperviewAxis: .horizontal)
        labelsContainer.autoPinEdgeToSuperview(edge: .trailing)
        labelsContainer.autoPin(edge: .leading, to: .trailing, of: peripheralControl)

        nameLabel.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        lastFourLabel.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        lastFourLabel.autoPin(edge: .top, to: .bottom, of: nameLabel, offset: 5)

        // bind label content
        labelContent.producer.startWithValues({ optional in
            let font = UIFont.gothamBook(11)

            nameLabel.attributedText = optional
                .map({ text, _ in font.track(250, text.uppercased()).attributedString })

            lastFourLabel.attributedText = optional
                .map({ _, text in font.track(250, text.uppercased()).attributedString })
        })

        // bind image view content
        styleContent.producer.startWithValues({ peripheralControl.style = $0 })

        reactive.producerFor(keyPath: "highlighted", defaultValue: false).startWithValues({ highlighted in
            let alpha: CGFloat = highlighted ? 0.9 : 1
            peripheralControl.alpha = alpha
            labelsContainer.alpha = alpha
        })
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
