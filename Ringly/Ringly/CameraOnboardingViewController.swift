import PureLayout
import UIKit

/// A view controller displayed when user first uses camera feature.
final class CameraOnboardingViewController: ServicesViewController
{
    // MARK: - Child View Controllers
    private let video = VideoBackgroundViewController()
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // add the video view controller first, as a background for all other views
        addChildViewController(video)
        view.addSubview(video.view)
        video.view.autoPinEdgesToSuperviewEdges()
        video.didMove(toParentViewController: self)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        video.configuration.value = Bundle.main.url(forResource: "camera", withExtension: "mp4").map({ url in
            (videoURL: url, completion: .callback({ [weak self] in
                guard let strong = self else { return }
                let camera = CameraViewController(services: strong.services)
                camera.mode.value = .onboarding
                strong.navigationController?.setViewControllers([camera], animated: true)
            }))
        })
    }
    
    // MARK: - View Controller
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}
