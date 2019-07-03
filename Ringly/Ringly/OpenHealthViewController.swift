import UIKit
import enum Result.NoError
import enum RinglyExtensions.DeviceScreenHeight
import struct ReactiveSwift.SignalProducer

final class OpenHealthViewController: UIViewController
{
    // MARK: - Subviews
    fileprivate let button = ButtonControl.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        self.view = view

        // dynamic layout for smaller screens
        let height = DeviceScreenHeight.current
        let stackPadding: CGFloat = height.select(four: 10, five: 30, preferred: 44)
        let topInset: CGFloat = height.select(four: 10, preferred: 28)
        let bottomInset: CGFloat = height.select(four: 10, five: 44, preferred: 50)

        // add the title at the top of the view
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        titleLabel.attributedText = [
            UIFont.gothamBook(15).track(160, "FOLLOW THESE STEPS TO"),
            "\n",
            UIFont.gothamBook(15).track(160, "CONNECT TO THE HEALTH APP")
        ].join().attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 5))
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: topInset)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // add the stack of open settings views
        let stack = UIStackView.openSettingsView(3, items: [
            (
                image: UIImage(asset: .openHealthSpringboard),
                tracking: 160,
                text: [.normal("GO TO THE IPHONE\n"), .bold("HEALTH APP")]
            ),
            (
                image: UIImage(asset: .openHealthTabBar),
                tracking: 75,
                text: [.normal("TAP "), .bold("SOURCES"), .normal(" IN THE\nBOTTOM NAVIGATION")]
            ),
            (
                image: UIImage(asset: .openHealthApps),
                tracking: 160,
                text: [.normal("UNDER APPS,\nTAP "), .bold("RINGLY")]
            ),
            (
                image: UIImage(asset: .openHealthAllCategoriesOn),
                tracking: 160,
                text: [.normal("TAP "), .bold("TURN ALL\nCATEGORIES ON")]
            )
        ])

        view.addSubview(stack)
        stack.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: stackPadding)
        stack.autoAlignAxis(toSuperviewAxis: .vertical)

        // add the button at the bottom of the view
        button.title = "GOT IT!"
        view.addSubview(button)

        button.autoAlignAxis(toSuperviewAxis: .vertical)
        button.autoSetDimensions(to: CGSize(width: 165, height: 50))
        button.autoPin(edge: .top, to: .bottom, of: stack, offset: stackPadding)
        button.autoPinEdgeToSuperview(edge: .bottom, inset: bottomInset)
    }
}

extension OpenHealthViewController: ClosableConnectOverlay
{
    var closeProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(button.reactive.controlEvents(.touchUpInside)).void
    }
}

extension UIStackView
{
    fileprivate static func openSettingsView(_ lineSpacing: CGFloat,
                                         items: [(image: UIImage?, tracking: CGFloat, text: [OpenHealthText])])
        -> UIStackView
    {
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing

        let style = NSParagraphStyle.with(alignment: .left, lineSpacing: lineSpacing)

        items.forEach({ image, tracking, text in
            let attributed = text.attributedString(
                bold: UIFont.gothamBold(12),
                normal: UIFont.gothamBook(12),
                tracking: tracking,
                style: style
            )

            stackView.addArrangedSubview(DFUOpenSettingsSubview.view(text: attributed, image: image))
        })

        return stackView
    }
}

private enum OpenHealthText
{
    case bold(String)
    case normal(String)
}

extension Sequence where Iterator.Element == OpenHealthText
{
    fileprivate func attributedString(bold: UIFont, normal: UIFont, tracking: CGFloat, style: NSParagraphStyle)
        -> NSAttributedString
    {
        return map({ text in
            switch text
            {
            case let .bold(string):
                return string.attributes(font: bold, paragraphStyle: style, tracking: tracking)
            case let .normal(string):
                return string.attributes(font: normal, paragraphStyle: style, tracking: tracking)
            }
        }).join()
    }
}
