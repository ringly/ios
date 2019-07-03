import PureLayout
import ReactiveSwift
import Result
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


final class AuthenticationFieldsViewController: ServicesViewController
{
    // MARK: - Views
    fileprivate let form = AuthenticationForm.newAutoLayout()
    fileprivate let activity = DiamondActivityIndicator.newAutoLayout()
    fileprivate let scrollView = UIScrollView.newAutoLayout()

    // MARK: - State

    /// An enumeration of the possible view controller states.
    fileprivate enum State
    {
        case fieldEntry, requesting, completed
    }

    /// The current state of the view controller.
    fileprivate let state = MutableProperty(State.fieldEntry)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add content view
        let contentView = UIView.newAutoLayout()
        view.addSubview(contentView)

        let inset = AuthenticationNavigationController.topMargin
        contentView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0))

        // add activity indicator
        activity.alpha = 0
        contentView.addSubview(activity)
        activity.constrainToDefaultSize()
        activity.autoCenterInSuperview()

        // scroll view formatting
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(scrollView)

        // add center container
        let centerContainer = UIView.newAutoLayout()
        scrollView.addSubview(centerContainer)

        // add fields
        form.email.field.text = services.preferences.lastAuthenticatedEmail.value
        form.email.field.delegate = self
        form.password.field.delegate = self
        centerContainer.addSubview(form)

        // layout
        scrollView.autoPinEdgesToSuperviewEdges()

        // center container layout
        centerContainer.autoPinEdgeToSuperview(edge: .top)
        centerContainer.autoPin(edge: .leading, to: .leading, of: contentView)
        centerContainer.autoPin(edge: .trailing, to: .trailing, of: contentView)
        centerContainer.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)

        let formInset: CGFloat = UIScreen.main.deviceScreenHeight > .five ? 60 : 10
        form.autoAlign(axis: .vertical, toSameAxisOf: contentView)
        form.autoPin(edge: .leading, to: .leading, of: contentView, offset: 12)
        form.autoPin(edge: .trailing, to: .trailing, of: contentView, offset: -12)
        form.autoPinEdgeToSuperview(edge: .top, inset: formInset)
        form.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            self.form.autoAlignAxis(toSuperviewAxis: .horizontal)
        })

        // set conditional text display
        let isLogin = mode.producer.map({ mode in mode == .login }).skipRepeats()
        let isValid = SignalProducer.combineLatest(mode.producer, form.email.field.reactive.allTextValues, form.password.field.reactive.allTextValues)
            .map({ mode, email, password in
                AuthenticationFieldsViewController.stateIsValidForSubmission(mode, email: email, password: password)
            })
            .skipRepeats()

        isLogin.combineLatest(with: isValid)
            .startCrossDissolve(in: form.confirmControl, duration: 0.25, action: { [weak form] isLogin, isValid in
                form?.confirmControl.title = tr(isLogin ? .login : .signUp)
                form?.confirmControl.textColor = isValid
                    ? UIColor.authenticationButtonValid
                    : UIColor.authenticationButtonInvalid
            })

        isLogin.start(animationDuration: 0.25, action: { [weak form] isLogin in
            // swap appearance of password utility views
            form?.passwordRequirements.alpha = isLogin ? 0 : 1
            form?.forgotPassword.alpha = isLogin ? 1 : 0
            form?.forgotPassword.isUserInteractionEnabled = isLogin

            // swap appearance of switch controls
            form?.switchToLogin.isUserInteractionEnabled = !isLogin
            form?.switchToLogin.alpha = isLogin ? 0 : 1
            form?.switchToRegister.isUserInteractionEnabled = isLogin
            form?.switchToRegister.alpha = isLogin ? 1 : 0
        })

        form.password.field.reactive.allTextValues
            .map({ value in (value?.characters.count ?? 0) > 7 })
            .start(animationDuration: 0.25, action: { [weak form] isValid in
                form?.passwordRequirements.verified = isValid
                form?.passwordRequirements.layoutIfInWindowAndNeeded()
            })

        // update the interface when the keyboard shows and hides
        services.keyboard.animationProducer.startWithValues({ [weak self] frame in
            self?.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.size.height, right: 0)

            // only layout once we are in a window, to avoid invalid layout errors
            view.layoutIfInWindowAndNeeded()
        })

        // update interface visibility
        state.producer.equals(.fieldEntry).startWithValues({ [weak scrollView, weak activity] showingFields in
            scrollView?.isUserInteractionEnabled = showingFields
            scrollView?.alpha = showingFields ? 1 : 0
            activity?.alpha = showingFields ? 0 : 1
        })
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // track analytics events
        let modeProducer = mode.producer
        reactive.viewDidAppear
            .flatMap(.latest, transform: { _ in modeProducer })
            .map({ mode -> AnalyticsEvent in
                switch mode
                {
                case .login: return AnalyticsEvent.viewedScreen(name: .login)
                case .register: return AnalyticsEvent.viewedScreen(name: .register)
                }
            })
            .startWithValues({ [weak self] event in
                self?.services.analytics.track(event)
            })

        // push "reset password"
        SignalProducer(form.forgotPassword.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            guard let strong = self else { return }

            let controller = ResetTokenRequestViewController(services: strong.services)
            controller.email.field.text = strong.form.email.field.text
            strong.navigationController?.pushViewController(controller, animated: true)

            // sync changes to the email field
            controller.email.field.reactive.allTextValues
                .skip(first: 1)
                .take(until: controller.reactive.viewDidDisappear)
                .startWithValues({ [weak self] email in self?.form.email.field.text = email })
        })

        // allow switching modes
        for (control, mode) in [(form.switchToRegister, Mode.register), (form.switchToLogin, .login)]
        {
            SignalProducer(control.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
                self?.mode.value = mode
            })
        }

        let analytics = services.analytics

        // observe current view controller state for registration/login action
        SignalProducer.combineLatest(mode.producer, form.email.field.reactive.allTextValues, form.password.field.reactive.allTextValues)

            // sample every time the user taps the action button
            .sample(on: SignalProducer(form.confirmControl.reactive.controlEvents(.touchUpInside)).map({ _ in () }))

            // a signal producer of producers that will authenticate the producer
            .map({ [weak self] mode, maybeEmail, maybePassword -> SignalProducer<(), NSError>? in
                // make sure view controller is still allocated
                guard let strong = self else { return nil }

                // make sure the user has entered an email (3 chars = a@b)
                guard let email = maybeEmail, email.characters.count > 3 else {
                    strong.form.email.rly_wiggleForFormRejection()
                    return nil
                }

                // make sure the user has entered a password if registering, if logging in, they could have previously
                // registered with a now-invalid password, so we shouldn't validate
                guard let password = maybePassword, password.characters.count > 7 || mode == .login else {
                    strong.form.password.rly_wiggleForFormRejection()
                    strong.form.passwordRequirements.rly_wiggleForFormRejection()
                    return nil
                }

                let analyticsMode: AnalyticsAuthenticationMethod = mode == .register ? .register : .login

                return strong.authenticationProducerWithMode(mode, email: email, password: password)
                    .observe(on: UIScheduler())
                    .on(
                        failed: { error in
                            analytics.track(AuthenticationFailedEvent(method: analyticsMode, error: error))
                        },
                        completed: {
                            analytics.track(AuthenticationCompletedEvent(method: analyticsMode))
                        }
                    )
            })

            // add side effects for activity indicator presentation
            .flatMapOptional(.latest, transform: { [weak self] producer -> SignalProducer<(), NoError> in
                return UIView.animationProducer(duration: 0.5, animations: { [weak self] in
                        // fade out the input views and display the activity indicator
                        self?.state.value = .requesting
                    })
                    .ignoreValues()
                    .then(producer.flatMapError({ [weak self] error in
                        self?.presentErrorProducer(error, closeButtonTitle: tr(.gotIt))
                            .then(UIView.animationProducer(duration: 0.5, animations: { [weak self] in
                                // fade out the input views and display the activity indicator
                                self?.state.value = .fieldEntry
                            }).ignoreValues())
                            ?? SignalProducer.empty
                    }))
            })
            .start()

        // store entered email addresses
        services.preferences.lastAuthenticatedEmail <~ form.email.field.reactive.continuousTextValues
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        if form.email.field.text?.characters.count > 0
        {
            form.password.field.becomeFirstResponder()
        }
        else
        {
            form.email.field.becomeFirstResponder()
        }
    }

    // MARK: - Authentication Producers

    /**
     A producer to authenticate using the view controller's services.

     - parameter mode:     The authentication mode to use.
     - parameter email:    The email address to use.
     - parameter password: The password to use.
     */
    fileprivate func authenticationProducerWithMode(_ mode: Mode, email: String, password: String)
        -> SignalProducer<(), NSError>
    {
        switch mode
        {
        case .login:
            return loginProducer(email: email, password: password)
        case .register:
            return registerProducer(email: email, password: password)
        }
    }

    /**
     A producer to register using the view controller's services.

     - parameter email:    The email address to use.
     - parameter password: The password to use.
     */
    fileprivate func registerProducer(email: String, password: String) -> SignalProducer<(), NSError>
    {
        return services.api.registerProducer(
            email: email,
            password: password,
            firstName: nil,
            lastName: nil,
            receiveUpdates: true,
            device: UIDevice.current
        ).ignoreValues()
    }

    /**
     A producer to log in using the view controller's services.

     - parameter email:    The email address to use.
     - parameter password: The password to use.
     */
    fileprivate func loginProducer(email: String, password: String) -> SignalProducer<(), NSError>
    {
        return services.api.authenticateProducer(
            email: email,
            password: password,
            device: UIDevice.current
        ).ignoreValues()
    }

    // MARK: - Mode

    /// The view modes of this view controller.
    enum Mode
    {
        /// The registration interface is displayed.
        case register

        /// The login interface is displayed.
        case login
    }

    /// The current display mode.
    let mode = MutableProperty(Mode.register)

    // MARK: - Utility
    fileprivate static func stateIsValidForSubmission(_ mode: Mode, email: String?, password: String?) -> Bool
    {
        guard let email = email, let password = password else { return false }

        switch mode
        {
        case .login:
            return email.characters.count > 3 && password.characters.count > 1
        case .register:
            return email.characters.count > 3 && password.characters.count > 7
        }
    }
}

extension AuthenticationFieldsViewController: UITextFieldDelegate
{
    // MARK: - Text Field Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch textField
        {
        case form.email.field:
            form.password.field.becomeFirstResponder()
        case form.password.field:
            form.confirmControl.sendActions(for: .touchUpInside)
        default: break
        }

        return false
    }
}

// MARK: - Form Class
private final class AuthenticationForm: UIView
{
    // MARK: - Subviews

    /// The email field.
    let email = BorderedField.newAutoLayout()

    /// The password field.
    let password = BorderedField.newAutoLayout()

    /// The confirmation control.
    let confirmControl = ButtonControl.newAutoLayout()

    /// The "Forgot Password" control.
    let forgotPassword = UnderlineLinkControl.newAutoLayout()

    /// The control for switching from register to login.
    let switchToLogin = UnderlineDetailControl.newAutoLayout()

    /// The control for switching from login to register.
    let switchToRegister = UnderlineDetailControl.newAutoLayout()

    /// Displays the requirements for a password.
    let passwordRequirements = RuleVerificationView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add fields
        email.formatForAuthenticationEmailInput()
        addSubview(email)

        password.formatForAuthenticationPasswordInput()
        password.field.accessibilityHint = tr(.passwordRequirementsLong)
        addSubview(password)

        passwordRequirements.text = tr(.passwordRequirementsShort)
        addSubview(passwordRequirements)

        // add center controls
        confirmControl.textColor = .gray
        confirmControl.title = tr(.login)
        addSubview(confirmControl)

        forgotPassword.text = tr(.forgotPasswordQuestion)
        addSubview(forgotPassword)

        // it's necessary to have two separate views for switching modes because the glow effect glitches out when
        // using a view transition and changing the text content
        switchToRegister.leadingText = "\(tr(.newToRinglyQuestion)) "
        switchToRegister.trailingText = tr(.signUp)
        addSubview(switchToRegister)

        switchToLogin.leadingText = "\(tr(.alreadySignedUpQuestion)) "
        switchToLogin.trailingText = tr(.login)
        addSubview(switchToLogin)

        // contents layout
        email.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)

        password.autoPin(edge: .top, to: .bottom, of: email, offset: 20)
        password.autoPinEdgeToSuperview(edge: .leading)
        password.autoPinEdgeToSuperview(edge: .trailing)

        forgotPassword.autoSet(dimension: .height, to: 44)
        forgotPassword.autoPin(edge: .top, to: .bottom, of: password, offset: 0)
        forgotPassword.autoAlignAxis(toSuperviewAxis: .vertical)

        passwordRequirements.autoPin(edge: .top, to: .bottom, of: password, offset: 9)
        passwordRequirements.autoAlignAxis(toSuperviewAxis: .vertical)

        confirmControl.autoAlignAxis(toSuperviewAxis: .vertical)
        confirmControl.autoSetDimensions(to: CGSize(width: 256, height: 50))
        confirmControl.autoPin(edge: .top, to: .bottom, of: passwordRequirements, offset: 55)
        confirmControl.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        confirmControl.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)

        // switch mode layout
        for control in [switchToLogin, switchToRegister]
        {
            control.autoFloatInSuperview(alignedTo: .vertical)
            control.autoPin(edge: .top, to: .bottom, of: confirmControl)
            control.autoPinEdgeToSuperview(edge: .bottom)
            control.autoSet(dimension: .height, to: 44, relation: .greaterThanOrEqual)
        }
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
