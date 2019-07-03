import UIKit

final class TopbarView: UIView
{
    // MARK: - Content
    var title: String? = nil
    {
        didSet
        {
            guard let title = self.title?.uppercased() else {
                titleLabel.text = nil
                return
            }

            let font = UIFont.gothamBook(15)
            titleLabel.attributedText = font.track(.controlsTracking, title).attributedString
        }
    }

    // MARK: - Subviews

    /// The title label.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The control on the leading edge of the view, typically used for navigation.
    let leadingControl = TopbarControl.newAutoLayout()

    /// The control on the trailing edge of the view, typically used for an action.
    let trailingControl = TopbarControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = UIColor.black

        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ringlyTextHighlight
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)

        addSubview(leadingControl)
        addSubview(trailingControl)

        // ensure that controls are at least as wide as they are tall
        leadingControl.autoMatch(
            dimension: .width,
            to: .height,
            of: leadingControl,
            offset: 0,
            relation: .greaterThanOrEqual
        )

        trailingControl.autoMatch(
            dimension: .width,
            to: .height,
            of: trailingControl,
            offset: 0,
            relation: .greaterThanOrEqual
        )

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            self.leadingControl.autoMatch(
                dimension: .width,
                to: .height,
                of: self.leadingControl
            )

            self.trailingControl.autoMatch(
                dimension: .width,
                to: .height,
                of: self.trailingControl
            )
        })

        // pin controls to edges
        leadingControl.autoPinEdgeToSuperview(edge: .leading)
        leadingControl.autoPinEdgeToSuperview(edge: .top)
        leadingControl.autoPinEdgeToSuperview(edge: .bottom)

        trailingControl.autoPinEdgeToSuperview(edge: .trailing)
        trailingControl.autoPinEdgeToSuperview(edge: .top)
        trailingControl.autoPinEdgeToSuperview(edge: .bottom)

        // setup title label inside buttons and centered
        titleLabel.autoPin(edge: 
            .leading,
            to: .trailing,
            of: leadingControl,
            offset: 10,
            relation: .greaterThanOrEqual
        )

        titleLabel.autoPin(edge: 
            .trailing,
            to: .leading,
            of: trailingControl,
            offset: -10,
            relation: .lessThanOrEqual
        )

        titleLabel.autoCenterInSuperview()
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
