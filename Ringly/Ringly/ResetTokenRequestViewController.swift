import PureLayout
import ReactiveSwift
import Result
import RinglyAPI
import RinglyExtensions
import UIKit

/// Allows the user to request a reset token for an email address.
final class ResetTokenRequestViewController: ServicesViewController
{
    // MARK: - Subviews
    fileprivate let formContainer = UIView.newAutoLayout()
    fileprivate let confirmedContainer = UIView.newAutoLayout()

    let email = BorderedField.newAutoLayout()
    fileprivate let submitButton = ButtonControl.newAutoLayout()

    fileprivate let openEmailButton = ButtonControl.newAutoLayout()

    // MARK: - State
    fileprivate enum State { case emailEntry, requesting, completed }

    /// The current state of the view controller.
    fileprivate let state = MutableProperty(State.emailEntry)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add outer content containers
        let contentView = UIView.newAutoLayout()
        view.addSubview(contentView)

        contentView.addSubview(formContainer)
        contentView.addSubview(confirmedContainer)

        // form content
        func attributes(_ string: AttributedStringProtocol) -> NSAttributedString
        {
            return string.attributes(
                font: .gothamBook(18),
                paragraphStyle: .with(alignment: .center, lineSpacing: 5),
                tracking: 300
            )
        }

        let formTitle = UILabel.newAutoLayout()
        formTitle.numberOfLines = 0
        formTitle.textColor = UIColor.white
        formTitle.attributedText = attributes(tr(.forgotPasswordTitle)).attributedString
        formContainer.addSubview(formTitle)

        email.field.delegate = self
        email.formatForAuthenticationEmailInput()
        formContainer.addSubview(email)

        submitButton.title = tr(.resetPassword)
        formContainer.addSubview(submitButton)

        // confirmed content
        let envelope = UIImageView.newAutoLayout()
        envelope.image = UIImage(asset: .authenticationLargeEnvelope)
        confirmedContainer.addSubview(envelope)

        let confirmedLabelContainer = UIView.newAutoLayout()
        confirmedContainer.addSubview(confirmedLabelContainer)

        let confirmedLabel = UILabel.newAutoLayout()
        confirmedLabel.numberOfLines = 0
        confirmedLabel.textColor = UIColor.white
        confirmedLabel.attributedText =
            attributes(trUpper(.checkEmailForPasswordLink)).attributedString
        confirmedLabelContainer.addSubview(confirmedLabel)

        openEmailButton.title = tr(.openEmail)
        confirmedContainer.addSubview(openEmailButton)

        // add activity indicator
        let activity = DiamondActivityIndicator.newAutoLayout()
        view.addSubview(activity)
        activity.autoCenterInSuperview()
        activity.constrainToDefaultSize()

        // layout for outer containers
        contentView.autoPinEdgesToSuperviewEdges(insets: 
            UIEdgeInsets(top: AuthenticationNavigationController.topMargin, left: 0, bottom: 0, right: 0)
        )

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultLow, forConstraints: {
            self.formContainer.autoPinEdgeToSuperview(edge: .top, inset: 43)
        })

        formContainer.autoPinEdgeToSuperview(edge: .top, inset: 10, relation: .greaterThanOrEqual)
        formContainer.autoPinEdgeToSuperview(edge: .leading)
        formContainer.autoPinEdgeToSuperview(edge: .trailing)
        formContainer.autoSet(dimension: .height, to: 265, relation: .lessThanOrEqual)

        confirmedContainer.autoPinEdgeToSuperview(edge: .top, inset: 55)
        confirmedContainer.autoPinEdgeToSuperview(edge: .leading)
        confirmedContainer.autoPinEdgeToSuperview(edge: .trailing)
        confirmedContainer.autoPinEdgeToSuperview(edge: .bottom)

        /// ensure the the form container isn't under the keyboard
        let formContainerBottom = formContainer
            .autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)

        services.keyboard.animationProducer.startWithValues({ frame in
            formContainerBottom.constant = -frame.size.height - 10
        })

        // basic layout for form content
        formTitle.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        formTitle.autoAlignAxis(toSuperviewAxis: .vertical)
        formTitle.autoPinEdgeToSuperview(edge: .top)

        submitButton.autoAlignAxis(toSuperviewAxis: .vertical)
        submitButton.autoSetDimensions(to: CGSize(width: 256, height: 50))
        submitButton.autoPinEdgeToSuperview(edge: .bottom)

        email.autoPinEdgeToSuperview(edge: .leading, inset: 12)
        email.autoPinEdgeToSuperview(edge: .trailing, inset: 12)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            self.email.autoPin(edge: .top, to: .bottom, of: formTitle, offset: 64)
            self.email.autoPin(edge: .bottom, to: .top, of: self.submitButton, offset: -60)
        })

        email.autoPin(edge: .top, to: .bottom, of: formTitle, offset: 10, relation: .greaterThanOrEqual)
        email.autoPin(edge: .bottom, to: .top, of: submitButton, offset: -10, relation: .lessThanOrEqual)

        // confirmed container layout
        envelope.autoPinEdgeToSuperview(edge: .top)
        envelope.autoConstrainAspectRatio()
        envelope.autoAlignAxis(toSuperviewAxis: .vertical)

        confirmedLabelContainer.autoPinEdgeToSuperview(edge: .leading, inset: 10)
        confirmedLabelContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 10)
        confirmedLabelContainer.autoPin(edge: .top, to: .bottom, of: envelope, offset: 5)

        confirmedLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        confirmedLabel.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        confirmedLabel.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        confirmedLabel.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        confirmedLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        confirmedLabel.autoSet(dimension: .width, to: 270)
        confirmedLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultLow, forConstraints: {
            confirmedLabel.autoConstrain(attribute: 
                .horizontal,
                to: .bottom,
                of: confirmedLabelContainer,
                multiplier: 0.3
            )
        })

        openEmailButton.autoPin(edge: .top, to: .bottom, of: confirmedLabelContainer, offset: 10)
        openEmailButton.autoPinEdgeToSuperview(edge: .bottom, inset: 55)
        openEmailButton.autoAlignAxis(toSuperviewAxis: .vertical)
        openEmailButton.autoSetDimensions(to: CGSize(width: 256, height: 50))

        // display correct content
        state.producer.equals(.emailEntry).skipRepeats()
            .start(animationDuration: 0.25, action: { [weak self] showForm in
                self?.formContainer.alpha = showForm ? 1 : 0
                self?.formContainer.isUserInteractionEnabled = showForm

                if showForm
                {
                    self?.email.field.becomeFirstResponder()
                }
                else
                {
                    self?.email.field.endEditing(true)
                }
            })

        state.producer.equals(.completed).skipRepeats()
            .start(animationDuration: 0.25, action: { [weak self] requested in
                self?.confirmedContainer.alpha = requested ? 1 : 0
                self?.confirmedContainer.isUserInteractionEnabled = requested
            })

        state.producer.equals(.requesting).skipRepeats()
            .start(animationDuration: 0.25, action: { showActivity in activity.alpha = showActivity ? 1 : 0 })

        email.field.reactive.allTextValues
            .map({ text -> Bool in text?.isValidEmailAddress ?? false })
            .skipRepeats(==)
            .startCrossDissolve(in: submitButton, duration: 0.25, action: { [weak self] isValid in
                self?.submitButton.textColor = isValid
                    ? UIColor.authenticationButtonValid
                    : UIColor.authenticationButtonInvalid
            })

        // after completing, when the app comes back to the foreground, return to the login screen
        let willEnterForeground = NotificationCenter.default.reactive.notifications(
            forName: NSNotification.Name.UIApplicationWillEnterForeground,
            object: UIApplication.shared
        )

        state.producer
            .sample(on: SignalProducer(willEnterForeground).void)
            .filter({ $0 == .completed })
            .startWithValues({ [weak self] _ in
                _ = self?.navigationController?.popViewController(animated: false)
            })
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let api = services.api

        email.field.reactive.allTextValues
            .sample(on: SignalProducer(submitButton.reactive.controlEvents(.touchUpInside)).void)
            .map({ [weak self] maybeEmail -> SignalProducer<(), NSError>? in
                guard let email = maybeEmail, email.characters.count > 2 else {
                    self?.email.rly_wiggleForFormRejection()
                    return nil
                }

                return api.resultProducer(for: ResetTokenRequestRequest(email: email))
                    .observe(on: QueueScheduler.main)
            })
            .flatMapOptional(.latest, transform: { [weak self] producer -> SignalProducer<(), NoError> in
                return producer
                    .on(
                        started: { [weak self] in self?.state.value = .requesting },
                        completed: { [weak self] in self?.state.value = .completed }
                    )
                    .flatMapError({ error in
                        guard let strong = self else { return SignalProducer.empty }
                        return strong.presentErrorProducer(error, closeButtonTitle: tr(.gotIt))
                            .on(completed: { [weak self] in self?.state.value = .emailEntry })
                    })

            })
            .take(until: state.producer.await(.completed))
            .start()

        SignalProducer(openEmailButton.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            var pairs = [("Mail", NSURL(string: "message://"))]

            for pair in [("Gmail", "googlegmail://"), ("Inbox", "inbox-gmail://")]
            {
                if let URL = NSURL(string: pair.1), UIApplication.shared.canOpenURL(URL as URL)
                {
                    pairs.append((pair.0, URL))
                }
            }

            if pairs.count > 1
            {
                let sheet = SheetViewController()

                sheet.actions = pairs.map({ text, maybeURL in
                    return SheetAction(label: trUpper(.openIn(text)), action: {
                        guard let URL = maybeURL else { return }
                        UIApplication.shared.openURL(URL as URL)
                    })
                }) + [SheetAction(label: trUpper(.cancel), action: {})]

                sheet.actionTapped = { sheet in sheet.dismiss(animated: true, completion: nil) }

                self?.present(sheet, animated: true, completion: nil)
            }
            else if let URL = pairs.first?.1
            {
                UIApplication.shared.openURL(URL as URL)
            }
        })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        DispatchQueue.main.async(execute: {
            if self.state.value == .emailEntry
            {
                self.email.field.becomeFirstResponder()
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        email.field.resignFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        services.analytics.track(AnalyticsEvent.viewedScreen(name: .forgotPassword))
    }
}

extension ResetTokenRequestViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == email.field
        {
            submitButton.sendActions(for: .touchUpInside)
        }

        return false
    }
}
