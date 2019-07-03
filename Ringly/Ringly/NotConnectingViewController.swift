import ReactiveSwift
import UIKit
import enum Result.NoError

/// The view controller displaying the "Not Connecting?" interface.
final class NotConnectingViewController: UIViewController, ClosableConnectOverlay
{
    // MARK: - View Loading
    override func loadView()
    {
        // add component info views
        let asleep = NotConnectingInfoView.newAutoLayout()
        asleep.title = "IS YOUR RINGLY ASLEEP?"
        asleep.body = "If sleep mode is turned on, your Ringly will disconnect when it is not moving. Move your Ringly to wake it up."
        asleep.image = UIImage(asset: .notConnectingAsleep)

        let proximity = NotConnectingInfoView.newAutoLayout()
        proximity.title = "IS YOUR RINGLY CLOSE BY?"
        proximity.body = "Your Ringly needs to be in close proximity to your phone in order to connect."
        proximity.image = UIImage(asset: .notConnectingProximity)

        let charged = NotConnectingInfoView.newAutoLayout()
        charged.title = "IS YOUR RINGLY CHARGED?"
        charged.body = "If your Ringly battery dies, it will disconnect from your phone. Charging it will allow you to connect."
        charged.image = UIImage(asset: .notConnectingLowBattery)
        
        let dfuFailed = NotConnectingInfoView.newAutoLayout()
        dfuFailed.title = "IS YOUR RINGLY FLASHING COLORS?"
        dfuFailed.body = "If your Ringly did not update correctly, it will flash rainbow colors. Press the '+' button on the Connect screen to restart update."
        dfuFailed.image = UIImage(asset: .dfuBolt)
        
        // create the prompt
        let prompt = ConnectPromptView(
            frame: .zero,
            infoViews: [asleep, proximity, charged, dfuFailed],
            infoViewsWidth: 310,
            minimumInfoViewSpacing: 28,
            desiredInfoViewSpacing: 41
        )

        prompt.title = "NOT\nCONNECTING?"
        prompt.closeProducer.start(closePipe.1)

        let scrollView = UIScrollView.newAutoLayout()
        scrollView.clipsToBounds = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(prompt)
        prompt.autoPinEdgesToSuperviewEdges()
        prompt.autoAlignAxis(toSuperviewAxis: .vertical)
        
        self.view = scrollView
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }

    // MARK: - Closing

    /// A backing pipe for `closeProducer`.
    fileprivate let closePipe = Signal<(), NoError>.pipe()

    /// A producer for notifying an observer that the user has tapped the "close" button.
    var closeProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(closePipe.0)
    }
}
