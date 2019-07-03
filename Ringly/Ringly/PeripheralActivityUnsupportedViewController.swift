import ReactiveSwift
import UIKit
import enum Result.NoError

enum PeripheralActivityUnsupportedReason
{
    case updateRequired
    case unavailable
}

extension PeripheralActivityUnsupportedReason: AlertViewControllerContent
{
    // MARK: - Alert Content View
    var alertContentView: UIView
    {
        return AlertImageTextContent(image: image, text: text, detailText: detailText).alertContentView
    }

    // MARK: - Alert Action Group
    func alertActionGroup(showAction: Bool, action: @escaping () -> ()) -> AlertViewController.ActionGroup
    {
        let dismiss = (title: dismissTitle, dismiss: true, action: {})

        return showAction
            ? .double(action: (title: actionTitle, dismiss: true, action: action), dismiss: dismiss)
            : .single(action: dismiss)
    }

    // MARK: - Content Components
    fileprivate var image: UIImage?
    {
        switch self
        {
        case .unavailable:
            return UIImage(asset: .activityUnavailable)
        case .updateRequired:
            return UIImage(asset: .tabConnect)
        }
    }

    fileprivate var text: String
    {
        switch self
        {
        case .unavailable:
            return "THIS RINGLY\nDOESN'T SUPPORT\nACTIVITY."
        case .updateRequired:
            return "UNLOCK NEW FEATURES"
        }
    }

    fileprivate var detailText: String
    {
        switch self
        {
        case .unavailable:
            return "Not to worry!\nYou can still track activity\nusing the Health app."
        case .updateRequired:
            return "Update this Ringly to add activity tracking."
        }
    }

    fileprivate var actionTitle: String
    {
        switch self
        {
        case .unavailable:
            return "LET’S DO IT"
        case .updateRequired:
            return trUpper(.goForIt)
        }
    }

    fileprivate var dismissTitle: String
    {
        switch self
        {
        case .unavailable:
            return "OK, I GOT IT"
        case .updateRequired:
            return "NOT NOW"
        }
    }
}
