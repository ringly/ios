import ReactiveSwift
import UIKit

final class PreferencesBodyDataViewController: UIViewController
{
    // MARK: - Subviews
    fileprivate let navigationBar = NavigationBar.newAutoLayout()

    // MARK: - Child View Controller
    var childViewController: UIViewController?
    {
        didSet
        {
            oldValue?.removeFromParentViewControllerImmediately()

            if let new = childViewController
            {
                addChildViewController(new)
                view.addSubview(new.view)
                new.view.autoPinEdgesToSuperviewEdges(excluding: .top)
                new.view.autoPin(edge: .top, to: .bottom, of: navigationBar)
                new.didMove(toParentViewController: self)
            }
        }
    }

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        navigationBar.title.value = .text("ACTIVITY")
        navigationBar.backAvailable.value = true
        view.addSubview(navigationBar)
        navigationBar.autoSet(dimension: .height, to: NavigationBar.standardHeight)
        navigationBar.autoPinEdgesToSuperviewEdges(excluding: .bottom)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        navigationBar.backProducer.startWithValues({ [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        })
    }
}
