import ReactiveSwift
import UIKit

final class PreferencesSwitchesPagesViewController: ServicesViewController
{
    // MARK: - Switches
    let visibleSwitch = MutableProperty(PreferencesSwitch?.none)

    // MARK: - Child View Controllers
    fileprivate let blurContainer = UIView.newAutoLayout()
    fileprivate let pages = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add blur effect
        view.addSubview(blurContainer)
        blurContainer.autoPinEdgesToSuperviewEdges()

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurContainer.addSubview(blur)
        blur.autoPinEdgesToSuperviewEdges()

        // add pages view controller
        addChildViewController(pages)
        view.addSubview(pages.view)
        pages.view.autoPinEdgesToSuperviewEdges()
        pages.didMove(toParentViewController: self)
    }

    // MARK: - View Lifecyle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        pages.dataSource = self

        // initialize with the first visible switch
        visibleSwitch.producer.skipNil().take(first: 1).startWithValues({ [weak self] preferencesSwitch in
            guard let strong = self else { return }
            let controller = strong.detailViewController(preferencesSwitch)
            strong.pages.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
        })
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension PreferencesSwitchesPagesViewController
{
    fileprivate func detailViewController(_ preferencesSwitch: PreferencesSwitch)
        -> PreferencesSwitchDetailViewController
    {
        let controller = PreferencesSwitchDetailViewController()
        controller.preferencesSwitch.value = preferencesSwitch

        controller.closeProducer
            .take(until: controller.reactive.lifetime.ended)
            .startWithValues({ [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            })

        controller.switchControl.bindProducer(preferencesSwitch: preferencesSwitch, to: services.preferences)
            .take(until: controller.reactive.lifetime.ended)
            .start()

        return controller
    }
}

extension PreferencesSwitchesPagesViewController: UIPageViewControllerDataSource
{
    fileprivate func relativeViewController(_ offset: Int, from current: UIViewController)
        -> PreferencesSwitchDetailViewController?
    {
        let all = PreferencesSwitch.all

        return (current as? PreferencesSwitchDetailViewController)
            .flatMap({ $0.preferencesSwitch.value })
            .flatMap({ all.index(of: $0) })
            .map({ $0 + offset })
            .flatMap({ (index: Int) -> PreferencesSwitchDetailViewController? in
                index >= all.startIndex && index < all.endIndex
                    ? detailViewController(all[index])
                    : nil
            })
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
                            -> UIViewController?
    {
        return relativeViewController(1, from: viewController)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
                            -> UIViewController?
    {
        return relativeViewController(-1, from: viewController)
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        return (pageViewController.viewControllers?.first as? PreferencesSwitchDetailViewController)
            .flatMap({ $0.preferencesSwitch.value })
            .flatMap({ PreferencesSwitch.all.index(of: $0) })
            ?? 0
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return PreferencesSwitch.all.count
    }
}

extension PreferencesSwitchesPagesViewController: ForegroundBackgroundContentViewProviding
{
    var foregroundContentView: UIView? { return pages.view }
    var backgroundContentView: UIView? { return blurContainer }
}
