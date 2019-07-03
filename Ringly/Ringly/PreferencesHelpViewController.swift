import ReactiveSwift
import SafariServices
import UIKit

final class PreferencesHelpViewController: ServicesViewController
{
    fileprivate let helpControl = ButtonControl.newAutoLayout()
    fileprivate let legalControl = LinkControl.newAutoLayout()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        let titleLabel = UILabel.newAutoLayout()
        titleLabel.textColor = .white
        titleLabel.attributedText = UIFont.gothamBook(15).track(250, "HELP").attributedString
        view.addSubview(titleLabel)

        let imageView = UIImageView.newAutoLayout()
        imageView.image = UIImage(asset: .preferencesHelpCenter)
        view.addSubview(imageView)

        let descriptionLabel = UILabel.newAutoLayout()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .white
        descriptionLabel.attributedText = UIFont.gothamBook(12).track(150, "Visit the help center for setup instructions, tips, FAQs, or to contact our customer support team.")
            .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))
        view.addSubview(descriptionLabel)

        helpControl.title = "HELP, PLEASE"
        view.addSubview(helpControl)

        legalControl.text.value = "LEGAL"
        legalControl.font.value = UIFont.gothamBook(10)
        legalControl.alpha = 0.75
        view.addSubview(legalControl)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 44)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical)

        imageView.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 15)
        imageView.autoFloatInSuperview(alignedTo: .vertical)

        descriptionLabel.autoPin(edge: .top, to: .bottom, of: imageView, offset: 38)
        descriptionLabel.autoFloatInSuperview(alignedTo: .vertical)
        descriptionLabel.autoSet(dimension: .width, to: 210, relation: .lessThanOrEqual)

        helpControl.autoPin(edge: .top, to: .bottom, of: descriptionLabel, offset: 42)
        helpControl.autoSetDimensions(to: CGSize(width: 195, height: 45))
        helpControl.autoAlignAxis(toSuperviewAxis: .vertical)

        legalControl.autoSetDimensions(to: CGSize(width: 195, height: 45))
        legalControl.autoAlignAxis(toSuperviewAxis: .vertical)
        legalControl.autoPin(edge: .top, to: .bottom, of: helpControl, offset: 20)
        legalControl.autoPinEdgeToSuperview(edge: .bottom, inset: 10)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        SignalProducer(helpControl.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            let safari = SFSafariViewController(url: URL(string: "http://ringly.com/setup")!)
            self?.present(safari, animated: true, completion: nil)
        })

        SignalProducer(legalControl.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            guard let strong = self else { return }

            let legal = LegalViewController(services: strong.services)
            strong.present(legal, animated: true, completion: nil)
        })
    }
}
