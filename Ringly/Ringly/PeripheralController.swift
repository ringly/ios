import Foundation
import ReactiveSwift
import RinglyActivityTracking
import RinglyExtensions
import RinglyKit
import enum Result.NoError

/// Acts as a peripheral observer, and creates dependent services.
final class PeripheralController: NSObject
{
    // MARK: - Initialization

    /// Initializes a peripheral controller.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral to control.
    ///   - savedPeripheral: A previous representation of the peripheral as a `SavedPeripheral`. This can be used for
    ///                      assuming the firmware version of the peripheral, before it has been read.
    ///   - activatedProducer: A producer of booleans, describing whether or not the peripheral should be activated.
    ///   - applicationsProducer: A producer of application configurations to use with the peripheral.
    ///   - contactsProducer: A producer of contact configurations to use with the peripheral.
    ///   - analyticsService: An analytics service, for tracking peripheral-related events.
    ///   - activityTracking: An activity tracking service, for managing activity tracking data.
    ///   - preferences: A preferences store.
    init(peripheral: RLYPeripheral,
         savedPeripheral: SavedPeripheral?,
         activatedProducer: SignalProducer<Bool, NoError>,
         applicationsProducer: SignalProducer<[ApplicationConfiguration], NoError>,
         contactsProducer: SignalProducer<[ContactConfiguration], NoError>,
         analyticsService: AnalyticsService,
         activityTracking: ActivityTrackingService,
         preferences: Preferences)
    {
        // assign properties
        self.peripheral = peripheral
        self.savedPeripheral = savedPeripheral
        self.analyticsService = analyticsService
        
        disposable += SignalProducer.merge(
            // read device and battery information
            peripheral.reactive.readInformation(),

            // write settings and connection LED responses
            peripheral.reactive.writeSettings(from: preferences),

            //rewrite name if rose device and in macaddress list
            peripheral.reactive.rewrite(config: RewriteConfig.rose()),
            
            //rewrite name if love device and in macaddress list
            peripheral.reactive.rewrite(config: RewriteConfig.love()),
            
            // write connection led responses
            peripheral.reactive.enableConnectionLEDResponse(),
            peripheral.reactive.writeConnectionLEDResponse(
                activatedProducer: activatedProducer.and(preferences.connectionTaps.producer),
                fallbackApplicationVersion: savedPeripheral?.applicationVersion
            ),

            // perform ANCS behavior on the peripheral
            peripheral.reactive.performANCSActions(
                activatedProducer: activatedProducer,
                applicationsProducer: applicationsProducer,
                contactsProducer: contactsProducer,
                innerRingProducer: preferences.innerRing.producer,
                analyticsService: analyticsService
            ),

            // send low battery notifications
            peripheral.reactive.sendLowBatteryNotifications(
                preferences: preferences,
                activatedProducer: activatedProducer
            ),
            
            // send full battery notifications
            peripheral.reactive.sendFullBatteryNotifications(
                preferences: preferences,
                activatedProducer: activatedProducer
            ),
            
            // send charge battery notifications
            peripheral.reactive.sendChargeBatteryNotifications(
                preferences: preferences,
                activatedProducer: activatedProducer
            ),
            
            // enable activity trackng and read data
            peripheral.reactive.performActivityTrackingActions(syncingWith: activityTracking)
        ).start()
        
        super.init()
        
        #if DEBUG || EXPERIMENTAL
            if let oldVersion = UserDefaults.standard.value(forKey: "CancelNotificationBuildVersionKey") as? String,
                let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                if oldVersion != currentVersion {
                    UserDefaults.standard.set(currentVersion, forKey: "CancelNotificationBuildVersionKey")
                    UIApplication.shared.cancelAllLocalNotifications()
                    SLogAppleNotifications("Cancelled all local notifications from previous builds")
                }
            }
            else {
                if let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    UserDefaults.standard.set(currentVersion, forKey: "CancelNotificationBuildVersionKey")
                }
            }


        #endif
        
        #if DEBUG || FUTURE
        // log flash log data
        disposable += peripheral.reactive.accumulatedFlashLog.startWithValues({ data in
            SLogBluetooth("Read flash log data: \(data)")
        })
            
        //write notification alert
        var cutoffTime : Date = Date()
        var wasPinned : Bool = false
            
        disposable += SignalProducer.combineLatest(applicationsProducer, contactsProducer)
            .sample(with: peripheral.reactive.ANCSV2NotificationsProducer())
            .startWithValues({ applications, notification in
                //check to see if app is supported and activated
                let appSupportedAndActivated = applications.0
                    .filter({$0.application.identifiers.contains(notification.applicationIdentifier)})
                    .first?
                    .activated ?? false
                
                //log notification if app is activated and contact configuration is activated
                if appSupportedAndActivated {   //&& contactConfigurationActivated {
                    cutoffTime = Date(timeIntervalSinceNow: TimeInterval(300))
                    NotificationAlertService.sharedNotificationService
                        .log(application: notification.applicationIdentifier,
                            title: notification.title,
                            message: notification.message,
                            date: notification.date ?? Date(),
                            pinned: false)
                    wasPinned = false
                }
            })
        
        disposable += activatedProducer
            // pin notification whenever three taps are received
            .sample(on: peripheral.reactive.receivedTaps.filter({ $0 == 3 }).void)
            .startWithValues({ _ in
                if (NSDate().earlierDate(cutoffTime) != cutoffTime) && (wasPinned == false) {
                    NotificationAlertService.sharedNotificationService.makePinned()
                    peripheral.write(command: RLYColorVibrationCommand(azureColorAndVibration: .twoPulses))
                    wasPinned = true
                }
            })
            
        #endif

        peripheral.add(observer: self)
    }

    deinit
    {
        peripheral.remove(observer: self)
        disposable.dispose()
    }

    private let disposable = CompositeDisposable()

    // MARK: - Peripheral

    /// The peripheral associated with this controller.
    let peripheral: RLYPeripheral

    /// The saved peripheral representation for this peripheral, if any.
    let savedPeripheral: SavedPeripheral?

    // MARK: - Sub-Services

    /// A passed-in analytics service.
    fileprivate let analyticsService: AnalyticsService
}

extension PeripheralController
{
    // MARK: - Saved Peripheral Producer

    /// A signal producer for the current saved peripheral value.
    ///
    /// The value of `savedPeripheral`, if available, is used to backfill the peripheral's application version if it
    /// has not yet been read.
    var savedPeripheralProducer: SignalProducer<SavedPeripheral, NoError>
    {
        let parameters = SignalProducer.combineLatest(
            peripheral.reactive.identifier,
            peripheral.reactive.name,
            peripheral.reactive.applicationVersion,
            peripheral.reactive.activityTrackingSupport
        )

        return parameters.scan(savedPeripheral, { current, next in
            return SavedPeripheral(
                identifier: next.0,
                name: next.1 ?? current?.name,
                applicationVersion: next.2 ?? current?.applicationVersion,
                activityTrackingSupport: next.3
            )
        }).skipNil()
    }
}

extension PeripheralController: RLYPeripheralObserver
{
    // MARK: - Peripheral Observer - Taps
    func peripheral(_ peripheral: RLYPeripheral, receivedTapsWithCount tapCount: UInt)
    {
        SLogBluetooth("Peripheral “\(peripheral.loggingName)” tapped \(tapCount) times")
    }

    // MARK: - Peripheral Observer - Commands
    func peripheral(_ peripheral: RLYPeripheral, didWrite command: RLYCommand)
    {
        SLogBluetooth("Writing command “\(command)” to peripheral “\(peripheral.loggingName)”")
    }

    func peripheral(_ peripheral: RLYPeripheral, failedToWrite command: RLYCommand, withError error: Error)
    {
        SLogBluetooth("Writing command “\(command)” to peripheral “\(peripheral.loggingName)” with error \(error)")
    }

    // MARK: - Peripheral Observer - Errors
    func peripheral(_ peripheral: RLYPeripheral,
                    encounteredApplicationErrorWithCode code: UInt,
                    lineNumber: UInt,
                    filename: String)
    {
        SLogBluetooth("Peripheral “\(peripheral.loggingName)”: application error \(code) at line \(lineNumber) in file \(filename)")

        let event = PeripheralApplicationErrorEvent(
            peripheral: peripheral,
            code: Int(code),
            line: Int(lineNumber),
            file: filename
        )

        analyticsService.track(event)
    }

    func peripheral(_ peripheral: RLYPeripheral, receivedUnsupportedMessageType type: UInt8, with data: Data)
    {
        let dataString = String.init(data: data, encoding: .utf8)
        
        SLogBluetooth("Peripheral “\(peripheral.loggingName)”: received message type \(type) with data \(dataString) at \(Date().timeIntervalSince1970)")
    }
}
