import UIKit

/// Contains the controls for the standard camera interface.
final class CameraButtonsView: UIView
{
    // MARK: - Buttons

    /// camera button to take picture
    let takePicture = CameraButton.newAutoLayout()

    /// switch camera
    let switchCamera = UIButton.newAutoLayout()

    /// info button
    let info = UIButton.newAutoLayout()

    /// flash settings
    let flash = UIButton.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        // setup camera button
        addSubview(takePicture)
        takePicture.autoAlignAxis(toSuperviewAxis: .vertical)
        takePicture.autoPinEdgeToSuperview(edge: .top)

        // setup switch camera button
        switchCamera.setImage(UIImage(asset: .cameraFlip), for: .normal)
        switchCamera.imageEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        switchCamera.showsTouchWhenHighlighted = true
        addSubview(switchCamera)

        switchCamera.autoAlignAxis(toSuperviewAxis: .vertical)
        switchCamera.autoPinEdgeToSuperview(edge: .bottom)
        switchCamera.autoPin(edge: .top, to: .bottom, of: takePicture, offset: 16)

        // setup flash button and add front flash view
        flash.setImage(UIImage(asset: .flashOff), for: .normal)
        flash.showsTouchWhenHighlighted = true
        addSubview(flash)

        flash.autoPinEdgeToSuperview(edge: .left, inset: 45)
        flash.autoAlign(axis: .horizontal, toSameAxisOf: switchCamera)

        // setup info button
        info.setImage(UIImage(asset: .info), for: .normal)
        info.showsTouchWhenHighlighted = true
        addSubview(info)

        info.autoPinEdgeToSuperview(edge: .right, inset: 45)
        info.autoConstrain(attribute: .height, to: .height, of: flash)
        info.autoConstrain(attribute: .width, to: .height, of: info)
        info.autoAlign(axis: .horizontal, toSameAxisOf: switchCamera)
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
}
