import RinglyDFU

final class DFUActivityViewController: UIViewController, DFUStatelessChildViewController
{
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let activity = DiamondActivityIndicator.newAutoLayout()
        activity.constrainToDefaultSize()
        view.addSubview(activity)
        activity.autoCenterInSuperview()
    }
}
