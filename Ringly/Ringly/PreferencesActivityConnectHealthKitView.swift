import UIKit

final class PreferencesActivityConnectHealthKitView: UIView
{
    // MARK: - Control
    let control = ButtonControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add label to the top of the view
        let label = UILabel.newAutoLayout()
        label.attributedText = "Get the most out of Activity by connecting to the Health app."
            .preferencesBodyAttributedString
        label.textColor = .white
        label.numberOfLines = 0

        addSubview(label)

        label.autoPinEdgeToSuperview(edge: .top)
        label.autoFloatInSuperview(alignedTo: .vertical)
        label.autoSet(dimension: .width, to: 270, relation: .lessThanOrEqual)

        // add control to the bottom of the view
        control.title = "CONNECT"
        addSubview(control)

        control.autoPin(edge: .top, to: .bottom, of: label, offset: 27)
        control.autoPinEdgeToSuperview(edge: .bottom)
        control.autoFloatInSuperview(alignedTo: .vertical)
        control.autoSetDimensions(to: CGSize(width: 246, height: 46))
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
