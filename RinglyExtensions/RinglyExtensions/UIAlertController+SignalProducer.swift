import ReactiveSwift
import UIKit
import enum Result.NoError

extension UIAlertController
{
    // MARK: - Choice

    /**
     A producer that will present an alert controller, and yield the user's choice.
     
     If the user does not choose a value, the producer will complete without sending a value.

     - parameter title:          The alert controller's title.
     - parameter message:        The alert controller's message.
     - parameter preferredStyle: The alert controller's preferred style.
     - parameter viewController: The view controller to present the alert controller in.
     - parameter choices:        The choices displayed by the alert controller.
     */
    public static func choose<Value>(title: String? = nil,
                                     message: String? = nil,
                                     preferredStyle: UIAlertControllerStyle,
                                     inViewController viewController: UIViewController,
                                     choices: [AlertControllerChoice<Value>])
                                     -> SignalProducer<Value, NoError>
    {
        return SignalProducer { observer, _ in
            let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)

            let actions = choices.map({ choice in
                UIAlertAction(title: choice.title, style: choice.style, handler: { _ in
                    observer.send(value: choice.value)
                    observer.sendCompleted()
                })
            })

            actions.forEach(controller.addAction)

            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                observer.sendCompleted()
            }))

            viewController.present(controller, animated: true, completion: nil)
        }
    }
}

public struct AlertControllerChoice<Value>
{
    public init(title: String, style: UIAlertActionStyle = .default, value: Value)
    {
        self.title = title
        self.style = style
        self.value = value
    }

    let title: String
    let style: UIAlertActionStyle
    let value: Value
}
