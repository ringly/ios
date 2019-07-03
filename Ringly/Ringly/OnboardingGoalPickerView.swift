//
//  PreferencesGoalPickerView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/17/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class OnboardingGoalPickerView: UIView {
    var title: String?
        {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue?.pickerTitleAttributedString
        }
    }
    
    /// A label displaying `title`.
    fileprivate let titleLabel = UILabel.newAutoLayout()
    
    /// A label displaying `quantity`, as modified by `formatter`.
    fileprivate let quantityLabel = UILabel.newAutoLayout()
    
    /// The control to increase the `quantity`.
    fileprivate let increaseControl = UIButton.newAutoLayout()
    
    /// The control to decrease the `quantity`.
    fileprivate let decreaseControl = UIButton.newAutoLayout()
    
    let quantity = MutableProperty(Int?.none)

    
    func setup() {
        // add buttons
        let normalPixel = UIImage.rly_pixel(with: ButtonControl.defaultFillColor)
        let highlightedPixel = UIImage.rly_pixel(with: ButtonControl.defaultHighlightedFillColor)
        
        increaseControl.accessibilityLabel = "Increase"
        increaseControl.setImage(UIImage(asset: .onboardingPlus), for: UIControlState())
        increaseControl.setBackgroundImage(normalPixel, for: .normal)
        increaseControl.setBackgroundImage(highlightedPixel, for: .highlighted)
        addSubview(increaseControl)
        
        decreaseControl.accessibilityLabel = "Decrease"
        decreaseControl.setImage(UIImage(asset: .onboardingMinus), for: UIControlState())
        decreaseControl.setBackgroundImage(normalPixel, for: .normal)
        decreaseControl.setBackgroundImage(highlightedPixel, for: .highlighted)
        addSubview(decreaseControl)

        let controlSize = CGSize.init(width: 45, height: 45)
        [decreaseControl, increaseControl].forEach({
            $0.autoSetDimensions(to: controlSize)
            $0.layer.cornerRadius = controlSize.width / 2
            $0.clipsToBounds = true
        })
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.quantityLabel)
        
        self.quantityLabel.autoPinEdgeToSuperview(edge: .top)
        self.quantityLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        self.titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        self.titleLabel.autoPin(edge: .top, to: .bottom, of: self.quantityLabel, offset: 10)
        
        self.increaseControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        self.decreaseControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        self.increaseControl.autoPinEdgeToSuperview(edge: .right, inset: 40)
        self.decreaseControl.autoPinEdgeToSuperview(edge: .left, inset: 40)
        
        quantity.producer.skipNil().startWithValues({ [weak self] quantity in
            guard let strong = self else { return }
            let goalFormatter = NumberFormatter()
            goalFormatter.usesGroupingSeparator = true
            goalFormatter.numberStyle = .decimal
            strong.quantityLabel.attributedText = goalFormatter.string(from: NSNumber.init(value: quantity))?.quantityAttributedString
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

    // MARK: - Actions
    
    enum Action { case increase, decrease }

    
    var actionsProducer: SignalProducer<Action, NoError>
    {
        return SignalProducer.merge(
            decreaseControl.repeatedTouchProducer.map({ _ in .decrease }),
            increaseControl.repeatedTouchProducer.map({ _ in .increase })
        )
    }
}

extension String
{
    
    fileprivate var pickerTitleAttributedString: NSAttributedString
    {
        return uppercased().attributes(
            color: .white,
            font: .gothamBook(22),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 300
        )
    }
    
    fileprivate var quantityAttributedString: NSAttributedString
    {
        return self.attributes(
            color: .white,
            font: .gothamBook(40),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 150
        )
    }
}
