import ReactiveSwift
import UIKit

final class BorderedField: UIView
{
    // MARK: - Subviews
    let icon = UIImageView.newAutoLayout()
    let field = UITextField.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // changes the insertion caret color to white
        tintColor = UIColor.white

        // container setup
        let upperContainer = UIView.newAutoLayout()
        addSubview(upperContainer)

        let separator = UIView.newAutoLayout()
        separator.backgroundColor = UIColor.white
        addSubview(separator)

        // container layout
        upperContainer.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        upperContainer.autoSet(dimension: .height, to: 41, relation: .greaterThanOrEqual)

        separator.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        separator.autoPin(edge: .top, to: .bottom, of: upperContainer)
        separator.autoSet(dimension: .height, to: 1)

        // contents setup
        upperContainer.addSubview(icon)

        field.font = UIFont.gothamBook(14)
        field.textColor = UIColor.white
        field.rightViewMode = .always
        upperContainer.addSubview(field)

        if let image = UIImage(asset: .textFieldClear)
        {
            let clearButton = UIButton()
            clearButton.setImage(image, for: UIControlState())
            clearButton.isHidden = true
            clearButton.accessibilityLabel = "Clear"

            clearButton.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
                self?.field.text = ""
            })

            field.rightView = clearButton
            clearButton.autoSetDimensions(to: image.size)
        }

        // contents layout
        icon.autoPinEdgeToSuperview(edge: .leading, inset: 5)
        icon.autoAlignAxis(toSuperviewAxis: .horizontal)

        field.autoPinEdgeToSuperview(edge: .leading, inset: 55)
        field.autoPinEdgeToSuperview(edge: .trailing)
        field.autoPinEdgeToSuperview(edge: .top)
        field.autoPinEdgeToSuperview(edge: .bottom)

        // fields cannot be collapsed vertically, it would look VERY bad
        setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        // this is a workaround for buggy .WhileEditing behavior
        let center = NotificationCenter.default

        let forceHidden = Signal.merge(
            center.reactive.notifications(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: field)
                .map({ _ in false }),
            center.reactive.notifications(forName: Notification.Name.UITextFieldTextDidEndEditing, object: field)
                .map({ _ in true })
        )

        SignalProducer(forceHidden).combineLatest(with: field.reactive.allTextValues)
            .map({ force, text in force || text?.characters.count ?? 0 == 0 })
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak field] mode in
                guard let strongField = field else { return }
                strongField.rightView?.isHidden = mode
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
}

extension String
{
    var attributedBorderedFieldPlaceholder: NSAttributedString
    {
        return UIFont.gothamBook(14).track(.controlsTracking, uppercased()).attributes(color: .white)
    }
}

extension BorderedField
{
    fileprivate func applySharedAuthenticationFormatting()
    {
        field.defaultTextAttributes = [
            NSFontAttributeName: UIFont.gothamBook(14),
            NSForegroundColorAttributeName: UIColor.white,
            NSKernAttributeName: 2.8,
            NSLigatureAttributeName: 0
        ]
    }

    func formatForNameInput()
    {
        applySharedAuthenticationFormatting()
        field.attributedPlaceholder = "Name".attributedBorderedFieldPlaceholder
        field.autocapitalizationType = .words
        field.autocorrectionType = .no
        field.returnKeyType = .next
        icon.image = UIImage(asset: .authenticationEmail)
    }

    func formatForAuthenticationEmailInput()
    {
        applySharedAuthenticationFormatting()
        field.attributedPlaceholder = "Email Address".attributedBorderedFieldPlaceholder
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
        field.returnKeyType = .next
        icon.image = UIImage(asset: .authenticationEmail)
    }

    func formatForAuthenticationPasswordInput()
    {
        applySharedAuthenticationFormatting()
        field.attributedPlaceholder = "Password".attributedBorderedFieldPlaceholder
        field.isSecureTextEntry = true
        field.returnKeyType = .go
        icon.image = UIImage(asset: .authenticationLock)
    }
}
