//
//  GoalSummaryView.swift
//  Ringly
//
//  Created by Daniel Katz on 4/5/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import HealthKit

class GoalSummaryControl: UIControl {
    let activityProgressControl = ActivityProgressControl.init(strokeWidth: 8.0, withShadow: false)
    fileprivate let titleLabel = UILabel.newAutoLayout()
    fileprivate let descriptionLabel = UILabel.newAutoLayout()
    let indicatorImage:UIImageView = UIImageView.newAutoLayout()
    
    var title = MutableProperty<String>("")
    var descriptionFormat = MutableProperty<String>("")

    let goal = MutableProperty(Int?.none)
    let count = MutableProperty(0)
    let activityControlData = MutableProperty(ActivityControlData?.none)
    let progressColorScheme = MutableProperty(ActivityProgressColorScheme.stepsSmall())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        //data binding
        self.activityProgressControl.contentHidden.value = true
        self.activityProgressControl.data <~ self.activityControlData
        self.activityProgressControl.colorScheme <~ self.progressColorScheme
        
        //view setup
        self.backgroundColor = UIColor.white
        
        self.addSubview(self.activityProgressControl)
        self.activityProgressControl.autoPinEdgeToSuperview(edge: .left, inset: 16)
        self.activityProgressControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        self.activityProgressControl.autoPin(edge: .top, to: .top, of: self, offset: 13)
        self.activityProgressControl.autoPin(edge: .bottom, to: .bottom, of: self, offset: -13)
        self.activityProgressControl.autoSet(dimension: .width, to: 54)
        
        self.indicatorImage.image = UIImage(asset: .fakePreferencesDisclosure).withRenderingMode(.alwaysTemplate)
        self.indicatorImage.tintColor = UIColor(red: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1.0)
        self.addSubview(self.indicatorImage)
        self.indicatorImage.autoSetDimensions(to: CGSize.init(width: 8, height: 13))
        self.indicatorImage.autoPinEdgeToSuperview(edge: .right, inset: 24)
        self.indicatorImage.autoAlign(axis: .horizontal, toSameAxisOf: self.activityProgressControl)
        
        self.titleLabel.font = UIFont.gothamBook(16)
        self.addSubview(self.titleLabel)
        self.titleLabel.autoPin(edge: .left, to: .right, of: self.activityProgressControl, offset: 16)
        self.titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 20)
        self.titleLabel.autoPin(edge: .right, to: .left, of: self.indicatorImage, offset: 24)
        
        self.descriptionLabel.font = UIFont.gothamBook(12)
        self.addSubview(self.descriptionLabel)
        self.descriptionLabel.autoPin(edge: .left, to: .right, of: self.activityProgressControl, offset: 16)
        self.descriptionLabel.autoPin(edge: .top, to: .bottom, of: self.titleLabel, offset: 5)
        self.descriptionLabel.autoPin(edge: .right, to: .left, of: self.indicatorImage, offset: 24)
        
        self.title.producer.startWithValues({ [weak self] title in
            self?.titleLabel.attributedText = title.attributes(
                color: UIColor.init(white: 0.2, alpha: 1.0),
                font: UIFont.gothamBook(16),
                paragraphStyle: nil,
                tracking: .controlsTracking
            )
        })
        
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .decimal
        
        SignalProducer.combineLatest(
            self.descriptionFormat.producer,
            self.goal.producer.skipNil(),
            self.count.producer
            )
            .startWithValues { (descriptionFormat, goal, count)
                in
             self.descriptionLabel.attributedText = String(
                format: descriptionFormat,
                numberFormatter.string(from: NSNumber(value: count))!,
                numberFormatter.string(from: NSNumber(value: goal))!
            ).attributes(color: UIColor.init(white: 0.2, alpha: 0.7), font: UIFont.gothamBook(12), paragraphStyle: nil, tracking: 100.0)
        }
    }
    
    func roundCorners() {
        self.layer.cornerRadius = 2.0
    }

}
