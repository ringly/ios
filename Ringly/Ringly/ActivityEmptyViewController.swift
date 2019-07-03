import ReactiveSwift
import UIKit
import enum Result.NoError

final class ActivityEmptyViewController: ServicesViewController
{
    // MARK: - Subviews
    fileprivate let contentView = ActivityEmptyViewControllerContentView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        view.addSubview(contentView)
        contentView.autoFloatInSuperview()
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // a producer that is `true` when HealthKit is available, disabled, and `false` otherwise
        let healthKitDisabledProducer = services.activityTracking.healthKitAvailable
            ? services.activityTracking.healthKitAuthorization.producer
                .map({ $0 != .sharingAuthorized })
                .take(until: reactive.lifetime.ended)
            : SignalProducer(value: false)

        // a producer for whether or not the user has a step tracking device connected
        connectivity <~ services.peripherals.activityTrackingConnectivityProducer
            .take(until: reactive.lifetime.ended)
            .map({ $0 })

        // bind the content of labels and visibility of action button
        healthKitDisabledProducer.combineLatest(with: connectivity.producer.skipNil())
            .startWithValues({ [weak self] healthKitDisabled, activityTrackingConnectivity in
                // only show the button when healthkit is explicitly disabled
                self?.contentView.actionButton.isUserInteractionEnabled = healthKitDisabled
                self?.contentView.actionButton.isHidden = !healthKitDisabled

                self?.contentView.titleLabel.attributedText = activityTrackingConnectivity.titleAttributedString
                self?.contentView.detailsLabel.attributedText = activityTrackingConnectivity
                    .detailsAttributedString(healthKitDisabled)

                self?.contentView.actionButton.title = activityTrackingConnectivity.actionButtonTitle
            })

        // button actions
        func actionProducer(_ connectivity: Bool) -> SignalProducer<(), NoError>
        {
            return self.connectivity.producer
                .sample(on: SignalProducer(contentView.actionButton.reactive.controlEvents(.touchUpInside)).void)
                .skipNil()
                .filter({ $0.isUpdateRequired == connectivity })
                .void
        }

        startRequestingHealthKitAccess(on: actionProducer(false))
        actionProducer(true).startWithValues({ [weak self] in self?.presentDFU() })
    }

    /// Multicasts the current activity tracking connectivity.
    fileprivate let connectivity = MutableProperty(ActivityTrackingConnectivity?.none)

    /// Presents the DFU controller when the update button is tapped.
    fileprivate func presentDFU()
    {
        guard let connectivity = self.connectivity.value else { return }

        switch connectivity
        {
        case let .updateRequired(.some(identifier), _):
            if let peripheral = services.peripherals.activatedPeripheral.value,
               let firmwareResult = services.updates.firmwareResults.value[identifier]?.value.flatten()
            {
                presentDFU(peripheral: peripheral, firmwareResult: firmwareResult)
            }
        default:
            break
        }
    }
}

// MARK: - Content View
private final class ActivityEmptyViewControllerContentView: UIView
{
    // MARK: - Subviews
    let titleLabel = UILabel.newAutoLayout()
    let detailsLabel = UILabel.newAutoLayout()
    let actionButton = ButtonControl.newAutoLayout()
    let backgroundView = EmptyMessageBackgroundView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // subview setup
        [titleLabel, detailsLabel].forEach({
            $0.textColor = .white
            $0.numberOfLines = 0
        })
        
        detailsLabel.font = UIFont.gothamBook(12)
        actionButton.font = UIFont.gothamMedium(12)

        // add and align all views
        [backgroundView, titleLabel, detailsLabel, actionButton].forEach({
            addSubview($0)
            $0.autoFloatInSuperview(alignedTo: .vertical)
        })

        // vertical positioning of views
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 34)
        detailsLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 28)
        actionButton.autoPin(edge: .top, to: .bottom, of: detailsLabel, offset: 25)
        actionButton.autoPinEdgeToSuperview(edge: .bottom, inset: 24)

        // sizing of views
        titleLabel.autoSet(dimension: .width, to: 300)
        detailsLabel.autoSet(dimension: .width, to: 300)
        actionButton.autoSetDimensions(to: CGSize(width: 143, height: 44))
        
        backgroundView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 0, left: 16, bottom: 0, right: 16))
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

// MARK: - Activity Tracking Connectivity Strings
extension ActivityTrackingConnectivity
{
    fileprivate var titleAttributedString: NSAttributedString
    {
        func attributes(_ string: String) -> NSAttributedString
        {
            return string.attributes(
                font: .gothamBook(15),
                paragraphStyle: .with(alignment: .center, lineSpacing: 3),
                tracking: 250
            )
        }

        switch self
        {
        case .haveTracking, .haveTrackingAndNoTracking:
            return attributes("NO ACTIVITY DATA")
        case let .updateRequired(_, optionalPeriperalName):
            if let peripheralName = optionalPeriperalName
            {
                return attributes("UPDATE YOUR \(peripheralName.uppercased()) RINGLY")
            }
            else
            {
                return attributes("UPDATE YOUR RINGLY")
            }
        case let .noTracking(_, optionalPeripheralName):
            if let peripheralName = optionalPeripheralName
            {
                return attributes("YOUR \(peripheralName.uppercased()) RINGLY DOESN'T SUPPORT ACTIVITY TRACKING")
            }
            else
            {
                return attributes("TRACK YOUR ACTIVITY")
            }
        case .noPeripheralsNoHealth:
            return attributes("TRACK YOUR ACTIVITY")
        }
    }

    fileprivate func detailsAttributedString(_ healthKitDisabled: Bool) -> NSAttributedString
    {
        func attributes(_ string: String) -> NSAttributedString
        {
            return string.attributes(
                font: .gothamBook(12),
                paragraphStyle: .with(alignment: .center, lineSpacing: 3),
                tracking: 150
            )
        }

        switch self
        {
        case .haveTracking, .haveTrackingAndNoTracking, .noPeripheralsNoHealth:
            return healthKitDisabled
                ? attributes("You’re in luck. Even if you don’t have a Ringly yet, you can still track your steps in the Ringly app if you connect the Apple Health App.")
                : attributes("Get moving and get those steps.\nYou can do it!")
        case .noTracking:
            return healthKitDisabled
                ? attributes("Even though your Ringly doesn’t support activity, you can still track your steps in the Ringly app if you connect the Apple Health App.")
                : attributes("Get moving and get those steps.\nYou can do it!")
        case .updateRequired:
            return attributes("to enable its built-in\nactivity tracking features.")
        }
    }

    fileprivate var actionButtonTitle: String
    {
        switch self
        {
        case .updateRequired:
            return "UPDATE"
        default:
            return "CONNECT"
        }
    }

    fileprivate var isUpdateRequired: Bool
    {
        switch self
        {
        case .updateRequired:
            return true
        default:
            return false
        }
    }
}

class EmptyMessageBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        let color = UIColor.init(red: 195.0 / 255.0, green: 86.0 / 255.0, blue: 143.0 / 255.0, alpha: 0.4)
        let triangle = TriangleView(color: color)
        self.addSubview(triangle)
        triangle.autoSetDimensions(to: CGSize.init(width: 20, height: 10))
        triangle.autoPinEdgeToSuperview(edge: .top)
        triangle.autoAlignAxis(toSuperviewAxis: .vertical)
        
        let roundedCornerView = UIView.newAutoLayout()
        roundedCornerView.backgroundColor = color
        roundedCornerView.layer.cornerRadius = 2.0
        self.addSubview(roundedCornerView)
        roundedCornerView.autoPin(edge: .top, to: .bottom, of: triangle, offset: 0)
        roundedCornerView.autoPinEdgesToSuperviewEdges(excluding: .top)
    }
}

class TriangleView: UIView {
    let color: UIColor
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: CGRect.zero)
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: rect.size.height))
        bezierPath.addLine(to: CGPoint(x: rect.size.width / 2, y: 0))
        bezierPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        self.color.setFill()
        bezierPath.fill()
    }
}

