//
//  SelectGoalViewController.swift
//  Ringly
//
//  Created by Daniel Katz on 3/22/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import HealthKit
import RinglyExtensions
import ReactiveSwift
import Result

class SelectGoalViewController: ServicesViewController {
    

    /// A backing pipe for `confirmedValueSignal`.
    fileprivate let confirmedValuePipe = Signal<Int, NoError>.pipe()
    
    /// A signal that sends the selected value when the user taps the confirmation button.
    var confirmedValueSignal: Signal<Int, NoError>
    {
        return confirmedValuePipe.0
    }

    fileprivate let titleLabel = UILabel.newAutoLayout()
    fileprivate let descriptionLabel = UILabel.newAutoLayout()
    fileprivate let confirmButton = ButtonControl.newAutoLayout()
    fileprivate let goalPicker = OnboardingGoalPickerView.newAutoLayout()

    let goalProperty = MutableProperty<Int>(0)
    
    fileprivate let units = Locale.current.preferredUnits

    var dataConfiguration: SelectGoalDataConfiguration? {
        didSet {
            self.goalPicker.title = dataConfiguration!.unitOfMeasureString(dataConfiguration!.defaultValue)
            self.goalProperty.value = Int(dataConfiguration!.defaultValue)
        }
    }
    var displayConfiguration: SelectGoalDisplayConfiguration? {
        didSet {
            self.titleLabel.attributedText = displayConfiguration!.title.titleAttributedString
            self.descriptionLabel.attributedText = displayConfiguration!.description.titleAttributedString
            self.confirmButton.title = displayConfiguration!.confirmTitle
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SignalProducer(confirmButton.reactive.controlEvents(.touchUpInside))
            .map({ _ in self.goalProperty.value })
            .start(confirmedValuePipe.1)
    }
    
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // label setup
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        view.addSubview(descriptionLabel)
        
        // button setup
        confirmButton.title = "SET GOAL"
        view.addSubview(confirmButton)
        
        view.addSubview(goalPicker)
        
        
        titleLabel.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 20, left: 20, bottom: 0, right: 20), excluding: .bottom)
        
        
        descriptionLabel.autoPinEdgeToSuperview(edge: .left, inset: 40)
        descriptionLabel.autoPinEdgeToSuperview(edge: .right, inset: 40)
        descriptionLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 18)
        
        confirmButton.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
        confirmButton.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 0, left: 20, bottom: 20, right: 20), excluding: .top)
        confirmButton.autoSetDimensions(to: CGSize(width: 155, height: 50))
        
        goalPicker.autoPinEdgeToSuperview(edge: .left, inset: 0)
        goalPicker.autoPinEdgeToSuperview(edge: .right, inset: 0)
        goalPicker.autoPin(edge: .top, to: .bottom, of: descriptionLabel, offset: 35)
        goalPicker.autoSet(dimension: .height, to: 90)
        
        goalPicker.actionsProducer.startWithValues({ [unowned self] action in
            let offset = self.dataConfiguration!.stepSize * (action == .increase ? 1 : -1)
            let maxValue = self.dataConfiguration!.range.upperBound
            let minValue = self.dataConfiguration!.range.lowerBound
            
            self.goalProperty.pureModify({ current in
                min(maxValue, max(minValue, current + offset))
            })
        })

        
        goalPicker.quantity <~ self.goalProperty.producer
    }
}

extension String
{

    var titleAttributedString: NSAttributedString
    {
        return self.attributes(
            color: .white,
            font: .gothamBook(16),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 250
        )
    }
}

struct SelectGoalDisplayConfiguration
{
    let title: String
    let description: String
    let confirmTitle: String
}

struct SelectGoalDataConfiguration
{
    /// The starting value.
    let range: Range<Int>

    /// The size of each step
    let stepSize: Int
    
    let defaultValue: Int
    
    
    /// A function to determine the unit of measure string
    let unitOfMeasureString: (Int) -> String
    
    /// A function to determine the value strings.
    let valueString: (Int) -> AttributedStringProtocol
}
