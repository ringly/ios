import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

final class ActivityDayProgressCell: UICollectionViewCell
{
    let moveMoreView = GoalSummaryControl.newAutoLayout()

    
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
    
    func setup()
    {
        contentView.addSubview(moveMoreView)
        moveMoreView.translatesAutoresizingMaskIntoConstraints = false
        moveMoreView.autoPinEdgesToSuperviewEdges()
        moveMoreView.autoSet(dimension: .height, to: 80)
        moveMoreView.layer.shadowColor = UIColor.gray.cgColor
        moveMoreView.layer.shadowOffset = CGSize.init(width: 0, height: 2)
        
        moveMoreView.progressColorScheme.value = ActivityProgressColorScheme.stepsDay()
        moveMoreView.title.value = tr(.stayActive)
        moveMoreView.indicatorImage.isHidden = true
        moveMoreView.descriptionFormat.value = "%@ of %@ steps"
        
        self.isUserInteractionEnabled = true
    }
}
