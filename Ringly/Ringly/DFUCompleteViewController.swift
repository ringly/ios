import RinglyExtensions
import UIKit

final class DFUCompleteViewController: UIViewController
{
    // MARK: - Peripheral Style
    var peripheralStyle: RLYPeripheralStyle?

    // MARK: - Subviews
    fileprivate let doneButton = ButtonControl.newAutoLayout()
    fileprivate let doneCheck = UIImageView.init(image: Asset.doneCheckLarge.image)
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add title label
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.attributedText = tr(.dfuCompleteText).rly_DFUTitleString()
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 45).priority = UILayoutPriorityDefaultLow
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 10, relation: .greaterThanOrEqual)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // add body label
        let bodyLabel = UILabel.newAutoLayout()
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.attributedText = tr(.dfuCompleteDetailText).rly_DFUBodyString()
        bodyLabel.sizeToFit()
        view.addSubview(bodyLabel)

        bodyLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20)
        bodyLabel.autoSet(dimension: .width, to: 300, relation: .lessThanOrEqual)
        bodyLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        // add done check image
        let checkContainer = UIView.newAutoLayout()
        view.addSubview(checkContainer)
        
        checkContainer.autoPinEdgeToSuperview(edge: .leading)
        checkContainer.autoPinEdgeToSuperview(edge: .trailing)
        checkContainer.autoPin(edge: .top, to: .bottom, of: bodyLabel, offset: 50).priority = UILayoutPriorityDefaultLow
        checkContainer.autoPin(edge: .top, to: .bottom, of: bodyLabel, offset: 10, relation: .greaterThanOrEqual)
        
        checkContainer.addSubview(doneCheck)
        doneCheck.autoSetDimensions(to: CGSize.init(width: 140, height: 140))
        doneCheck.autoCenterInSuperview()
        
        let close:((Any)->()) = { [weak self] _ in
            if let strongSelf = self
            {
                strongSelf.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
        // add done button
        doneButton.title = tr(.done)
        view.addSubview(doneButton)
        
        doneButton.autoSet(dimension: .height, to: 62)
        doneButton.autoPinEdgeToSuperview(edge: .leading, inset: 40)
        doneButton.autoPinEdgeToSuperview(edge: .trailing, inset: 40)
        doneButton.autoPin(edge: .top, to: .bottom, of: checkContainer, offset: 40)
        doneButton.autoPinEdgeToSuperview(edge: .bottom, inset: 40)
        doneButton.reactive.controlEvents(.touchUpInside).observeValues(close)
    }
}

extension DFUCompleteViewController: DFUChildViewController
{
    func update(_ state: RLYPeripheralStyle?)
    {
        peripheralStyle = state
    }
}
