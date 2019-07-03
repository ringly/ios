import ReactiveSwift
import Result
import UIKit

extension UIViewController
{
    // MARK: - Presenting Alerts

    /// Presents an alert view controller above the receiver.
    ///
    /// - Parameter setup: A function to initialize the alert view controller.
    func presentAlert(setup: (AlertViewController) -> ())
    {
        let alert = AlertViewController()
        setup(alert)
        alert.present(above: self)
    }

    /**
     Presents an alert above the view controller.

     - parameter title:   The alert title.
     - parameter message: The alert message.
     */
    func presentAlert(title: String, message: String)
    {
        presentAlert { alert in
            alert.content = AlertImageTextContent(text: title, detailText: message)
            alert.actionGroup = .single(action: (title: tr(.close), dismiss: true, action: {}))
        }
    }
    
    /**
     Presents an alert above the view controller.
     
     - parameter title:   The alert title.
     - parameter message: The alert message.
     - parameter image: The alert image.
     */
    func presentAlert(title: String, message: String, image: UIImage)
    {
        presentAlert { alert in
            alert.content = AlertImageTextContent(image: image, text: title, detailText: message)
            alert.actionGroup = .single(action: (title: tr(.close), dismiss: true, action: {}))
        }
    }

    // MARK: - Presenting Error Alerts

    /**
     Creates a producer to present an error alert above the view controller, completing after the alert is dismissed.

     - parameter error:             The error to present.
     - parameter closeButtonTitle:  The alert's close button title.
     */
    func presentErrorProducer(_ error: NSError, closeButtonTitle: String = tr(.close))
        -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, disposable in
            // TODO: disposable?
            DispatchQueue.main.async(execute: {
                AlertViewController(error: error, closeButtonTitle: closeButtonTitle, closeAction: observer.sendCompleted)
                    .present(above: self)
            })
        }
    }
    
    // MARK: - Presenting DFU Error Alerts
    
    /**
     Creates a producer to present an error alert above the view controller, completing after the alert is dismissed.
     
     - parameter error:             The error to present.
     */
    func presentDFUErrorProducer(_ error: NSError)
        -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, disposable in
            // TODO: disposable, configure alert to error type?
            DFUAlertViewController(alertType: .didNotUpdate, closeAction: observer.sendInterrupted).present(above: self)
        }
    }

    /**
     Presents an error above the view controller.

     - parameter error: The error to present.
     */
    func presentError(_ error: NSError)
    {
        presentErrorProducer(error).start()
    }
}
