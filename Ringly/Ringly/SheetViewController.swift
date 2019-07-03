import ReactiveSwift
import UIKit

/// Displays a popover sheet interface, with a number of actions that can be set by the client.
final class SheetViewController: UIViewController
{
    // MARK: - Initialization
    init()
    {
        super.init(nibName: nil, bundle: nil)

        // set presentation and transition style
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)

        // set presentation and transition style
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    // MARK: - View Loading
    override func loadView()
    {
        super.loadView()

        let cornerRadius: CGFloat = 4
        let borderWidth: CGFloat = 2
        let borderColor = UIColor(white: 0.8668, alpha: 1.0)

        // add blurry background
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.addSubview(blur)

        // add shadow view
        let shadow = RinglyAlertShadowView.newAutoLayout()
        shadow.shadowSize = CGSize(width: 10, height: 10)
        shadow.radius = cornerRadius
        shadow.color = UIColor(white: 0, alpha: 0.1)
        blur.contentView.addSubview(shadow)

        // add center container for action buttons
        let container = UIView.newAutoLayout()
        container.backgroundColor = UIColor.white
        container.clipsToBounds = true
        container.layer.cornerRadius = cornerRadius
        container.layer.borderWidth = borderWidth
        container.layer.borderColor = borderColor.cgColor
        blur.contentView.addSubview(container)

        // layout for container and shadow
        blur.autoPinEdgesToSuperviewEdges()

        shadow.autoPin(edge: .top, to: .top, of: container)
        shadow.autoPin(edge: .left, to: .left, of: container)
        shadow.autoPin(edge: .bottom, to: .bottom, of: container, offset: 10)
        shadow.autoPin(edge: .right, to: .right, of: container, offset: 10)

        container.autoSet(dimension: .width, to: 250)
        container.autoCenterInSuperview()

        // add motion drift effect
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)

        for effect in [horizontal, vertical]
        {
            effect.minimumRelativeValue = -25
            effect.maximumRelativeValue = 25

            shadow.addMotionEffect(effect)
            container.addMotionEffect(effect)
        }

        // add and remove buttons for actions
        func actionText(_ text: String) -> NSAttributedString
        {
            return text.attributes(
                color: UIColor(red: 0.4204, green: 0.5713, blue: 0.8151, alpha: 1.0),
                font: .gothamBook(15),
                tracking: 300
            )
        }

        _actions.producer
            .map({ [weak self] actions -> [UIButton] in
                actions.map({ [weak self] action in
                    let button = UIButton.newAutoLayout()
                    button.setAttributedTitle(actionText(action.label), for: .normal)
                    button.setBackgroundImage(UIImage.rly_pixel(with: borderColor), for: .highlighted)

                    button.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
                        action.action()

                        if let strong = self
                        {
                            strong.actionTapped?(strong)
                        }
                    })

                    return button
                })
            })
            .map({ buttons -> ([UIButton], [UIView]) in
                return (
                    buttons,
                    (0..<(buttons.count - 1)).map({ _ in
                        let view = UIView.newAutoLayout()
                        view.backgroundColor = borderColor
                        return view
                    })
                )
            })
            .combinePrevious(([], []))
            .startWithValues({ previous, current in
                // remove all old views
                (previous.0 as [UIView] + previous.1).forEach({ view in view.removeFromSuperview() })

                // add new views
                (current.0 as [UIView] + current.1).forEach({ view in
                    container.addSubview(view)
                    view.autoPinEdgeToSuperview(edge: .leading)
                    view.autoPinEdgeToSuperview(edge: .trailing)
                })

                // pin top and bottom views to edges
                current.0.first?.autoPinEdgeToSuperview(edge: .top)
                current.0.last?.autoPinEdgeToSuperview(edge: .bottom)

                // pin buttons to separators below them
                zip(current.0, current.1).forEach({ button, separator in
                    button.autoPin(edge: .bottom, to: .top, of: separator)
                })

                // pin buttons to separators above them
                zip(current.0.dropFirst(), current.1).forEach({ button, separator in
                    button.autoPin(edge: .top, to: .bottom, of: separator)
                })

                // set heights for controls
                current.0.forEach({ button in button.autoSet(dimension: .height, to: 52) })
                current.1.forEach({ button in button.autoSet(dimension: .height, to: borderWidth) })
            })
    }

    // MARK: - Callbacks

    /// A callback sent when the user taps a button in the sheet.
    var actionTapped: ((SheetViewController) -> ())? = nil

    // MARK: - Actions

    /// A backing property for `actions`.
    fileprivate let _actions = MutableProperty([SheetAction]())

    /// The current actions displayed by the sheet view controller.
    var actions: [SheetAction]
    {
        get { return _actions.value }
        set { _actions.value = newValue }
    }
}

struct SheetAction
{
    /// The label text displayed by the sheet.
    let label: String

    /// The action to perform when the action is tapped.
    let action: () -> ()
}
