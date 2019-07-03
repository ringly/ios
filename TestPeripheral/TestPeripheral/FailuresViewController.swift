import ReactiveSwift
import UIKit

final class FailuresViewController: UIViewController
{
    @IBOutlet fileprivate var textView: UITextView?

    let failures = MutableProperty<[(title: String, reason: String)]>([])

    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = "Test Failures"

        // set the content of the text view
        failures.producer.map({ failures -> NSAttributedString in
            let string = NSMutableAttributedString()
            let bold = [NSFontAttributeName: UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)]
            let normal = [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]

            failures.forEach({ title, reason in
                string.append(NSAttributedString(string: title + "\n", attributes: bold))
                string.append(NSAttributedString(string: reason + "\n\n", attributes: normal))
            })

            return string
        }).startWithValues({ [weak self] in self?.textView?.textStorage.setAttributedString($0) })

        // dismiss the view controller when a "done" button is tapped
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(FailuresViewController.dismissAction)
        )
    }

    @objc fileprivate func dismissAction()
    {
        dismiss(animated: true, completion: nil)
    }
}
