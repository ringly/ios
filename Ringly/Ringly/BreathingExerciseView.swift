//
//  BreathingExerciseControl.swift
//  Ringly
//
//  Created by Daniel Katz on 4/6/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import RinglyExtensions
import ReactiveSwift
import ReactiveCocoa
import Result

enum BreathingVibrationStyle: String {
    case light = "Light"
    case heavy = "Heavy"
}

extension BreathingVibrationStyle {
    static func types() -> [BreathingVibrationStyle] {
        return [.light, .heavy]
    }
}

enum BreathingInstuction {
    case countdown(text: String)
    case instruction(text: String)
    case complete
}
extension BreathingInstuction {
    
    var instructionAttributedString:AttributedStringProtocol? {
        switch self {
        case .countdown(let text):
            return text.attributes(color: .white, font: UIFont.gothamBook(16), paragraphStyle: nil, tracking: nil)
        case .instruction(let text):
            return text.attributes(color: .white, font: UIFont.gothamBook(16), paragraphStyle: nil, tracking: nil)
        default:
            return nil
        }
    }
}

extension BreathingInstuction: Equatable {}
func ==(lhs: BreathingInstuction, rhs: BreathingInstuction) -> Bool
{
    switch (lhs, rhs)
    {
    case (.countdown(let lhsText), .countdown(let rhsText)):
        return lhsText == rhsText
    case (.instruction(let lhsParams), .instruction(let rhsParams)):
        return lhsParams == rhsParams
    case (.complete, .complete):
        return true
    default:
        return false
    }
}


class BreathingExerciseView: UIView {
    
    
    fileprivate let instructionLabel = UILabel.newAutoLayout()
    
    fileprivate let breathingCircleTop = BreathingRingView.init(frame: CGRect.init(x: 0, y: 0, width: 130, height: 130))
    fileprivate let breathingCircleBottom = BreathingRingView.init(frame: CGRect.init(x: 0, y: 0, width: 130, height: 130))
    
    fileprivate var firstTimestamp:CFTimeInterval?
    
    fileprivate var currentBreathingInstruction:BreathingInstuction?
        
    let doneButton = ButtonControl.newAutoLayout()
    let finalCheck = UIImageView.init(image: Asset.doneCheckLarge.image)
    
    let breathingInstruction:MutableProperty<BreathingInstuction?> = MutableProperty(nil)
    
    var breathingConfig:BreathingExerciseConfig
    var topBreathingRingSizeConstraint:[NSLayoutConstraint]?
    var bottomBreathingRingSizeConstraint:[NSLayoutConstraint]?
    
    let (doneSignal, doneObserver) = Signal<(), NoError>.pipe()    


    let sequenceStartedHelperView = UIView.newAutoLayout()
    let activatedPeripheral: RLYPeripheral?
    
    fileprivate var breathingDidTimeout = false

    
    init(breathingConfig: BreathingExerciseConfig, activatedPeripheral: RLYPeripheral?) {
        self.breathingConfig = breathingConfig
        self.activatedPeripheral = activatedPeripheral
        
        super.init(frame: CGRect.zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func setup() {
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        self.addSubview(instructionLabel)
        instructionLabel.alpha = 0.0
        instructionLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        instructionLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 90)
        instructionLabel.autoPinEdgeToSuperview(edge: .left, inset: 0)
        instructionLabel.autoPinEdgeToSuperview(edge: .right, inset: 0)
        
        self.breathingCircleTop.alpha = 0
        self.breathingCircleBottom.alpha = 0
        self.addSubview(self.breathingCircleTop)
        self.addSubview(self.breathingCircleBottom)
        
        self.breathingCircleTop.layer.anchorPoint = CGPoint.init(x: 0.5, y: 1.0)
        self.breathingCircleBottom.layer.anchorPoint = CGPoint.init(x: 0.5, y: 0.0)
        self.breathingCircleTop.shape.anchorPoint = CGPoint.init(x: 0.5, y: 1.0)
        self.breathingCircleBottom.shape.anchorPoint = CGPoint.init(x: 0.5, y: 0.0)

        
        self.doneButton.title = tr(.done)
        self.doneButton.alpha = 0.0
        self.doneButton.textColor = UIColor.init(red: 0.28, green: 0.69, blue: 0.91, alpha: 1.0)
        self.addSubview(self.doneButton)
        self.doneButton.autoSet(dimension: .height, to: 60)
        self.doneButton.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 0, left: 0, bottom: 40, right: 0), excluding: .top)
        
        
        self.finalCheck.alpha = 0
        self.addSubview(self.finalCheck)
        self.finalCheck.autoSetDimensions(to: CGSize.init(width: 140, height: 140))
        self.finalCheck.autoAlignAxis(toSuperviewMarginAxis: .vertical)
        self.finalCheck.autoAlign(axis: .horizontal, toSameAxisOf: self, offset: -20)
        

        
        let countdownInstruction:BreathingInstuction = .countdown(text: "Collect your focus with a short breathing exercise.")
        
        let ringsFadeIn = UIView.animationProducer(duration: 0.4) { [weak self] in
            self?.breathingCircleTop.alpha = 1
            self?.breathingCircleBottom.alpha = 1
        }
        
        let instructionFadeIn = self.instructionFadeIn { [weak self] in
            self?.instructionLabel.attributedText = countdownInstruction.instructionAttributedString?.attributedString
        }
        
        let repeatCount = self.repeatCount(peripheral: self.activatedPeripheral)
        
        
        let startedPeripheralMotorFrames = SignalProducer.`defer` { [unowned self] () -> SignalProducer<(), NSError> in

            guard let activatedPeripheral = self.activatedPeripheral, activatedPeripheral.isConnected, activatedPeripheral.isValidated, !self.breathingDidTimeout, self.isBreathingBuzzCapable(peripheral: activatedPeripheral), self.breathingConfig.shouldBuzz else {

                return SignalProducer.empty
            }
            
            let frameCommand = RLYKeyframeCommand.init(colorKeyframes: [], vibrationKeyframes: self.breathingConfig.vibrationPattern, repeatCount: UInt8(repeatCount - 1))
            debugPrint("\(Date().timeIntervalSince1970) writing to peripheral")
            activatedPeripheral.write(command: frameCommand)
            
            return activatedPeripheral.reactive.framesState.await(.started)
                .timeout(after: 1.5, raising: NSError.init(domain: "PeripheralError", code: 0, userInfo: nil), on: QueueScheduler.main)
                .flatMapError({ error in
                    SLogBluetooth("Breathing exercise timeout of 1.5s")
                    self.breathingDidTimeout = true
                    return SignalProducer.empty
                })
        }
        
        //countdown sequence
        let countdownSequence =
                SignalProducer.merge([ringsFadeIn, instructionFadeIn])
                .delay(breathingConfig.countdownSeconds, on: QueueScheduler.main)
                .then(self.instructionFadeOut())
        
        
        
        let breathingInstructionSequence =  self.breathingConfig.breathPattern.map { [weak self] (patternItem) -> SignalProducer<Bool,
            NoError> in
            guard let strong = self else { return SignalProducer.empty }

            let duration = patternItem.patternItemDuration(forCycle: strong.breathingConfig.cycleDuration())

            return strong.instructionFadeIn { [weak self] in
                self?.instructionLabel.attributedText = patternItem.breathingInstruction.instructionAttributedString?.attributedString
            }.delay(duration - 0.8, on: QueueScheduler.main)
            .then(strong.instructionFadeOut())
        }
        
        let breathingRingSequence = self.breathingConfig.breathPattern.map({ [weak self] patternItem -> SignalProducer<Bool, NoError> in
            guard let strong = self else { return SignalProducer.empty }

            let duration = patternItem.patternItemDuration(forCycle: strong.breathingConfig.cycleDuration())

            switch patternItem {
            case .breathIn:
                return CATransaction.producerWithDuration(duration, animations: strong.breathingRingAnimation(forward: true, duration: duration)).map({ true })
            case .breathOut:
                return CATransaction.producerWithDuration(duration, animations: strong.breathingRingAnimation(forward: false, duration: duration)).map({ true })
            case .hold:
                return SignalProducer.empty.delay(duration, on: QueueScheduler.main)
            }
        })
        
        let breathingAnimationSequence = SignalProducer.concat(breathingInstructionSequence)
            .and(SignalProducer.concat(breathingRingSequence))
        
        let totalCycles = self.breathingConfig.totalCycles()
        let cyclesPerPeripheralBuzz = totalCycles / repeatCount
        
        let breathing =
            startedPeripheralMotorFrames
                .then(breathingAnimationSequence.repeat(repeatCount))

        
        countdownSequence
            .then(breathing.repeat(cyclesPerPeripheralBuzz))
            .take(until: reactive.lifetime.ended)
            .startWithCompleted { [weak self] in
                self?.doneObserver.sendCompleted()
                self?.doneButton.alpha = 1.0
                self?.finalCheck.alpha = 1.0
                self?.breathingCircleTop.alpha = 0.0
                self?.breathingCircleBottom.alpha = 0.0
        }
    
    }
    
    func repeatCount(peripheral:RLYPeripheral?) -> Int {
        var repeatCount = 2
        
        if let activatedPeripheral = self.activatedPeripheral, activatedPeripheral.isConnected, activatedPeripheral.isValidated {
            repeatCount = (activatedPeripheral.applicationVersion?.versionNumberIsAfter(after: "2.3.0") ?? false) ? 6 : 2
        }
        
        return repeatCount
    }
    
    func isBreathingBuzzCapable(peripheral: RLYPeripheral) -> Bool {
        return peripheral.applicationVersion?.versionNumberIsAfter(after: "2.0") ?? false
    }
    
    func breathingRingAnimation(forward: Bool, duration: TimeInterval) -> (()->Void) {
        
        var fromPath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 130, height: 130))
        var toPath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 255, height: 255))
        
        if !forward {
            fromPath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 255, height: 255))
            toPath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 130, height: 130))
        }
        
        return { [weak self] in
            guard let strong = self else { return }

            let pathAnimation = CABasicAnimation(keyPath: "path");
            pathAnimation.duration = duration;
            pathAnimation.fromValue = fromPath.cgPath;
            pathAnimation.toValue = toPath.cgPath
            pathAnimation.isRemovedOnCompletion = false
            pathAnimation.fillMode = kCAFillModeForwards
            pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            
            let boundsAnimation = CABasicAnimation(keyPath: "bounds")
            boundsAnimation.duration = duration
            boundsAnimation.fromValue = fromPath.bounds
            boundsAnimation.toValue = toPath.bounds
            boundsAnimation.isRemovedOnCompletion = false
            boundsAnimation.fillMode = kCAFillModeForwards
            boundsAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            
            strong.breathingCircleTop.shape.add(pathAnimation, forKey: "path");
            strong.breathingCircleBottom.shape.add(pathAnimation, forKey: "path");
            strong.breathingCircleTop.layer.add(boundsAnimation, forKey: "bounds");
            strong.breathingCircleBottom.layer.add(boundsAnimation, forKey: "bounds");
        }
    }
    
    func instructionFadeIn(preAnimate:@escaping (()->Void)) -> SignalProducer<Bool, NoError> {
        return UIView.animationProducer(duration: 0.3, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
            preAnimate()
            self?.instructionLabel.alpha = 1.0
        })
    }
    
    func instructionFadeOut() -> SignalProducer<Bool, NoError> {
        return UIView.animationProducer(duration: 0.3, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
            self?.instructionLabel.alpha = 0.0
        })
    }
    
    override func layoutSubviews() {
        self.breathingCircleTop.frame = CGRect.init(x: self.frame.midX - 130, y: self.frame.midY - 25, width: 130, height: 130)
        self.breathingCircleBottom.frame = CGRect.init(x: self.frame.midX - 130, y: self.frame.midY - 155, width: 130, height: 130)
    }
}

class BreathingRingView: UIView
{
    
    let shape = CAShapeLayer.init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        self.backgroundColor = .clear

        
        let path = UIBezierPath(ovalIn: bounds.insetBy(dx: 8, dy: 8)).cgPath
        shape.fillColor = nil
        shape.strokeColor = UIColor.white.cgColor
        shape.lineWidth = 8.0
        shape.path = path
        shape.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        
        
        self.layer.addSublayer(shape)
    }
}
