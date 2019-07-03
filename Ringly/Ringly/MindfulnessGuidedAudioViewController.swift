//
//  MindfulnessGuidedAudioViewController.swift
//  Ringly
//
//  Created by Daniel Katz on 5/10/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import HealthKit
import ReactiveSwift
import Result
import AudioPlayer
import MediaPlayer
import RinglyActivityTracking

enum ToggleType { case AfterCountdown; case FiveSecondsIn; case ManualTap }
typealias AudioProgress = (time: TimeInterval, percentagePlayed: CGFloat)

protocol GestureAvoidable {}

class MindfulnessGuidedAudioViewController: ServicesViewController, UIGestureRecognizerDelegate, AudioPlayerDelegate {

    fileprivate let background = GradientView.mindfulnessGradientView
    fileprivate let tap = UITapGestureRecognizer()
    
    fileprivate let closeButton = GestureAvoidableButton.newAutoLayout()
    fileprivate let activityProgressControl = ActivityProgressControl.init(strokeWidth: 9.5, withShadow: true)
    fileprivate var countdownView:SimpleCountdownView?

    var exerciseModel:MindfulnessExerciseModel
    let progress:MutableProperty<AudioProgress> = MutableProperty((0.0, 0.0))

    fileprivate let player = AudioPlayer()
    fileprivate let stopped = MutableProperty(false)
    fileprivate let playing = MutableProperty(true)
    fileprivate let duration = MutableProperty(TimeInterval?.none)
    
    fileprivate let closeXImageView = UIImageView.newAutoLayout()

    // signal to update boundary dates and update activity cache
    let (guidedSessionEndSignal, guidedSessionEndObserver) = Signal<Bool, NoError>.pipe()

    fileprivate var currentView:UIView?
    
    init(exerciseModel: MindfulnessExerciseModel, services: Services) {
        self.exerciseModel = exerciseModel
        super.init(services: services)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.player.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        MPRemoteCommandCenter.shared().playCommand.removeTarget(self)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(self)
    }
    
    override func loadView() {
        super.loadView()
        
        self.services.analytics.track(
            AnalyticsEvent.guidedAudioIntro(
                title: self.exerciseModel.title,
                totalMinutes: self.exerciseModel.timeInSeconds.minutes))
        
        //Tap gesture
        self.tap.delegate = self
        self.view.addGestureRecognizer(self.tap)
        
        self.view.addSubview(background)
        background.autoPinEdgesToSuperviewEdges()
        
        let close:((Any)->Void) = { [weak self] _ in
            if let strongSelf = self {
                if !strongSelf.services.preferences.mindfulReminderAlertOnboardingState.value &&
                    !strongSelf.services.preferences.mindfulRemindersEnabled.value &&
                    strongSelf.progress.value.percentagePlayed != 0.0 &&
                    strongSelf.progress.value.time < (self?.exerciseModel.timeInSeconds)! {
                    strongSelf.player.pause()
                    
                    let alert = MindfulAlertViewController(services: strongSelf.services)
                    alert.present(above: strongSelf)
                }
                // send not completed signal
                strongSelf.guidedSessionEndObserver.send(value: false)
                strongSelf.dismiss(animated: true, completion: nil)
            }
        }
        
        closeXImageView.image = Asset.alertClose.image.withRenderingMode(.alwaysTemplate)
        closeXImageView.tintColor = UIColor.white
        closeXImageView.contentMode = .scaleAspectFit
        
        self.view.addSubview(closeButton)
        closeButton.autoPinEdgeToSuperview(edge: .top, inset: 16)
        closeButton.autoPinEdgeToSuperview(edge: .left, inset: 16)
        closeButton.autoSetDimensions(to: CGSize.init(width: 44, height: 44))
        closeButton.addSubview(closeXImageView)
        closeButton.reactive.controlEvents(.touchUpInside).observeValues(close)
        
        closeXImageView.autoSetDimensions(to: CGSize.init(width: 14, height: 14))
        closeXImageView.autoCenterInSuperview()

        self.duration.producer.skipNil().combineLatest(with: self.progress.producer.filter({ $0.time > 0.0 }))
            .startWithValues { [weak self] (duration, progress) in
            if let strongSelf = self {
                guard let countdownView =  strongSelf.countdownView else {
                    strongSelf.countdownView = SimpleCountdownView.init(duration: duration)
                    strongSelf.countdownView?.center = CGPoint.init(x: strongSelf.view.center.x, y: 40)
                    strongSelf.view.addSubview(strongSelf.countdownView!)
                    return
                }
                
                countdownView.time = progress.0
            }
        }
        
        self.transition(to: .intro)
    }
    
    func startGuidedAudioExercise(url: URL?) {
        self.services.analytics.track(
            AnalyticsEvent.guidedAudioStarted(
                title: self.exerciseModel.title,
                totalMinutes: self.exerciseModel.timeInSeconds.minutes))
        self.services.engagementNotifications.cancel(.startedMeditation)


        MPRemoteCommandCenter.shared().playCommand.addTarget(handler: { _ in
            self.player.resume()
            return .success
        })
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(handler: { _ in
            self.player.pause()
            return .success
        })
        
        
        UIApplication.shared.isIdleTimerDisabled = true

        self.services.activityTracking.realmService!.startMindfulnessSession(
            mindfulnessType: .guidedAudio,
            description: self.exerciseModel.title,
            initialCount: 0)
        .skipNil()
        .flatMap(.latest, transform: { session -> SignalProducer<(), NSError> in
            let id = session.id
            return self.progress.producer
                .filter({ (time, _) in (time.truncatingRemainder(dividingBy: 60.0) > HealthKitService.secondDelay) })
                .map({ (time, _) in return Int(floor(time / 60.0)) })
            .skipRepeats()
            .flatMap(.latest, transform: { minute in
                return self.services.activityTracking.realmService!
                    .addMinuteToMindfulnessSession(sessionId: id,
                                                   store:self.services.activityTracking.healthStore)
                    .ignoreValues()
            })
        }).startWithCompleted({})

        self.showProgressCircle()

        self.player.delegate = self
        let item = AudioItem(mediumQualitySoundURL: url)
        self.player.play(item: item!)
    }
    
    func showProgressCircle() {
        activityProgressControl.colorScheme.value = .guidedAudioLarge()
        self.view.insertSubview(activityProgressControl, belowSubview: self.closeButton)
        activityProgressControl.contentHidden.value = true
        activityProgressControl.autoCenterInSuperview()
        activityProgressControl.autoSetDimensions(to: CGSize.init(width: 137, height: 137))
    }
    
    func hideProgressCircle() {
        UIView.animate(withDuration: 0.2) { 
            self.activityProgressControl.alpha = 0
        }
    }
    
    func transition(to stage: GuidedAudioStage) {
        let close:((Any)->Void) = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        
        self.currentView?.removeFromSuperview()
        
        switch stage {
        case .intro:
            let introView = GuidedAudioIntroView.init(guidedAudioModel: self.exerciseModel)
            introView.onComplete = { [weak self] in
                guard let strong = self else {
                    return
                }
                if FileManager.default.fileExists(atPath: strong.exerciseModel.downloadUrlDestination()!.path) {
                    self?.transition(to: .audio)
                } else {
                    self?.transition(to: .downloading)
                }
            }
            self.currentView = introView
            self.view.insertSubview(self.currentView!, belowSubview: self.closeButton)
            self.currentView!.autoPinEdgesToSuperviewEdges()
        case .downloading:
            self.showProgressCircle()
            
            
            let downloadingView = GuidedAudioDownloadingView.init(guidedAudioModel: self.exerciseModel)
            downloadingView.onComplete = { [weak self] downloadedUrl in
                self?.transition(to: .audio)
            }

            self.activityProgressControl.data <~ downloadingView.progress.map({ percentComplete in
                return ActivityControlData(progress: CGFloat(percentComplete), valueText: nil)
            })
            
            self.currentView = downloadingView
            self.view.insertSubview(self.currentView!, belowSubview: self.closeButton)
            self.currentView!.autoAlignAxis(toSuperviewAxis: .vertical)
            self.currentView!.autoAlign(axis: .horizontal, toSameAxisOf: self.view, offset: -21.0)
        case .audio:
            self.startGuidedAudioExercise(url: self.exerciseModel.downloadUrlDestination())
            let playerView = GuidedAudioPlayerControlView.init(guidedAudioModel: self.exerciseModel, player: self.player)
            playerView.playing <~ self.playing.producer
            self.player.currentItem?.title = exerciseModel.title
            self.player.currentItem?.artist = exerciseModel.author?.name ?? "Ringly"
            self.player.currentItem?.artwork = MPMediaItemArtwork(image: Asset.sessionArtwork.image)
            activityProgressControl.data <~ self.progress.producer.map({ (timeLeft, progress) in
                return ActivityControlData(progress: progress, valueText: nil)
            })
            self.currentView = playerView
            self.view.insertSubview(self.currentView!, belowSubview: self.closeButton)
            self.currentView!.autoPinEdgesToSuperviewEdges()
        case .complete:
            self.hideProgressCircle()
            self.guidedSessionEndObserver.send(value: true)
            self.closeXImageView.isHidden = true
            
            let completeView = GuidedAudioCompleteView.init(close: close)
            self.currentView = completeView
            self.view.insertSubview(self.currentView!, belowSubview: self.closeButton)
            self.currentView!.autoPinEdgesToSuperviewEdges()
            
            UIView.animate(withDuration: 0.2, delay: 0.2, options: .curveEaseIn, animations: { [weak self] in
                self?.currentView!.alpha =  1.0
                }, completion: { _ in
                    if !(self.services.preferences.mindfulReminderAlertOnboardingState.value) &&
                        !(self.services.preferences.mindfulRemindersEnabled.value) {
                            let alert = MindfulAlertViewController(services: self.services)
                            alert.present(above: self)
                    }
            })
        }
    }
    
    
    //MARK: AudioPlayerDelegate
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        self.progress.value = (time, CGFloat(percentageRead) / CGFloat(100.0))
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        self.duration.value = duration
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        switch state {
        case .paused:
            self.playing.value = false
        case .stopped:
            self.playing.value = false
            self.stopped.value = true
            self.transition(to: .complete)
        default:
            self.playing.value = true
        }
    }
    
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    
    //MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view! is GestureAvoidable {
            return false
        }
        
        return true
    }
}

class GestureAvoidableButton: UIButton, GestureAvoidable {
    
}

class SimpleCountdownView: UIView {
    fileprivate let timeLabel:UILabel
    fileprivate let duration:TimeInterval
    var time:TimeInterval = 0.0 {
        didSet {
            self.timeLabel.text = self.format(interval: self.duration - time)
        }
    }
    
    init(duration: TimeInterval) {
        self.duration = duration
        self.timeLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 30))

        super.init(frame: self.timeLabel.bounds)

        self.timeLabel.textAlignment = .center
        self.timeLabel.textColor = .white
        self.timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: 0.3)
        
        self.addSubview(self.timeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func format(interval: CFTimeInterval) -> String
    {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60)
        return String(format: "%2d:%02d", minutes, seconds)
    }
}
