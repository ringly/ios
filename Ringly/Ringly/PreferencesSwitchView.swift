import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

final class PreferencesSwitchView: UIView, SwitchProtocol
{
    // MARK: - Subviews

    /// The on/off switch view.
    fileprivate let onOffView = SwitchOnOffView.newAutoLayout()

    /// The label displaying the switch's title.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The button to tap to request more information about the preference.
    fileprivate let infoButton = UIButton.newAutoLayout()

    // MARK: - Content

    /// The title of the switch.
    var title: String?
    {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                text.attributes(
                    font: .gothamBook(12),
                    paragraphStyle: .with(alignment: .right, lineSpacing: 3),
                    tracking: 150
                )
            })
        }
    }

    // MARK: - Initialization
    fileprivate func setup()
    {
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        infoButton.clipsToBounds = true
        infoButton.setBackgroundImage(UIImage.rly_pixel(with: UIColor(white: 1, alpha: 0.8)), for: .normal)
        infoButton.setImage(UIImage(asset: .preferencesSwitchQuestion), for: UIControlState())
        infoButton.showsTouchWhenHighlighted = true

        let separator = UIView.newAutoLayout()
        separator.backgroundColor = UIColor(white: 1, alpha: 0.5)
        addSubview(separator)

        // center all elements vertically in this view
        [onOffView, titleLabel, infoButton].forEach({ view in
            addSubview(view)
            view.autoFloatInSuperview(alignedTo: .horizontal)
        })

        // title label fixed size
        titleLabel.autoSet(dimension: .width, to: 120)

        // separator fixed size (also defines view height)
        separator.autoSet(dimension: .width, to: 1)
        separator.autoSet(dimension: .height, to: 31, relation: .greaterThanOrEqual)
        separator.autoPinEdgeToSuperview(edge: .top)
        separator.autoPinEdgeToSuperview(edge: .bottom)

        // arrange elements with separator
        separator.autoPin(edge: .leading, to: .trailing, of: titleLabel, offset: 18)
        onOffView.autoPin(edge: .leading, to: .trailing, of: separator, offset: 12)

        // the info button has a fixed size
        infoButton.autoSetDimensions(to: CGSize(width: 30, height: 30))
        infoButton.autoPin(edge: .leading, to: .trailing, of: onOffView, offset: 22)
        infoButton.autoPinEdgeToSuperview(edge: .trailing)

        // set up horizontal arrangement of elements
        titleLabel.autoPinEdgeToSuperview(edge: .leading)
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

    // MARK: - Info Requests
    var infoRequestedProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(infoButton.reactive.controlEvents(.touchUpInside)).void
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        infoButton.layer.cornerRadius = infoButton.bounds.size.width / 2
    }

    // MARK: - Switch
    func setOn(_ on: Bool, animated: Bool)
    {
        onOffView.setOn(on, animated: animated)
    }

    var isOn: Bool { return onOffView.isOn }

    var valueChangedSignal: Signal<(), NoError>
    {
        return onOffView.switchControl.valueChangedSignal
    }
    
    var touchedSignal: Signal<(), NoError>
    {
        return onOffView.switchControl.touchedSignal
    }
}

final class SwitchOnOffView: UIView
{
    // MARK: - Subviews
    let switchControl = UISwitch.newAutoLayout()
    let onLabel = UILabel.newAutoLayout()
    let offLabel = UILabel.newAutoLayout()

    var textColor: UIColor?
    {
        get { return onLabel.textColor }
        set
        {
            onLabel.textColor = newValue
            offLabel.textColor = newValue
        }
    }

    // MARK: - Initialization
    fileprivate func setup()
    {
        switchControl.onTintColor = UIColor.ringlyGreen

        // on larger phones, add on/off labels to the switch
        if DeviceScreenHeight.current > .five
        {
            onLabel.textAlignment = .center
            onLabel.isUserInteractionEnabled = false
            onLabel.isAccessibilityElement = false

            offLabel.textAlignment = .center
            offLabel.isUserInteractionEnabled = false
            offLabel.isAccessibilityElement = false

            textColor = .white

            [switchControl, onLabel, offLabel].forEach({ view in
                addSubview(view)
                view.autoFloatInSuperview(alignedTo: .horizontal)
            })

            // set labels to fixed dimensions, since they'll be using different font weights and would resize
            offLabel.autoSet(dimension: .width, to: 45)
            onLabel.autoSet(dimension: .width, to: 38)

            offLabel.autoPinEdgeToSuperview(edge: .leading)
            switchControl.autoPin(edge: .leading, to: .trailing, of: offLabel)
            switchControl.autoPin(edge: .trailing, to: .leading, of: onLabel)
            onLabel.autoPinEdgeToSuperview(edge: .trailing)
        }
        else
        {
            addSubview(switchControl)
            switchControl.autoFloatInSuperview()
        }

        // animate labels when switch changes
        switchControl.reactive.controlEvents(.valueChanged).observeValues({ [weak self] _ in
            self?.updateLabelAppearance(animated: true)
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

    private func updateLabelAppearance(animated: Bool)
    {
        let current = switchControl.isOn

        func update(label: UILabel, text: String, preferred: Bool)
        {
            // see if this label matches the current state of the switch
            let matching = current == preferred

            // select the correct font and color to use
            let font = (matching ? UIFont.gothamBold : UIFont.gothamBook)(12)

            // update the text of the label
            label.attributedText = font.track(150, text).attributedString
        }

        let labels = [(onLabel, "ON", true), (offLabel, "OFF", false)]

        if animated
        {
            labels.forEach({ label, text, preferred in
                UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    update(label: label, text: text, preferred: preferred)
                }, completion: nil)
            })
        }
        else
        {
            labels.forEach(update)
        }
    }

    // MARK: - Switch Protocol
    func setOn(_ on: Bool, animated: Bool)
    {
        switchControl.setOn(on, animated: animated)
        updateLabelAppearance(animated: animated)
    }

    var isOn: Bool { return switchControl.isOn }
}
