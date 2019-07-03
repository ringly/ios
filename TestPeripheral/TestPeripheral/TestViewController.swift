import ReactiveSwift
import RinglyKit
import UIKit
import enum Result.NoError

final class TestViewController: UIViewController
{
    // MARK: - Views
    @IBOutlet fileprivate var tableView: UITableView?

    // MARK: - Configuration
    typealias Configuration = (central: RLYCentral, peripheral: RLYPeripheral, hardwareVersion: RLYKnownHardwareVersion)
    let configuration = MutableProperty(Configuration?.none)

    // MARK: - Test Cases
    let testCases = MutableProperty<[TestCase]>([])
    let testResults = MutableProperty<[(test: TestCase, result: TestResult?)]?>(nil)

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        configuration.producer.startWithValues({ [weak self] configuration in
            self?.title = (configuration?.peripheral.style).map(RLYPeripheralStyleName)
                ?? configuration?.peripheral.name
        })

        testCases <~ configuration.producer.map({ configuration in
            (configuration?.hardwareVersion).map({ version in
                allTestCases.filter({ $0.supports(version) })
            }) ?? []
        })

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .play,
            target: self,
            action: #selector(TestViewController.runAction)
        )

        // add peripheral observer for logging
        configuration.producer
            .map({ $0?.peripheral })
            .concat(value: nil)
            .combinePrevious(nil)
            .startWithValues({ [weak self] previous, current in
                guard let strong = self else { return }
                previous?.remove(observer: strong)
                current?.add(observer: strong)
            })

        // reload table as tests execute
        SignalProducer.merge(testCases.producer.map({ _ in () }), testResults.producer.map({ _ in () }))
            .startWithValues({ [weak self] in self?.tableView?.reloadData() })
    }

    // MARK: - Actions
    @objc fileprivate func runAction()
    {
        guard let (central, peripheral, hardwareVersion) = configuration.value else { return }

        // disallow running tests while tests are running
        navigationItem.rightBarButtonItem?.isEnabled = false

        // convert test cases to signal producers with the current configuration
        let cases = testCases.value

        var caseProducers = cases.testResultProducers(
            central: central,
            peripheral: peripheral,
            hardwareVersion: hardwareVersion
        )

        // if table view rows are selected, only run those tests
        if let selectedRows = tableView?.indexPathsForSelectedRows
        {
            let indices = Set(selectedRows.map({ $0.row }))
            caseProducers = caseProducers.enumerated()
                .filter({ index, _ in indices.contains(index) })
                .map({ _, producer in producer })
        }

        // start with an empty set of results
        testResults.value = cases.map({ (test: $0, result: nil) })

        SignalProducer(caseProducers).flatten(.concat).on(
            completed: { [weak self] in
                // determine which of the tests failed
                let failures = (self?.testResults.value ?? []).flatMap({ test, result in
                    (result?.failureReason).map({ (title: test.title, reason: $0) })
                })

                // if a non-0 number of tests failed, display a controller summarizing the failures
                if failures.count > 0
                {
                    let controller = FailuresViewController()
                    controller.failures.value = failures

                    let navigation = UINavigationController(rootViewController: controller)
                    self?.present(navigation, animated: true, completion: nil)
                }

                self?.navigationItem.rightBarButtonItem?.isEnabled = true
            },
            value: { [weak self] (index: Int, result: TestResult) in
                self?.testResults.modify({ current in
                    if let test = current?[index].test
                    {
                        current?[index] = (test: test, result: result)
                    }
                })
            }
        ).start()
    }
}

extension TestViewController: UITableViewDataSource
{
    fileprivate func testTitleText(at index: Int) -> String
    {
        if let results = testResults.value
        {
            return results[index].test.title
        }
        else
        {
            return testCases.value[index].title
        }
    }

    fileprivate func testResultText(at index: Int) -> String
    {
        if let results = testResults.value, let result = results[index].result
        {
            switch result
            {
            case .success: return "Passed"
            case .failure: return "Failed"
            }
        }
        else
        {
            return "Waiting"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return testCases.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .value1, reuseIdentifier: identifier)

        cell.textLabel?.text = testTitleText(at: indexPath.row)
        cell.detailTextLabel?.text = testResultText(at: indexPath.row)

        return cell
    }
}

extension TestViewController: RLYPeripheralObserver
{
    func peripheral(_ peripheral: RLYPeripheral, didWrite command: RLYCommand)
    {
        print("Wrote “\(command)” to peripheral")
    }

    func peripheral(_ peripheral: RLYPeripheral, failedToWrite command: RLYCommand, withError error: Error)
    {
        print("Failed to write “\(command)” to peripheral: \(error)")
    }

    func peripheral(_ peripheral: RLYPeripheral, readFlashLogData data: Data)
    {
        print("Read flash log data \(data)")
    }
}
