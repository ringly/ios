import StoreKit
import ReactiveSwift
import RinglyAPI
import UIKit
import func RinglyExtensions.timerUntil

final class ReviewsViewController: ServicesViewController
{
    // MARK: - View Loading
    fileprivate let container = ContainerViewController()

    override func loadView()
    {
        view = UIView()

        container.childTransitioningDelegate = self
        container.addAsEdgePinnedChild(of: self, in: view)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        container.childViewController <~ services.preferences.reviewsState.producer
            .map({ $0?.displayValue })
            .mapOptionalFlat({ [weak self] display in
                self?.viewController(for: display)
            })
    }

    // MARK: - Constants
    static let emojiFontSize: CGFloat = 72
}

extension ReviewsViewController
{
    /// Creates a child view controller for the specified model. Actions taken on the returned view controller will
    /// affect this view controller.
    ///
    /// - Parameter model: The model.
    fileprivate func viewController(for display: ReviewsDisplay) -> UIViewController
    {
        switch display
        {
        case .prompt:
            let prompt = ReviewsPromptViewController()
            services.preferences.reviewsState <~ prompt.feedbackProducer.map({ .display(.feedback($0)) })

            services.preferences.reviewsTextFeedback <~
                prompt.feedbackProducer.filter({ $0 == .positive }).map({ _ in
                    ReviewsTextFeedback(feedback: .positive, text: nil)
                })

            return prompt

        case let .feedback(feedback):
            switch feedback
            {
            case .positive:
                let positive = ReviewsPositiveViewController()

                // when the action button is tapped, present the app store to the user
                positive.actionProducer.startWithValues({
                    UIApplication.shared.openURL(
                        URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=942001990&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!
                    )
                })

                // when either button is tapped, set the state to "displayed" - there is no completion for a positive
                // review
                services.preferences.reviewsState <~
                    SignalProducer.merge(positive.actionProducer, positive.dismissProducer).map({
                        return .displayed(version: Bundle.main.version ?? "unknown")
                    })

                return positive

            case .negative:
                let negative = ReviewsNegativeViewController()

                negative.actionProducer.startWithValues({ [weak self] in
                    guard let strong = self else { return }

                    let feedback = ReviewsFeedbackViewController(services: strong.services)
                    strong.present(feedback, animated: true, completion: nil)

                    feedback.action = { [weak self, weak feedback] text in
                        self?.displayNegativeCompletion()

                        self?.services.preferences.reviewsTextFeedback.value = ReviewsTextFeedback(
                            feedback: .negative,
                            text: text
                        )

                        feedback?.dismiss(animated: true, completion: nil)
                    }
                })

                negative.dismissProducer.startWithValues({ [weak self] in
                    self?.services.preferences.reviewsState.value = ReviewsState.displayedForCurrentVersion
                    self?.services.preferences.reviewsTextFeedback.value = ReviewsTextFeedback(
                        feedback: .negative,
                        text: nil
                    )
                })

                return negative
            }

        case .negativeCompletion:
            return ReviewsNegativeCompletionViewController()
        }
    }

    fileprivate func displayNegativeCompletion()
    {
        let preferences = services.preferences

        preferences.reviewsState.value = .display(.negativeCompletion)

        preferences.reviewsState <~
            timerUntil(date: Date(timeIntervalSinceNow: 5), on: QueueScheduler.main)
                .map({ _ in ReviewsState.displayedForCurrentVersion })
    }
}

extension ReviewsViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        return fromViewController != nil ? CrossDissolveTransitionController(duration: 0.25) : nil
    }
}

extension String
{
    // MARK: - Reviews Attributed String Extensions

    /// An attributed string formatted for reviews title display.
    var reviewsTitleAttributedString: NSAttributedString
    {
        return uppercased().attributes(
            font: .gothamBook(15),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 250
        )
    }

    /// An attributed string formatted for reviews body display.
    var reviewsBodyAttributedString: NSAttributedString
    {
        return uppercased().attributes(
            font: .gothamBook(12),
            paragraphStyle: .with(alignment: .center, lineSpacing: 4),
            tracking: 150
        )
    }
}
