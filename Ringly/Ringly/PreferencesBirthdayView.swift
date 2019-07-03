import ReactiveSwift
import UIKit
import enum Result.NoError

final class PreferencesBirthdayView: UIView
{
    // MARK: - Data
    let birthday = MutableProperty(DateComponents?.none)

    // MARK: - Subviews

    /// An add control, displayed when a birthday has not been set.
    fileprivate let addControl = PreferencesActivityAddControl.newAutoLayout()

    /// Labels, displayed when we have a birthday.
    fileprivate let labelsButton = PreferencesBirthdayLabelsButton.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(labelsButton)
        labelsButton.autoFloatInSuperview(alignedTo: .vertical)
        labelsButton.autoPinEdgeToSuperview(edge: .top)
        let labelsToBottom = labelsButton.autoPinEdgeToSuperview(edge: .bottom)

        // add control, displayed when we do not have a birthday
        addControl.title = "AGE"
        addSubview(addControl)
        addControl.autoFloatInSuperview(alignedTo: .vertical)
        addControl.autoPinEdgeToSuperview(edge: .top)
        let addControlToBottom = addControl.autoPinEdgeToSuperview(edge: .bottom)

        // update content when birthday is set
        let formatter = DateFormatter(localizedFormatTemplate: "MMMMd")

        birthday.producer.startWithValues({ [weak self] optionalComponents in
            NSLayoutConstraint.conditionallyActivateConstraints([
                (addControlToBottom, optionalComponents == nil),
                (labelsToBottom, optionalComponents != nil )
            ])

            self?.labelsButton.isHidden = optionalComponents == nil
            self?.addControl.isHidden = optionalComponents != nil

            self?.labelsButton.birthday.attributedText = optionalComponents
                .flatMap({ components in
                    (components.calendar ?? Calendar.current).date(from: components)
                })
                .map({ date in
                    UIFont.gothamBook(18)
                        .track(250, formatter.string(from: date).uppercased()).attributedString
                })
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

    // MARK: - Actions

    /// A signal producer that sends a value when the user taps a control to edit her birthday.
    var editTappedProducer: SignalProducer<(), NoError>
    {
        return SignalProducer.merge(
            SignalProducer(addControl.reactive.controlEvents(.touchUpInside)).void,
            SignalProducer(labelsButton.reactive.controlEvents(.touchUpInside)).void
        )
    }
}

private final class PreferencesBirthdayLabelsButton: UIButton
{
    // MARK: - Subviews
    fileprivate let title = UILabel.newAutoLayout()
    fileprivate let birthday = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        showsTouchWhenHighlighted = true

        title.isUserInteractionEnabled = false
        title.textColor = .white
        title.attributedText = "BIRTHDAY".preferencesActivityControlTitleString
        addSubview(title)

        birthday.isUserInteractionEnabled = false
        birthday.textColor = .white
        addSubview(birthday)

        title.autoPinEdgeToSuperview(edge: .top)
        title.autoFloatInSuperview(alignedTo: .vertical)

        birthday.autoPin(edge: .top, to: .bottom, of: title, offset: 30)
        birthday.autoPinEdgeToSuperview(edge: .bottom)
        birthday.autoFloatInSuperview(alignedTo: .vertical)
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
