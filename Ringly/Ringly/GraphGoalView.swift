import PureLayout
import ReactiveSwift
import UIKit

final class GraphGoalView: UIView
{
    // MARK: - Goal

    /// The goal string to display.
    let goalValue = MutableProperty(String?.none)

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add bottom divider bar
        let bar = UIView.newAutoLayout()
        bar.backgroundColor = .white
        bar.alpha = 0.5
        addSubview(bar)

        bar.autoSet(dimension: .height, to: 1)
        bar.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)

        // add labels
        let goalLabel = UILabel.newAutoLayout()
        let goalValueLabel = UILabel.newAutoLayout()

        [(goalLabel, ALEdge.leading), (goalValueLabel, .trailing)].forEach({ label, edge in
            label.textColor = .white
            addSubview(label)

            label.autoPinEdgeToSuperview(edge: .top)
            label.autoPinEdgeToSuperview(edge: edge, inset: 9)
            label.autoPin(edge: .bottom, to: .top, of: bar, offset: -6)
        })

        // set label text
        let font = UIFont.gothamBook(10)
        goalLabel.attributedText = font.track(150, "GOAL").attributedString

        goalValue.producer
            .mapOptional({ font.track(150, $0).attributedString })
            .startWithValues({ goalValueLabel.attributedText = $0 })
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
