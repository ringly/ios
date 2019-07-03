import AVFoundation
import PureLayout
import ReactiveSwift
import Result
import UIKit

/// A view controller that displays a video as a background
final class VideoBackgroundViewController: UIViewController
{
    // MARK: - Configuration
    enum Completion
    {
        /// The video should loop indefinitely.
        case loop

        /// A callback function should be called when the video completes.
        case callback(() -> ())
    }

    typealias Configuration = (videoURL: URL, completion: Completion)

    let configuration = MutableProperty(Configuration?.none)

    // MARK: - Video Effect

    /// The layer in which the video is played.
    fileprivate let playerLayer = AVPlayerLayer()

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // don't stop background music
        do
        {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        }
        catch let error as NSError
        {
            SLogGeneric("Error changing audio session properties \(error)")
        }

        // add a video player layer
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, at: 0)

        // determine whether or not we are currently showing the video
        let showVideo = SignalProducer.merge(
            reactive.viewWillAppear.map({ _ in true }), // video should be shown once view appears
            reactive.viewDidDisappear.map({ _ in false }) // video should be stopped once view disappears
        )

        // when we are showing the video, observe the value of the video property
        let configurationProducer = configuration.producer
        let currentConfiguration = showVideo.flatMap(.latest, transform: { showVideo in
            showVideo ? configurationProducer : SignalProducer(value: nil)
        })

        // create player objects from non-nil URLs
        let currentPlayer = currentConfiguration.mapOptional({ url, completion -> (AVPlayer, Completion) in
            let player = AVPlayer(url: url)
            player.isMuted = true
            player.actionAtItemEnd = .none
            return (player, completion)
        })

        currentPlayer
            // start playing the video
            .on(value: { [weak self] tuple in
                self?.playerLayer.player = tuple?.0
                tuple?.0.play()
            })

            // observe events to restart playback when necessary
            .flatMapOptional(.latest, transform: { player, completion -> SignalProducer<(), NoError> in
                let center = NotificationCenter.default.reactive

                return SignalProducer.merge(
                    SignalProducer(
                        center.notifications(forName: .AVPlayerItemDidPlayToEndTime, object: nil)
                    ).on(value: { notification in
                        switch completion
                        {
                        case .loop:
                            if player.currentItem === notification.object as AnyObject
                            {
                                player.seek(to: kCMTimeZero)
                                player.play()
                            }
                        case let .callback(function):
                            function()
                        }
                    }),
                    SignalProducer(
                        center.notifications(forName: .UIApplicationWillEnterForeground, object: UIApplication.shared)
                    ).on(value: { _ in player.play() })
                ).ignoreValues()
            })
            .start()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        playerLayer.frame = view.bounds
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        playerLayer.frame = CGRect(origin: CGPoint.zero, size: size)
    }

    // MARK: - View Controller
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}
