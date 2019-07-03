import ReactiveCocoa
import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension RLYPeripheral
{
    /**
     Writes the specified notification to the peripheral.

     - parameter notification: The notification to write.
     */
    func writeNotification(_ notification: PeripheralNotification)
    {
        write(command: notification.command)
    }
}

extension RLYPeripheral
{
    // MARK: - Non-Optional Names

    /// The name to use in logging.
    var loggingName: String
    {
        return lastFourMAC ?? identifier.uuidString
    }

    /// The peripheral style's name, or "Ringly" is the style is unknown or unavailable.
    var displayName: String
    {
        return RLYPeripheralStyleName(style) ?? "Ringly"
    }

    /// The peripheral style's name with "Ringly" appended, or "Ringly" is the style is unknown or unavailable.
    var displayNameRingly: String
    {
        return RLYPeripheralStyleName(style).map({ "\($0) Ringly" }) ?? "Ringly"
    }
}

extension Reactive where Base: RLYPeripheralDeviceInformation, Base: NSObject
{
    /// A signal producer for the peripheral's logging name.
    var loggingName: SignalProducer<String, NoError>
    {
        return SignalProducer.combineLatest(lastFourMAC, identifier).map({ $0 ?? $1.uuidString })
    }
}

extension RLYPeripheralStyle
{
    var image: UIImage?
    {
        switch self
        {
        case .daybreak:
            return UIImage(asset: .ringDaybreak)

        case .daydream:
            return UIImage(asset: .ringDaydream)

        case .disruptGold:
            return UIImage(asset: .ringDisruptGold)

        case .disruptRhodium:
            return UIImage(asset: .ringDiveBar)

        case .diveBar:
            return UIImage(asset: .ringDiveBar)

        case .intoTheWoods:
            return UIImage(asset: .ringIntoTheWoods)

        case .openingNight:
            return UIImage(asset: .ringOpeningNight)

        case .outToSea:
            return UIImage(asset: .ringOutToSea)

        case .stargaze:
            return UIImage(asset: .ringStargaze)

        case .wineBar:
            return UIImage(asset: .ringWineBar)

        case .wanderlust:
            return UIImage(asset: .ringWanderlust)

        case .backstage:
            return UIImage(asset: .braceletBackstage)

        case .boardwalk:
            return UIImage(asset: .braceletBoardwalk)

        case .lakeside:
            return UIImage(asset: .braceletLakeside)

        case .photoBooth:
            return UIImage(asset: .braceletPhotoBooth)

        case .rendezvous:
            return UIImage(asset: .braceletRendezvous)

        case .roadTrip:
            return UIImage(asset: .braceletRoadTrip)
        
        case .go01:
            return UIImage(asset: .braceletGO01)
        
        case .go02:
            return UIImage(asset: .braceletGO02)
        
        case .rose:
            return UIImage(asset: .braceletRoseAllDay)
        case .jets:
            return UIImage(asset: .braceletJetSet)
        case .ride:
            return UIImage(asset: .braceletJoyRide)
        case .bonv:
            return UIImage(asset: .braceletBonVoyage)
        case .date:
            return UIImage(asset: .ringFirstDate)
        case .hour:
            return UIImage(asset: .ringAfterHours)
        case .moon:
            return UIImage(asset: .ringFullMoon)
        case .tide:
            return UIImage(asset: .ringHighTide)
        case .day2:
            return UIImage(asset: .ringDaydream)

        case .invalid: fallthrough
        case .undetermined:
            return nil
        }
    }
}

extension RLYPeripheralType
{
    var image: UIImage?
    {
        switch self
        {
        case .bracelet:
            return UIImage(asset: .braceletPhotoBooth)

        default:
            return UIImage(asset: .ringDaydream)
        }
    }
}

extension SignalProducerProtocol where Value: OptionalProtocol
{
    /**
     When the receiver yields a value, starts the producer returned by passing the value to `function`. When that
     producer yields `.Supported`, the returned producer yields the initial value. Otherwise, the producer yields `nil`.

     - parameter function: A function to create a feature support producer.
     */
    
    func ifSupports(_ function: @escaping (Value.Wrapped) -> SignalProducer<RLYPeripheralFeatureSupport, Error>)
        -> SignalProducer<Value.Wrapped?, Error>
    {
        return flatMapOptionalFlat(.latest, transform: { value in
            function(value).map({ $0 == .supported ? value : nil })
        })
    }
}
