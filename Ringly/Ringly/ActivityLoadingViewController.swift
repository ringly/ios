import UIKit

final class ActivityLoadingViewController: UIViewController
{
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let indicator = DiamondActivityIndicator.newAutoLayout()
        view.addSubview(indicator)

        indicator.constrainToDefaultSize()
        indicator.autoCenterInSuperview()
    }
}
