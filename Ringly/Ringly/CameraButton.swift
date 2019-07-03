import UIKit

final class CameraButton: UIButton
{
    
    // MARK: - Initialization
    private func setup()
    {
        showsTouchWhenHighlighted = true
        self.autoSetDimensions(to: CGSize(width: 64, height: 64))
        self.frame = self.frame.insetBy(dx: -30, dy: -30)
        self.layer.cornerRadius = 32
        self.clipsToBounds = false
        self.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        
        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        
        
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
