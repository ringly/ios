import AVFoundation
import Photos
import PureLayout
import ReactiveCocoa
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit
import enum Result.NoError

final class PhotoViewController: ServicesViewController
{
    
    let photoView : PhotoView = PhotoView()

    override func loadView()
    {
        self.view = RotatingGradientView.pinkGradientView(start: 0.3, end: 1)
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(photoView)
        photoView.autoPinEdgesToSuperviewEdges()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        photoView.backButton.addTarget(self, action: #selector(PhotoViewController.takePicture), for: .touchUpInside)
        photoView.shareButton.addTarget(self, action: #selector(PhotoViewController.sharePicture), for: .touchUpInside)
        photoView.exitButton.addTarget(self, action: #selector(PhotoViewController.exitCamera), for: .touchUpInside)

        // analytics for filter buttons
        let analytics = services.analytics

        let pairs = [
            (photoView.ringlyGem, AnalyticsSticker.gem),
            (photoView.ringlyIcon, AnalyticsSticker.rLogo),
            (photoView.ringlyWord, AnalyticsSticker.ringly)
        ]

        Signal.merge(pairs.map({ button, sticker in
            button.reactive.controlEvents(.touchUpInside).map({ _ in sticker })
        })).observeValues({ sticker in
            analytics.track(AnalyticsEvent.selfieAddSticker(sticker: sticker))
        })
    }

    func takePicture()
    {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear ,animations: {
            self.photoView.layer.opacity = 0.1
        }, completion: { _ in
            _ = self.navigationController?.popViewController(animated: true)
        })
    }
    
    func sharePicture()
    {
        let activityVC: UIActivityViewController

        // save image
        if (photoView.gemOn || photoView.wordOn || photoView.iconOn) {
            let originalImage = photoView.imageView.image
            let filters = UIImage(view: photoView.filterView)

            let newSize = filters.size
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)

            originalImage?.draw(in: CGRect(origin: .zero, size: newSize))
            filters.draw(in: CGRect(origin: .zero, size: newSize))

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            activityVC = UIActivityViewController(activityItems: [newImage!], applicationActivities: nil)
        }
        else {
            activityVC = UIActivityViewController(activityItems: [photoView.imageView.image!], applicationActivities: nil)
        }

        // once the user successfully shares the image, if they saved it to the camera roll, attempt to add it to the
        // "Ringly" album.
        activityVC.completionWithItemsHandler = { [weak self] type, completed, items, error in
            guard completed else { return }
            
            self?.services.analytics.track(AnalyticsEvent.selfieShareComplete(type: type))

            if type == UIActivityType.saveToCameraRoll
            {
                let fetchOptions = PHFetchOptions()
                fetchOptions.fetchLimit = 1
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                if let first = PHAsset.fetchAssets(with: fetchOptions).firstObject
                {
                    let library = PHPhotoLibrary.shared()
                    library.reactive.fetchOrCreateRinglyAssetCollection()
                        .flatMap(.concat, transform: { library.reactive.save(asset: first, to: $0) })
                        .startWithFailed({ SLogGeneric("Error saving asset to album: \($0)") })
                }
                else
                {
                    SLogGeneric("No asset found, cannot move to Ringly album")
                }
            }
        }
        
        present(activityVC, animated: true, completion: nil)

        services.analytics.track(AnalyticsEvent.selfieShareOpen)
    }
    
    func exitCamera()
    {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension UIImage
{
    convenience init(view: UIView)
    {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}


