import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

final class SettingsSwitchView: UIView, SwitchProtocol
{
    // MARK: - Subviews
    
    /// The on/off switch view.
    fileprivate let onOffView = SettingsSwitchOnOffView.newAutoLayout()
    
    /// The label displaying the switch's title.
    fileprivate let titleLabel = UILabel.newAutoLayout()
    
    // MARK: - Content
    
    /// The title of the switch.
    var title: String?
        {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                text.attributes(
                    font: .gothamBook(15),
                    paragraphStyle: .with(alignment: .left, lineSpacing: 3),
                    tracking: 150
                )
            })
        }
    }
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        
        // center all elements vertically in this view
        [onOffView, titleLabel].forEach({ view in
            addSubview(view)
            view.autoFloatInSuperview(alignedTo: .horizontal)
        })
        
        // title label fixed size
        titleLabel.autoSet(dimension: .width, to: 190)
        
        onOffView.autoPinEdgeToSuperview(edge: .trailing)

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

final class SettingsSwitchOnOffView: UIView
{
    // MARK: - Subviews
    let switchControl = UISwitch.newAutoLayout()
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        switchControl.tintColor = UIColor.ringlyLightBlack.withAlphaComponent(0.2)
        switchControl.onTintColor = UIColor.ringlyLightBlack.withAlphaComponent(0.2)
        

        addSubview(switchControl)
        switchControl.autoFloatInSuperview()
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
    
    // MARK: - Switch Protocol
    func setOn(_ on: Bool, animated: Bool)
    {
        switchControl.setOn(on, animated: animated)
    }
    
    var isOn: Bool { return switchControl.isOn }
}

