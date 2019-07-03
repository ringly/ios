import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

final class ActivityDayEmptyStateCell: UICollectionViewCell
{
    let containerView = UIView.newAutoLayout()
    let sadFace = UILabel.newAutoLayout()
    let title = UILabel.newAutoLayout()
    let subtitle = UILabel.newAutoLayout()
    
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
        let size = bounds.size
        
        let titleSize: CGFloat = 16
        let subtitleSize: CGFloat = 12
        func attributes(_ string: AttributedStringProtocol, size: CGFloat, tracking: CGFloat) -> NSAttributedString
        {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 1.3
            paragraphStyle.alignment = .center
            paragraphStyle.maximumLineHeight = 25
            return string.attributes(
                font: UIFont.gothamBook(size),
                paragraphStyle: paragraphStyle,
                tracking: tracking
            )
        }
        
        backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        containerView.backgroundColor = UIColor.init(white: 0.85, alpha: 1.0)
        containerView.autoSetDimensions(to: CGSize(width: size.width - 30.0, height: size.height - 60.0))
        contentView.addSubview(containerView)
        containerView.autoFloatInSuperview()
        
        let titleText = "WE DON'T HAVE ANY DATA FOR THIS DAY!"
        let subtitleText = "Looks like we didn't record any data for this day. Get up and get moving!"
        sadFace.attributedText = UIFont.gothamBook(35).track(50, "😥").attributedString
        title.attributedText = attributes(titleText, size: titleSize, tracking: 250.0)
        subtitle.attributedText = attributes(subtitleText, size: subtitleSize, tracking: 130.0)
        
        title.textAlignment = .center
        title.textColor = UIColor(white: 0.1, alpha: 1.0)
        title.lineBreakMode = .byWordWrapping
        title.numberOfLines = 2
        title.adjustsFontSizeToFitWidth = true
        title.autoSet(dimension: .width, to: size.width - 110.0)
        
        subtitle.textAlignment = .center
        subtitle.textColor = UIColor(white: 0.2, alpha: 1.0)
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.numberOfLines = 0
        subtitle.autoSet(dimension: .width, to: size.width - 80.0)
        
        containerView.addSubview(sadFace)
        containerView.addSubview(title)
        containerView.addSubview(subtitle)
        sadFace.autoPinEdgeToSuperview(edge: .top, inset: 20)
        sadFace.autoAlignAxis(toSuperviewAxis: .vertical)
        title.autoPin(edge: .top, to: .bottom, of: sadFace, offset: 10)
        title.autoAlignAxis(toSuperviewAxis: .vertical)
        subtitle.autoPin(edge: .top, to: .bottom, of: title, offset: 10)
        subtitle.autoPinEdgeToSuperview(edge: .bottom, inset: 20)
        subtitle.autoAlignAxis(toSuperviewAxis: .vertical)
        
        self.isUserInteractionEnabled = true
    }
}
