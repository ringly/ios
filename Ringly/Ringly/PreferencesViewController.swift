import UIKit

final class PreferencesViewController: ServicesViewController
{
    // MARK: - Navigation
    fileprivate let navigation = UINavigationController()

    // MARK: - View Loading
    override func loadView()
    {
        let view = GradientView.blueGreenGradientView
        self.view = view

        navigation.delegate = SlideTransitionController.sharedDelegate.horizontal
        navigation.isNavigationBarHidden = true
        navigation.pushViewController(PreferencesContentViewController(services: services), animated: false)

        addChildViewController(navigation)
        view.addSubview(navigation.view)
        navigation.view.autoPinEdgesToSuperviewEdges()
        navigation.didMove(toParentViewController: self)
    }
}

extension PreferencesViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        if navigation.viewControllers.count == 1
        {
            (navigation.viewControllers[0] as? TabBarViewControllerTappedSelectedListener)?
                .tabBarViewControllerDidTapSelectedItem()
        }
        else if navigation.viewControllers.count > 1
        {
            navigation.popViewController(animated: true)
        }
    }
}
