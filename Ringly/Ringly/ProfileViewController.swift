import MobileCoreServices
import ReactiveSwift
import RinglyAPI
import RinglyExtensions
import UIKit
import enum Result.NoError

final class ProfileViewController: ServicesViewController
{
    // MARK: - User

    /// The user displayed by the view controller.
    fileprivate let user = MutableProperty(User?.none)

    /// The file URL at which the user's avatar is stored.
    fileprivate let avatarURL = FileManager.default.rly_documentsURL
        .appendingPathComponent("ringlyProfileImage.png", isDirectory: false)

    // MARK: - Mode

    /// Enumerates the cases for `mode`.
    enum Mode { case display, edit }

    /// The current mode of the view controller. The view controller will modify this property itself when controls are
    /// tapped, but the property can also be modified from outside of the view controller.
    let mode = MutableProperty(Mode.display)

    /// `true` if the view controller is currently submitting changes to the API.
    fileprivate let submittingChanges = MutableProperty(false)

    // MARK: - Content Subviews

    /// Displays the user's avatar.
    fileprivate let avatar = AvatarControl.newAutoLayout()

    /// Displays the user's name and email address.
    fileprivate let labels = ProfileLabelsView.newAutoLayout()

    /// Allows editing of the user's name and email address.
    fileprivate let fields = ProfileFieldsView.newAutoLayout()

    // MARK: - Button Subviews

    /// A button to save changes made in edit mode.
    fileprivate let saveButton = UIButton.newAutoLayout()

    /// A button to enter edit mode, or to exit it without saving changes.
    fileprivate let editCancelButton = UIButton.newAutoLayout()

    /// A button to log the user out of her Ringly account.
    fileprivate let logoutButton = LinkControl.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add shadow behind all others
        let shadow = UIImageView.newAutoLayout()
        shadow.image = UIImage(asset: .shadowBracelet)
        view.addSubview(shadow)

        // add avatar-level controls
        view.addSubview(avatar)

        let normalImage = UIImage.rly_pixel(with: ButtonControl.defaultFillColor)
        let highlightedImage = UIImage.rly_pixel(with: ButtonControl.defaultHighlightedFillColor)

        editCancelButton.setBackgroundImage(normalImage, for: .normal)
        editCancelButton.setBackgroundImage(highlightedImage, for: .highlighted)

        saveButton.accessibilityLabel = "Save"
        saveButton.setImage(UIImage(asset: .profileCheckMark), for: UIControlState())
        saveButton.setBackgroundImage(normalImage, for: .normal)
        saveButton.setBackgroundImage(highlightedImage, for: .highlighted)

        view.addSubview(saveButton)
        view.addSubview(editCancelButton)

        // add non-editable labels
        view.addSubview(labels)

        // add editable fields
        view.addSubview(fields)

        logoutButton.text.value = "LOG OUT"
        view.addSubview(logoutButton)

        // layout
        avatar.autoPinEdgeToSuperview(edge: .top, inset: 4)
        avatar.autoFloatInSuperview(alignedTo: .vertical)

        shadow.autoFloatInSuperview(alignedTo: .vertical)
        shadow.autoConstrainAspectRatio()
        shadow.autoPin(edge: .top, to: .bottom, of: avatar, offset: 4)

        let editToAvatarClosed = editCancelButton.autoPin(edge: .leading, to: .trailing, of: avatar, offset: -35)
        let editToAvatarOpen = editCancelButton.autoPin(edge: .leading, to: .trailing, of: avatar, offset: 10)

        let saveToAvatarClosed = saveButton.autoPin(edge: .trailing, to: .leading, of: avatar, offset: 35)
        let saveToAvatarOpen = saveButton.autoPin(edge: .trailing, to: .leading, of: avatar, offset: -10)

        let buttons = [saveButton, editCancelButton]
        let buttonAlignments = buttons.map({ $0.autoAlign(axis: .horizontal, toSameAxisOf: avatar) })

        [labels, fields].forEach({ view in
            view.autoPinEdgeToSuperview(edge: .leading)
            view.autoPinEdgeToSuperview(edge: .trailing)
        })

        labels.autoPin(edge: .top, to: .bottom, of: avatar, offset: 41)

        logoutButton.autoFloatInSuperview(alignedTo: .vertical)
        logoutButton.autoSet(dimension: .height, to: 44)
        logoutButton.autoPin(edge: .top, to: .bottom, of: fields, offset: 20)
        logoutButton.autoPinEdgeToSuperview(edge: .bottom, inset: 20)

        let labelsToBottom = labels.autoPinEdgeToSuperview(edge: .bottom, inset: 29)
        let fieldsToAvatar = fields.autoPin(edge: .top, to: .bottom, of: avatar, offset: 41)

        buttons.forEach({
            $0.autoSetDimensions(to: CGSize(width: 50, height: 50))
            $0.layer.cornerRadius = 25
            $0.clipsToBounds = true
        })

        // move/fade/scale controls when changing mode
        let editingProducer = mode.producer.map({ $0 == .edit })

        editingProducer.start(animationDuration: 0.25, action: { [weak self] editing in
            // change the image of the editing button
            self?.editCancelButton.setImage(
                UIImage(asset: editing ? .profileCloseMark : .profileEditMark),
                for: .normal
            )

            self?.editCancelButton.accessibilityLabel = editing ? "Cancel" : "Edit Profile"

            // hide the save button when not in editing mode
            self?.saveButton.alpha = editing ? 1 : 0

            // show and hide the labels and fields
            self?.labels.alpha = editing ? 0 : 1

            // adjust layout
            buttonAlignments.forEach({ $0.constant = editing ? 45 : -45 })

            NSLayoutConstraint.conditionallyActivateConstraints([
                // labels vs. fields
                (labelsToBottom, !editing),
                (fieldsToAvatar, editing),

                // edit/cancel alignment
                (editToAvatarOpen, editing),
                (editToAvatarClosed, !editing),

                // save alignment
                (saveToAvatarOpen, editing),
                (saveToAvatarClosed, !editing)
            ])

            self?.fields.transform = editing ? .identity : CGAffineTransform(scaleX: 0.5, y: 0.5)

            self?.view.superview?.layoutIfInWindowAndNeeded()
        })

        // enable and disable editing fields
        editingProducer.combineLatest(with: submittingChanges.producer)
            .start(animationDuration: 0.25, action: { [weak self] editing, submittingChanges in
                self?.fields.alpha = editing ? 1 : 0
                self?.logoutButton.alpha = editing ? 1 : 0
                self?.editCancelButton.isUserInteractionEnabled = !submittingChanges

                let editingNotSubmitting = editing && !submittingChanges
                self?.fields.isUserInteractionEnabled = editingNotSubmitting
                self?.avatar.isUserInteractionEnabled = editingNotSubmitting
                self?.saveButton.isUserInteractionEnabled = editingNotSubmitting
                self?.logoutButton.isUserInteractionEnabled = editingNotSubmitting
            })
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // initialize avatar image
        avatar.image = UIImage(contentsOfFile: avatarURL.path)

        // non-self references for closures
        let API = services.api
        let user = self.user
        let fields = self.fields

        // bind current user to content
        user <~ services.api.authentication.producer.map({ $0.user })
        labels.user <~ user.producer

        // start/stop editing whenever the edit/cancel button is tapped
        SignalProducer(editCancelButton.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            self?.mode.pureModify({ current in
                if current == .display
                {
                    self?.services.analytics.track(AnalyticsEvent.profileEditShown)
                    return .edit
                }
                else
                {
                    return .display
                }
            })
        })

        // initialize fields whenever the edit button is tapped
        user.producer
            .sample(on: SignalProducer(editCancelButton.reactive.controlEvents(.touchUpInside)).void)
            .startWithValues({ [weak fields] user in
                fields?.nameField.text = user?.name
                fields?.emailField.text = user?.email
            })

        // edit the user when requested
        SignalProducer(saveButton.reactive.controlEvents(.touchUpInside))
            // we use this instead of sampleOn so that manually setting `text` is picked up correctly
            .map({ _ -> (current: User, new: User)? in
                guard let current = user.value, let email = fields.emailField.text else { return nil }

                let name = fields.nameField.text

                return (
                    current: current,
                    new: User(
                        identifier: current.identifier,
                        email: email,
                        firstName: name?.rly_firstName,
                        lastName: name?.rly_lastName,
                        receiveUpdates: current.receiveUpdates
                    )
                )
            })
            .flatMapOptional(.latest, transform: { [weak self] current, new -> SignalProducer<(), NoError> in
                if current == new
                {
                    return SignalProducer.`defer` { [weak self] in
                        self?.mode.value = .display
                        return SignalProducer.empty
                    }
                }
                else
                {
                    return API.editUserProducer(new)
                        .on(completed: { [weak self] in
                            self?.mode.value = .display
                            self?.services.analytics.track(AnalyticsEvent.profileSaved)
                        })
                        .flatMapError({ [weak self] error -> SignalProducer<(), NoError> in
                            self?.presentErrorProducer(error) ?? SignalProducer.empty
                        })
                        .on(
                            started: { [weak self] in
                                // remove focus from keyboard fields
                                self?.fields.nameField.resignFirstResponder()
                                self?.fields.emailField.resignFirstResponder()

                                // enable submitting changes UI
                                self?.submittingChanges.value = true
                            },
                            terminated: { [weak self] in
                                self?.submittingChanges.value = false
                            }
                        )
                }
            })
            .start()

        // edit image when tapping avatar
        SignalProducer(avatar.reactive.controlEvents(.touchUpInside))
            .flatMap(.latest, transform: { [weak self] _ in
                self.map({ strong in
                    UIImagePickerController.selectImageProducer(
                        in: strong,
                        includeRemove: strong.avatar.image != nil,
                        allowEditing: true
                    ).resultify()
                }) ?? SignalProducer.empty
            })
            .startWithValues({ [weak self] result in
                guard let strong = self else { return }

                switch result
                {
                case let .success(image):
                    strong.avatar.image = image

                    do
                    {
                        try UIImagePNGRepresentation(image)?.write(to: strong.avatarURL, options: .atomicWrite)
                    }
                    catch let error as NSError
                    {
                        SLogUI("Error writing profile image: \(error)")
                    }

                case .failure(.remove):
                    strong.avatar.image = nil

                    do
                    {
                        try FileManager.default.removeItem(at: strong.avatarURL)
                    }
                    catch let error as NSError
                    {
                        SLogUI("Error removing profile image: \(error)")
                    }
                }
            })

        // show an activity indicator while submitting changes
        submittingChanges.producer.skipRepeats()
            .map({ submitting -> ActivityController? in submitting ? ActivityController() : nil })
            .combinePrevious(nil)
            .startWithValues({ [weak self] previous, current in
                previous?.dismiss(animated: true, completion: nil)

                if let controller = current
                {
                    self?.present(controller, animated: true, completion: nil)
                }
            })

        // log out on request
        SignalProducer(logoutButton.reactive.controlEvents(.touchUpInside))
            // display a confirmation sheet before logging out
            .flatMap(.latest, transform: { [weak self] _ -> SignalProducer<(), NoError> in
                guard let strong = self else { return SignalProducer.empty }

                return UIAlertController.choose(
                    preferredStyle: .actionSheet,
                    inViewController: strong,
                    choices: [AlertControllerChoice(title: "Log Out", style: .destructive, value: ())]
                )
            })
            .startWithValues({ [weak self] _ in
                self?.services.api.logout()
            })
    }
}
