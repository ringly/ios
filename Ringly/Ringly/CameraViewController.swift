import AVFoundation
import Photos
import PureLayout
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit
import enum Result.NoError

final class CameraViewController: ServicesViewController
{
    // MARK: - Mode
    enum Mode
    {
        /// The view controller displays the onboarding interface, and prompts the user to tap her peripheral twice.
        case onboarding

        /// The view controller displays the camera interface, and allows the user to take a photo.
        case camera
    }

    /// The current view controller mode to use.
    let mode = MutableProperty(Mode.camera)

    // MARK: - Capture Session

    /// The current capture session associated with the view controller.
    private let captureSession = MutableProperty(CaptureSession?.none)

    /// Whether or not flash should be used.
    private let useFlash = MutableProperty(false)

    var previewLayer : AVCaptureVideoPreviewLayer?
    var focusCircle : CameraFocusCircle?

    // MARK: - View Loading
    private let cameraView = CameraView()

    override func loadView()
    {
        self.view = RotatingGradientView.pinkGradientView(start: 0.3, end: 1)
        self.view.backgroundColor = UIColor.clear

        self.view.addSubview(cameraView)
        cameraView.autoPinEdgesToSuperviewEdges()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // show correct accessory views
        cameraView.showOnboarding <~ mode.producer.map({ $0 == .onboarding })
        cameraView.reactive.useFlash <~ useFlash
        
        // add actions for camera buttons
        cameraView.reactive.takePicture.observeValues({ [weak self] in self?.capturePicture(trigger: .uiButton) })
        cameraView.reactive.switchCamera.observeValues({ [weak self] in self?.switchCamera() })
        cameraView.reactive.switchFlash.observeValues({ [weak self] in self?.didPressFlash() })
        cameraView.reactive.showOnboarding.observeValues({ [weak self] in self?.helpCamera() })

        // add action for exit button
        cameraView.reactive.exit.observeValues({ [weak self] in self?.exitCamera() })

        // add action for exiting onboarding
        cameraView.reactive.skipOnboarding.observeValues({ [weak self] in
            self?.mode.value = .camera
            self?.services.analytics.track(AnalyticsEvent.profileSaved)
        })

        // detect double tap gesture to switch camera view
        cameraView.pinch.addTarget(self, action: #selector(self.pinchToZoom(_:)))
        cameraView.reactive.captureSession <~ captureSession
        
        // capture taps
        let visible = SignalProducer.merge(
            reactive.viewDidAppear.map({ true }),
            reactive.viewWillDisappear.map({ false })
        )
        
        //TODO: when reactivating this feature, test that it works from this refactor
        let receivedTaps = services.peripherals.activatedPeripheral.producer.skipNil()
            .flatMap(.latest, transform: { $0.reactive.receivedTaps })
            .filter({ $0 == 2 })
        

        visible.sample(on: receivedTaps.void)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] visible in
                guard let strong = self, visible else { return }

                switch strong.mode.value
                {
                case .onboarding:
                    strong.cameraView.showOnboardingCompletion().startWithCompleted({
                        self?.mode.value = .camera
                    })

                    strong.services.analytics.track(AnalyticsEvent.selfieDemoComplete(trigger: .peripheral))

                case .camera:
                    if strong.captureSession.value?.ready.value ?? false
                    {
                        strong.capturePicture(trigger: .peripheral)
                    }
                }
            })

        // automatically request authorization if necessary, otherwise, initialize the capture session
        captureSession <~ reactive.viewDidAppear.take(first: 1)
            .then(reactive.authorizeCaptureSession(devicePosition: .front))

        // present the DFU alert for buggy Madison versions
        let incompatiblePeripherals = services.peripherals.activatedPeripheral.producer
            .flatMapOptionalFlat(.latest, transform: { peripheral in
                peripheral.reactive.applicationVersion.mapOptional({ (version: $0, peripheral: peripheral) })
            })
            .skipNil()
            .filter({ $0.version.versionNumberIs(after: "2", before: "2.2.2") })

        reactive.viewDidAppear.take(first: 1)
            .then(incompatiblePeripherals)
            .take(first: 1)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] _, peripheral in
                self?.presentAlert { alert in
                    alert.content = AlertImageTextContent(
                        text: tr(.updateYourRingly),
                        detailText: tr(.cameraNeedsUpdateDetailText)
                    )

                    alert.actionGroup = .actionOrClose(title: tr(.okExclamation), action: {
                        guard let strong = self else { return }
                        strong.presentDFU(services: strong.services, peripheral: peripheral)
                    })
                }
            })
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard
            let captureSession = self.captureSession.value,
            let touch = touches.first,
            touches.count < 2
        else { return }

        let x = touch.location(in: view).x / cameraView.frame.width
        let y = touch.location(in: view).y / cameraView.frame.height
        let focusPoint = CGPoint(x: x, y: y)
        
        let touchLocation = CGPoint(x: touch.location(in: view).x, y: touch.location(in: view).y)

        if cameraView.captureSessionView.frame.contains(touchLocation) {
            do {
                try captureSession.configure(
                    exposure: (mode: .continuousAutoExposure, pointOfInterest: focusPoint),
                    focus: (mode: .autoFocus, pointOfInterest: focusPoint)
                )

                if let focus = self.focusCircle {
                    focus.updatePoint(touchLocation)
                }
                else {
                    self.focusCircle = CameraFocusCircle(touch: touchLocation)
                    self.view.addSubview(self.focusCircle!)
                    self.focusCircle?.setNeedsDisplay()
                }
            
                self.focusCircle?.animateFocus()
            } catch let error as NSError {
                SLogGeneric("Error refocusing camera: \(error)")
            }
        }
    }

    func capturePicture(trigger: AnalyticsTrigger)
    {
        guard let captureSession = self.captureSession.value else { return }

        let usingFrontCamera = captureSession.devicePosition.value == .front

        if useFlash.value && usingFrontCamera
        {
            cameraView.flash()
        }


        UIView.animate(withDuration: 0.25, animations: {
            self.cameraView.captureSessionView.shutterClosed = true
            self.cameraView.captureSessionView.layoutIfNeeded()
        })

        captureSession.capture().observe(on: UIScheduler()).startWithResult({ [weak self] result in
            guard let strong = self else { return }

            switch result
            {
            case let .success(display, save):
                strong.saveImageToRinglyAlbum(save)

                let secondViewController = PhotoViewController(services: strong.services)
                secondViewController.photoView.updateImage(display)
                strong.navigationController?.pushViewController(secondViewController, animated: false)

            case let .failure(error):
                strong.presentError(error)
            }

            UIView.animate(withDuration: 0.25, animations: {
                self?.cameraView.captureSessionView.shutterClosed = false
                self?.cameraView.captureSessionView.layoutIfNeeded()
            })
        })

        services.analytics.track(AnalyticsEvent.selfieSnap(trigger: trigger))
    }

    func pinchToZoom(_ pinch : UIPinchGestureRecognizer)
    {
        guard let captureSession = self.captureSession.value, pinch.state == .changed else { return }

        do
        {
            try captureSession.configure(zoomFactor: max(1, min(pinch.scale, captureSession.maxZoomFactor)))
        }
        catch let error as NSError
        {
            SLogGeneric("Error setting camera zoom: \(error)")
        }
    }
    
    func switchCamera()
    {
        guard let captureSession = self.captureSession.value else { return }
        captureSession.devicePosition.modify({ $0 = $0 == .front ? .back : .front })
    }
    
    func handlePinchGesture(_ pinchRecognizer: UIPinchGestureRecognizer)
    {
        let point = pinchRecognizer.location(in: self.cameraView)
        let frameOfInterest = self.cameraView.captureSessionView.frame
        if frameOfInterest.contains(point) {
            self.pinchToZoom(pinchRecognizer)
        }
    }
    
    func didPressFlash()
    {
        useFlash.modify({ $0 = !$0 })

        guard let captureSession = self.captureSession.value, captureSession.isFlashAvailable else { return }

        do
        {
            try captureSession.configure(flashMode: useFlash.value ? .on : .off)
        }
        catch let error as NSError
        {
            SLogGeneric("Error setting camera zoom: \(error)")
        }
    }
    
    func exitCamera()
    {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func helpCamera()
    {
        let camVC = CameraOnboardingViewController(services: self.services)
        navigationController?.setViewControllers([camVC], animated: true)
    }

    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override var shouldAutorotate: Bool
    {
        return false
    }
}
