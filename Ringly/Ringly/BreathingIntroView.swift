//
//  BreathingIntroView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/10/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class BreathingIntroView: UIView, UIGestureRecognizerDelegate {
    
    let (startBreathingSignal, startBreathingObserver) = Signal<DispatchTimeInterval, NoError>.pipe()
    fileprivate let breathingSettingsView:BreathingSettingsView
    fileprivate let titleLabel = UILabel.newAutoLayout()
    fileprivate let descriptionLabel = UILabel.newAutoLayout()
    fileprivate let startBreathingButton = UIButton.newAutoLayout()
    
    fileprivate var breathingSettingsConstraint:NSLayoutConstraint?
    fileprivate var contentStackViewCenterConstraint:NSLayoutConstraint?
    fileprivate let backgroundTap = UITapGestureRecognizer()
    
    fileprivate let preferences: Preferences
    
    init(preferences: Preferences) {
        self.preferences = preferences
        self.breathingSettingsView = BreathingSettingsView.init(preferences: preferences)
        
        super.init(frame: CGRect.zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundTap.addTarget(self, action: #selector(self.collapseSettings))
        backgroundTap.delegate = self
        self.addGestureRecognizer(backgroundTap)
        
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.alignment = .center
        self.addSubview(stackView)
        stackView.autoPinEdgeToSuperview(edge: .left, inset: 46)
        stackView.autoPinEdgeToSuperview(edge: .right, inset: 46)
        self.contentStackViewCenterConstraint = stackView.autoAlign(axis: .horizontal, toSameAxisOf: self, offset: -52)
        
        titleLabel.attributedText = "TAKE A BREATHER".introAttributedString
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = "Collect your focus with a short breathing exercise.".introAttributedString
        
        //MARK: Breathing Button
        startBreathingButton.setBackgroundImage(Asset.backgroundRing.image, for: .normal)
        startBreathingButton.reactive.controlEvents(.touchUpInside)
            .observeValues({ [weak self] _ in
                if let weakSelf = self {
                    weakSelf.startBreathingObserver.send(value: .minutes(weakSelf.breathingSettingsView.minuteSelected.value))
                }
            })

        let iconImageView = UIImageView.init(image: Asset.mindfulnessBreath.image)
        iconImageView.contentMode = .scaleAspectFit
        startBreathingButton.addSubview(iconImageView)
        iconImageView.autoAlign(axis: .horizontal, toSameAxisOf: startBreathingButton, offset: -15)
        iconImageView.autoAlignAxis(toSuperviewAxis: .vertical	)

        let iconLabelView = UILabel.newAutoLayout()
        iconLabelView.attributedText = "BEGIN".startBreathingTextAttributedString
        startBreathingButton.addSubview(iconLabelView)
        iconLabelView.autoAlignAxis(toSuperviewAxis: .vertical)
        iconLabelView.autoAlign(axis: .horizontal, toSameAxisOf: startBreathingButton, offset: 20)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(startBreathingButton)
        stackView.addArrangedSubview(descriptionLabel)
        
        startBreathingButton.autoSetDimensions(to: CGSize.init(width: 150, height: 150))
        
        breathingSettingsView.seeMoreTapped.startWithValues {
        
            if self.breathingSettingsConstraint?.constant == -110 {
                self.breathingSettingsConstraint?.constant = -169
                self.contentStackViewCenterConstraint?.constant = -100
            } else {
                self.breathingSettingsConstraint?.constant = -110
                self.contentStackViewCenterConstraint?.constant = -52
            }
                
            UIView.animate(withDuration: 0.3, animations: { 
                self.layoutIfNeeded()
            })
        }
        self.addSubview(breathingSettingsView)
        breathingSettingsView.autoPinEdgeToSuperview(edge: .left)
        breathingSettingsView.autoPinEdgeToSuperview(edge: .right)
        self.breathingSettingsConstraint = breathingSettingsView.autoPin(edge: .top, to: .bottom, of: self, offset: -110)
    }
    
    func fadeOut(completion:@escaping (()->Void)) {
        let initialFadeOut = UIView.animationProducer(duration: 0.2) { 
            self.breathingSettingsView.alpha = 0.0
            self.titleLabel.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
        }
        
        let beginButtonFade = UIView.animationProducer(duration: 0.4) {
            self.startBreathingButton.alpha = 0.0
            self.startBreathingButton.transform = self.startBreathingButton.transform.scaledBy(x: 1.4, y: 1.4)
        }
        
        SignalProducer.concat([
                initialFadeOut,
                beginButtonFade
            ]).startWithCompleted {
                completion()
        }
    }
    
    func collapseSettings() {
        self.breathingSettingsView.seeMoreButton.sendActions(for: .touchUpInside)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view {
            if view.isDescendant(of: self.breathingSettingsView) {
                return false
            }
        }
        
        return true
    }

}


extension String
{
    var pickerTextAttributedString: NSAttributedString
    {
        return self.attributes(
            color: UIColor.init(white: 0.2, alpha: 1.0),
            font: .gothamBook(16)
        )
    }
    
    var selectedButtonAttributedString: NSAttributedString
    {
        return uppercased().attributes(
            color: .white,
            font: .gothamBook(16)
        )
    }
    
    var startBreathingTextAttributedString: NSAttributedString
    {
        return uppercased().attributes(
            color: UIColor.init(white: 0.2, alpha: 1.0),
            font: .gothamBook(16),
            tracking: 250
        )
    }
    
    var introAttributedString: NSAttributedString
    {
        
        return self.attributes(
            color: .white,
            font: .gothamBook(16),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 250
        )
    }
    
    var introSubAttributedString: NSAttributedString
    {
        
        return self.attributes(
            color: .white,
            font: .gothamBook(16),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 200
        )
    }
    
    var introDescriptionAttributedString: NSAttributedString
    {
        
        return self.attributes(
            color: .white,
            font: .gothamBook(16),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 200
        )
    }
}

extension DispatchTimeInterval {
    static func minutes(_ minutes: Int) -> DispatchTimeInterval {
        return .seconds(minutes * 60)
    }
}

