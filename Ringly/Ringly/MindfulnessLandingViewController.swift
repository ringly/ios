//
//  MindfulnessLandingViewController.swift
//  Ringly
//
//  Created by Daniel Katz on 5/9/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import RinglyAPI
import RinglyExtensions
import RinglyActivityTracking
import SafariServices

class MindfulnessLandingViewController: ServicesViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
    private let mindfulnessGoalSummaryView = GoalSummaryControl.newAutoLayout()
    private let sections:[MindfulnessType] = [.breathing, .guidedAudio]
    private let breathingModels = [MindfulnessExerciseModel.init(image: .left(Asset.mindfulnessBreath.image), title: "TAKE A BREATHER", subtitle: "Breathing Exercise", description: nil, time: "1-5 minutes", timeInSeconds:0, assetUrl: nil, author: nil)]
    private var guidedAudioModels:[MindfulnessExerciseModel]
    
    private let background = GradientView.mindfulnessGradientView
    
    let mindfulMinutes = MutableProperty(MindfulMinuteData?.none)
    let mindfulnessControlData = MutableProperty(ActivityControlData?.none)
    
    let (mindfulSessionEndSignal, mindfulSessionEndObserver) = Signal<Bool, NoError>.pipe()

    init(services: Services, guidedAudioModels: [MindfulnessExerciseModel]) {
        self.guidedAudioModels = guidedAudioModels
        
        super.init(services: services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(background)
        background.autoPinEdgesToSuperviewEdges()

        //if you land here and you havent prompted for healthkit, show the dialog
        services.activityTracking.healthKitAuthorization.producer
            .startWithValues { [weak self] status in
                if status == .notDetermined {
                    if let strong = self, strong.mindfulHealthKitPromptTimesSeen() < 2 {
                        strong.presentMindfulHealthkitPrompt()
                        strong.mindfulIncrementHealthkitPromptSeen()
                    }
                }
        }
        
        let mindfulMinutesGoalProducer = services.preferences.activityTrackingMindfulnessGoal

        mindfulnessGoalSummaryView.count <~ mindfulMinutes.producer.skipNil().map({ $0.minuteCount })
        mindfulnessGoalSummaryView.activityControlData <~ mindfulnessControlData.producer.skipNil()
        mindfulnessGoalSummaryView.goal <~ mindfulMinutesGoalProducer
        mindfulnessGoalSummaryView.progressColorScheme.value = ActivityProgressColorScheme.mindfulnessSmall()
        mindfulnessGoalSummaryView.title.value = "STAY MINDFUL"
        mindfulnessGoalSummaryView.indicatorImage.isHidden = true
        mindfulnessGoalSummaryView.descriptionFormat.value = "%@ of %@ mindful minutes"
        self.view.addSubview(mindfulnessGoalSummaryView)
        mindfulnessGoalSummaryView.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        mindfulnessGoalSummaryView.autoSet(dimension: .height, to: 80)
        mindfulnessGoalSummaryView.layer.shadowColor = UIColor.gray.cgColor
        mindfulnessGoalSummaryView.layer.shadowOffset = CGSize.init(width: 0, height: 2)
        
        tableView.registerCellType(MindfulnessLandingTableViewCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
        tableView.estimatedSectionHeaderHeight = 50
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = self.footerView()
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges(excluding: .top)
        tableView.autoPin(edge: .top, to: .bottom, of: mindfulnessGoalSummaryView)
        
        guard self.guidedAudioModels.count == 0 else {
            return
        }
        
       self.services.cache.cacheGuidedAudioSessions() { [weak self] in
            guard let strong = self else {
                return
            }
            strong.guidedAudioModels = strong.services.cache.mindfulnessAudioSessions
            strong.tableView.beginUpdates()
            strong.tableView.insertRows(at: strong.guidedAudioModels.enumerated().map({ index,_ in IndexPath.init(row: index, section: 1) }), with: .right)
            strong.tableView.endUpdates()
       }
        
        services.analytics.track(AnalyticsEvent.viewedScreen(name: .mindfulness))
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        self.mindfulSessionEndObserver.send(value: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.sections[section]
        
        switch section {
        case .breathing:
            return self.breathingModels.count
        case .guidedAudio:
            return self.guidedAudioModels.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellOfType(MindfulnessLandingTableViewCell.self, forIndexPath: indexPath)
        let section = self.sections[indexPath.section]
        
        switch section {
        case .breathing:
            cell.populate(model: self.breathingModels[indexPath.row])
        case .guidedAudio:
            cell.populate(model: self.guidedAudioModels[indexPath.row])
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = self.sections[indexPath.section]
        
        switch section {
        case .breathing:
            let breathingExercise = MindfulnessBreathingExerciseViewController(services: self.services)
            breathingExercise.breathingSessionEndSignal.observe({ change in
                guard let value = change.value else { return }
                guard let totalMinutes = breathingExercise.breathingControl?
                    .breathingConfig.totalTime.timeInterval.minutes else { return }
                self.mindfulSessionEndObserver.send(value: true)
                // if breathing exercise completed, update mindful minutes time and log completed breathing event
                if value {
                    self.services.analytics.track(
                        AnalyticsEvent.breathingCompleted(totalMinutes: totalMinutes))
                }
                // else, log abandoned breathing event
                else {
                    self.services.analytics.track(
                        AnalyticsEvent.breathingAbandoned(
                            minutesCompleted: breathingExercise.timerLabel.timeElapsed.minutes,
                            totalMinutes: totalMinutes))
                }
            })
            self.present(breathingExercise, animated: true, completion: nil)
        case .guidedAudio:
            let guidedAudioModel = self.guidedAudioModels[indexPath.row]
            let guidedAudio = MindfulnessGuidedAudioViewController.init(exerciseModel: guidedAudioModel, services: self.services)
            guidedAudio.guidedSessionEndSignal.observe({ change in
                guard let value = change.value else { return }
                self.mindfulSessionEndObserver.send(value: true)
                // if guided audio completed, update mindful minutes time and log completed guided meditation event
                if value {
                    self.services.analytics.track(
                        AnalyticsEvent.guidedAudioCompleted(
                            title: guidedAudio.exerciseModel.title,
                            totalMinutes: guidedAudio.exerciseModel.timeInSeconds.minutes))
                }
                // else, log abandoned event
                else {
                    self.services.analytics.track(
                        AnalyticsEvent.guidedAudioAbandoned(
                            title: guidedAudio.exerciseModel.title,
                            minutesCompleted: guidedAudio.progress.value.time.minutes,
                            totalMinutes: guidedAudio.exerciseModel.timeInSeconds.minutes))
                }
            })
            self.present(guidedAudio, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 50))
        
        let label = UILabel(frame: containerView.frame.insetBy(dx: 16, dy: 0))
        label.attributedText = self.sections[section].title.uppercased().attributes(
            color: UIColor.init(white: 0.5, alpha: 1.0),
            font: UIFont.gothamBook(12),
            paragraphStyle: nil,
            tracking: .controlsTracking
        ).attributedString
        
        containerView.addSubview(label)
        
        return containerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func footerView() -> UIView {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 145))
        let horizontalLine = UIView.newAutoLayout()
        horizontalLine.backgroundColor = UIColor.init(white: 0.6, alpha: 0.5)
        
        let feedbackLabel = UILabel.newAutoLayout()
        feedbackLabel.numberOfLines = 0
        feedbackLabel.attributedText = "We'd love to hear your feedback about RINGLY's mindfulness features".attributes(color: UIColor.init(white: 0.4, alpha: 1.0), font: UIFont.gothamBook(12), paragraphStyle: .with(alignment: .center, lineSpacing: 3), tracking: 100.0)
        let feedbackButton = UIButton.newAutoLayout()
        let feedbackButtonAttributedText = "Let us know what you think!".attributes(color: .black, font: UIFont.gothamBook(12), paragraphStyle: .with(alignment: .center, lineSpacing: 3), tracking: 100.0, underlined: true)
        feedbackButton.setAttributedTitle(feedbackButtonAttributedText, for: .normal)
        SignalProducer(feedbackButton.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            let safari = SFSafariViewController(url: URL(string: "https://ringly.typeform.com/to/hTfOHd")!)
            self?.present(safari, animated: true, completion: nil)
        })
        
        view.addSubview(horizontalLine)
        horizontalLine.autoPinEdgeToSuperview(edge: .top, inset: 24)
        horizontalLine.autoSet(dimension: .height, to: 1)
        horizontalLine.autoPinEdgeToSuperview(edge: .left)
        horizontalLine.autoPinEdgeToSuperview(edge: .right)
        
        view.addSubview(feedbackLabel)
        feedbackLabel.autoPin(edge: .top, to: .bottom, of: horizontalLine, offset: 24)
        feedbackLabel.autoPinEdgeToSuperview(edge: .left, inset: 16)
        feedbackLabel.autoPinEdgeToSuperview(edge: .right, inset: 16)
        
        view.addSubview(feedbackButton)
        feedbackButton.autoPin(edge: .top, to: .bottom, of: feedbackLabel, offset: 14)
        feedbackButton.autoPinEdgeToSuperview(edge: .left, inset: 16)
        feedbackButton.autoPinEdgeToSuperview(edge: .right, inset: 16)
        
        return view
    }
    
    func mindfulHealthKitPromptTimesSeen() -> Int {
        return UserDefaults.standard.integer(forKey: "MindfulHealthKitPromptSeen")
    }
    
    func mindfulIncrementHealthkitPromptSeen() {
        let currentVal = self.mindfulHealthKitPromptTimesSeen()
        UserDefaults.standard.set(currentVal + 1, forKey: "MindfulHealthKitPromptSeen")
    }
    
    /// Presents a healthkit prompt to turn on mindfulness
    ///
    fileprivate func presentMindfulHealthkitPrompt()
    {
        let alert = AlertViewController()
        let actionTitle = tr(.connect)
        let dismissTitle = tr(.notNow)
        
        let dismiss = (title: dismissTitle, dismiss: true, action: { })
        let action:(()->Void) = {
            [weak self] in
            self?.services.activityTracking.requestHealthKitAuthorizationProducer().startWithFailed({ [weak self] in
                self?.presentError($0)
            })
        }
        
        alert.actionGroup = .double(action: (title: actionTitle, dismiss: true, action: action), dismiss: dismiss)
        alert.content = AlertImageTextContent(image: Asset.healthKitConnect.image, text: "NOW SUPPORTING APPLE HEALTH MINDFULNESS", detailText: "Find all of your mindful minutes from all your favorite meditation apps all in one place.", tinted: false)
        alert.modalPresentationStyle = .overFullScreen
        
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }
}


struct MindfulnessExerciseModel {
    let image:Either<UIImage, URL>
    let title:String
    let subtitle:String
    let description: String?
    let time:String
    let timeInSeconds:TimeInterval
    let assetUrl:URL?
    let author:GuidedAudioAuthor?
    
    func downloadUrlDestination() -> URL?
    {
        if let assetUrl = self.assetUrl {
            return FileManager.default.rly_cachesURL.appendingPathComponent(assetUrl.lastPathComponent)
        }
        
        return nil
    }
}

extension TimeInterval {
    var minutes: Int {
        return Int(floor(self / 60.0))
    }
}
