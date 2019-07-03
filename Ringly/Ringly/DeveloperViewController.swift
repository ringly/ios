#if DEBUG || FUTURE

import Foundation
import MessageUI
import PureLayout
import ReactiveSwift
import Result
import RinglyAPI
import RinglyActivityTracking
import RinglyExtensions
import Crashlytics

final class DeveloperViewController: ServicesViewController
{
    // MARK: - View Loading
    fileprivate let scrollView = UIScrollView.newAutoLayout()

    override func loadView()
    {
        // initial view setup
        let view = GradientView.purpleBlueGradientView
        self.view = view

        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()

        // puts the peripheral into deep sleep, or resets its firmware
        let (sleep, reset) = sideBySideButtons(titles: ("💤 Sleep", "🔄 Reset"), belowView: nil)
        [sleep, reset].forEach({ $0.autoPinEdgeToSuperview(edge: .top, inset: 10) })

        sleep.addTarget(self, action: #selector(DeveloperViewController.deepSleepAction), for: .touchUpInside)
        reset.addTarget(self, action: #selector(DeveloperViewController.firmwareResetAction), for: .touchUpInside)

        // allows manual DFU or name change
        let (dfu, name) = sideBySideButtons(titles: ("💾 DFU", "🙋 Name"), belowView: sleep)

        dfu.addTarget(self, action: #selector(DeveloperViewController.DFUAction), for: .touchUpInside)
        name.addTarget(self, action: #selector(DeveloperViewController.peripheralNameAction), for: .touchUpInside)

        // queries the peripheral for logging information
        let loggingQuery = centeredButton(
            title: "🌲 Logging Query 🌲",
            belowView: dfu,
            action: #selector(DeveloperViewController.loggingQueryAction)
        )
        
        let sendDiagnostics = centeredButton(
            title: "🛰 Send Diagnostics 🛰",
            belowView: loggingQuery,
            action: #selector(DeveloperViewController.sendDiagnostics)
        )

        // allows modification of the peripheral's tap parameters
        let changeAPIServer = centeredButton(
            title: "📡 API Server 📡",
            belowView: sendDiagnostics,
            action: #selector(DeveloperViewController.changeAPIServer)
        )

        // allows modification of the peripheral's tap parameters
        let tapParameters = centeredButton(
            title: "👉 Tap Params 👈",
            belowView: changeAPIServer,
            action: #selector(DeveloperViewController.tapParameters)
        )

        // kills the app immediately
        let killButton = centeredButton(
            title: "💀 KILL 💀",
            belowView: tapParameters,
            action: #selector(DeveloperViewController.kill)
        )

        // displays the onboarding process, even if it has already been completed
        let onboarding = centeredButton(
            title: "🚆 Onboarding 🚆",
            belowView: killButton,
            action: #selector(DeveloperViewController.showOnboarding)
        )

        // adds sample activity tracking data
        let activityTracking = centeredButton(
            title: "👠 Add Activity 👠",
            belowView: onboarding,
            action: #selector(DeveloperViewController.demoActivityData)
        )
        
        
        // change the motor power for breathing exercise
        let motorPower = centeredButton(
            title: "💨 Breathing Motor Power 💨",
            belowView: activityTracking,
            action: #selector(DeveloperViewController.changeBreathingExercisePower)
        )
        
        // change the motor power for breathing exercise
        let breathingStyle = centeredButton(
            title: "💨 Breathing Buzz Style 💨",
            belowView: motorPower,
            action: #selector(DeveloperViewController.changeBreathingStyle)
        )
        
        // adds sample mindful minutes data
        let mindfulnessMinutes = centeredButton(
            title: "😇 Add Mindful Minutes 😇",
            belowView: breathingStyle,
            action: #selector(DeveloperViewController.demoMindfulnessData)
        )

        let clearActivity = centeredButton(
            title: "🔥 Clear Activity 🔥",
            belowView: mindfulnessMinutes,
            action: #selector(DeveloperViewController.clearActivityData)
        )
        
        let invalidatePeripheral = centeredButton(
            title: "🔥 Invalidate Peripheral 🔥",
            belowView: clearActivity,
            action: #selector(DeveloperViewController.invalidatePeripheral)
        )

        let rewriteHealthKit = centeredButton(
            title: " 🏥 ↻ HealthKit 🏥",
            belowView: invalidatePeripheral,
            action: #selector(DeveloperViewController.rewriteHealthKit)
        )

        let resetBodyData = centeredButton(
            title: "💪 ↻ Body Data 💪" ,
            belowView: rewriteHealthKit,
            action: #selector(DeveloperViewController.resetBodyData)
        )
        
        let resetGoals = centeredButton(
            title: "📊 ↻ Goal Settings 📊" ,
            belowView: resetBodyData,
            action: #selector(DeveloperViewController.resetGoals)
        )

        // allows hourly data dump
        let hourlyData = centeredButton(
            title: "⏳ Hourly Data ⌛️",
            belowView: resetGoals,
            action: #selector(DeveloperViewController.hourlyData)
        )

        // changes custom simulated screen size
        let screenSize = centeredButton(
            title: "📱 SCREEN SIZE 📱",
            belowView: hourlyData,
            action: #selector(DeveloperViewController.screenSize)
        )

        // displays the review request prompt
        let reviews = centeredButton(
            title: "⭐️ RESET REVIEW 1min ⭐️",
            belowView: screenSize,
            action: #selector(DeveloperViewController.review)
        )
        
        // simulate crash
        let crash = centeredButton(
            title: "☠ SIMULATE CRASH ☠",
            belowView: reviews,
            action: #selector(DeveloperViewController.simulateCrash)
        )
        
        // trigger manual peripheral sync
        let manualSync = centeredButton(
            title: "𝍅 MANUAL SYNC 𝍅",
            belowView: crash,
            action: #selector(DeveloperViewController.manualSync)
        )
        
        // removes apps for testing added apps notifications
        let removeApps = centeredButton(
            title: "🥖 REMOVE APPS 🥖",
            belowView: manualSync,
            action: #selector(DeveloperViewController.removeApps)
        )
        

        // removes apps for testing added apps notifications
        let frameCommand = centeredButton(
            title: "🎞 SEND FRAME COMMAND 🎞",
            belowView: removeApps,
            action: #selector(DeveloperViewController.sendFrameCommand)
        )

        let resetNotifications = centeredButton(
            title: "👀 RESET NOTIFICATIONS 👀",
            belowView: frameCommand,
            action: #selector(DeveloperViewController.resetNotifications)
        )


        // enables and disables launch notifications
        let notifications = switchWithTitle(
            title: "Background Launch Notifications",
            preference: services.preferences.launchNotificationsEnabled,
            below: resetNotifications
        )

        // enables and disables ANCS timeout alerts
        let ANCSTimeout = switchWithTitle(
            title: "ANCS Timeout Alerts",
            preference: services.preferences.ANCSTimeout,
            below: notifications
        )

        // enables and disables continuous daily steps notifications
        let dailySteps = switchWithTitle(
            title: "Current day steps notifications",
            preference: services.preferences.developerCurrentDayStepsNotifications,
            below: ANCSTimeout
        )

        dailySteps.autoPin(edge: .bottom, to: .bottom, of: scrollView, offset: -10)
    }

    fileprivate var instagramDocumentController: UIDocumentInteractionController?
}

extension DeveloperViewController
{
    // MARK: - Choosing a Peripheral
    fileprivate func selectPeripheral(completion: @escaping (RLYPeripheral) -> ())
    {
        let peripherals = services.peripherals.peripherals.value

        switch peripherals.count
        {
        case 0:
            presentAlert(title: "Error", message: "No peripherals")
        case 1:
            completion(peripherals[0])
        default:
            let controller = UIAlertController(title: "Select Peripheral", message: nil, preferredStyle: .alert)

            let actions = peripherals.map({ peripheral in
                UIAlertAction(
                    title: peripheral.name ?? peripheral.identifier.uuidString,
                    style: .default,
                    handler: { _ in
                        completion(peripheral)
                    }
                )
            })

            actions.forEach(controller.addAction)

            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(controller, animated: true, completion: nil)
        }
    }
}

extension DeveloperViewController
{
    // MARK: - Button Actions
    @objc fileprivate func deepSleepAction()
    {
        selectPeripheral { peripheral in
            peripheral.write(command: RLYDeepSleepCommand())
        }
    }

    @objc fileprivate func firmwareResetAction()
    {
        selectPeripheral { peripheral in
            peripheral.write(command: RLYFirmwareResetCommand())
        }
    }

    @objc fileprivate func loggingQueryAction()
    {
        selectPeripheral { peripheral in
            // create actions to send logging queries
            let queries = [
                ("Frequency", RLYLoggingQuery.freqRSSI),
                ("Reset Reason", RLYLoggingQuery.resetReason),
                ("Freq + RSSI", RLYLoggingQuery.freqRSSI),
                ("Time Since Bootup", RLYLoggingQuery.timeSinceBootup),
                ("State Pin Value", RLYLoggingQuery.statePinValue),
                ("Charge Pin Value", RLYLoggingQuery.chargePinValue),
                ("Burn Test Data", RLYLoggingQuery.burnTestData)
            ]

            let actions = queries.map({ title, query in
                UIAlertAction(title: title, style: .default, handler: { _ in
                    peripheral.write(command: RLYLoggingQueryCommand(query: query))
                })
            })

            // display alert to choose logging query
            let alert = UIAlertController(title: "Logging Query", message: nil, preferredStyle: .actionSheet)
            actions.forEach(alert.addAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc fileprivate func kill()
    {
        _ = Darwin.kill(getpid(), SIGKILL)
    }

    @objc fileprivate func showOnboarding()
    {
        let clear = { [weak services] in
            guard let preferences = services?.preferences else { return }
            preferences.onboardingShown.value = false
            preferences.applicationsOnboardingState.value = .overlay
            preferences.cameraOnboardingShown.value = false

            EngagementNotification.all.forEach({ notification in
                notification.stateProperty(in: preferences.engagement).value = .unscheduled
                UIApplication.shared.cancelEngagementNotifications(notification)
            })
        }

        if services.peripherals.peripherals.value.count > 0
        {
            let alert = UIAlertController.choose(
                title: "Continue resetting onboarding?",
                message: "Engagement notifications will not behave correctly if a peripheral is currently paired. To test engagement notifications, forget all peripherals first.",
                preferredStyle: .alert,
                inViewController: self,
                choices: [AlertControllerChoice(title: "Continue", style: .destructive, value: true)]
            )

            alert.startWithValues({ _ in clear() })
        }
        else
        {
            clear()
        }
    }
    
    @objc fileprivate func invalidatePeripheral()
    {
        self.selectPeripheral(completion: { peripheral in
            peripheral.addValidationError(NSError.init(domain: "FakeError", code: 100, userInfo: nil))
        })
    }

    @objc fileprivate func sendDiagnostics()
    {
        self.collectDiagnosticData(from: services, queryItems: [URLQueryItem.init(name: "reference", value: "test-diagnostic")])
    }
    
    @objc fileprivate func changeAPIServer()
    {
        let alert = UIAlertController(
            title: "📡 Change API Server 📡",
            message: "Current server is “\(services.api.authentication.value.server)”. Changing servers will reset authentication.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "🌎 Production", style: .default, handler: { [weak self] _ in
            self?.services.preferences.authentication.value = Authentication(user: nil, token: nil, server: .production)
        }))

        alert.addAction(UIAlertAction(title: "🎬 Staging", style: .default, handler: { [weak self] _ in
            self?.services.preferences.authentication.value = Authentication(user: nil, token: nil, server: .staging)
        }))

        alert.addAction(UIAlertAction(title: "💻 Custom", style: .default, handler: { [weak self] _ in
            self?.setCustomAPIServer()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    fileprivate func setCustomAPIServer()
    {
        let alert = UIAlertController(title: "💻 Custom API Server 💻", message: nil, preferredStyle: .alert)

        let appTokenProperty = MutableProperty(String?.none), baseURLProperty = MutableProperty(URL?.none)

        let done = UIAlertAction(title: "Confirm", style: .default, handler: { [weak self] _ in
            guard let appToken = appTokenProperty.value, let baseURL = baseURLProperty.value else { return }

            let server = APIServer.custom(appToken: appToken, baseURL: baseURL)
            self?.services.preferences.authentication.value = Authentication(user: nil, token: nil, server: server)
        })

        appTokenProperty.producer.combineLatest(with: baseURLProperty.producer)
            .map(unwrap)
            .map({ $0 != nil })
            .startWithValues({ done.isEnabled = $0 })

        alert.addAction(done)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addTextField(configurationHandler: { field in
            field.placeholder = "App Token"
            field.autocorrectionType = .no
            field.autocapitalizationType = .none
            appTokenProperty <~ field.reactive.continuousTextValues
        })

        alert.addTextField(configurationHandler: { field in
            field.placeholder = "Base URL, with trailing “/”"
            field.autocorrectionType = .no
            field.autocapitalizationType = .none
            field.keyboardType = .URL
            baseURLProperty <~ SignalProducer(field.reactive.continuousTextValues).mapOptionalFlat({ URL(string: $0) })
        })

        present(alert, animated: true, completion: nil)
    }

    @objc fileprivate func DFUAction()
    {
        selectPeripheral { peripheral in
            let builder = DFUPackageBuilderViewController(services: self.services)
            builder.peripheral.value = peripheral

            let navigation = UINavigationController(rootViewController: builder)

            builder.completed = { [weak self, weak navigation] _, result in
                navigation?.dismiss(animated: true, completion: nil)
                self?.presentDFU(peripheral: peripheral, firmwareResult: result)
            }

            builder.cancelled = { [weak navigation] _ in
                navigation?.dismiss(animated: true, completion: nil)
            }

            self.present(navigation, animated: true, completion: nil)
        }
    }

    @objc fileprivate func peripheralNameAction()
    {
        selectPeripheral { peripheral in
            var nameField: UITextField?

            let alert = UIAlertController(title: "Set Peripheral Name",
                                          message: peripheral.name.map({ "Current is “\($0)”" }),
                                          preferredStyle: .alert)

            func write(diamond: Bool)
            {
                nameField?.resignFirstResponder()
                guard let name = nameField?.text else { return }
                peripheral.write(command: RLYAdvertisingNameCommand(shortName: name, diamondClub: diamond))
            }

            // add alert actions
            let diamond = UIAlertAction(title: "💎 Diamond Club 💎", style: .default, handler: { _ in
                write(diamond: true)
            })

            alert.addAction(diamond)

            let normal = UIAlertAction(title: "Normal", style: .default, handler: { _ in
                write(diamond: false)
            })

            alert.addAction(normal)

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                nameField?.resignFirstResponder()
            }))

            // add the name field
            alert.addTextField(configurationHandler: { textField in
                nameField = textField

                // only allow submission with four characters
                SignalProducer(textField.reactive.continuousTextValues)
                    .mapOptional({ $0.characters.count == 4 })
                    .map({ $0 ?? false })
                    .startWithValues({ enabled in
                        diamond.isEnabled = enabled
                        normal.isEnabled = enabled
                    })

                textField.autocapitalizationType = .allCharacters
                textField.autocorrectionType = .no
                textField.placeholder = "Short Name (“DAYD”, etc.)"
            })

            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc fileprivate func tapParameters()
    {
        selectPeripheral { peripheral in
            let titles = [
                "Threshold",
                "Time Limit",
                "Latency",
                "Window",
                "Field 5",
                "Field 6",
                "Field 7",
                "Field 8",
                "Field 9",
                "Field 10"
            ]

            SignalProducer.concat(titles.map(self.tapParametersFieldProducer))
                .collect()
                .flatMapError({ _ in SignalProducer.empty })
                .startWithValues({ parameters in
                    guard parameters.count == 10 else { return }

                    peripheral.write(command: RLYTapParametersCommand(
                        threshold: parameters[0],
                        timeLimit: parameters[1],
                        latency: parameters[2],
                        window: parameters[3],
                        field5: parameters[4],
                        field6: parameters[5],
                        field7: parameters[6],
                        field8: parameters[7],
                        field9: parameters[8],
                        field10: parameters[9]
                    ))
                })
        }
    }

    fileprivate func tapParametersFieldProducer(title: String) -> SignalProducer<UInt8, Interrupt>
    {
        return SignalProducer.`defer` {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            let (signal, observer) = Signal<UInt8, Interrupt>.pipe()

            var field: UITextField?

            let continueAction = UIAlertAction(title: "Continue", style: .default, handler: { _ in
                if let value = (field?.text).flatMap({ UInt8($0) })
                {
                    observer.send(value: value)
                    observer.sendCompleted()
                }
                else
                {
                    observer.send(error: Interrupt())
                }
            })

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                observer.send(error: Interrupt())
            })

            [continueAction, cancelAction].forEach(alert.addAction)

            alert.addTextField(configurationHandler: { (textField: UITextField) in
                field = textField
                SignalProducer(textField.reactive.continuousTextValues)
                    .mapOptional({ UInt8($0) != nil })
                    .map({ $0 ?? false })
                    .startWithValues({ continueAction.isEnabled = $0 })
            })

            return self.reactive.present(viewController: alert, animated: true)
                .promoteErrors(Interrupt.self)
                .then(SignalProducer(signal))
                .take(first: 1)
        }
    }
    
    @objc fileprivate func demoMindfulnessData() {
        guard services.activityTracking.realmService != nil else {
            presentAlert(title: "Realm Error", message: "Realm service doesn't exist. See DeveloperViewController.")
            return
        }
        self.services.activityTracking.realmService?.startMindfulnessSession(mindfulnessType: .breathing, description: "Breathing").flatMap(.latest, transform: { session in
            self.services.activityTracking.realmService!.addMinuteToMindfulnessSession(sessionId: session!.id, store: self.services.activityTracking.healthStore)
        }).start()
        
    }
    
    @objc fileprivate func changeBreathingExercisePower() {
        selectMotorPower()
    }
    
    @objc fileprivate func changeBreathingStyle() {
        let alert = UIAlertController.choose(title: "Choose Style", message: nil, preferredStyle: .actionSheet, inViewController: self, choices: BreathingVibrationStyle.types().map({ style in
            return AlertControllerChoice.init(title: style.rawValue, value: style.rawValue)
        }))
        
        alert.startWithValues({ value in
            self.services.preferences.breathingVibrationStyle.value = value
        })
    }

    @objc fileprivate func demoActivityData()
    {
        guard let realm = services.activityTracking.realmService else {
            presentAlert(title: "Realm Error", message: "Realm service doesn't exist. See DeveloperViewController.")
            return
        }

        selectNumberOfHours(
            title: "Sample Activity Data",
            message: "How many hours of sample data, backwards from the current date?",
            actionTitle: "Generate",
            completion: { hours, macAddress in
                let currentDate = Date()

                let updates = (0..<(hours * 60)).flatMap({ index -> SourcedUpdate? in
                    do
                    {
                        // skip some minutes
//                        guard arc4random() % 6 == 0 else { return nil }

                        // create the date for the update
                        let date = currentDate.addingTimeInterval(-TimeInterval(index) * 60)
                        let activityTrackingDate = try RLYActivityTrackingDate(date: date)

                        // create the update and sourced update
                        let update = RLYActivityTrackingUpdate(
                            date: activityTrackingDate,
                            walkingSteps: 2,
                            runningSteps: 0
                        )

                        return SourcedUpdate(macAddress: macAddress, update: update)
                    }
                    catch // this indicates overflowing the date bounds, not really an issue
                    {
                        return nil
                    }
                })

                realm.writeSourcedUpdatesWithLogging(updates).start()
            }
        )
    }

    @objc fileprivate func clearActivityData()
    {
        guard let realm = services.activityTracking.realmService else {
            presentAlert(title: "Realm Error", message: "Realm service doesn't exist. See DeveloperViewController.")
            return
        }

        let alert = UIAlertController(
            title: "Delete all Realm activity data?",
            message: "This will not clear data that has been written to HealthKit.",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            realm.deleteAllData().startWithFailed(self.presentError)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    @objc fileprivate func rewriteHealthKit()
    {
        services.activityTracking.realmService?.rewriteAllHealthKitData().start()
    }

    @objc fileprivate func resetBodyData()
    {
        services.preferences.activityTrackingBodyMass.value = nil
        services.preferences.activityTrackingHeight.value = nil
        services.preferences.activityTrackingBirthDateComponents.value = nil
    }
    
    @objc fileprivate func resetGoals()
    {
        services.preferences.activityTrackingStepsGoal.value = 10000
        services.preferences.activityTrackingMindfulnessGoal.value = 5
    }
    
    fileprivate func selectMotorPower()
    {
        let alert = UIAlertController(title: "Change Power", message: nil, preferredStyle: .alert)
        
        let textProperty:MutableProperty<String?> = MutableProperty("\(self.services.preferences.motorPower.value)")
        
        alert.addTextField(configurationHandler: { field in
            field.keyboardType = .decimalPad
            field.text = "\(self.services.preferences.motorPower.value)"
            textProperty <~ field.reactive.continuousTextValues
            field.placeholder = "Power"
        })
        
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let power = textProperty.value.flatMap({ Int($0) })
            {
                self.services.preferences.motorPower.value = power
            }
            else
            {
                self.presentAlert(title: "Not a number", message: "“\(textProperty.value ?? "")” is not a number")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }


    fileprivate func selectNumberOfHours(title: String, message: String, actionTitle: String, completion: @escaping (Int, Int64) -> ())
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let textProperty = MutableProperty(String?.none)
        let macAddressProperty = MutableProperty(String?.none)

        alert.addTextField(configurationHandler: { field in
            field.keyboardType = .decimalPad
            textProperty <~ field.reactive.continuousTextValues
            field.placeholder = "Hours"
        })
        
        alert.addTextField(configurationHandler: { field in
            field.keyboardType = .decimalPad
            macAddressProperty <~ field.reactive.continuousTextValues
            field.placeholder = "Mac Address"
        })

        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            if let hours = textProperty.value.flatMap({ Int($0) }), let macAddress = macAddressProperty.value.flatMap({ Int64($0) })
            {
                completion((hours, macAddress))
            }
            else
            {
                self.presentAlert(title: "Not a number", message: "“\(textProperty.value ?? "")” is not a number")
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    @objc fileprivate func hourlyData()
    {
        selectNumberOfHours(
            title: "Data Length",
            message: "How many hours of data, backwards from the current hour?",
            actionTitle: "Collect Data",
            completion: collectHourlyData
        )
    }

    @objc fileprivate func collectHourlyData(hours: Int, macAddress: Int64)
    {
        let calendar = NSCalendar.current

        var endComponents = calendar.dateComponents([.era, .year, .month, .day, .hour], from: Date())
        endComponents.hour = endComponents.hour.map({ $0 + 1 })

        guard let end = calendar.date(from: endComponents) else {
            presentAlert(title: "Failed to create end date", message: "components are \(endComponents)")
            return
        }

        guard let start = calendar.date(byAdding: .hour, value: -hours, to: end) else {
            presentAlert(title: "Failed to create start date", message: "end date is \(end)")
            return
        }

        let boundaries = calendar.boundaryDatesForHours(from: start, to: end)

        let activity = ActivityController()
        present(activity, animated: false, completion: nil)

        SignalProducer<BoundaryDates, NoError>(boundaries)
            .promoteErrors(NSError.self)
            .flatMap(.concat, transform: { boundaryDates in
                self.services.activityTracking.stepsDataProducer(
                    startDate: boundaryDates.start,
                    endDate: boundaryDates.end
                ).take(first: 1).map({ BoundaryDatedSteps(steps: $0.steps, boundaryDates: boundaryDates) })
            })
            .collect()
            .observe(on: UIScheduler())
            .startWithResult({ result in
                activity.dismiss(animated: false, completion: nil)

                switch result
                {
                case let .success(steps):
                    let data = steps.commaSeparatedValueRepresentation.data(using: .utf8)
                    let attachment = data.map({ data in
                        MailComposeAttachment(
                            data: data,
                            mimeType: "text/csv",
                            fileNameBase: "logs",
                            fileExtension: "csv"
                        )
                    })

                    self.mail(
                        description: "hourly data",
                        reference: nil,
                        recipients: [],
                        userEmail: self.services.api.authentication.value.user?.email,
                        attach: {
                            Result(attachment, failWith: MailComposeError(
                                errorDescription: "Error",
                                failureReason: "Error converting to CSV data representation."
                            ) as NSError)
                        }
                    )

                case let .failure(error):
                    self.presentError(error)
                }
            })
    }

    @objc fileprivate func screenSize()
    {
        let controller = UIAlertController(
            title: "Simulated Screen Size",
            message: "The view will be resized to simulate a smaller screen for layout testing. This may not be perfect.",
            preferredStyle: .alert
        )

        let sizes = [
            ("iPhone 4", CGSize(width: 320, height: 480)),
            ("iPhone 5", CGSize(width: 320, height: 568)),
            ("iPhone 6", CGSize(width: 375, height: 667)),
            ("iPhone 6 Plus", CGSize(width: 414, height: 736)),
            ("Reset", CGSize?.none)
        ]

        let smaller = sizes.filter({ _, optional in
            optional.map({ size in
                size.height < UIScreen.main.bounds.size.height
            }) ?? true
        })

        let actions = smaller.map({ title, size in
            UIAlertAction(title: title, style: .default, handler: { [weak self] _ in
                self?.services.preferences.simulatedScreenSize.value = size
            })
        })

        actions.forEach(controller.addAction)

        present(controller, animated: true, completion: nil)
    }

    @objc fileprivate func review()
    {
        services.preferences.reviewsState.value = nil
        services.preferences.reviewsState.transitionReviewsState(after: 60.0)
        
        presentAlert(title: "Review State Reset", message: "Restart app in 1 min to see review")
    }
    
    @objc fileprivate func simulateCrash() {
        Crashlytics.sharedInstance().crash()
    }
    
    @objc fileprivate func manualSync() {
        self.services.activityTracking.syncObserver.send(value: .dev)
    }
    
    @objc fileprivate func resetNotifications() {
        let preferences = services.preferences
        
//        // cancel engagement notifications
//        EngagementNotification.all.forEach({ notification in
//            notification.stateProperty(in: preferences.engagement).value = .unscheduled
//            UIApplication.shared.cancelEngagementNotifications(notification)
//        })
        
        // cancel all notifications, including charge
        UIApplication.shared.cancelAllLocalNotifications()
        
//        // reset engagement notifications
//        services.engagementNotifications.reactive.manageAllInitialPairNotificationsDebug(
//            stepGoalProducer: preferences.activityTrackingStepsGoal.producer,
//            preferences: preferences.engagement
//            ).start()
        
        // reset mindful preferences
        preferences.mindfulReminderTime.value = DateComponents.init(hour: 8, minute: 0)
        preferences.mindfulRemindersEnabled.value = false
        preferences.mindfulReminderAlertOnboardingState.value = false
        
        presentAlert(title: "Notifications Reset", message: "Check logs to see rescheduled mindfulness, and charge notifications.")
    }
}

extension DeveloperViewController
{
    // MARK: - Button Builders
    fileprivate func sideBySideButtons(titles: (String, String), belowView: UIView?) -> (UIControl, UIControl)
    {
        let leading = ButtonControl.newAutoLayout()
        leading.title = titles.0
        leading.textColor = .gray
        scrollView.addSubview(leading)

        let trailing = ButtonControl.newAutoLayout()
        trailing.title = titles.1
        trailing.textColor = .gray
        scrollView.addSubview(trailing)

        [leading, trailing].forEach({ button in
            button.font = UIFont.gothamBook(12)
            belowView?.autoPin(edge: .bottom, to: .top, of: button, offset: -20)
            button.autoSet(dimension: .height, to: 44)
        })

        leading.autoPin(edge: .leading, to: .leading, of: view, offset: 20)
        trailing.autoPin(edge: .trailing, to: .trailing, of: view, offset: -20)

        trailing.autoPin(edge: .leading, to: .trailing, of: leading, offset: 20)
        trailing.autoMatch(dimension: .width, to: .width, of: leading)

        return (leading, trailing)
    }

    fileprivate func centeredButton(title: String, belowView: UIView?, action: Selector) -> UIControl
    {
        let control = ButtonControl.newAutoLayout()
        control.title = title
        control.textColor = .gray
        control.font = UIFont.gothamBook(12)
        scrollView.addSubview(control)

        control.autoSetDimensions(to: CGSize(width: 280, height: 44))
        control.autoAlignAxis(toSuperviewAxis: .vertical)
        belowView?.autoPin(edge: .bottom, to: .top, of: control, offset: -20)

        control.addTarget(self, action: action, for: .touchUpInside)

        return control
    }

    fileprivate func switchWithTitle(title: String, preference: MutableProperty<Bool>, below: UIView) -> UIView
    {
        let wrapper = UIView.newAutoLayout()

        let label = UILabel.newAutoLayout()
        label.text = title
        label.font = UIFont.gothamBook(12)
        label.textColor = UIColor.white
        wrapper.addSubview(label)

        let control = UISwitch.newAutoLayout()
        control.isOn = preference.value

        SignalProducer(control.reactive.controlEvents(.valueChanged)).startWithValues({ _ in
            preference.value = control.isOn
        })

        wrapper.addSubview(control)
        scrollView.addSubview(wrapper)

        wrapper.autoPinEdgeToSuperview(edge: .leading, inset: 20)
        wrapper.autoPinEdgeToSuperview(edge: .trailing, inset: 20)
        wrapper.autoPin(edge: .top, to: .bottom, of: below, offset: 20)

        [label, control].forEach({ view in
            view.autoAlignAxis(toSuperviewAxis: .horizontal)
            view.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
            view.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        })

        label.autoPinEdgeToSuperview(edge: .leading)
        control.autoPinEdgeToSuperview(edge: .trailing)
        control.autoPin(edge: .leading, to: .trailing, of: label, offset: 20, relation: .greaterThanOrEqual)

        return wrapper
    }

    @objc fileprivate func removeApps()
    {
        let controller = UINavigationController(rootViewController: RemoveAppsViewController(services: services))
        present(controller, animated: true, completion: nil)
    }
    
    @objc fileprivate func sendFrameCommand()
    {
        let breathingExerciseConfig = BreathingExerciseConfig.oneHold(cyclesPerMinute: 6, totalTime: .seconds(60))
        selectPeripheral { peripheral in
            peripheral.write(
                command: RLYKeyframeCommand.init(
                    colorKeyframes: [],
                    vibrationKeyframes: breathingExerciseConfig.vibrationPattern,
                    repeatCount: 2)
                )
        }
    }
}

// MARK: - Private Types
private struct Interrupt: Error {}

private struct BoundaryDatedSteps
{
    let steps: Steps
    let boundaryDates: BoundaryDates
}

extension BoundaryDatedSteps: CommaSeparatedValueRepresentable
{
    static var commaSeparatedHeaders: [String]
    {
        return [
            "Steps",
            "Walking Steps",
            "Running Steps",
            "Start Timestamp",
            "End Timestamp"
        ]
    }

    var commaSeparatedFields: [String]
    {
        return [
            String(steps.stepCount),
            String(steps.walkingStepCount),
            String(steps.runningStepCount),
            String(boundaryDates.start.timeIntervalSince1970),
            String(boundaryDates.end.timeIntervalSince1970)
        ]
    }
}

#endif
