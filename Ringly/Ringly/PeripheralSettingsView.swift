import Foundation
import ReactiveSwift
import enum Result.NoError

final class PeripheralSettingsView: UIView
{
    // MARK: - Subviews

    /// The subview displaying a brightness slider.
    fileprivate let brightnessView = PeripheralSettingsSliderView.newAutoLayout()

    /// The subview displaying a vibration slider.
    fileprivate let vibrationView = PeripheralSettingsSliderView.newAutoLayout()

    /// The view's brightness slider.
    var brightnessSlider: UISlider { return brightnessView.slider }

    /// The view's vibration slider.
    var vibrationSlider: UISlider { return vibrationView.slider }

    /// The view's remove control, which the user can use to request peripheral removal.
    fileprivate let removeControl = LinkControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        brightnessView.title = "BRIGHTNESS"
        addSubview(brightnessView)

        vibrationView.title = "VIBRATION"
        addSubview(vibrationView)

        removeControl.text.value = "REMOVE"
        addSubview(removeControl)

        brightnessView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)

        vibrationView.autoPin(edge: .top, to: .bottom, of: brightnessView, offset: 28)
        vibrationView.autoPinEdgeToSuperview(edge: .leading)
        vibrationView.autoPinEdgeToSuperview(edge: .trailing)

        removeControl.autoPin(edge: .top, to: .bottom, of: vibrationView, offset: 28)
        removeControl.autoPinEdgeToSuperview(edge: .bottom)
        removeControl.autoFloatInSuperview(alignedTo: .vertical)
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

    // MARK: - Actions

    /// A signal producer that will send a value when the user requests that a peripheral be removed.
    var removeProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(removeControl.reactive.controlEvents(.touchUpInside)).void
    }
}
