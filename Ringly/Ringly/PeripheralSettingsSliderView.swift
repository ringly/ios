import UIKit

/// An individual peripheral settings slider, with all associated labels.
final class PeripheralSettingsSliderView: UIView
{
    // MARK: - Subviews

    /// The slider contained in this view.
    let slider: UISlider = PeripheralSettingsSlider.newAutoLayout()

    /// The title label - content of this view is controlled via `title`.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    // MARK: - Title

    /// The title displayed by the view.
    var title: String?
    {
        get { return titleLabel.attributedText?.string }
        set { titleLabel.attributedText = newValue.map({ font.track(250, $0).attributedString }) }
    }

    /// The font used for the view's labels.
    fileprivate let font = UIFont.gothamBook(12)

    // MARK: - Initialization
    fileprivate func setup()
    {
        slider.maximumTrackTintColor = UIColor(red: 0.4723, green: 0.4606, blue: 0.5708, alpha: 1.0)
        slider.minimumTrackTintColor = UIColor(red: 0.4723, green: 0.4606, blue: 0.5708, alpha: 1.0)
        addSubview(slider)

        titleLabel.textColor = .white
        addSubview(titleLabel)

        let offLabel = UILabel.newAutoLayout()
        offLabel.textColor = .white
        offLabel.attributedText = font.track(250, "OFF").attributedString
        addSubview(offLabel)

        let highLabel = UILabel.newAutoLayout()
        highLabel.textColor = .white
        highLabel.attributedText = font.track(250, "HIGH").attributedString
        addSubview(highLabel)

        // position title label in the top center
        titleLabel.autoPinEdgeToSuperview(edge: .top)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical)

        // position labels on the sides
        offLabel.autoMatch(dimension: .width, to: .width, of: highLabel)
        offLabel.autoPinEdgeToSuperview(edge: .leading)
        highLabel.autoPinEdgeToSuperview(edge: .trailing)

        offLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        highLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        offLabel.autoConstrain(attribute: .baseline, to: .baseline, of: highLabel)

        // position slider in the center
        slider.autoAlignAxis(toSuperviewAxis: .vertical)
        slider.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20)
        slider.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        slider.autoPin(edge: .leading, to: .trailing, of: offLabel, offset: 16)
        slider.autoPin(edge: .trailing, to: .leading, of: highLabel, offset: -16)

        // offset makes up for modified rect
        slider.autoAlign(axis: .horizontal, toSameAxisOf: offLabel)
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

/// Provides a custom track rect to match the height in the designs.
private final class PeripheralSettingsSlider: UISlider
{
    fileprivate override func trackRect(forBounds bounds: CGRect) -> CGRect
    {
        return CGRect(
            x: 0,
            y: bounds.midY - 3,
            width: bounds.size.width,
            height: 6
        )
    }
}
