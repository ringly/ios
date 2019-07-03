import ReactiveSwift
import Result
import UIKit

extension UIViewController
{
    /// Presents an interface for collecting diagnostic data from the user.
    ///
    /// - Parameters:
    ///   - services: The services object to collect data from.
    ///   - reference: The user's reference value, typically a Zendesk thread.
    @nonobjc func collectDiagnosticData(from services: Services, queryItems: [URLQueryItem]?)
    {
        let stepProducer: SignalProducer<CollectDiagnosticDataStep, NSError> = SignalProducer(value: .collecting)
            .concat(services.diagnosticDataRequestProducer(queryItems: queryItems)
                .flatMap(.concat, transform: { request in
                    SignalProducer(value: .uploading).concat(
                        services.api.producer(for: request).ignoreValues(CollectDiagnosticDataStep.self)
                    )
                })
            )

        presentAlert { alert in
            weak var weakAlert = alert // compiler issue workaround for [weak alert]

            stepProducer.observe(on: UIScheduler()).on(completed: {
                weakAlert?.content = AlertActivityContent(
                    text: tr(.finishedUploadingDiagnosticData),
                    activityIndicatorType: .emoji(symbol:"💎")
                )
                
                RLYDispatchAfterMain(1.5, { weakAlert?.dismiss() })
            }).startWithResult({ result in
                switch result
                {
                case let .success(step):
                    weakAlert?.content = step.alertContent
                case let .failure(error):
                    weakAlert?.content = AlertImageTextContent(error: error)
                    weakAlert?.error = error
                    weakAlert?.actionGroup = .close
                }
            })
        }
    }
}

private enum CollectDiagnosticDataStep
{
    case collecting
    case uploading
}

extension CollectDiagnosticDataStep
{
    var alertContent: AlertViewControllerContent
    {
        switch self
        {
        case .collecting:
            return AlertActivityContent(text: tr(.collectingDiagnosticData), activityIndicatorType: .ui)
        case .uploading:
            return AlertActivityContent(text: tr(.uploadingDiagnosticData), activityIndicatorType: .ui)
        }
    }
}
