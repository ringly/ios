import QuartzCore
import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

class TapAnimationView : UIView
{
    let circleContainer = UIView.newAutoLayout()
    let innerCircleContainer = UIView.newAutoLayout()
    let outerCircleContainer = UIView.newAutoLayout()
    let emojiContainer = UIView.newAutoLayout()
    
    let centerCircle = CenterCircle()
    let innerRing = InnerRing()
    let outerRing = OuterRing()
    
    // tap animation
    let tapLabel : UILabel = UILabel.newAutoLayout()
    
    // completed
    let youDidIt = UILabel.newAutoLayout()
    let blackBackground = UIView.newAutoLayout()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder)
    {
        super.init(coder: coder)!
    }
    
    
    private func setup()
    {
        self.isUserInteractionEnabled = false
        
        // background for tap completed
        self.addSubview(blackBackground)
        blackBackground.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        blackBackground.alpha = 0.0
        blackBackground.autoSet(dimension: .width, to: 500, relation: .lessThanOrEqual)
        blackBackground.autoSet(dimension: .height, to: 500, relation: .lessThanOrEqual)
        blackBackground.autoMatch(dimension: .height, to: .width, of: blackBackground)
        blackBackground.autoPinEdgeToSuperview(edge: .leading)
        blackBackground.autoPinEdgeToSuperview(edge: .trailing)
        blackBackground.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            (200...500).forEach({ offset in
                blackBackground.autoSet(dimension: .width, to: CGFloat(offset), relation: .greaterThanOrEqual)
            })
        })
        
        let font = UIFont.gothamBook(25)
        youDidIt.attributedText = font.track(.controlsTracking, "YOU DID IT").attributedString
        youDidIt.textAlignment = .center
        youDidIt.textColor = UIColor.white
        youDidIt.adjustsFontSizeToFitWidth = true
        youDidIt.alpha = 0.0
        self.addSubview(youDidIt)
        youDidIt.autoCenterInSuperview()
        

        self.addSubview(emojiContainer)
        emojiContainer.autoPinEdgesToSuperviewEdges()
        
        
        // tap animation view
        self.addSubview(circleContainer)
        circleContainer.autoSetDimensions(to: CGSize(width: 160, height: 160))
        circleContainer.autoCenterInSuperview()
        
        self.addSubview(innerCircleContainer)
        innerCircleContainer.autoSetDimensions(to: CGSize(width: 230, height: 230))
        innerCircleContainer.autoCenterInSuperview()
        
        self.addSubview(outerCircleContainer)
        outerCircleContainer.autoSetDimensions(to: CGSize(width: 290, height: 290))
        outerCircleContainer.autoCenterInSuperview()
        
        self.addSubview(tapLabel)
        tapLabel.autoSetDimensions(to: CGSize(width: 160, height: 160))
        tapLabel.autoCenterInSuperview()
        tapLabel.attributedText = UIFont.gothamBook(18).track(.controlsTracking, " TAP\n RINGLY").attributedString
        tapLabel.lineBreakMode = .byWordWrapping
        tapLabel.adjustsFontSizeToFitWidth = true
        tapLabel.textAlignment = .center
        tapLabel.textColor = UIColor.darkGray.withAlphaComponent(0.8)
        tapLabel.numberOfLines = 2
    }
    
    func tapsComplete()
    {
        self.circleContainer.isHidden = true
        self.innerCircleContainer.isHidden = true
        self.outerCircleContainer.isHidden = true
        self.tapLabel.isHidden = true
        self.youDidIt.alpha = 1.0
        self.blackBackground.alpha = 1.0
        
        let emojis = ["🌼", "🦄", "💫", "💎", "🍑", "🌟", "🍭", "🍍", "🥑"]
        for _ in 0...6 {
            for emoji in emojis {
                let emoji = EmojiShower(emoji: emoji)
                emojiContainer.addSubview(emoji)
                emoji.animate()
            }
        }
    }
    
    func addCenterCircle()
    {
        circleContainer.layer.insertSublayer(centerCircle, at: 0)
        innerCircleContainer.layer.addSublayer(innerRing)
        outerCircleContainer.layer.addSublayer(outerRing)
        
        timer(interval: .milliseconds(2500), on: QueueScheduler.main).take(until: reactive.lifetime.ended).startWithValues( { [weak self] _ in
            self?.addInnerRing()
        })
    }

    func addInnerRing()
    {
        // animation - circles pulsing to speed to taps
        centerCircle.expand()
        innerRing.expand()
        outerRing.expand()
        centerCircle.changeOpacity()
        innerRing.changeOpacity()
        outerRing.changeOpacity()
    }
    

}

