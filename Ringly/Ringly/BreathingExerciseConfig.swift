//
//  BreathingExerciseConfig.swift
//  Ringly
//
//  Created by Daniel Katz on 4/6/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit

enum BreathPatternItem
{
    case breathIn(cyclePercentRange:Range<Double>)
    case breathOut(cyclePercentRange:Range<Double>)
    case hold(cyclePercenRange:Range<Double>)
}

extension BreathPatternItem {
    var cyclePercent:Range<Double> {
        switch self {
        case .breathIn(let cyclePercenRange):
            return cyclePercenRange
        case .breathOut(let cyclePercenRange):
            return cyclePercenRange
        case .hold(let cyclePercenRange):
            return cyclePercenRange
        }
    }
    
    var breathingInstruction:BreathingInstuction {
        switch self {
        case .breathIn:
            return .instruction(text: "Inhale")
        case .breathOut:
            return .instruction(text: "Exhale")
        case .hold:
            return .instruction(text: "Hold")
        }
    }
    
    func startTime(with totalDuration: TimeInterval) -> TimeInterval {
        return self.cyclePercent.lowerBound * totalDuration
    }
    
    func patternItemDuration(forCycle cycleDuration: TimeInterval) -> TimeInterval {
        return (self.cyclePercent.upperBound - self.cyclePercent.lowerBound) * cycleDuration
    }
}

struct BreathingExerciseConfig: MindfulnessExerciseConfig {
    let breathPattern:[BreathPatternItem]
    let cyclesPerMinute:Int
    var totalTime:DispatchTimeInterval
    var countdownSeconds:TimeInterval
    let motorPower:Int
    let vibrationStyle:BreathingVibrationStyle
    var shouldBuzz: Bool
    
    func totalCycles() -> Int {
        return Int(floor(Double(self.cyclesPerMinute) * (totalTime.timeInterval / 60.0)))
    }
    
    func cycleDuration() -> TimeInterval {
        return self.totalTime.timeInterval / ((self.totalTime.timeInterval / 60.0) * Double(cyclesPerMinute))
    }
}

extension BreathingExerciseConfig {
    static func noHolds(cyclesPerMinute:Int = 6, totalTime: DispatchTimeInterval = .seconds(60), motorPower: Int = 80, vibrationStyle: BreathingVibrationStyle = .heavy) -> BreathingExerciseConfig {
        return BreathingExerciseConfig(
            breathPattern: [.breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.0, 0.5))), .breathOut(cyclePercentRange: Range.init(uncheckedBounds: (0.5, 1.0)))],
            cyclesPerMinute: cyclesPerMinute,
            totalTime: totalTime,
            countdownSeconds: 3,
            motorPower: motorPower,
            vibrationStyle: vibrationStyle,
            shouldBuzz: true
        )
    }
    
    static func oneHold(cyclesPerMinute:Int = 6, totalTime: DispatchTimeInterval = .seconds(60), motorPower: Int = 80, vibrationStyle: BreathingVibrationStyle = .heavy) -> BreathingExerciseConfig {
        return BreathingExerciseConfig(
            breathPattern: [.breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.0, 0.4))), .hold(cyclePercenRange: Range.init(uncheckedBounds: (0.4, 0.6))), .breathOut(cyclePercentRange: Range.init(uncheckedBounds: (0.6, 1.0)))],
            cyclesPerMinute: cyclesPerMinute,
            totalTime: totalTime,
            countdownSeconds: 3,
            motorPower: motorPower,
            vibrationStyle: vibrationStyle,
            shouldBuzz: true
        )
    }
    
    static func twoHolds(cyclesPerMinute:Int = 6, totalTime: DispatchTimeInterval = .seconds(60), motorPower: Int = 80, vibrationStyle: BreathingVibrationStyle = .heavy) -> BreathingExerciseConfig {
        return BreathingExerciseConfig(
            breathPattern: [.breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.0, 0.25))), .breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.25, 0.5))), .breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.5, 0.75))),.breathIn(cyclePercentRange: Range.init(uncheckedBounds: (0.75, 1.0)))],
            cyclesPerMinute: cyclesPerMinute,
            totalTime: totalTime,
            countdownSeconds: 3,
            motorPower: motorPower,
            vibrationStyle: vibrationStyle,
            shouldBuzz: true
        )
    }
    
    var vibrationPattern:[RLYVibrationKeyframe] {
        get {
            switch vibrationStyle {
            case .heavy:
                return self.heavyVibrationPattern()
            case .light:
                return self.lightVibrationPattern()
            }
        }
    }
    
    private func lightVibrationPattern() -> [RLYVibrationKeyframe]
    {
        return self.breathPattern.map({ patternItem -> [RLYVibrationKeyframe] in
            
            let startTimestamp = patternItem.startTime(with: self.cycleDuration()) * 1000.0 / 50.0
            
            switch patternItem {
            case .breathIn:
                return [
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp), vibrationPower: RLYVibrationPower(self.motorPower), interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 1.75), vibrationPower: 0, interpolateToNext: false)
                ]
            case .breathOut:
                return [
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp), vibrationPower: RLYVibrationPower(motorPower), interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 1.75), vibrationPower: 0, interpolateToNext: false)
                ]
            case .hold:
                return [
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp), vibrationPower: RLYVibrationPower(motorPower), interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 1.75), vibrationPower: 0, interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 3.0), vibrationPower: RLYVibrationPower(motorPower), interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 4.75), vibrationPower: 0, interpolateToNext: false)
                    
                ]
            }
        }).flatMap({ $0 })
    }
    
    private func heavyVibrationPattern() -> [RLYVibrationKeyframe]
    {
        return self.breathPattern.map({ patternItem -> [RLYVibrationKeyframe] in
            
            let duration = patternItem.patternItemDuration(forCycle: self.cycleDuration())
            let startTimestamp = patternItem.startTime(with: self.cycleDuration()) * 1000.0 / 50.0
            let endTimestamp = startTimestamp + (duration * 1000.0 / 50.0)
            
            switch patternItem {
            case .breathIn:
                var currentTime = startTimestamp
                
                let separationPattern = [5, 5, 4, 4, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2]
                
                return separationPattern.map({ separation -> [RLYVibrationKeyframe] in
                    let keyframes:[RLYVibrationKeyframe] =  [
                        RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(currentTime), vibrationPower: RLYVibrationPower(self.motorPower), interpolateToNext: false),
                        RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(currentTime + 2.0), vibrationPower: 0, interpolateToNext: false)
                    ]
                    
                    currentTime = currentTime + Double(separation) + 2.0
                    
                    return keyframes
                })
                    .flatMap({ $0 })
                    .filter({ (keyframe: RLYVibrationKeyframe) -> Bool in keyframe.timestamp < RLYKeyframeTimestamp(endTimestamp - 2.0) })
            case .breathOut:
                return [
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp), vibrationPower: RLYVibrationPower(Double(motorPower)), interpolateToNext: false),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(startTimestamp + 1.0), vibrationPower: 0, interpolateToNext: true),
                    RLYVibrationKeyframe.init(timestamp: RLYKeyframeTimestamp(endTimestamp), vibrationPower: 0, interpolateToNext: false)
                ]
            case .hold:
                return []
            }
        }).flatMap({ $0 })
    }
}

