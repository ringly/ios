//
//  ActivityGoalsViewController.swift
//  Ringly
//
//  Created by Daniel Katz on 5/30/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift

class ActivityGoalsViewController: ServicesViewController {
    
    let stepGoalSummaryView = GoalSummaryControl.newAutoLayout()
    let mindfulnessGoalSummaryView = GoalSummaryControl.newAutoLayout()
    let showSteps = MutableProperty(true)
    
    fileprivate var stepsHeightConstraint:NSLayoutConstraint?
    fileprivate var mindfulnessTopSpacing:NSLayoutConstraint?

    
    fileprivate let statisticsController: ActivityStatisticsController
    
    init(services: Services, statisticsController: ActivityStatisticsController) {
        self.statisticsController = statisticsController
        
        super.init(services: services)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let stepsGoalProducer = services.preferences.activityTrackingStepsGoal.producer
        let mindfulMinutesGoalProducer = services.preferences.activityTrackingMindfulnessGoal
        
        let goalContentView = UIView.newAutoLayout()
        goalContentView.backgroundColor = UIColor(red: 234.0/255.0, green: 234.0/255.0, blue: 234.0/255.0, alpha: 1.0)
        self.view.addSubview(goalContentView)
        goalContentView.autoPinEdgesToSuperviewEdges()
        
        goalContentView.addSubview(stepGoalSummaryView)
        stepGoalSummaryView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 8, left: 8, bottom: 0, right: 8), excluding: .bottom)
        self.stepsHeightConstraint = stepGoalSummaryView.autoSet(dimension: .height, to: 80)
        stepGoalSummaryView.roundCorners()
        
        
        goalContentView.addSubview(mindfulnessGoalSummaryView)
        self.mindfulnessTopSpacing = mindfulnessGoalSummaryView.autoPin(edge: .top, to: .bottom, of: stepGoalSummaryView, offset: 8)
        mindfulnessGoalSummaryView.autoPinEdgeToSuperview(edge: .left, inset: 8)
        mindfulnessGoalSummaryView.autoPinEdgeToSuperview(edge: .right, inset: 8)
        mindfulnessGoalSummaryView.autoPinEdgeToSuperview(edge: .bottom, inset: 8)
        mindfulnessGoalSummaryView.autoSet(dimension: .height, to: 80)
        
        stepGoalSummaryView.activityControlData <~ self.statisticsController.stepsControlData.producer.observe(on: UIScheduler())
        stepGoalSummaryView.goal <~ stepsGoalProducer.observe(on: UIScheduler())
        stepGoalSummaryView.count <~ self.statisticsController.steps.producer.skipNil().map({ $0.stepCount }).observe(on: UIScheduler())
        stepGoalSummaryView.progressColorScheme.value = ActivityProgressColorScheme.stepsDay()
        stepGoalSummaryView.title.value = tr(.stayActive)
        stepGoalSummaryView.indicatorImage.isHidden = true
        stepGoalSummaryView.descriptionFormat.value = "%@ of %@ steps"
        
        mindfulnessGoalSummaryView.activityControlData <~ self.statisticsController.mindfulnessControlData.producer.observe(on: UIScheduler())
        mindfulnessGoalSummaryView.goal <~ mindfulMinutesGoalProducer.producer.observe(on: UIScheduler())
        mindfulnessGoalSummaryView.count <~ self.statisticsController.mindfulMinutes.producer.skipNil().map({ $0.minuteCount }).observe(on: UIScheduler())
        mindfulnessGoalSummaryView.progressColorScheme.value = ActivityProgressColorScheme.mindfulnessSmall()
        mindfulnessGoalSummaryView.indicatorImage.isHidden = true
        mindfulnessGoalSummaryView.title.value = "STAY MINDFUL"
        mindfulnessGoalSummaryView.descriptionFormat.value = "%@ of %@ mindful minutes"
        mindfulnessGoalSummaryView.indicatorImage.isHidden = true
        mindfulnessGoalSummaryView.roundCorners()
        
        self.showSteps.producer.startWithValues({ show in
            if let stepsHeightConstraint = self.stepsHeightConstraint, let mindfulnessTopSpacing = self.mindfulnessTopSpacing {
                if show {
                    stepsHeightConstraint.constant = 80
                    self.stepGoalSummaryView.activityProgressControl.setNeedsUpdateConstraints()
                    mindfulnessTopSpacing.constant = 8
                } else {
                    stepsHeightConstraint.constant = 0
                    mindfulnessTopSpacing.constant = 0
                }
            }
        })
    }

}
