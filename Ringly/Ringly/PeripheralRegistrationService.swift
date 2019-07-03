import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyExtensions
import RinglyAPI
import RinglyKit

/// Automatically registers peripherals.
final class PeripheralRegistrationService: NSObject
{
    // MARK: - Peripherals

    /// The peripherals to register, if necessary.
    let peripherals = MutableProperty(Set<RLYPeripheral>())

    // MARK: - Initialization

    /// Initializes a peripheral registration service. The service is active immediately.
    ///
    /// - Parameters:
    ///   - APIService: The API service to register on.
    ///   - preferences: The preferences object to store registered peripherals in.
    init(APIService: RinglyAPI.APIService, preferences: Preferences)
    {
        super.init()

        // a producer of PeripheralRegistrationRequest values - when a next is sent, it should be sent as a request
        let endpointsProducer = peripherals.producer
            // This will cause some duplicates when a peripheral is added or removed, because all producers will be
            // generated again, and will immediately yield an endpoint. However, I consider this okay because those
            // events are relatively rare, and we filter out duplicate registrations regardless, so the only cost is
            // in additional processing - there are still no redundant network requests made.
            .flatMap(.latest, transform: { peripheral -> SignalProducer<PeripheralRegistrationRequest, NoError> in
                SignalProducer.merge(peripheral.map({ $0.reactive.peripheralRegistrationRequest }))
            })

        let usersProducer = APIService.authentication.producer
            .map({ authentication in authentication.user })
        
        SignalProducer.combineLatest(usersProducer, endpointsProducer)
            // drop cases where we do not have one or the other
            .map(unwrap)
            .skipNil()

            // a short name is required to register a peripheral
            .filter({ _, endpoint in RLYPeripheralShortNameFromName(endpoint.name) != nil })
        
            // ignore peripherals that we have already registered
            .filter({ user, endpoint in
                // this is unpleasant, since it requires reaching out into the non-pure world of state
                // but it is much more efficient than always retaining that list in memory
                !preferences.registeredRingNames.value.contains(endpoint.uniqueKeyWithUser(user))
            })
        
            .flatMap(.concat, transform: { user, endpoint in
                APIService.producer(for: endpoint)
                    .on(
                        failed: { error in
                            SLogGeneric("Error registering peripheral \(endpoint.MACAddress) for user \(user.email): \(error)")
                        },
                        completed: {
                            SLogGeneric("Registered peripheral for user \(user.email) with parameters \(endpoint.jsonBody)")
                            preferences.registeredRingNames.value.append(endpoint.uniqueKeyWithUser(user))
                        }
                    )
                    .ignoreValues()
                    .flatMapError({ error in SignalProducer.empty })
            })
        
            .take(until: reactive.lifetime.ended)
            .start()
    }

    /// Initializes a peripheral registration service, binding to a peripherals service.
    ///
    /// - Parameters:
    ///   - APIService: The API service to register on.
    ///   - peripheralsService: The peripherals service to bind to.
    ///   - preferences: The preferences object to store registered peripherals in.
    convenience init(APIService: RinglyAPI.APIService, peripheralsService: PeripheralsService, preferences: Preferences)
    {
        self.init(APIService: APIService, preferences: preferences)
        self.peripherals <~ peripheralsService.peripherals.producer.map(Set.init)
    }
}

extension Reactive where Base: RLYPeripheral
{
    /// A producer of registration endpoints for the peripheral.
    fileprivate var peripheralRegistrationRequest: SignalProducer<PeripheralRegistrationRequest, NoError>
    {
        return SignalProducer.combineLatest(
            name.skipNil(),
            MACAddress.skipNil(),
            applicationVersion.skipNil(),
            bootloaderVersion.skipNil(),
            softdeviceVersion.skipNil(),
            hardwareVersion.skipNil()
        ).map(PeripheralRegistrationRequest.init)
    }
}

extension PeripheralRegistrationRequest
{
    /// A unique key for the endpoint, to prevent re-uploads of the same data.
    fileprivate func uniqueKeyWithUser(_ user: User) -> String
    {
        return jsonBody
            .map({ key, value in "\(key)=\(value)" })
            .sorted(by: <)
            .joined(separator: ";")
            + ";\(user.email)"
    }
}
