import PureLayout
import ReactiveSwift
import RinglyKit
import UIKit

protocol VibrationChooserViewDelegate: class
{
    /**
     Notifies the delegate that the vibration chooser view has requested expansion (the user has tapped on the closed
     selected vibration icon).
     
     -parameter vibrationChooserView: The vibration chooser view.
     */
    func vibrationChooserViewRequestedExpansion(_ vibrationChooserView: VibrationChooserView)
    
    /**
     Notifies the user that the vibration chooser view has selected a vibration while expanded.
     
     -parameter vibrationChooserView: The vibration chooser view.
     -parameter vibration:            The selected vibration.
     */
    func vibrationChooserView(_ vibrationChooserView: VibrationChooserView, selectedVibration vibration: RLYVibration)
}

private let buttonParameters: [(vibration: RLYVibration, asset: Asset)] = [
    (vibration: .none, asset: .vibrations0),
    (vibration: .onePulse, asset: .vibrations1),
    (vibration: .twoPulses, asset: .vibrations2),
    (vibration: .threePulses, asset: .vibrations3),
    (vibration: .fourPulses, asset: .vibrations4)
]

final class VibrationChooserView: UIView
{
    // MARK: - Properties
    
    /// Whether or not the chooser view is expanded.
    let expanded = MutableProperty(false)
    
    /// The current selected vibration value.
    let selectedVibration = MutableProperty(RLYVibration.none)
    
    /// The chooser view's delegate.
    weak var delegate: VibrationChooserViewDelegate?

    /// The buttons used by the chooser view.
    fileprivate let buttons: [UIButton] = buttonParameters.map({ _, asset in
        let button = UIButton()
        button.setImage(UIImage(asset: asset), for: UIControlState())
        button.showsTouchWhenHighlighted = true
        return button
    })

    fileprivate let backgrounds = (0..<buttonParameters.count).map({ index -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.alpha = 0.2 + 0.1 * CGFloat(index)
        return view
    })

    // MARK: - Initialization
    fileprivate func setup()
    {
        let backgrounds = self.backgrounds

        // add actions to buttons
        let buttonVibrations = zip(buttons, buttonParameters.map({ $0.vibration }))

        let buttonVibrationProducers = buttonVibrations.map({ button, vibration in
            SignalProducer(button.reactive.controlEvents(.touchUpInside)).map({ _ in vibration })
        })

        SignalProducer.merge(buttonVibrationProducers).startWithValues({ [weak self] vibration in
            guard let strongSelf = self else { return }

            if strongSelf.expanded.value
            {
                strongSelf.delegate?.vibrationChooserView(strongSelf, selectedVibration: vibration)
                strongSelf.selectedVibration.value = vibration
            }
            else
            {
                strongSelf.delegate?.vibrationChooserViewRequestedExpansion(strongSelf)
            }
        })

        buttonVibrations.forEach({ button, vibration in
            selectedVibration.producer
                .combineLatest(with: expanded.producer)
                .startWithValues({ selected, expanded in
                    let show = selected == vibration || expanded
                    button.alpha = show ? 1 : 0
                    button.isUserInteractionEnabled = show

                    button.accessibilityLabel = expanded
                        ? RLYVibrationToString(vibration)
                        : (selected == vibration ? "Edit Vibration" : nil)
                })
        })
        
        // add subviews
        backgrounds.forEach(addSubview)
        buttons.forEach(addSubview)

        expanded.producer.startWithValues({ [weak self] expanded in
            self?.setNeedsLayout()
            backgrounds.last?.alpha = 0.2 + 0.1 * CGFloat(expanded ? backgrounds.count - 1 : 0)
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        if expanded.value
        {
            return super.point(inside: point, with: event)
        }
        else
        {
            let converted = buttons[0].convert(point, from: self)
            return super.point(inside: point, with: event) && buttons[0].point(inside: converted, with: event)
        }
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        var frame = bounds
        frame.size.width /= CGFloat(buttons.count)

        if expanded.value
        {
            zip(buttons, backgrounds).enumerated().forEach({ index, views in
                let adjusted = frame.offsetBy(dx: CGFloat(index) * frame.size.width, dy: 0)
                views.0.frame = adjusted
                views.1.frame = adjusted
            })
        }
        else
        {
            let adjusted = frame.offsetBy(dx: CGFloat(buttons.count - 1) * frame.size.width, dy: 0)

            buttons.forEach({ $0.frame = adjusted })
            backgrounds.last?.frame = adjusted

            let collapsedFrame = CGRect(origin: adjusted.origin, size: CGSize(width: 0, height: frame.size.height))
            backgrounds.dropLast().forEach({ $0.frame = collapsedFrame })
        }
    }
}
