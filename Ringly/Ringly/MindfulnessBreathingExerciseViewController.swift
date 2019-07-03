//
//  MindfulnessBreathingExerciseViewController.swift
//  Ringly
//
//  Created by Daniel Katz on 4/6/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import RinglyActivityTracking
import RinglyExtensions


class MindfulnessBreathingExerciseViewController: ServicesViewController, UIGestureRecognizerDelegate {

    var timerLabel:CountdownTimer!
    fileprivate let closeButton = UIButton.newAutoLayout()
    fileprivate let background = GradientView.mindfulnessGradientView
    fileprivate let breathingIntroView:BreathingIntroView
    fileprivate let tap = UITapGestureRecognizer()
    var breathingControl:BreathingExerciseView?
    
    // signal to update boundary dates and update activity cache
    let (breathingSessionEndSignal, breathingSessionEndObserver) = Signal<Bool, NoError>.pipe()

    override init(services: Services) {
        self.breathingIntroView = BreathingIntroView.init(preferences: services.preferences)
        
        super.init(services: services)
    }

    override func loadView() {
        super.loadView()
        
        //Tap gesture
        self.tap.delegate = self
        self.view.addGestureRecognizer(self.tap)
    
        self.view.addSubview(background)
        background.autoPinEdgesToSuperviewEdges()

        background.addSubview(breathingIntroView)
        breathingIntroView.autoPinEdgesToSuperviewEdges()
        breathingIntroView.startBreathingSignal.observeValues { [weak self] length in
            self?.breathingIntroView.fadeOut {
                self?.shouldStartBreathingExercise(shouldStart: { shouldStart in
                    if shouldStart {
                        self?.startBreathingExercise(length: length)
                    }
                })
                
            }
        }
        
        let closeXImageView = UIImageView.newAutoLayout()
        closeXImageView.image = Asset.alertClose.image.withRenderingMode(.alwaysTemplate)
        closeXImageView.tintColor = UIColor.white
        closeXImageView.contentMode = .scaleAspectFit
        
        self.view.addSubview(closeButton)
        closeButton.autoPinEdgeToSuperview(edge: .top, inset: 16)
        closeButton.autoPinEdgeToSuperview(edge: .left, inset: 16)
        closeButton.autoSetDimensions(to: CGSize.init(width: 44, height: 44))
        closeButton.addSubview(closeXImageView)
        closeButton.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.breathingSessionEndObserver.send(value: false)
            if !strongSelf.services.preferences.mindfulReminderAlertOnboardingState.value &&
                !strongSelf.services.preferences.mindfulRemindersEnabled.value &&
                strongSelf.timerLabel != nil {
                    if let presentingController = strongSelf.presentingViewController {
                        strongSelf.dismiss(animated: true, completion: {
                            let alert = MindfulAlertViewController(services: strongSelf.services)
                            alert.present(above: presentingController)
                        })
                    }
            }
            strongSelf.dismiss(animated: true, completion: nil)
        })
        
        closeXImageView.autoSetDimensions(to: CGSize.init(width: 14, height: 14))
        closeXImageView.autoCenterInSuperview()
        
        services.analytics.track(AnalyticsEvent.breathingIntro)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let breathingControl = self.breathingControl {
            breathingControl.doneObserver.sendCompleted()
        }
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func displayNotConnectedAlert(shouldContinue:@escaping ((Bool)-> Void)) {
        let alert = AlertViewController()
        let actionTitle = "CONTINUE"
        let connectTitle = "RECONNECT"
        
        let contineuAction = (title: actionTitle, dismiss: true, action: { shouldContinue(true) })
        let connectAction = (title: connectTitle, dismiss: true, action: { shouldContinue(false) })
        
        
        alert.actionGroup = .double(action: connectAction, dismiss: contineuAction)
        alert.content = AlertImageTextContent(image: nil ,text: "WE CAN'T FIND YOUR RINGLY", detailText: " Looks like we're having trouble connecting to your Ringly for this breathing exercise. Either try reconnecting or continue with out device buzzes!", tinted: false)
        alert.modalPresentationStyle = .overFullScreen
        
        
        present(alert, animated: true, completion: nil)
    }
    
    func shouldStartBreathingExercise(shouldStart:@escaping (Bool) -> Void) {
        if self.services.preferences.breathingExerciseShouldBuzz.value == false {
            shouldStart(true)
            
            return
        }
        
        let displayConnectedAlert:(() -> Void) = {
            self.displayNotConnectedAlert(shouldContinue: { shouldContinue in
                if shouldContinue {
                    shouldStart(true)
                } else {
                    self.dismiss(animated: true, completion: {
                        self.dismiss(animated: true, completion: {
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.switchTab(tab: .connection)
                            }
                        })
                    })
                }
            })
        }
        
        if let activatedPeripheral = self.services.peripherals.activatedPeripheral.value, activatedPeripheral.isConnected {
            if activatedPeripheral.isValidated {
                shouldStart(true)
            } else {
                displayConnectedAlert()
            }
        } else {
            displayConnectedAlert()
        }
    }

    
    func startBreathingExercise(length: DispatchTimeInterval) {
        services.analytics.track(AnalyticsEvent.breathingStarted(totalMinutes: length.timeInterval.minutes))
        services.engagementNotifications.cancel(.startedBreather)

        UIApplication.shared.isIdleTimerDisabled = true

        var breathingConfig = BreathingExerciseConfig.oneHold(cyclesPerMinute: 6, totalTime: length, motorPower: self.services.preferences.motorPower.value, vibrationStyle: BreathingVibrationStyle(rawValue: self.services.preferences.breathingVibrationStyle.value)!)
        breathingConfig.shouldBuzz = self.services.preferences.breathingExerciseShouldBuzz.value
        breathingControl = BreathingExerciseView(breathingConfig: breathingConfig, activatedPeripheral: self.services.peripherals.activatedPeripheral.value)
        

        self.services.activityTracking.realmService!.startMindfulnessSession(mindfulnessType: .breathing, description: "Breathing", initialCount: 0)
            .skipNil()
            .flatMap(FlattenStrategy.concat, transform: { [unowned self] session -> SignalProducer<(), NSError> in
                let id = session.id
                let delaySeconds = breathingConfig.countdownSeconds + HealthKitService.secondDelay
                let initialDelay = timer(interval: .seconds(Int(delaySeconds)), on: QueueScheduler.main).take(first: 1).ignoreValues().promoteErrors(NSError.self)
                let minuteTimer = immediateTimer(interval: .seconds(60), on: QueueScheduler.main).take(until: self.breathingControl!.doneSignal)
                    .flatMap(.latest, transform: { [weak self] _ -> SignalProducer<Void, NSError> in
                        if let strong = self {
                            return strong.services.activityTracking.realmService!
                                .addMinuteToMindfulnessSession(sessionId: id,
                                                               store:self?.services.activityTracking.healthStore)
                                .ignoreValues()
                        } else {
                           return SignalProducer.empty.promoteErrors(NSError.self)
                        }
                    })
                return initialDelay.concat(minuteTimer)
            }).start()
   
        
        guard let breathingControl = breathingControl else { return }
        
        self.view.addSubview(breathingControl)
        
        breathingControl.autoPinEdgeToSuperview(edge: .left, inset: 60)
        breathingControl.autoPinEdgeToSuperview(edge: .right, inset: 60)
        breathingControl.autoAlignAxis(toSuperviewAxis: .horizontal)
        breathingControl.autoAlignAxis(toSuperviewAxis: .vertical)
        breathingControl.autoPinEdgeToSuperview(edge: .bottom)
        breathingControl.doneButton.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            self?.breathingSessionEndObserver.send(value: true)
            if !(self?.services.preferences.mindfulReminderAlertOnboardingState.value)! &&
                !(self?.services.preferences.mindfulRemindersEnabled.value)! {
                
                let alert = MindfulAlertViewController(services: (self?.services)!)
                if let strongSelf = self {
                    alert.present(above: strongSelf)
                }
            }
            self?.dismiss(animated: true, completion: nil)
        })
        
        self.timerLabel = CountdownTimer(duration: breathingConfig.totalTime.timeInterval)
        self.timerLabel.alpha = 0.0
        
        enum ToggleType { case AfterCountdown; case FiveSecondsIn; case ManualToggle }
        
        let afterCountdown = timer(interval: .milliseconds(Int(breathingConfig.countdownSeconds * 1000) + 400), on: QueueScheduler.main).take(first: 1).on(completed: { [weak self] in
            if let strong = self {
                strong.view.addSubview(strong.timerLabel)
                strong.timerLabel.autoSetDimensions(to: CGSize.init(width: 200, height: 20))
                strong.timerLabel.autoPinEdgeToSuperview(edge: .top, inset: 20)
                strong.timerLabel.autoAlignAxis(toSuperviewAxis: .vertical)
            }
        }).map(({ _ in ToggleType.AfterCountdown }))
        let fiveSecondsIn = timer(interval: .seconds(5), on: QueueScheduler.main).take(first: 1).map(({ _ in ToggleType.FiveSecondsIn }))
        let toggle = SignalProducer(tap.reactive.stateChanged.filter({ $0.state == .ended }).map(({ _ in ToggleType.ManualToggle })))
        
        SignalProducer.concat([
            afterCountdown,
            fiveSecondsIn,
            toggle
            ]).flatMap(.latest, transform: { [weak self] toggleType -> SignalProducer<Bool, NoError> in
                return UIView.animationProducer(duration: 0.4, animations: {
                    self?.timerLabel.alpha = self?.timerLabel.alpha == 1.0 ? 0 : 1.0
                    
                    if toggleType != .AfterCountdown {
                        self?.closeButton.alpha = self?.closeButton.alpha == 1.0 ? 0 : 1.0
                    }
                })
            }).start()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    // UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let breathingControl = breathingControl, breathingControl.superview != nil {
            if touch.view!.isDescendant(of: breathingControl.doneButton) {
                return false
            }
        }
        
        if touch.view! is GestureAvoidable {
            return false
        }
        
        return true
    }
}
