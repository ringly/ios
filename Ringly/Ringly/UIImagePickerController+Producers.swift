import MobileCoreServices
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit

extension UIImagePickerController
{
    enum SelectError: Error
    {
        /// The user requested that the image be removed.
        case remove
    }

    static func selectImageProducer(in viewController: UIViewController,
                                    includeRemove: Bool = false,
                                    allowEditing: Bool = false)
        -> SignalProducer<UIImage, SelectError>
    {
        return selectSourceProducer(in: viewController, includeRemove: includeRemove)
            .flatMap(.latest, transform: { source -> SignalProducer<UIImage, NoError> in
                UIImagePickerController.presentImagePickerProducer(
                    in: viewController,
                    sourceType: source,
                    allowEditing: allowEditing
                )
            })
    }

    static func selectSourceProducer(in viewController: UIViewController, includeRemove: Bool = false)
        -> SignalProducer<UIImagePickerControllerSourceType, SelectError>
    {
        var choices: [AlertControllerChoice<Result<UIImagePickerControllerSourceType, SelectError>>] = []

        if includeRemove
        {
            choices.append(AlertControllerChoice(title: "Remove Photo", style: .destructive, value: .failure(.remove)))
        }

        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            choices.append(AlertControllerChoice(title: "Take Photo", value: .success(.camera)))
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        {
            choices.append(AlertControllerChoice(title: "Choose Photo", value: .success(.photoLibrary)))
        }

        return UIAlertController.choose(
            preferredStyle: .actionSheet,
            inViewController: viewController,
            choices: choices
        ).deresultify()
    }

    static func presentImagePickerProducer(in viewController: UIViewController,
                                           sourceType: UIImagePickerControllerSourceType,
                                           allowEditing: Bool = false)
        -> SignalProducer<UIImage, NoError>
    {
        return SignalProducer { observer, _ in
            let picker = UIImagePickerController()

            let delegate = ImagePickerDelegate { delegate, optionalImage in
                if let image = optionalImage
                {
                    observer.send(value: image)
                }

                picker.dismiss(animated: true, completion: observer.sendCompleted)

                activeDelegates.remove(delegate)
            }

            picker.delegate = delegate
            picker.transitioningDelegate = SlideTransitionController.sharedDelegate.vertical
            picker.mediaTypes = [kUTTypeImage as String]
            picker.allowsEditing = allowEditing
            picker.sourceType = sourceType

            viewController.present(picker, animated: true, completion: nil)

            activeDelegates.insert(delegate)
        }
    }
}

private var activeDelegates: Set<ImagePickerDelegate> = []

private final class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    init(complete: @escaping (ImagePickerDelegate, UIImage?) -> ())
    {
        self.complete = complete
    }

    let complete: (ImagePickerDelegate, UIImage?) -> ()

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        let image = info[UIImagePickerControllerEditedImage] as? UIImage
                 ?? info[UIImagePickerControllerOriginalImage] as? UIImage

        complete(self, image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        complete(self, nil)
    }
}
