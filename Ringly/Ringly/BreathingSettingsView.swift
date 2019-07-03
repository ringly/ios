//
//  BreathingSettingsView.swift
//  Ringly
//
//  Created by Daniel Katz on 6/15/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

class BreathingSettingsView:UIView
{
    let minuteSelected = MutableProperty<Int>(1)
    let shouldBuzzSetting = MutableProperty(true)
    let seeMoreButton = GestureAvoidableButton.newAutoLayout()
    var seeMoreButtonHeightConstraint:NSLayoutConstraint?
    fileprivate let preferences: Preferences

    var seeMoreTapped: SignalProducer<(), NoError> {
        return SignalProducer(seeMoreButton.reactive.controlEvents(.touchUpInside)).void
    }
    
    init(preferences: Preferences) {
        self.preferences = preferences
        
        super.init(frame: CGRect.zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.backgroundColor = .white
        
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .horizontal
        stackView.spacing = 8.0
        self.addSubview(stackView)
        stackView.autoSet(dimension: .height, to: 46)
        stackView.autoAlignAxis(toSuperviewAxis: .vertical)
        stackView.autoPinEdgeToSuperview(edge: .top, inset: 24)
        
        let introLabel = UILabel.newAutoLayout()
        introLabel.attributedText = "I have".pickerTextAttributedString
        let unitsLabel = UILabel.newAutoLayout()
        unitsLabel.attributedText = "minutes".pickerTextAttributedString
        
        stackView.addArrangedSubview(introLabel)
        stackView.addArrangedSubview(self.pickerButton(numberOfMinutes: 1))
        stackView.addArrangedSubview(self.pickerButton(numberOfMinutes: 3))
        stackView.addArrangedSubview(self.pickerButton(numberOfMinutes: 5))
        stackView.addArrangedSubview(unitsLabel)
        
        let downFacingCaret = ShapeView.downFacingCaret()
        downFacingCaret.isUserInteractionEnabled = false
        seeMoreButton.addSubview(downFacingCaret)
        downFacingCaret.autoSetDimensions(to: CGSize.init(width: 15, height: 8))
        downFacingCaret.autoCenterInSuperview()
        addSubview(seeMoreButton)
        seeMoreButton.autoPin(edge: .top, to: .bottom, of: stackView, offset: 5)
        seeMoreButton.autoMatch(dimension: .width, to: .width, of: stackView)
        self.seeMoreButtonHeightConstraint = seeMoreButton.autoSet(dimension: .height, to: 30)
        
        seeMoreButton.autoAlignAxis(toSuperviewAxis: .vertical)
        SignalProducer(seeMoreButton.reactive.controlEvents(.touchUpInside)).startWithValues({ button in
            self.seeMoreButtonHeightConstraint?.constant = self.seeMoreButtonHeightConstraint?.constant == 30.0 ? 0.0 : 30.0
            self.seeMoreButton.alpha = self.seeMoreButton.alpha == 1.0 ? 0.0 : 1.0
        })
        
        let buzzRinglySettingView = self.switchWithTitle(title: "Breathing Buzzes", preference: self.preferences.breathingExerciseShouldBuzz, below: seeMoreButton)
        buzzRinglySettingView.autoSet(dimension: .height, to: 80)
        buzzRinglySettingView.autoPinEdgeToSuperview(edge: .bottom)
    }
    
    func pickerButton(numberOfMinutes: Int) -> UIButton {
        let button = UIButton.newAutoLayout()
        button.tag = numberOfMinutes
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("\(numberOfMinutes)", for: .normal)
        button.setBackgroundImage(UIImage(), for: .normal)
        button.setBackgroundImage(Asset.minuteButtonBackground.image, for: .selected)
        self.minuteSelected <~ button.reactive.controlEvents(.touchUpInside).map({ $0.tag })
        button.reactive.isSelected <~ self.minuteSelected.map({ button.tag == $0 })
        button.autoSetDimensions(to: CGSize.init(width: 46, height: 46))
        
        return button
    }
    
    func switchWithTitle(title: String, preference: MutableProperty<Bool>, below: UIView) -> UIView
    {
        let wrapper = UIView.newAutoLayout()
        
        let label = UILabel.newAutoLayout()
        label.text = title
        label.font = UIFont.gothamBook(16)
        label.textColor = UIColor.black
        wrapper.addSubview(label)
        
        let control = UISwitch.newAutoLayout()
        control.isOn = preference.value
        
        SignalProducer(control.reactive.controlEvents(.valueChanged)).startWithValues({ _ in
            preference.value = control.isOn
        })
        
        let line = UIView.newAutoLayout()
        line.backgroundColor = UIColor.init(white: 0.91, alpha: 1.0)
        
        
        wrapper.addSubview(control)
        wrapper.addSubview(line)
        self.addSubview(wrapper)
        
        line.autoPinEdgeToSuperview(edge: .left)
        line.autoPinEdgeToSuperview(edge: .right)
        line.autoSet(dimension: .height, to: 1.0)
        line.autoPinEdgeToSuperview(edge: .top)
        
        wrapper.autoPinEdgeToSuperview(edge: .leading, inset: 32)
        wrapper.autoPinEdgeToSuperview(edge: .trailing, inset: 32)
        wrapper.autoPin(edge: .top, to: .bottom, of: below, offset: 20)
        
        control.autoPinEdgeToSuperview(edge: .top, inset: 24)
        control.autoSetDimensions(to: CGSize.init(width: 51, height: 31))
        label.autoAlign(axis: .horizontal, toSameAxisOf: control)

        
        label.autoPinEdgeToSuperview(edge: .leading)
        control.autoPinEdgeToSuperview(edge: .trailing)
        control.autoPin(edge: .leading, to: .trailing, of: label, offset: 20, relation: .greaterThanOrEqual)
        
        return wrapper
    }
}
