import AVFoundation
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit

/// Wraps an AVFoundation capture session, allowing multiple clients to easily attach.
final class CaptureSession
{
    // MARK: - Initialization
    init(devicePosition: AVCaptureDevicePosition)
    {
        self.devicePosition = MutableProperty(devicePosition)

        // determine the capture device for the requested position
        device = self.devicePosition.map({ position in
            (AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice]).flatMap({ devices in
                devices.first(where: { $0.position == position })
            })
        })

        // create an input from each selected capture device
        input = device.map({ optional in
            optional.map({ device in
                materialize { try AVCaptureDeviceInput(device: device) }
            })
        })

        // attach inputs to session
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        self.session = session

        if session.canAddOutput(output)
        {
            session.addOutput(output)
        }

        input.producer.combinePrevious(nil).startWithValues({ previous, current in
            if let previousInput = previous?.value
            {
                session.removeInput(previousInput)
            }

            switch current
            {
            case let .some(.success(input)):
                if session.canAddInput(input)
                {
                    session.addInput(input)
                }
                else
                {
                    SLogGeneric("Cannot add input \(input)")
                }

            case let .some(.failure(error)):
                SLogGeneric("Capture session error: \(error)")

            case .none:
                break
            }
        })

        ready = Property.combineLatest(input, started).map({ $0 != nil && $1 }).skipRepeats()

        // start on a background thread, to prevent issues with
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            session.startRunning()
//            self?.started.value = true
//        }

        session.startRunning()
        self.started.value = true
    }

    // MARK: - Changing Device
    let devicePosition: MutableProperty<AVCaptureDevicePosition>

    // MARK: - AVFoundation
    fileprivate let session: AVCaptureSession
    private let device: Property<AVCaptureDevice?>
    private let input: Property<Result<AVCaptureInput, AnyError>?>
    private let output = AVCaptureStillImageOutput()

    // MARK: - Readiness
    private let started = MutableProperty(false)
    let ready: Property<Bool>

    // MARK: - Capturing

    /// Captures an image from the session.
    func capture() -> SignalProducer<(display: UIImage, save: UIImage), NSError>
    {
        let bufferProducer: SignalProducer<CMSampleBuffer, NSError> = SignalProducer.`defer` {
            guard let connection = self.output.connection(withMediaType: AVMediaTypeVideo) else {
                return SignalProducer(error: UnknownError() as NSError) // TODO: real error
            }

            return SignalProducer { observer, _ in
                self.output.captureStillImageAsynchronously(
                    from: connection,
                    completionHandler: observer.completionHandler
                )
            }
        }

        return devicePosition.producer
            .promoteErrors(NSError.self)
            .combineLatest(with: bufferProducer)
            .take(first: 1)
            .map({ position, buffer in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)

                let cgImageRef = CGImage(
                    jpegDataProviderSource: CGDataProvider(data: imageData! as CFData)!,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: .defaultIntent
                )!

                let width = CGFloat(cgImageRef.width), height = CGFloat(cgImageRef.height)
                let size = min(width, height)
                let cropped = cgImageRef.cropping(to: CGRect(x: width / 2 - size / 2, y: height / 2 - size / 2, width: size, height: size))

                if position == .front
                {
                    return (
                        display: UIImage(cgImage: cropped!, scale: 1.0, orientation: .leftMirrored),
                        save: UIImage(cgImage: cropped!, scale: 1.0, orientation: .rightMirrored)
                    )
                }
                else
                {
                    let image = UIImage(cgImage: cropped!, scale: 1.0, orientation: .right)
                    return (display: image, save: image)
                }
            })
    }

    // MARK: - Configuration
    func configure(exposure: (mode: AVCaptureExposureMode, pointOfInterest: CGPoint)? = nil,
                   flashMode: AVCaptureFlashMode? = nil,
                   focus: (mode: AVCaptureFocusMode, pointOfInterest: CGPoint)? = nil,
                   zoomFactor: CGFloat? = nil)
        throws
    {
        guard let device = self.device.value else { return }

        try device.lockForConfiguration()

        if let (mode, pointOfInterest) = exposure
        {
            device.exposurePointOfInterest = pointOfInterest
            device.exposureMode = mode
        }

        if let flashMode = flashMode
        {
            device.flashMode = flashMode
        }

        if let (mode, pointOfInterest) = focus,
            device.isFocusPointOfInterestSupported,
            device.isFocusModeSupported(mode)
        {
            device.focusPointOfInterest = pointOfInterest
            device.focusMode = mode
        }

        if let zoomFactor = zoomFactor
        {
            device.videoZoomFactor = zoomFactor
        }

        device.unlockForConfiguration()
    }

    var maxZoomFactor: CGFloat
    {
        return device.value?.activeFormat.videoMaxZoomFactor ?? 1
    }

    var isFlashAvailable: Bool
    {
        return device.value?.isFlashAvailable ?? false
    }

    var flashMode: AVCaptureFlashMode
    {
        return device.value?.flashMode ?? .off
    }
}

extension Reactive where Base: UIViewController
{
    /// Authorizes for video capture, then presents a capture session. If an authorization error occurs, presents an
    /// "open settings" alert.
    func authorizeCaptureSession(devicePosition: AVCaptureDevicePosition) -> SignalProducer<CaptureSession?, NoError>
    {
        return AVCaptureDevice.reactive.autoRequestAuthorization(forMediaType: AVMediaTypeVideo)
            .observe(on: UIScheduler())
            .on(value: { [weak base] authorized in
                guard let strong = base, !authorized else { return }
                AlertViewController(openSettingsDetailText: tr(.cameraAuthorizationDenied)).present(above: strong)
            })
            .map({ $0 ? CaptureSession(devicePosition: devicePosition) : nil })
    }
}

final class CaptureSessionView: UIView
{
    // MARK: - Properties

    /// The capture session currently displayed by the view. Modify this property to display a new capture session.
    let captureSession = MutableProperty(CaptureSession?.none)

    /// When `true`, a black shutter closes over the image.
    var shutterClosed = false { didSet { setNeedsLayout() } }

    // MARK: - View Components

    /// The preview layer displayed in this view, set by `captureSession`.
    private let previewLayer = MutableProperty(AVCaptureVideoPreviewLayer?.none)

    /// A black overlay view, used to mask
    private let shutterViews = (0..<9).map({ _ in UIView.newAutoLayout() })

    // MARK: - Initialization
    private func setup()
    {
        clipsToBounds = true

        // a producer for only sessions that have been started
        let readySession: SignalProducer<CaptureSession?, NoError> = captureSession.producer
            .flatMapOptionalFlat(.latest, transform: { (session: CaptureSession) -> SignalProducer<CaptureSession?, NoError> in
                session.ready.producer.map({ [weak session] in $0 ? session : nil })
            })
            .skipRepeatsOptional(===)

        // create preview layers for each new session
        previewLayer <~ readySession.mapOptionalFlat({ session in
            let previewLayer = AVCaptureVideoPreviewLayer(session: session.session)
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewLayer?.connection?.videoOrientation = .portrait
            return previewLayer
        })

        previewLayer.producer
            .combinePrevious(nil)
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] previous, current in
                previous?.removeFromSuperlayer()

                if let newLayer = current, let strong = self
                {
                    strong.layer.insertSublayer(newLayer, at: 0)
                    strong.setNeedsLayout()
                }
            })

        shutterViewsWithAngles.forEach({ angle, view in
            view.transform = CGAffineTransform(rotationAngle: angle)
            view.backgroundColor = .black
            addSubview(view)
        })
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        previewLayer.value?.frame = layer.bounds

        let size = bounds.size
        let radius = sqrt(pow(size.width, 2) + pow(size.height, 2))

        let offset = shutterClosed ? radius / 2 : radius

        shutterViewsWithAngles.forEach({ angle, view in
            view.bounds = CGRect(x: 0, y: 0, width: radius, height: radius)
            view.center = CGPoint(
                x: size.width / 2 + cos(angle) * offset,
                y: size.height / 2 + sin(angle) * offset
            )
        })
    }

    private var shutterViewsWithAngles: [(CGFloat, UIView)]
    {
        return shutterViews.enumerated().map({ index, view in
            let fraction = CGFloat(index) / CGFloat(shutterViews.count)
            return (fraction * CGFloat(M_PI * 2), view)
        })
    }
}
