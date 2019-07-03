//
//  RingConnectivityIndicatorControl.swift
//  Ringly
//
//  Created by Daniel Katz on 4/20/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift

struct ConnectivityStatus {
    var hasPeripherals: Bool
    var peripheralConnected: Bool
    var batteryPercentage: Int?
    var healthConnected: Bool
    
    var image:UIImage? {
        get {
            if peripheralConnected || hasPeripherals {
                return Asset.ringIndicator.image
            } else if !healthConnected {
                return Asset.addHealthIndicator.image
            } else {
                return Asset.healthIndicator.image
            }
        }
    }
}


class ConnectivityIndicatorControl: UIControl {
    
    let connectivityStatus = MutableProperty(ConnectivityStatus?.none)
    let imageView = UIImageView.newAutoLayout()
    
    let superscriptContainer = UIView.newAutoLayout()
    
    func setup() {
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.autoPinEdgeToSuperview(edge: .left)
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)

        addSubview(superscriptContainer)
        superscriptContainer.autoSetDimensions(to: CGSize.init(width:12, height:12))
        superscriptContainer.autoPin(edge: .left, to: .right, of: imageView, offset: 0  )
        superscriptContainer.autoPin(edge: .top, to: .top, of: imageView, offset: -5)

        self.connectivityStatus.producer.startWithValues({ status in
            if let status = status {
                
                guard let image = status.image else {
                    return
                }

                /// commented out - causing app crash while updating autolayout on background thread
//                self.imageView.autoSetDimensions(to: image.size)
                self.imageView.image = image
                
                self.superscriptContainer.subviews.forEach({ $0.removeFromSuperview() })
                
                if let batteryPercentage = status.batteryPercentage, status.peripheralConnected {
                    let batteryView = BatteryView.newAutoLayout()
                    batteryView.tintColor = UIColor.white
                    batteryView.alpha = 0.7
                    batteryView.config.value = .small
                    batteryView.percentage.value = batteryPercentage
                    self.superscriptContainer.addSubview(batteryView)
                    batteryView.autoCenterInSuperview()
                } else if (!status.peripheralConnected && status.hasPeripherals) {
                    let disconnectedView = UIImageView.newAutoLayout()
                    disconnectedView.image = Asset.ringDisconnected.image
                    self.superscriptContainer.addSubview(disconnectedView)
                    disconnectedView.autoCenterInSuperview()
                }
            }
        })
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    

}
