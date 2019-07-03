import ReactiveSwift
import UIKit
import enum Result.NoError

final class ContactsOnboardingViewController: UIViewController
{
    // MARK: - Subviews
    fileprivate let gradient = GradientView.pinkGradientView()
    fileprivate let content = UIView.newAutoLayout()
    fileprivate let button = ButtonControl.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add a gradient below all other views
        view.addSubview(gradient)
        gradient.autoPinEdgesToSuperviewEdges()

        // add content container
        view.addSubview(content)
        content.autoPinEdgesToSuperviewEdges()

        // add a container within the gradient view, to compensate for the title bar
        let outerContainer = UIView.newAutoLayout()
        content.addSubview(outerContainer)
        outerContainer.autoPinEdgeToSuperview(edge: .leading)
        outerContainer.autoPinEdgeToSuperview(edge: .trailing)
        outerContainer.autoPinEdgeToSuperview(edge: .top, inset: NavigationBar.standardHeight)

        // add a container to vertically center content
        let container = UIView.newAutoLayout()
        outerContainer.addSubview(container)
        container.autoFloatInSuperview()

        // add a header image
        let header = UIImageView.newAutoLayout()
        header.image = UIImage(asset: .contactsEmptyHeader)
        container.addSubview(header)

        header.autoConstrainAspectRatio()
        header.autoPinEdgeToSuperview(edge: .top)

        // add a feature description label
        let label = UILabel.newAutoLayout()
        label.textColor = .white
        label.numberOfLines = 0
        label.attributedText = tr(.contactsOnboardingDetails).attributedOnboardingDetailString

        container.addSubview(label)

        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.autoSet(dimension: .width, to: 286)
        label.autoPin(edge: .top, to: .bottom, of: header, offset: 30)
        label.autoPinEdgeToSuperview(edge: .bottom)

        // add the call-to-action button
        button.title = tr(.contactsOnboardingAction)
        content.addSubview(button)

        button.autoSet(dimension: .width, to: 246)
        button.autoSet(dimension: .height, to: 50)
        button.autoPin(edge: .top, to: .bottom, of: outerContainer, offset: 45)
        button.autoPinEdgeToSuperview(edge: .bottom, inset: ConfigurationsViewController.onboardingBottomPadding)

        // float elements horizontally
        [header, label, button].forEach({ $0.autoFloatInSuperview(alignedTo: .vertical, inset: 10) })
    }
}

extension ContactsOnboardingViewController: ConfigurationsOnboardingConfirmation
{
    var actionProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(button.reactive.controlEvents(.touchUpInside)).void
    }
}

extension ContactsOnboardingViewController: ForegroundBackgroundContentViewProviding
{
    var backgroundContentView: UIView? { return gradient }
    var foregroundContentView: UIView? { return content }
}
