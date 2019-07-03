//
//  CountdownTimer.swift
//  Ringly
//
//  Created by Daniel Katz on 4/6/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit

class CountdownTimer: DisplayLinkView {
    
    fileprivate var timerLabel:UILabel!
    fileprivate var endTimestamp:CFTimeInterval?
    fileprivate var duration: CFTimeInterval!
    var timeLeft: TimeInterval = 0.0
    var timeElapsed: TimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(duration: CFTimeInterval) {
        self.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 40))

        self.duration = duration

        self.timerLabel = UILabel.init(frame: self.bounds)
        self.timerLabel.textAlignment = .center
        self.timerLabel.textColor = .white
        self.timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: 0.3)

        self.addSubview(self.timerLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func displayLinkCallback(_ displayLink: CADisplayLink) {
        guard let endTimestamp = endTimestamp else {
            self.endTimestamp = displayLink.timestamp + self.duration + 1.0
            return
        }
        
        self.timeLeft = endTimestamp - displayLink.timestamp
        self.timeElapsed = self.duration - self.timeLeft
        
        guard endTimestamp > displayLink.timestamp else {
            return
        }
        
        self.timerLabel.text = self.format(interval: self.timeLeft)
    }
    
    func format(interval: CFTimeInterval) -> String
    {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60)
        return String(format: "%2d:%02d", minutes, seconds)
    }
}
