import Foundation

final class ProfileFieldsView: UIView
{
    // MARK: - Fields

    /// The bordered field displaying the user's name.
    fileprivate let nameBorderedField = BorderedField.newAutoLayout()

    /// The bordered field displaying the user's email address.
    fileprivate let emailBorderedField = BorderedField.newAutoLayout()

    /// The field displaying the user's name.
    var nameField: UITextField { return nameBorderedField.field }

    /// The field displaying the user's email address.
    var emailField: UITextField { return emailBorderedField.field }

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add placeholders to fields
        nameBorderedField.formatForNameInput()
        emailBorderedField.formatForAuthenticationEmailInput()

        // add the fields and pin to edges
        [nameBorderedField, emailBorderedField].forEach({ field in
            addSubview(field)
            field.autoPinEdgeToSuperview(edge: .leading)
            field.autoPinEdgeToSuperview(edge: .trailing)
        })

        // pin fields vertically
        nameBorderedField.autoPinEdgeToSuperview(edge: .top)
        emailBorderedField.autoPinEdgeToSuperview(edge: .bottom)
        emailBorderedField.autoPin(edge: .top, to: .bottom, of: nameBorderedField, offset: 20)
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
