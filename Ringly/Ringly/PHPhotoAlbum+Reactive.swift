import AVFoundation
import Photos
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit
import enum Result.NoError

extension UIViewController
{
    /// Saves the specified image to the "Ringly" photo album, creating it if necessary.
    ///
    /// - Parameter image: The image to save.
    @nonobjc func saveImageToRinglyAlbum(_ image: UIImage)
    {
        PHPhotoLibrary.reactive.requestAuthorization()
            .flatMap(.concat, transform: { status -> SignalProducer<(), NSError> in
                switch status
                {
                case .notDetermined:
                    fatalError()

                case .authorized:
                    let library = PHPhotoLibrary.shared()
                    return library.reactive.fetchOrCreateRinglyAssetCollection()
                        .flatMap(.concat, transform: { library.reactive.save(image: image, to: $0) })

                case .denied, .restricted: // TODO: design alert?
                    return SignalProducer.empty
                }
            })
            .observe(on: UIScheduler())
            .start(on: QueueScheduler(qos: .userInitiated, name: "SavingPhoto"))
            .startWithFailed({ [weak self] in self?.presentError($0) })
    }
}

extension Reactive where Base: PHPhotoLibrary
{
    /// A producer that, once started, will request authorization if necessary and possible.
    static func requestAuthorization() -> SignalProducer<PHAuthorizationStatus, NoError>
    {
        return SignalProducer { observer, _ in
            let status = PHPhotoLibrary.authorizationStatus()

            switch status
            {
            case .authorized, .denied, .restricted:
                observer.send(value: status)
                observer.sendCompleted()

            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({ status in
                    observer.send(value: status)
                    observer.sendCompleted()
                })
            }
        }
    }

    /// Creates a signal producer that saves the image to the specified asset collection.
    ///
    /// - Parameters:
    ///   - image: The image to save.
    ///   - collection: The collection to save to.
    /// - Returns: A producer that will complete after saving, or send an error if saving fails.
    func save(image: UIImage, to collection: PHAssetCollection) -> SignalProducer<(), NSError>
    {
        return SignalProducer { observer, _ in
            self.base.performChanges({
                let photoChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let photoPlaceholder = photoChangeRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: collection)
                albumChangeRequest!.addAssets([photoPlaceholder!] as NSArray)
            }, completionHandler: observer.completionHandler)
        }
    }

    /// Creates a signal producer that saves the image to the specified asset collection.
    ///
    /// - Parameters:
    ///   - asset: The asset to save.
    ///   - collection: The collection to save to.
    /// - Returns: A producer that will complete after saving, or send an error if saving fails.
    func save(asset: PHAsset, to collection: PHAssetCollection) -> SignalProducer<(), NSError>
    {
        return SignalProducer { observer, _ in
            self.base.performChanges({
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: collection)
                albumChangeRequest!.addAssets([asset] as NSArray)
            }, completionHandler: observer.completionHandler)
        }
    }

    /// Creates a signal producer that creates an asset collection with the specified title.
    ///
    /// - Parameter title: The title for the asset collection.
    /// - Returns: A producer that will complete after creating the asset collection, or send an error if the operation
    ///            fails.
    func createAssetCollection(named title: String) -> SignalProducer<PHAssetCollection, NSError>
    {
        let create: SignalProducer<(), NSError> = SignalProducer { observer, _ in
            self.base.performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            }, completionHandler: observer.completionHandler)
        }

        let fetch: SignalProducer<PHAssetCollection, NoError> = SignalProducer
            .deferValue({ PHAssetCollection.fetch(named: title) })
            .skipNil()

        return create.then(fetch)
    }

    /// Creates a signal producer that will retrieve and yield an asset collection with the specified title, and, if an
    /// asset collection matching the title does not exist, will create a new asset collection with the title and yield
    /// it.
    ///
    /// - Parameter title: The title of the asset collection to search for or create.
    /// - Returns: A producer that will send a single asset collection value, then complete, or will send an error.
    func fetchOrCreateAssetCollection(named title: String) -> SignalProducer<PHAssetCollection, NSError>
    {
        return SignalProducer.`defer` {
            PHAssetCollection.fetch(named: title).map(SignalProducer.init) ?? self.createAssetCollection(named: title)
        }
    }

    /// Creates a signal producer that will retrieve and yield an asset collection with the Ringly-specific title, and,
    /// if an asset collection matching the title does not exist, will create a new asset collection with the title and
    /// yield it.
    ///
    /// - Returns: A producer that will send a single asset collection value, then complete, or will send an error.
    func fetchOrCreateRinglyAssetCollection() -> SignalProducer<PHAssetCollection, NSError>
    {
        return fetchOrCreateAssetCollection(named: "Ringly")
    }
}

extension PHAssetCollection
{
    fileprivate static func fetch(named title: String) -> PHAssetCollection?
    {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options).firstObject
    }
}
