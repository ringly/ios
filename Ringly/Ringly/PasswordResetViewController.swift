import PureLayout
import ReactiveSwift
import Result
import RinglyAPI
import UIKit

/// Allows the user to reset the password for an email address.
final class PasswordResetViewController: ServicesViewController
{
    // MARK: - Token
    let tokenString = MutableProperty(String?.none)

    // MARK: - Views
    fileprivate let form = PasswordResetForm.newAutoLayout()

    // MARK: - State

    /// An enumeration of the possible view controller states.
    fileprivate enum State
    {
        case passwordEntry, requesting, completed
    }

    /// The current state of the view controller.
    fileprivate let state = MutableProperty(State.passwordEntry)

    // MARK: - Callbacks

    /// Sent when the password reset process completes.
    var completed: ((PasswordResetViewController) -> ())?

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add outer content containers
        let contentView = UIView.newAutoLayout()
        view.addSubview(contentView)

        // form content
        form.password.field.delegate = self
        contentView.addSubview(form)

        // layout for outer containers
        contentView.autoPinEdgesToSuperviewEdges(insets: 
            UIEdgeInsets(top: AuthenticationNavigationController.topMargin, left: 0, bottom: 0, right: 0)
        )

        form.autoPinEdgeToSuperview(edge: .top, inset: 43)
        form.autoPinEdgeToSuperview(edge: .leading)
        form.autoPinEdgeToSuperview(edge: .trailing)

        // ensure the the form container isn't under the keyboard
        let formContainerBottom = form.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)

        services.keyboard.animationProducer.startWithValues({ frame in
            formContainerBottom.constant = -frame.size.height - 10
        })

        // activity indicator
        let activity = DiamondActivityIndicator.newAutoLayout()
        view.addSubview(activity)
        activity.autoCenterInSuperview()
        activity.constrainToDefaultSize()

        // hide field content when not editing
        state.producer.equals(.passwordEntry)
            .skipRepeats()
            .start(animationDuration: 0.25, action: { [weak self] visible in
                self?.form.alpha = visible ? 1 : 0
                self?.form.isUserInteractionEnabled = visible
                activity.alpha = visible ? 0 : 1

                if visible
                {
                    self?.form.password.field.becomeFirstResponder()
                }
                else
                {
                    self?.form.password.endEditing(true)
                }
            })

        // update verification appearance
        let isValid = form.password.field.reactive.allTextValues
            .map({ maybePassword in (maybePassword?.characters.count)! > 7 })

        isValid.start(animationDuration: 0.25, action: { [weak self] verified in
            self?.form.verification.verified = verified
            self?.form.verification.layoutIfInWindowAndNeeded()
        })

        isValid.startCrossDissolve(in: form.submitButton, duration: 0.25, action: { [weak self] isValid in
            self?.form.submitButton.textColor = isValid
                ? UIColor.authenticationButtonValid
                : UIColor.authenticationButtonInvalid
        })
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let api = services.api

        // submit password recovery
        form.password.field.reactive.allTextValues.combineLatest(with: tokenString.producer)
            .sample(on: SignalProducer(form.submitButton.reactive.controlEvents(.touchUpInside)).void)
            .map({ [weak self] maybePassword, maybeTokenString -> SignalProducer<(), NSError>? in
                guard let password = maybePassword, let tokenString = maybeTokenString, password.characters.count > 7
                else {
                    self?.form.password.rly_wiggleForFormRejection()
                    return nil
                }

                // request the email address, then reset the password, then log in
                return api.resultProducer(for: RESTGetRequest<ResetToken>(identifier: tokenString))
                    .flatMap(.latest, transform: { token in
                        api.producer(for: PasswordResetRequest(resetToken: token, password: password)).then(
                            api.authenticateProducer(
                                email: token.email,
                                password: password,
                                device: UIDevice.current
                            )
                        )
                    })
                    .observe(on: QueueScheduler.main)
                    .ignoreValues()
            })
            .flatMapOptional(.latest, transform: { [weak self] producer -> SignalProducer<(), NoError> in
                producer
                    // update state when requests start and complete
                    .on(
                        started: { [weak self] in self?.state.value = .requesting },
                        completed: { [weak self] in self?.state.value = .completed }
                    )

                    // if the requests fail, show an error alert, then return to editing
                    .flatMapError({ [weak self] error in
                        self?.presentErrorProducer(error, closeButtonTitle: tr(.gotIt))
                            .on(completed: { [weak self] in self?.state.value = .passwordEntry })
                            ?? SignalProducer.empty
                    })
            })
            .start()

        state.producer.await(.completed).startWithCompleted({ [weak self] in
            guard let strong = self else { return }
            strong.completed?(strong)
        })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        DispatchQueue.main.async(execute: { [weak self] in
            self?.form.password.field.becomeFirstResponder()
        })
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        form.password.field.resignFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        services.analytics.track(AnalyticsEvent.viewedScreen(name: .resetPassword))
    }
}

extension PasswordResetViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == form.password.field
        {
            form.submitButton.sendActions(for: .touchUpInside)
        }

        return false
    }
}

private final class PasswordResetForm: UIView
{
    let password = BorderedField.newAutoLayout()
    let submitButton = ButtonControl.newAutoLayout()
    let verification = RuleVerificationView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        let formTitle = UILabel.newAutoLayout()
        formTitle.numberOfLines = 0
        formTitle.textColor = UIColor.white
        formTitle.attributedText = "ENTER A NEW\nPASSWORD".attributes(
            font: .gothamBook(18),
            paragraphStyle: .with(alignment: .center, lineSpacing: 5),
            tracking: 300
        )
        addSubview(formTitle)

        let fieldContainer = UIView.newAutoLayout()
        addSubview(fieldContainer)

        password.formatForAuthenticationPasswordInput()
        fieldContainer.addSubview(password)

        verification.text = "8 or more characters"
        fieldContainer.addSubview(verification)

        submitButton.title = "Login"
        addSubview(submitButton)

        // layout
        formTitle.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        formTitle.autoPinEdgeToSuperview(edge: .top)
        formTitle.autoAlignAxis(toSuperviewAxis: .vertical)

        submitButton.autoAlignAxis(toSuperviewAxis: .vertical)
        submitButton.autoSetDimensions(to: CGSize(width: 256, height: 50))
        submitButton.autoPinEdgeToSuperview(edge: .bottom)

        fieldContainer.autoPinEdgeToSuperview(edge: .leading, inset: 12)
        fieldContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 12)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            fieldContainer.autoPin(edge: .top, to: .bottom, of: formTitle, offset: 64)
            fieldContainer.autoPin(edge: .bottom, to: .top, of: self.submitButton, offset: -40)
        })

        fieldContainer.autoPin(edge: .top, to: .bottom, of: formTitle, offset: 10, relation: .greaterThanOrEqual)
        fieldContainer.autoPin(edge: .bottom, to: .top, of: submitButton, offset: -10, relation: .lessThanOrEqual)

        password.autoPinEdgeToSuperview(edge: .top)
        password.autoPinEdgeToSuperview(edge: .leading)
        password.autoPinEdgeToSuperview(edge: .trailing)

        verification.autoPin(edge: .top, to: .bottom, of: password, offset: 9)
        verification.autoPinEdgeToSuperview(edge: .bottom)
        verification.autoAlignAxis(toSuperviewAxis: .vertical)
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
