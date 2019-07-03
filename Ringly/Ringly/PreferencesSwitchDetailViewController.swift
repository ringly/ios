import ReactiveSwift
import UIKit
import enum Result.NoError

final class PreferencesSwitchDetailViewController: UIViewController
{
    // MARK: - Displayed Switch

    /// The switch displayed by this view controller.
    let preferencesSwitch = MutableProperty(PreferencesSwitch?.none)

    // MARK: - Subviews

    /// The label displaying an icon describing the preferences setting.
    fileprivate let iconView = UIImageView.newAutoLayout()

    /// The label displaying the title of the preferences setting.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The label displaying a detailed description of the preferences setting.
    fileprivate let informationLabel = UILabel.newAutoLayout()

    /// The switch to control the selected preference.
    let switchControl = UISwitch.newAutoLayout()

    /// A button to close the detail overlay interface.
    fileprivate let closeButton = UIButton.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add the card view, which will contain the main information displayed
        let card = UIView.newAutoLayout()
        card.backgroundColor = .white
        card.layer.shadowRadius = 5
        card.layer.shadowOpacity = 0.25
        card.layer.shadowOffset = .zero
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.borderColor = UIColor.black.cgColor
        card.layer.borderWidth = 0.5
        view.addSubview(card)

        // image formatting
        iconView.tintColor = .black

        // label formatting
        titleLabel.numberOfLines = 0
        informationLabel.numberOfLines = 0

        // use default ringly green color as "on" fill color
        switchControl.onTintColor = UIColor.ringlyGreen

        // close button formatting (temporary!)
        closeButton.setImage(UIImage(asset: .alertClose), for: UIControlState())
        closeButton.setBackgroundImage(UIImage.rly_pixel(with: UIColor(white: 0.8, alpha: 1.0)), for: .normal)
        closeButton.autoSetDimensions(to: CGSize(width: 44, height: 44))
        closeButton.layer.cornerRadius = 22
        closeButton.layer.masksToBounds = true

        // add all components to the card view
        let components = [iconView, titleLabel, informationLabel, switchControl, closeButton]
        components.forEach(card.addSubview)

        // center the card view within the container
        card.autoSetDimensions(to: CGSize(width: 300, height: 450))
        card.autoFloatInSuperview()

        // align components horizontally
        components.forEach({ $0.autoFloatInSuperview(alignedTo: .vertical, inset: 20) })

        // stack contents vertically
        iconView.autoPinEdgeToSuperview(edge: .top, inset: 20)
        titleLabel.autoPin(edge: .top, to: .bottom, of: iconView, offset: 20)
        informationLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20)
        switchControl.autoPin(edge: .top, to: .bottom, of: informationLabel, offset: 20, relation: .greaterThanOrEqual)
        closeButton.autoPin(edge: .top, to: .bottom, of: switchControl, offset: 20)
        closeButton.autoPinEdgeToSuperview(edge: .bottom, inset: 20)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // bind label content to the current preference
        preferencesSwitch.producer
            .mapOptional({ preferencesSwitch in
                UIFont.gothamBook(18).track(250, preferencesSwitch.title)
                    .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))
            })
            .startWithValues({ [weak titleLabel] in titleLabel?.attributedText = $0 })

        preferencesSwitch.producer
            .mapOptional({ preferencesSwitch in
                UIFont.gothamBook(12).track(150, preferencesSwitch.information)
                    .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))
            })
            .startWithValues({ [weak informationLabel] in informationLabel?.attributedText = $0 })

        // bind image content
        preferencesSwitch.producer
            .mapOptionalFlat({ $0.iconImage?.withRenderingMode(.alwaysTemplate) })
            .startWithValues({ [weak iconView] in iconView?.image = $0 })
    }

    /// A producer that yields a value when the user has requested that the card overlay be closed.
    var closeProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(closeButton.reactive.controlEvents(.touchUpInside)).void
    }
}
