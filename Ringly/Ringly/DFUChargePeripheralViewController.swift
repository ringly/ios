import ReactiveSwift
import RinglyDFU
import RinglyExtensions
import UIKit
import enum Result.NoError

final class DFUChargePeripheralViewController: UIViewController, DFUPropertyChildViewController
{
    // MARK: - State
    typealias State = RLYPeripheralBatteryState?
    let state = MutableProperty(State.none)

    // MARK: - Subviews
    fileprivate let checklist = DFUChecklistView.newAutoLayout()
    fileprivate let button = ButtonControl.newAutoLayout()
    fileprivate let activityView = UIView.newAutoLayout()
    fileprivate let activity = DiamondActivityIndicator.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add labels to the top of the view
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.attributedText = tr(.dfuRingInChargerText).rly_DFUTitleString()
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: DFUStartingViewController.topInset - 5)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        let detailLabel = UILabel.newAutoLayout()
        detailLabel.attributedText = tr(.dfuRingInChargerDetailText).rly_DFUBodyString().bodyString
        detailLabel.numberOfLines = 0
        detailLabel.adjustsFontSizeToFitWidth = true
        detailLabel.preferredMaxLayoutWidth = 282
        view.addSubview(detailLabel)

        detailLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20)
        detailLabel.autoSet(dimension: .width, to: 300)
        detailLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // add ring box view to the middle of the view
        let container = UIView.newAutoLayout()
        view.addSubview(container)

        container.autoPin(edge: .top, to: .bottom, of: detailLabel, offset: 50, relation: .lessThanOrEqual)
        container.autoPinEdgeToSuperview(edge: .left, inset: 40)
        container.autoPinEdgeToSuperview(edge: .right, inset: 40)

        container.addSubview(checklist)
        checklist.autoPinEdgesToSuperviewEdges(excluding: .bottom)

        // add activity indicator aligned with button
        activity.isUserInteractionEnabled = false
        activity.autoSetDimensions(to: CGSize(width: 22, height: 22))
        activityView.addSubview(activity)
        activity.autoPinEdgesToSuperviewEdges(excluding: .trailing)
        
        let waitingLabel = UILabel.newAutoLayout()
        waitingLabel.textColor = .white
        waitingLabel.attributedText = UIFont.gothamBook(12).track(50, "Waiting for charger...").attributedString
        activityView.addSubview(waitingLabel)
        waitingLabel.autoPin(edge: .leading, to: .trailing, of: activity, offset: 5)
        waitingLabel.autoPinEdgesToSuperviewEdges(excluding: .leading)
        
        view.addSubview(activityView)
        activityView.autoAlignAxis(toSuperviewAxis: .vertical)
        activityView.autoPin(edge: .top, to: .bottom, of: container, offset: 20)
        
        // add button to the bottom of the view
        button.title = tr(.getStarted)
        view.addSubview(button)
        
        button.autoSet(dimension: .height, to: 62)
        button.autoPin(edge: .top, to: .bottom, of: activity, offset: 20)
        button.autoPinEdgeToSuperview(edge: .left, inset: 40)
        button.autoPinEdgeToSuperview(edge: .right, inset: 40)
        button.autoPinEdgeToSuperview(edge: .bottom, inset: 40)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        state.producer.start(animationDuration: 0.25, action: { [weak self] state in
            let unknown = state == nil
            self?.activityView.alpha = unknown ? 1 : 0

            let charging = state == .charging || state == .charged
            self?.button.backgroundColor = charging ? UIColor(white: 1.0, alpha: 1.0) : UIColor(white: 1.0, alpha: 0.5)
            self?.button.isUserInteractionEnabled = charging
            self?.view.layoutIfInWindowAndNeeded()
        })
    }

    var confirmedProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(button.reactive.controlEvents(.touchUpInside)).void
    }
}

extension NSAttributedString
{
    var bodyString: NSAttributedString
    {
        if DeviceScreenHeight.current > .four
        {
            return self
        }
        else
        {
            let copy = mutableCopy() as! NSMutableAttributedString
            let range = NSMakeRange(0, copy.length)
            let style = NSParagraphStyle.with(alignment: .center, lineSpacing: 2)
            copy.addAttribute(NSFontAttributeName, value: UIFont.gothamBook(11), range: range)
            copy.addAttribute(NSParagraphStyleAttributeName, value: style, range: range)
            return copy
        }
    }
}

final class DFUChecklistView : UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup()
    {
        let checklist = [tr(.dfuChecklistOne), tr(.dfuChecklistTwo), tr(.dfuChecklistThree)]
        let stackView = UIStackView.newAutoLayout()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 25
        
        for item in checklist
        {
            let itemView = UIView.newAutoLayout()
            let doneCheck = UIImageView.init(image: Asset.doneCheckSmall.image)
            doneCheck.autoSetDimensions(to: CGSize.init(width: 25, height: 25))

            
            itemView.addSubview(doneCheck)
            doneCheck.autoPinEdgeToSuperview(edge: .top, inset: 5)
            doneCheck.autoPinEdgeToSuperview(edge: .leading)
            
            let label = UILabel.newAutoLayout()
            label.textAlignment = .left
            label.textColor = .white
            label.lineBreakMode = .byWordWrapping
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 0
            label.attributedText = UIFont.gothamBook(16).track(100, item).attributedString

            itemView.addSubview(label)
            label.autoPinEdgeToSuperview(edge: .top)
            label.autoPin(edge: .leading, to: .trailing, of: doneCheck, offset: 12)
            label.autoPinEdgeToSuperview(edge: .trailing)
            label.autoPinEdgeToSuperview(edge: .bottom)
            stackView.addArrangedSubview(itemView)
        }

    }
}
