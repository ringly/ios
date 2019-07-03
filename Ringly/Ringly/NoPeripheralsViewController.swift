import ReactiveSwift
import RinglyExtensions
import RinglyKit
import UIKit

final class NoPeripheralsViewController: ServicesViewController
{
    // MARK: - Subviews
    let button = ButtonControl.newAutoLayout()
    fileprivate let content = AddARinglyView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add the connect button
        button.title = "CONNECT"
        view.addSubview(button)

        button.autoSetDimensions(to: CGSize(width: 258, height: 50))
        button.autoPinEdgeToSuperview(edge: .bottom, inset: 50)
        button.autoFloatInSuperview(alignedTo: .vertical)

        // add a container to vertically center the content
        let container = UIView.newAutoLayout()
        view.addSubview(container)

        container.autoPinEdgesToSuperviewMarginsExcluding(edge: .bottom)
        container.autoPin(edge: .bottom, to: .top, of: button, offset: -10)

        container.addSubview(content)

        content.autoFloatInSuperview(alignedTo: .horizontal)
        content.autoPinEdgeToSuperview(edge: .left)
        content.autoPinEdgeToSuperview(edge: .right)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        SignalProducer(content.shopControl.reactive.controlEvents(.touchUpInside)).startWithValues({ _ in
            UIApplication.shared.openURL(URL(string: "https://ringly.com")!)
        })

        let options: [Either<UIImage?, RLYPeripheralStyle>] = [
            .left(UIImage(asset: .stylizedBraceletBackstage)),
            .left(UIImage(asset: .stylizedBraceletBoardwalk)),
            .left(UIImage(asset: .stylizedBraceletLakeside)),
            .left(UIImage(asset: .stylizedBraceletPhotoBooth)),
            .left(UIImage(asset: .stylizedBraceletRendezvous)),
            .left(UIImage(asset: .stylizedBraceletRoadtrip)),
            .right(.daydream),
            .right(.stargaze),
            .right(.wineBar),
            .right(.intoTheWoods),
            .right(.outToSea),
            .right(.daybreak),
            .right(.openingNight),
            .right(.wanderlust),
            .right(.diveBar)
        ].shuffled()

        immediateTimer(interval: .seconds(3), on: QueueScheduler.main)
            // select a random option, not allowing repeats
            .scan(0, { current, _ -> Int in (current + 1) % options.count })

            // create a view to display the image or peripheral style
            .map({ index -> UIView in
                switch options[index]
                {
                case let .left(image):
                    let view = UIImageView(image: image)
                    view.autoConstrainAspectRatio()
                    return view
                case let .right(style):
                    let view = OnboardingRingView.newAutoLayout()
                    view.style.value = style
                    view.autoSet(dimension: .height, to: 138)
                    return view
                }
            })
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak content] view in
                content?.display(peripheralView: view)
            })
    }
}

private final class AddARinglyView: UIView
{
    // MARK: - Subviews

    /// The control for opening the Ringly store.
    let shopControl = UnderlineLinkControl.newAutoLayout()

    /// The container for the current peripheral view.
    fileprivate let peripheralContainer = UIView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add the title label ("add a ringly")
        let title = UILabel.newAutoLayout()
        title.attributedText = UIFont.gothamBook(18).track(250, "ADD A RINGLY").attributedString
        title.textColor = .white
        addSubview(title)

        title.autoPinEdgeToSuperview(edge: .top)
        title.autoFloatInSuperview(alignedTo: .vertical)

        // add the center peripheral container
        addSubview(peripheralContainer)
        peripheralContainer.autoPin(edge: .top, to: .bottom, of: title, offset: 10)
        peripheralContainer.autoPinEdgeToSuperview(edge: .left)
        peripheralContainer.autoPinEdgeToSuperview(edge: .right)
        peripheralContainer.autoSet(dimension: .height, to: 182)

        // add the bottom content - control and prompt
        let prompt = UILabel.newAutoLayout()
        prompt.attributedText = UIFont.gothamBook(14).track(100, "Don't have a Ringly?").attributedString
        prompt.textColor = .white
        addSubview(prompt)

        prompt.autoFloatInSuperview(alignedTo: .vertical)
        prompt.autoPin(edge: .top, to: .bottom, of: peripheralContainer, offset: 10)

        shopControl.text = "Shop now."
        addSubview(shopControl)

        shopControl.autoPin(edge: .top, to: .bottom, of: prompt)
        shopControl.autoPinEdgeToSuperview(edge: .bottom)
        shopControl.autoFloatInSuperview(alignedTo: .vertical)
        shopControl.autoSetDimensions(to: CGSize(width: 180, height: 28))

        [title, prompt].forEach({ view in
            view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            view.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
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

    // MARK: - Displaying New Peripheral Views

    /// The currently-displayed peripheral view (see `display(peripheralView:)`).
    fileprivate var currentView: UIView?

    /// Displays a new peripheral view in the container.
    ///
    /// - parameter view: A peripheral view to display.
    func display(peripheralView view: UIView)
    {
        peripheralContainer.addSubview(view)
        view.autoFloatInSuperview()

        if let current = currentView
        {
            let width = bounds.size.width
            view.transform = CGAffineTransform(translationX: width, y: 0)

            UIView.animate(withDuration: 0.5, animations: {
                current.transform = CGAffineTransform(translationX: -width, y: 0)
                view.transform = CGAffineTransform.identity
            }, completion: { _ in
                current.removeFromSuperview()
            })
        }

        currentView = view
    }
}
