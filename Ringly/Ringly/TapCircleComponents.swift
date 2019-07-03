import RinglyExtensions
import ReactiveSwift
import UIKit
import enum Result.NoError

private let animationDuration : CFTimeInterval = 0.15

class CenterCircle : CAShapeLayer
{
    override init()
    {
        super.init()
        frame = CGRect(x: 0.0, y: 0.0, width: 160, height: 160)
        fillColor = UIColor.white.withAlphaComponent(0.8).cgColor
        path = beginCircle.cgPath
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder: ) is not implemented")
    }
    
    var beginCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: 150.0, height: 150.0))
    }
    
    var endCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 160.0, height: 160.0))
    }

    func expand()
    {
        let pulse: CABasicAnimation = CABasicAnimation(keyPath: "path")
        pulse.fromValue = beginCircle.cgPath
        pulse.toValue = endCircle.cgPath
        pulse.duration = animationDuration
        pulse.repeatCount = 2
        pulse.isRemovedOnCompletion = false
        pulse.autoreverses = true
        self.add(pulse, forKey: nil)
    }
    
    func changeOpacity()
    {
        let opacity: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1.0
        opacity.toValue = 0.9
        opacity.duration = animationDuration
        opacity.isRemovedOnCompletion = false
        opacity.repeatCount = 2
        self.add(opacity, forKey: nil)
    }
}

class InnerRing : CAShapeLayer
{
    override init()
    {
        super.init()
        frame = CGRect(x: 0.0, y: 0.0, width: 230, height: 230)
        fillColor = UIColor.clear.cgColor
        strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        lineWidth = 6.0
        path = beginCircle.cgPath
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder: ) is not implemented")
    }
    
    var beginCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 15, y: 15, width: 200.0, height: 200.0))
    }
    
    var endCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 230.0, height: 230.0))
    }
    
    func expand()
    {
        let pulse: CABasicAnimation = CABasicAnimation(keyPath: "path")
        pulse.fromValue = beginCircle.cgPath
        pulse.toValue = endCircle.cgPath
        pulse.duration = animationDuration
        pulse.repeatCount = 2
        pulse.isRemovedOnCompletion = false
        pulse.autoreverses = true
        self.add(pulse, forKey: nil)
    }
    
    func changeOpacity()
    {
        let opacity: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1.0
        opacity.toValue = 0.5
        opacity.duration = animationDuration
        opacity.isRemovedOnCompletion = false
        opacity.repeatCount = 2
        self.add(opacity, forKey: nil)
    }
}

class OuterRing : CAShapeLayer
{
    override init()
    {
        super.init()
        frame = CGRect(x: 0.0, y: 0.0, width: 290, height: 290)
        fillColor = UIColor.clear.cgColor
        strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        lineWidth = 6.0
        path = beginCircle.cgPath
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder: ) is not implemented")
    }
    
    var beginCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 25, y: 25, width: 240.0, height: 240.0))
    }
    
    var endCircle : UIBezierPath {
        return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 290.0, height: 290.0))
    }
    
    func expand()
    {
        let pulse: CABasicAnimation = CABasicAnimation(keyPath: "path")
        pulse.fromValue = beginCircle.cgPath
        pulse.toValue = endCircle.cgPath
        pulse.duration = animationDuration
        pulse.repeatCount = 2
        pulse.isRemovedOnCompletion = false
        pulse.autoreverses = true
        self.add(pulse, forKey: nil)
    }
        
    func changeOpacity()
    {
        let opacity: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1.0
        opacity.toValue = 0.2
        opacity.duration = animationDuration
        opacity.isRemovedOnCompletion = false
        opacity.repeatCount = 2
        self.add(opacity, forKey: nil)
    }
}

class EmojiShower : UIView
{
    private let emoji = UILabel()
    private let size = CGFloat.random(minimum: 32, maximum: 64)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    private func setup()
    {
        self.addSubview(emoji)
        emoji.autoPin(edge: .top, to: .top, of: self)
        emoji.autoPin(edge: .left, to: .left, of: self)
        isHidden = true
    }
    
    convenience init(emoji : String)
    {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 35.0))
        self.emoji.text = emoji
        self.emoji.font = UIFont.systemFont(ofSize: size)
    }
    
    func animationPath() -> UIBezierPath
    {
        let size = UIScreen.main.bounds.size
        let x = CGFloat.random(minimum: -30, maximum: size.width)
        let y = CGFloat.random(minimum: 0, maximum: size.height)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: -20 - size.height + y))
        path.addLine(to: CGPoint(x: x, y: size.height + y + self.size * 4))

        return path
    }

    func animate()
    {
        isHidden = false

        let position = CAKeyframeAnimation(keyPath: "position")
        position.path = animationPath().cgPath
        position.rotationMode = kCAAnimationPaced
        position.duration = 2.5
        position.fillMode = kCAFillModeForwards
        position.isRemovedOnCompletion = false
        layer.add(position, forKey: nil)
    }
}

