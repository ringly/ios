import AVFoundation

class CameraFocusCircle : UIView, CAAnimationDelegate
{
    
    internal let kSelectionAnimation : String = "selectionAnimation"
    var animation : CABasicAnimation?
    
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    
    convenience init(touch: CGPoint)
    {
        self.init()
        self.updatePoint(touch)
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = 100
        self.layer.borderColor = UIColor.ringlyBlue.withAlphaComponent(0.7).cgColor
        self.layer.borderWidth = 2
        setup()
    }
    
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setup()
    {
        self.animation = CABasicAnimation(keyPath: "cornerRadius")
        self.animation?.fromValue = self.layer.cornerRadius
        self.animation?.toValue = self.layer.cornerRadius + 30
        self.animation?.repeatCount = 2
        self.animation?.duration = 0.4
        self.animation?.delegate = self
    }
    
    
    func updatePoint(_ touch : CGPoint)
    {
        self.frame = CGRect(x: touch.x - 50,
                                    y: touch.y - 50,
                                    width: 100,
                                    height: 100)
    }
    
    
    func animateFocus()
    {
        if let blink = animation {
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
        }
    }
}
