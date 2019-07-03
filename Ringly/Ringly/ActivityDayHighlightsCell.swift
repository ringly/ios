import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

final class ActivityDayHighlightsCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource
{
    let tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
    let wakeupModel = HighlightModel.init(image: UIImage(asset: .sunLarge),
                                          title: "Rise And Shine: %@",
                                          subtitle: "First tracked activity",
                                          time: MutableProperty<String>(""),
                                          count: nil)
    let topHourModel = HighlightModel.init(image: UIImage(asset: .starLarge),
                                           title: "Top Hour: %@",
                                           subtitle: "%@ steps",
                                           time: MutableProperty<String>(""),
                                           count: MutableProperty<Int>(0))
    var highlightModels: [HighlightModel]
    
    let sections = ["Highlights"]

    override init(frame: CGRect)
    {
        self.highlightModels = [topHourModel]
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        self.highlightModels = [topHourModel]
        super.init(coder: coder)
        setup()
    }
    
    func setup()
    {
        tableView.registerCellType(ActivityHighlightsTableViewCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        tableView.estimatedSectionHeaderHeight = 50
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        
        contentView.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellOfType(ActivityHighlightsTableViewCell.self, forIndexPath: indexPath)
        let model = self.highlightModels[indexPath.row]
        
        if model == self.wakeupModel
        {
            cell.populate(model: model, withCount: false)
        }
        else if model == self.topHourModel
        {
            cell.populate(model: model, withCount: true)
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.highlightModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: contentView.frame.width, height: 50))
        
        let label = UILabel(frame: containerView.frame.insetBy(dx: 16, dy: 0))
        label.attributedText = self.sections[section].uppercased().attributes(
            color: UIColor.init(white: 0.5, alpha: 1.0),
            font: UIFont.gothamBook(12),
            paragraphStyle: nil,
            tracking: .controlsTracking
            ).attributedString
        
        containerView.addSubview(label)
        
        return containerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
}

class ActivityHighlightsTableViewCell: UITableViewCell {
    
    let exerciseIcon = UIImageView.newAutoLayout()
    let titleLabel = UILabel.newAutoLayout()
    let subtitleLabel = UILabel.newAutoLayout()
    
    // Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        self.selectionStyle = .none
        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        
        let bgView = UIView.newAutoLayout()
        bgView.backgroundColor = .white
        self.contentView.addSubview(bgView)
        bgView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8))
        
        exerciseIcon.contentMode = .scaleAspectFit
        bgView.addSubview(exerciseIcon)
        exerciseIcon.autoSetDimensions(to: CGSize.init(width: 24, height: 24))
        exerciseIcon.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 38, left: 16, bottom: 38, right: 0), excluding: .right)
        
        titleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.adjustsFontSizeToFitWidth = true
        
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        bgView.addSubview(stackView)
        stackView.autoPin(edge: .left, to: .right, of: exerciseIcon, offset: 16)
        stackView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 25, left: 0, bottom: 25, right: 16), excluding: .left)
    }
    
    func populate(model: HighlightModel, withCount: Bool) {
        self.exerciseIcon.image = model.image
        
        let titleFontSize = DeviceScreenHeight.current.select(four: 13, five: 13, preferred: 16)

        model.time.producer.startWithValues { time in
                self.titleLabel.attributedText = String(
                    format: model.title, time)
                    .attributes(color: UIColor.init(white: 0.2, alpha: 1.0), font: UIFont.gothamBook(CGFloat(titleFontSize)), paragraphStyle: nil, tracking: 125.0)
        }
        
        if withCount {
            let numberFormatter = NumberFormatter()
            numberFormatter.usesGroupingSeparator = true
            numberFormatter.numberStyle = .decimal
            
            model.count?.producer.startWithValues { count in
                if count > 0 {
                    self.subtitleLabel.attributedText = String(
                        format: model.subtitle,
                        numberFormatter.string(from: NSNumber(value: count))!
                        ).attributes(color: UIColor.init(white: 0.2, alpha: 0.7), font: UIFont.gothamBook(12), paragraphStyle: nil, tracking: 100.0)
                }
            }
        }
        else {
            self.subtitleLabel.attributedText = model.subtitle.attributes(color: UIColor.init(white: 0.2, alpha: 0.7), font: UIFont.gothamBook(12), paragraphStyle: nil, tracking: 100.0)
        }
    }
}

struct HighlightModel {
    let image:UIImage
    let title:String
    let subtitle:String
    let time:MutableProperty<String>
    let count:MutableProperty<Int>?
}

extension HighlightModel: Equatable {}
func ==(lhs: HighlightModel, rhs: HighlightModel) -> Bool
{
    return lhs.image == rhs.image &&
           lhs.title == rhs.title &&
           lhs.subtitle == rhs.subtitle &&
           lhs.time.value == rhs.time.value
}
