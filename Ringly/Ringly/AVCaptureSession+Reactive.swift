import AVFoundation
import ReactiveSwift
import RinglyExtensions
import enum Result.NoError

extension Reactive where Base: AVCaptureDevice
{
    /// Sends the current authorization status immediately once started, then whenever the app becomes active *and* the
    /// status has changed.
    ///
    /// - Parameter mediaType: The media type to retrieve the authorization status for.
    static func authorizationStatus(forMediaType mediaType: String)
        -> SignalProducer<AVAuthorizationStatus, NoError>
    {
        let becameActive = NotificationCenter.default.reactive.notifications(
            forName: .UIApplicationDidBecomeActive,
            object: UIApplication.shared
        )

        return SignalProducer(becameActive).initializeAndReplaceFuture({
            AVCaptureDevice.authorizationStatus(forMediaType: mediaType)
        }).skipRepeats()
    }

    /// Requests authorization from the user, then sends the result and completes.
    ///
    /// - Parameter mediaType: The media type to request authorization for.
    static func requestAuthorization(forMediaType mediaType: String)
        -> SignalProducer<AVAuthorizationStatus, NoError>
    {
        return SignalProducer { observer, _ in
            AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: { _ in
                observer.send(value: AVCaptureDevice.authorizationStatus(forMediaType: mediaType))
                observer.sendCompleted()
            })
        }
    }

    /// Reports the current authorization status as a boolean (`true` implies `.authorized`). If the authorization
    /// status is not determined, requests authorization from the user.
    ///
    /// - Parameter mediaType: The media type to retrieve or request authorization for.
    static func autoRequestAuthorization(forMediaType mediaType: String)
        -> SignalProducer<Bool, NoError>
    {
        func producerForStatus(_ status: AVAuthorizationStatus) -> SignalProducer<Bool, NoError>
        {
            switch status
            {
            case .authorized:
                return SignalProducer(value: true)
            case .denied, .restricted:
                return SignalProducer(value: false)
            case .notDetermined:
                return requestAuthorization(forMediaType: mediaType).flatMap(.latest, transform: producerForStatus)
            }
        }

        return authorizationStatus(forMediaType: mediaType).flatMap(.latest, transform: producerForStatus).skipRepeats()
    }
}
