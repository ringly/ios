//
//  GuidedAudioCompleteView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/22/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation


class GuidedAudioCompleteView: UIView, GestureAvoidable
{
    fileprivate let doneButton = ButtonControl.newAutoLayout()
    fileprivate let doneCheck = UIImageView.init(image: Asset.doneCheckLarge.image)
    fileprivate let close:((Any)->Void)
    
    init(close:@escaping ((Any)->Void)) {
        self.close = close
        
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.alpha = 0.0
        self.doneButton.title = tr(.done)
        self.doneButton.textColor = UIColor.init(red: 0.28, green: 0.69, blue: 0.91, alpha: 1.0)
        self.addSubview(self.doneButton)
        self.doneButton.autoSet(dimension: .height, to: 60)
        self.doneButton.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 0, left: 40, bottom: 40, right: 40), excluding: .top)
        self.doneButton.reactive.controlEvents(.touchUpInside).observeValues(close)
        
        self.addSubview(self.doneCheck)
        self.doneCheck.autoSetDimensions(to: CGSize.init(width: 129, height: 129))
        self.doneCheck.autoCenterInSuperview()
    }
}
