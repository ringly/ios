import Foundation
import ReactiveSwift
import UIKit
import enum Result.NoError

/// Displays the "Follow these steps..." interface.
final class RemovePeripheralViewController: UIViewController, ClosableConnectOverlay
{
    // MARK: - View Loading
    override func loadView()
    {
        let prompt = ConnectPromptView(
            frame: .zero,
            infoViews: [
                DFUOpenSettingsSubview.openSettingsView(with: UIImage(asset: .removePeripheralOpenSettings)!),
                DFUOpenSettingsSubview.bluetoothView(),
                DFUOpenSettingsSubview.findRinglyView(),
                DFUOpenSettingsSubview.forgetThisDeviceView()
            ],
            infoViewsWidth: 310,
            minimumInfoViewSpacing: 20,
            desiredInfoViewSpacing: 41
        )

        prompt.title = "FOLLOW THESE STEPS TO DISCONNECT YOUR RINGLY"
        prompt.closeProducer.start(closePipe.1)

        self.view = prompt
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
