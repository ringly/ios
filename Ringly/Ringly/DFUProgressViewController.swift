import Foundation
import ReactiveSwift

final class DFUProgressViewController: UIViewController, DFUPropertyChildViewController
{
    typealias State = (progress: Int, updateNumber: DFUProgressViewUpdateNumber)?
    let state = MutableProperty(State.none)
    let firstEncounter = MutableProperty<Bool>(true)
    let completed = MutableProperty<Bool>(false)
    
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add title label
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.attributedText = tr(.dfuConnectingText).rly_DFUTitleString()
        titleLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 45).priority = UILayoutPriorityDefaultLow
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 10, relation: .greaterThanOrEqual)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // add body label
        let bodyLabel = UILabel.newAutoLayout()
        bodyLabel.numberOfLines = 0
        view.addSubview(bodyLabel)

        bodyLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20)
        bodyLabel.autoSet(dimension: .width, to: 300, relation: .lessThanOrEqual)
        bodyLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // progress
        let container = UIView.newAutoLayout()
        view.addSubview(container)

        container.autoPinEdgeToSuperview(edge: .leading)
        container.autoPinEdgeToSuperview(edge: .trailing)
        container.autoPin(edge: .top, to: .bottom, of: bodyLabel, offset: 50).priority = UILayoutPriorityDefaultLow
        container.autoPin(edge: .top, to: .bottom, of: bodyLabel, offset: 10, relation: .greaterThanOrEqual)

        let progress = DFUProgressView.newAutoLayout()
        container.addSubview(progress)
        progress.autoFloatInSuperview()

        let activity = DiamondActivityIndicator.newAutoLayout()
        container.addSubview(activity)
        activity.constrainToDefaultSize()
        activity.autoCenterInSuperview()

        // update numbers
        let numberContainer = UIView.newAutoLayout()
        view.addSubview(numberContainer)

        numberContainer.autoPinEdgesToSuperviewMarginsExcluding(edge: .top)
        numberContainer.autoPin(edge: .top, to: .bottom, of: container, offset: 10)
        numberContainer.autoSet(dimension: .height, to: 155).priority = UILayoutPriorityDefaultLow - 1
        numberContainer.autoSet(dimension: .height, to: 40, relation: .greaterThanOrEqual)

        let numberLabel = UILabel.newAutoLayout()
        numberLabel.textColor = .white
        numberContainer.addSubview(numberLabel)

        numberLabel.autoCenterInSuperview()
        
        // lost connection alert
        let lostConnectionAlert = DFUAlertViewController(alertType: .lostConnection)
        
        state.producer.map({ $0?.updateNumber.total ?? 0 > 1 }).skipRepeats().startWithValues({ plural in
            bodyLabel.attributedText = tr(
                plural ? .dfuProgressDetailTextMultipleUpdates : .dfuProgressDetailTextSingleUpdate
            ).rly_DFUBodyString()
        })

        state.producer.startWithValues({ state in
            if !self.completed.value {
                progress.progress = state?.progress ?? 0
            }

            numberLabel.attributedText = (state?.updateNumber).flatMap({ updateNumber in
                guard updateNumber.total > 1 else { return nil }

                let normal = UIFont.gothamBook(18)
                let bold = UIFont.gothamBold(18)

                return [
                    "Update ".attributes(font: normal, tracking: 150),
                    "\(updateNumber.current)".attributes(font: bold, tracking: 150),
                    " of ".attributes(font: normal, tracking: 150),
                    "\(updateNumber.total)".attributes(font: bold, tracking: 150)
                ].join().attributedString
            })
        })

        state.producer.start(animationDuration: 0.25, action: { state in
            // state becomes nil once dfu completed, ensure connection alert does not pop up
            if !self.completed.value {
                activity.alpha = state == nil ? 1 : 0
                progress.alpha = state != nil ? 1 : 0
                titleLabel.attributedText = state == nil ? tr(.dfuConnectingText).rly_DFUTitleString() : tr(.dfuUpdatingText).rly_DFUTitleString()
                if (state == nil && !self.firstEncounter.value) {
                    lostConnectionAlert.present(above: self)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4, execute: {
                        lostConnectionAlert.dismiss()
                    })
                }
            }
            
            // only present alert after connection screen has been seen
            if state != nil && self.firstEncounter.value { self.firstEncounter.value = false }
            
            // nil state after completion, must dismiss connection alert
            if self.completed.value && lostConnectionAlert.isBeingPresented { lostConnectionAlert.dismiss() }
            
            // send completion signal upon successful dfu, complete above 98%
            guard let currentProgress = state?.progress else { return }
            if currentProgress > 98 {
                self.completed.value = true
            }
        })
    }
}
