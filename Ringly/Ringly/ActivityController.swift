import PureLayout
import UIKit

/// A view controller that presents an activity indicator over a blurred background.
public final class ActivityController: UIViewController
{
    public init()
    {
        super.init(nibName: nil, bundle: nil)
        
        // set presentation and transition style
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    public required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        // set presentation and transition style
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    public override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // add blur view
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        blurView.autoPinEdgesToSuperviewEdges()
        
        // add vibrancy view within blur view
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blur))
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(vibrancyView)
        vibrancyView.autoPinEdgesToSuperviewEdges()
        
        // add activity indicator view
        let activityIndicator = DiamondActivityIndicator.newAutoLayout()
        blurView.contentView.addSubview(activityIndicator)
        activityIndicator.autoCenterInSuperview()
        activityIndicator.constrainToDefaultSize()
    }
    
    public override var prefersStatusBarHidden : Bool
    {
        return presentingViewController?.prefersStatusBarHidden ?? true
    }
    
    public override var preferredStatusBarStyle : UIStatusBarStyle
    {
        return presentingViewController?.preferredStatusBarStyle ?? .lightContent
    }
}
