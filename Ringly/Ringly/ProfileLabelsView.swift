import ReactiveSwift
import RinglyAPI
import UIKit

/// A view displaying the name and email address, as is applicable, for a user.
final class ProfileLabelsView: UIView
{
    // MARK: - User

    /// The user displayed by this view.
    let user = MutableProperty(User?.none)

    /// An implementation detail of `setup`.
    fileprivate let labelTexts = MutableProperty((name: NSAttributedString?, email: NSAttributedString)?.none)

    /// The current text to display in `name`.
    fileprivate let nameText = MutableProperty(NSAttributedString?.none)

    /// The current text to display in `email`.
    fileprivate let emailText = MutableProperty(NSAttributedString?.none)

    // MARK: - Labels

    /// The label displaying the user's name.
    fileprivate let name = UILabel.newAutoLayout()

    /// The label displaying the user's email address.
    fileprivate let email = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add labels and perform layout
        [name, email].forEach({ label in
            label.textColor = .white
            label.textAlignment = .center
            addSubview(label)
            label.autoFloatInSuperview(alignedTo: .vertical)
        })

        name.autoPinEdgeToSuperview(edge: .top)
        name.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        email.autoPin(edge: .top, to: .bottom, of: name, offset: 5)

        // this constraint will be disabled if the email label is invisible
        let emailToBottom = email.autoPinEdgeToSuperview(edge: .bottom)

        // determine what text to use for which label - we prefer using the name text for the name label, of course, but
        // if there is no name text, we will use the email label for the name label, and leave the email label empty.
        let nameFont = UIFont.gothamBook(15)
        let emailFont = UIFont.gothamBook(12)

        labelTexts <~ user.producer.mapOptional({ user in
            (
                name: user.name.map({ nameFont.track(250, $0.uppercased()).attributedString }),
                email: emailFont.track(250, user.email).attributedString
            )
        })

        nameText <~ labelTexts.producer.mapOptional({ maybeName, email in maybeName ?? email })
        emailText <~ labelTexts.producer.mapOptionalFlat({ maybeName, email in maybeName != nil ? email : nil })

        // bind the text content to labels
        nameText.producer.startWithValues({ [weak name] in name?.attributedText = $0 })
        emailText.producer.startWithValues({ [weak email] text in
            emailToBottom.isActive = text != nil
            email?.attributedText = text
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
