import AVFoundation
import UIKit

class FlashView : UIView, CAAnimationDelegate
{
    var completion: () -> () = {}

    // animation
    private let kSelectionAnimation : String = "selectionAnimation"
    private var animation : CABasicAnimation?
    
    // original brightness
    private var startingBrightness = UIScreen.main.brightness
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setup()
    {
        self.backgroundColor = UIColor.white
        self.animation = CABasicAnimation(keyPath: "opacity")
        self.animation?.fromValue = 0.0
        self.animation?.toValue = 1.0
        self.animation?.repeatCount = 1
        self.animation?.duration = 0.6
        self.animation?.delegate = self
    }
    
    func flash()
    {
        if let blink = animation {
            startingBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = CGFloat(1.0)
            self.alpha = 1.0
            self.isHidden = false
            self.layer.add(blink, forKey: kSelectionAnimation)
        }
    }
    
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        if flag {
            self.alpha = 0.0
            self.isHidden = true
            UIScreen.main.brightness = startingBrightness
        }

        completion()
    }
}
