import ReactiveSwift
import UIKit
import enum Result.NoError

/// A view that displays two buttons - an action button and a dismiss button. Displayed at the bottom of two-choice
/// alerts.
final class AlertControlPad: UIView
{
    // MARK: - Appearance
    var normalColor: UIColor
    {
        get { return actionButton.fillColor }
        set
        {
            actionButton.fillColor = newValue
            updateDismissTitle(dismissTitle)
        }
    }

    var highlightedColor: UIColor
    {
        get { return actionButton.highlightedFillColor }
        set
        {
            actionButton.highlightedFillColor = newValue
            updateDismissTitle(dismissTitle)
        }
    }

    @nonobjc func useDarkAppearance()
    {
        normalColor = UIColor(white: 0.2, alpha: 1.0)
        highlightedColor = .black
    }

    // MARK: - Titles
    var actionTitle: String?
    {
        get { return actionButton.title }
        set { actionButton.title = newValue }
    }

    var dismissTitle: String?
    {
        get { return dismissButton.attributedTitle(for: UIControlState())?.string }
        set { updateDismissTitle(newValue?.uppercased()) }
    }

    fileprivate func updateDismissTitle(_ title: String?)
    {
        let font = UIFont.gothamMedium(12)

        func style(_ color: UIColor) -> (String) -> NSAttributedString
        {
            return { $0.attributes(color: color, font: font, tracking: .buttonTracking) }
        }

        dismissButton.setAttributedTitle(title.map(style(normalColor)), for: .normal)
        dismissButton.setAttributedTitle(title.map(style(highlightedColor)), for: .highlighted)
    }

    // MARK: - Button Producers
    var actionProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(actionButton.reactive.controlEvents(.touchUpInside)).void
    }

    var dismissProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(dismissButton.reactive.controlEvents(.touchUpInside)).void
    }

    // MARK: - Buttons
    fileprivate let actionButton = ButtonControl.newAutoLayout()
    fileprivate let dismissButton = UIButton.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        actionButton.font = UIFont.gothamMedium(12)
        addSubview(actionButton)

        actionButton.autoSet(dimension: .height, to: 44)
        actionButton.autoPinEdgesToSuperviewEdges(excluding: .bottom)

        addSubview(dismissButton)
        dismissButton.autoSet(dimension: .height, to: 44)
        dismissButton.autoPinEdgesToSuperviewEdges(excluding: .top)
        dismissButton.autoPin(edge: .top, to: .bottom, of: actionButton, offset: 8)
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
