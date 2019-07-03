//
//  ConnectivityDetailView.swift
//  Ringly
//
//  Created by Daniel Katz on 4/23/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class ConnectivityDetailView: UIView {

    fileprivate let title = UILabel.newAutoLayout()
    fileprivate let subtitle = UILabel.newAutoLayout()
    fileprivate let footerLabel = UILabel.newAutoLayout()
    fileprivate let hl1 = UIView.newAutoLayout()
    fileprivate let hl2 = UIView.newAutoLayout()
    fileprivate let hl3 = UIView.newAutoLayout()
    let peripheralDatasource = DataSourceConnectivityView.newAutoLayout()
    let healthkitDatasource = DataSourceConnectivityView.newAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        let stack = UIStackView.newAutoLayout()
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 25.0
        addSubview(stack)
        stack.autoPinEdgesToSuperviewEdges()
        
        hl1.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        hl2.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        hl3.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)

        title.attributedText = "ACTIVITY SOURCE".attributes(
            color: UIColor.black,
            font: .gothamBook(16),
            paragraphStyle: .centeredTitle,
            tracking: .titleTracking
            )
        
        subtitle.attributedText = "Ringly is using the following sources for activity data:".attributes(
            color: UIColor.black,
            font: .gothamBook(12),
            paragraphStyle: .centeredBody,
            tracking: .bodyTracking
        )
        subtitle.numberOfLines = 0
        
        footerLabel.attributedText = "Apple Health will combine your Ringly data with its other sources for more accurate activity tracking.".attributes(
            color: UIColor.init(white: 0.46, alpha: 1.0),
            font: .gothamBook(12),
            paragraphStyle:  .centeredBody,
            tracking: .bodyTracking
        )
        
        footerLabel.numberOfLines = 0
        
        stack.addArrangedSubview(title)
        title.autoMatch(dimension: .width, to: .width, of: self)
        title.autoPin(edge: .top, to: .top, of: stack, offset: 40)
        
        stack.addArrangedSubview(subtitle)
        subtitle.autoMatch(dimension: .width, to: .width, of: self)
        stack.addArrangedSubview(hl1)
        stack.addArrangedSubview(peripheralDatasource)
        peripheralDatasource.autoSet(dimension: .height, to: 36)
        peripheralDatasource.autoPinEdgeToSuperview(edge: .left)
        peripheralDatasource.autoPinEdgeToSuperview(edge: .right)
        stack.addArrangedSubview(hl2)
        stack.addArrangedSubview(healthkitDatasource)
        healthkitDatasource.autoSet(dimension: .height, to: 36)
        healthkitDatasource.autoPinEdgeToSuperview(edge: .left)
        healthkitDatasource.autoPinEdgeToSuperview(edge: .right)
        stack.addArrangedSubview(hl3)
        hl1.autoSet(dimension: .height, to: 1.0)
        hl1.autoMatch(dimension: .width, to: .width, of: self)
        hl2.autoSet(dimension: .height, to: 1.0)
        hl2.autoMatch(dimension: .width, to: .width, of: self)
        hl3.autoSet(dimension: .height, to: 1.0)
        hl3.autoMatch(dimension: .width, to: .width, of: self)
        stack.addArrangedSubview(footerLabel)
        footerLabel.autoMatch(dimension: .width, to: .width, of: self)
    }
}

struct DataSourceConnectivityModel {
    var title:String
    var isConnected:Bool
    var icon: UIImage
    var action: ((_ triggerProducer: SignalProducer<(), NoError>)->Void)?
}

class DataSourceConnectivityView: UIControl
{
    let connectivityModel = MutableProperty<DataSourceConnectivityModel?>(nil)
    
    fileprivate let datasourceIcon = UIImageView.newAutoLayout()
    fileprivate let datasourceTitle = UILabel.newAutoLayout()
    fileprivate let iconLabel = IconLabel.newAutoLayout()
    fileprivate let disclosureIndicator = UIImageView.newAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        datasourceIcon.contentMode = .center
        addSubview(datasourceIcon)
        datasourceIcon.autoSetDimensions(to: CGSize.init(width: 30, height: 30))
        datasourceIcon.autoAlign(axis: .horizontal, toSameAxisOf: self)
        datasourceIcon.autoPinEdgeToSuperview(edge: .left)
        
        addSubview(datasourceTitle)
        datasourceTitle.autoPin(edge: .left, to: .right, of: datasourceIcon, offset: 20)
        datasourceTitle.autoPinEdgeToSuperview(edge: .top)
        
        addSubview(iconLabel)
        iconLabel.autoPin(edge: .left, to: .right, of: datasourceIcon, offset: 20)
        iconLabel.autoSet(dimension: .height, to: 14)
        iconLabel.autoPinEdgeToSuperview(edge: .bottom)
        iconLabel.autoPinEdgeToSuperview(edge: .right)
        
        disclosureIndicator.image = Asset.fakePreferencesDisclosure.image.withRenderingMode(.alwaysTemplate)
        disclosureIndicator.tintColor = UIColor.init(white: 0.6, alpha: 1.0)
        disclosureIndicator.isHidden = true
        addSubview(disclosureIndicator)
        disclosureIndicator.autoSetDimensions(to: CGSize.init(width: 5, height: 10))
        disclosureIndicator.autoAlign(axis: .horizontal, toSameAxisOf: self)
        disclosureIndicator.autoPinEdgeToSuperview(edge: .right)

        
        self.connectivityModel.producer.skipNil().startWithValues({ connectivityModel in
            self.datasourceTitle.attributedText = connectivityModel.title.attributes(color: UIColor.black, font: .gothamBook(16), paragraphStyle: nil, tracking: .titleTracking)
            self.datasourceIcon.image = connectivityModel.icon
            self.iconLabel.text = connectivityModel.isConnected ? tr(.connected) : tr(.notConnected)
            self.iconLabel.iconColor = connectivityModel.isConnected ? .ringlyGreen : .ringlyYellow
            self.iconLabel.image = connectivityModel.isConnected ? Asset.syncedCheckmark.image.withRenderingMode(.alwaysTemplate) : Asset.ringDisconnected.image.withRenderingMode(.alwaysTemplate)
            self.iconLabel.setNeedsLayout()
            
            if let action = connectivityModel.action {
                self.disclosureIndicator.isHidden = false
                
                action(SignalProducer(self.reactive.controlEvents(.touchUpInside).void))

            } else {
                self.disclosureIndicator.isHidden = true
            }
        })
    }
}

fileprivate class IconLabel: UIView {
    var image:UIImage? = nil {
        didSet {
            self.icon.image = image
        }
    }
    
    var text:String = "" {
        didSet {
            self.textLabel.attributedText = text.attributes(color: UIColor.init(white: 0.46, alpha: 1.0), font: .gothamBook(12), paragraphStyle: nil, tracking: .bodyTracking)
        }
    }
    
    var iconColor:UIColor? = nil {
        didSet {
            if let iconColor = iconColor {
                self.icon.tintColor = iconColor
            }
        }
    }
    
    fileprivate let icon = UIImageView.newAutoLayout()
    fileprivate let textLabel = UILabel.newAutoLayout()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.spacing = 6
        addSubview(stack)
        stack.autoPinEdgesToSuperviewEdges()
        
        icon.contentMode = .scaleAspectFit
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(textLabel)
        
        icon.autoSetDimensions(to: CGSize.init(width: 12, height: 12))
    }
}
