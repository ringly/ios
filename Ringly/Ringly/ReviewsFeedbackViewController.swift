import ReactiveSwift
import UIKit
import enum Result.NoError

// MARK: - Feedback View Controller
final class ReviewsFeedbackViewController: ServicesViewController
{
    // MARK: View Loading
    override func loadView()
    {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view

        let textController = ReviewsFeedbackTextViewController(services: services)
        textController.actionSignal.observeValues({ [weak self] in self?.action?($0) })

        let navigation = UINavigationController(rootViewController: textController)
        navigation.addAsEdgePinnedChild(of: self, in: view)
    }

    // MARK: Status Bar
    override var prefersStatusBarHidden : Bool { return true }

    // MARK: Actions
    var action: ((String?) -> ())?
}

// MARK: - Text View Controller
private final class ReviewsFeedbackTextViewController: ServicesViewController
{
    // MARK: Text View
    fileprivate let textView = UITextView.newAutoLayout()
    fileprivate let textViewIsEmpty = MutableProperty(true)

    // MARK: View Loading
    fileprivate override func loadView()
    {
        let view = UIView()
        self.view = view

        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(horizontal: 5, vertical: 5)
        textView.delegate = self
        view.addSubview(textView)

        textView.autoPinEdgeToSuperview(edge: .leading)
        textView.autoPinEdgeToSuperview(edge: .trailing)
        textView.autoPinToTopLayoutGuide(of: self, inset: 0)
        textView.autoPinToBottomLayoutGuide(of: self, inset: 0)
    }

    // MARK: View Lifecycle
    fileprivate override func viewDidLoad()
    {
        super.viewDidLoad()

        title = tr(.reviewsFeedbackTitle)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(ReviewsFeedbackTextViewController.cancelAction)
        )

        textViewIsEmpty.producer.startWithValues({ [weak self] empty in
            guard let strong = self else { return }

            strong.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: tr(empty ? .skip : .send),
                style: .done,
                target: strong,
                action: empty
                    ? #selector(ReviewsFeedbackTextViewController.skipAction)
                    : #selector(ReviewsFeedbackTextViewController.sendAction)
            )
        })

        services.keyboard.frame.producer.take(until: reactive.lifetime.ended).startWithValues({ [weak self] frame in
            self?.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.size.height, right: 0)
        })
    }

    fileprivate override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    // MARK: Button Actions
    @objc fileprivate func cancelAction()
    {
        if textView.text.characters.count > 0
        {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            alert.addAction(
                UIAlertAction(title: tr(.reviewsFeedbackDiscard), style: .destructive, handler: { [weak self] _ in
                    self?.textView.resignFirstResponder()
                    self?.actionPipe.1.send(value: nil)
                })
            )

            alert.addAction(UIAlertAction(title: tr(.cancel), style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
        }
        else
        {
            textView.resignFirstResponder()
            actionPipe.1.send(value: nil)
        }
    }

    @objc fileprivate func skipAction()
    {
        actionPipe.1.send(value: nil)
    }

    @objc fileprivate func sendAction()
    {
        actionPipe.1.send(value: textView.text)
    }

    // MARK: Actions
    fileprivate let actionPipe = Signal<String?, NoError>.pipe()
    var actionSignal: Signal<String?, NoError> { return actionPipe.0 }
}

extension ReviewsFeedbackTextViewController: UITextViewDelegate
{
    @objc fileprivate func textViewDidChange(_ textView: UITextView)
    {
        textViewIsEmpty.value = textView.text.characters.count == 0
    }
}
