import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class PeripheralReferenceContentView: UIView
{
    // MARK: - Model

    /// Describes the potential states of a peripheral reference content view.
    struct Model
    {
        /// Whether or not the peripheral is connected.
        let connected: Bool

        /// Whether or not the view should display the selected interface or the unselected interface.
        let activated: Bool
        
        /// Validated state
        let validated: Bool

        /// Whether or not the view should display the update button.
        let updateAvailable: Bool


        /// The style of peripheral to display.
        let style: RLYPeripheralStyle

        /// The battery charge to display.
        let batteryCharge: Int?

        /// The battery state to display.
        let batteryState: RLYPeripheralBatteryState?
    }

    /// The view's current model.
    let model = MutableProperty(Model?.none)

    // MARK: - Labels

    /// Displays the current peripheral state.
    fileprivate let stateLabel = UILabel.newAutoLayout()

    // MARK: - Buttons

    /// Displays a prompt to update the peripheral.
    fileprivate let updateButton = UnderlineLinkControl.newAutoLayout()

    /// Allows the user to select the peripheral.
    fileprivate let selectButton = ButtonControl.newAutoLayout()

    fileprivate let batteryView = BatteryView.newAutoLayout()

    fileprivate let reconnectButton = ButtonControl.newAutoLayout()
    
    fileprivate var reconnectBottom:NSLayoutConstraint?
    
    fileprivate let batteryMoved = MutableProperty<Bool>(false)

    /// Allows the user to view reasons that the peripheral may not be connected.
    fileprivate let notConnectedButton = UIButton.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add title and state labels below the peripheral control
        let nameLabel = UILabel.newAutoLayout()
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        addSubview(nameLabel)

        stateLabel.textColor = .white
        stateLabel.textAlignment = .center
        addSubview(stateLabel)

        nameLabel.autoPinEdgeToSuperview(edge: .top, inset: 50)
        stateLabel.autoPin(edge: .top, to: .bottom, of: nameLabel, offset: 15)

        [nameLabel, stateLabel].forEach({
            $0.autoPinEdgeToSuperview(edge: .leading, inset: 10)
            $0.autoPinEdgeToSuperview(edge: .trailing, inset: 10)
            $0.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        })

        // add the update button below the name and state labels
        updateButton.text = trUpper(.updateYourRingly)
        addSubview(updateButton)
        
        updateButton.autoPin(edge: .top, to: .bottom, of: stateLabel, offset: 15)
        updateButton.autoSet(dimension: .height, to: 40)
        updateButton.autoFloatInSuperview(alignedTo: .vertical)
        
        // add the battery view between the labels and bottom buttons
        batteryView.tintColor = UIColor.white
        batteryView.config.value = .large
        addSubview(batteryView)


        let batteryDistance: CGFloat = DeviceScreenHeight.current.select(five: 20, preferred: 32)
        let updateBattery = batteryView.autoPin(edge: .top, to: .bottom, of: updateButton, offset: batteryDistance)
        let connectedBattery = batteryView.autoPin(edge: .top, to: .bottom, of: stateLabel, offset: batteryDistance)

        batteryView.autoAlignAxis(toSuperviewAxis: .vertical)

        // add the select buttons below the battery view, and at the bottom of the view
        selectButton.title = tr(.select)
        addSubview(selectButton)

        let selectBottom = selectButton.autoPinEdgeToSuperview(edge: .bottom)
        selectButton.autoPin(edge: .top, to: .bottom, of: batteryView, offset: batteryDistance)
        selectButton.autoAlignAxis(toSuperviewAxis: .vertical)
        selectButton.autoSetDimensions(to: CGSize(width: 165, height: 50))
        
        reconnectButton.title = trUpper(.reconnect)
        addSubview(reconnectButton)
        
        self.reconnectBottom = reconnectButton.autoPinEdgeToSuperview(edge: .bottom)
        reconnectButton.autoPin(edge: .top, to: .bottom, of: batteryView, offset: batteryDistance)
        reconnectButton.autoAlignAxis(toSuperviewAxis: .vertical)
        reconnectButton.autoSetDimensions(to: CGSize(width: 165, height: 50))
        
        // add the not connected button as an alternative bottom view
        notConnectedButton.showsTouchWhenHighlighted = true
        notConnectedButton.setImage(UIImage(asset: .notConnectedButton), for: UIControlState())
        addSubview(notConnectedButton)

        notConnectedButton.autoPin(edge: .top, to: .bottom, of: stateLabel, offset: 29)
        notConnectedButton.autoAlignAxis(toSuperviewAxis: .vertical)
        notConnectedButton.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)

        // update views as the view model changes

        // update the name label
        model.producer.map({ $0?.style })
            .skipRepeatsOptional(==)
            .startWithValues({ style in
                nameLabel.attributedText = UIFont.gothamBook(21)
                    .track(250, style.flatMap(RLYPeripheralStyleName)?.uppercased() ?? "RINGLY").attributedString
            })

        // update the state label
        model.producer
            .map({ ($0?.connected ?? false, $0?.validated ?? false, $0?.batteryState ?? .notCharging) })
            .skipRepeats(==)
            .startCrossDissolve(in: stateLabel, duration: 0.25, action: { [weak self] connected, validated, state in
                guard let strongSelf = self else { return }
                strongSelf.stateLabel.attributedText = UIFont.gothamBook(15)
                          .track(250, connected && validated
                              ? state.connectedStateString
                              : trUpper(.notConnected)
                        ).attributedString
            })
        
        model.producer.startWithValues({ [weak self] model in

            // hide and display the select button
            let unselected = !(model?.activated ?? true)
            self?.selectButton.activate(if: unselected)
            selectBottom.isActive = unselected

            // hide and display the disconnected button
            if let model = model {
                self?.notConnectedButton.activate(if: !model.connected && !model.validated && !unselected)
            }
            
            // hide and display the update button
            self?.updateButton.activate(if: model?.updateAvailable ?? false)
            NSLayoutConstraint.conditionallyActivateConstraints([
                (updateBattery, model?.updateAvailable ?? false), (connectedBattery, !(model?.updateAvailable ?? false))
                ])
            
            // update the battery view's state
            if let charge = model?.batteryCharge, model?.connected ?? false, model?.validated ?? false
            {
                self?.batteryView.percentage.value = charge
                self?.batteryView.alpha = 1
            }
            else
            {
                self?.batteryView.alpha = 0
            }
            

        })

        model.producer.debounce(3.0, on: QueueScheduler.main, valuesPassingTest: { (model) -> Bool in
            if let model = model {
                return !model.validated && model.connected
            }

            return false
        }).startWithValues({ [weak self] model in
            if let model = model, let strong = self {
                strong.reconnectBottom?.isActive = model.connected && !model.validated
                strong.reconnectButton.activate(if: model.connected && !model.validated)
            }
        })
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Producers
    var updateTapped: SignalProducer<(), NoError>
    {
        return SignalProducer(updateButton.reactive.controlEvents(.touchUpInside)).void
    }

    var notConnectedTapped: SignalProducer<(), NoError>
    {
        return SignalProducer(notConnectedButton.reactive.controlEvents(.touchUpInside)).void
    }

    var selectTapped: SignalProducer<(), NoError>
    {
        return SignalProducer(selectButton.reactive.controlEvents(.touchUpInside)).void
    }
    
    var reconnectTapped: SignalProducer<(), NoError>
    {
        return SignalProducer(reconnectButton.reactive.controlEvents(.touchUpInside)).void
    }

    var producerForDisconnectedWiggle: SignalProducer<(), NoError>
    {
        return SignalProducer.`defer` { [weak self] in
            self?.stateLabel.rly_wiggle(withMoves: 7, distance: CGSize(width: 5, height: 0), duration: 0.4)
            return timer(interval: .milliseconds(400), on: QueueScheduler.main).take(first: 1).ignoreValues()
        }
    }
}

extension RLYPeripheralBatteryState
{
    fileprivate var connectedStateString: String
    {
        switch self
        {
        case .notCharging, .error:
            return trUpper(.connected)
        case .charged:
            return trUpper(.charged)
        case .charging:
            return trUpper(.charging)
        }
    }
}
