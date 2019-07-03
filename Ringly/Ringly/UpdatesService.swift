import ReactiveSwift
import Result
import RinglyAPI
import RinglyDFU
import RinglyExtensions

/// Looks up firmware updates from the Ringly API.
final class UpdatesService: NSObject
{
    // MARK: - Results
    
    /// The available firmware updates for the `peripherals` specified in `peripherals`.
    let firmwareResults: Property<[UUID:Result<FirmwareResult?, NSError>]>

    // MARK: - Peripherals

    /// The current peripherals to retrieve firmware results for.
    let peripherals = MutableProperty<Set<RLYPeripheral>>([])

    /// Maps the identifiers of `peripherals` to a current version.
    private let identifierVersions: Property<[(UUID, UpdatesServiceVersions?)]>
    
    // MARK: - Initialization
    
    /**
    Initializes an update service.

    - parameter api: The API service to fetch updates with.
    */
    init(api: APIService)
    {
        // tracks current peripheral versions
        identifierVersions = Property(
            initial: [],
            then: peripherals.producer
                .flatMap(.latest, transform: { peripherals in
                    SignalProducer.combineLatest(peripherals.map({ peripheral in
                        peripheral.reactive.updatesServiceVersions.map({ (peripheral.identifier, $0) })
                    }))
                })
        )

        // yields all unique peripheral version combinations exactly once
        let uniqueVersions: SignalProducer<UpdatesServiceVersions, NoError> = identifierVersions.producer
            .flatMap(.concat, transform: { identifierVersions -> SignalProducer<UpdatesServiceVersions, NoError> in
                SignalProducer(identifierVersions.flatMap({ _, versions in versions }))
            })
            .uniqueValues({ $0.hashValue })

        // load firmware results for each peripheral version
        let versionFirmwares = uniqueVersions.flatMap(.merge, transform: { versions in
            api.producer(versions: versions)
                .on(failed: { SLogAPI("Firmware requested failed: \($0)") })
                .resultify()
                .map({ (versions, $0) })
        })

        let collectedVersionFirmwares = versionFirmwares.scan(
            [UpdatesServiceVersions:Result<FirmwareResult?, NSError>](), { current, next in
                var copy = current
                copy[next.0] = next.1
                return copy
            }
        )

        // map firmware results to peripheral identifiers
        firmwareResults = Property(
            initial: [:],
            then: SignalProducer.combineLatest(identifierVersions.producer, collectedVersionFirmwares)
                .map({ identifierVersions, results -> [UUID:Result<FirmwareResult?, NSError>] in
                    // all identifier/versions with a non-`nil` `UpdateServiceVersions` associated
                    let nonNilVersions = identifierVersions.lazy.map(unwrap).flatMap({ $0 })

                    return nonNilVersions.flatMap({ identifier, versions in unwrap(identifier, results[versions]) })
                        .mapToDictionary({ ($0, $1) })
                })
        )
    }

    /**
     Initializes an updates service by binding to a peripherals service.

     - parameter api: The API service to fetch updates with.
     - parameter peripheralsService: The peripherals service to bind to.
     */
    convenience init(api: RinglyAPI.APIService, peripheralsService: PeripheralsService)
    {
        self.init(api: api)
        self.peripherals <~ peripheralsService.peripherals.producer.map(Set.init)
    }
}

// MARK: - Session

extension APIService
{
    // MARK: - Session

    /**
     Requests a firmware result for the specified versions.

     - parameter versions: The versions.
     */
    fileprivate func producer(versions: UpdatesServiceVersions) -> SignalProducer<FirmwareResult?, NSError>
    {
        // network request to retrieve firmware result
        let endpoint = FirmwareRequest.versions(
            hardware: versions.hardware,
            application: versions.application,
            bootloader: versions.bootloader,
            softdevice: nil,
            forceResults: false
        )

        // only include results with applications
        return resultProducer(for: endpoint).map({ $0.applications.count > 0 ? .some($0) : .none })
    }
}

// MARK: - Versions

/// The versions that the updates service uses for requests.
struct UpdatesServiceVersions
{
    /// The application version.
    let application: String

    /// The hardware version.
    let hardware: String

    /// The bootloader version, if knowable.
    let bootloader: String?
}

extension UpdatesServiceVersions
{
    static func with(application: String?, hardware: String?, bootloader: String?)
        -> UpdatesServiceVersions?
    {
        return unwrap(application, hardware, bootloader ?? application?.impliedBootloaderVersion.value)
            .map(UpdatesServiceVersions.init)
    }
}

extension UpdatesServiceVersions: Hashable
{
    var hashValue: Int
    {
        return application.hashValue ^ (bootloader?.hashValue ?? 0) ^ hardware.hashValue
    }
}

func ==(lhs: UpdatesServiceVersions, rhs: UpdatesServiceVersions) -> Bool
{
    return lhs.application == rhs.application
        && lhs.bootloader == rhs.bootloader
        && lhs.hardware == rhs.hardware
}

// MARK: - Peripheral Extensions
extension Reactive where Base: RLYPeripheral
{
    fileprivate var updatesServiceVersions: SignalProducer<UpdatesServiceVersions?, NoError>
    {
        // only yield values when the peripheral is ready
        return ready
            .flatMapOptional(.latest, transform: { peripheral in
                SignalProducer.combineLatest(
                    peripheral.reactive.applicationVersion,
                    peripheral.reactive.hardwareVersion,
                    peripheral.reactive.bootloaderVersion
                )
            })

            // determine if we have the correct parameters for a request to be made
            .mapOptionalFlat(UpdatesServiceVersions.with)
    }
}
