import ReactiveSwift
import UIKit
import enum Result.NoError

final class ReviewsNegativeViewController: UIViewController
{
    // MARK: - View Loading
    fileprivate let feedback = ReviewsFeedbackView.newAutoLayout()

    override func loadView()
    {
        let view = ReviewsInsetView()
        self.view = view

        feedback.model = ReviewsFeedbackView.Model(
            emoji: tr(.reviewsNegativeEmoji),
            titleText: tr(.reviewsNegativeTitle),
            bodyText: tr(.reviewsNegativeBody),
            actionTitle: tr(.reviewsNegativeAction),
            dismissTitle: tr(.reviewsNegativeDismiss)
        )

        view.contentView.addSubview(feedback)
        feedback.autoFloatInSuperview()
    }

    // MARK: - Button Producers
    var actionProducer: SignalProducer<(), NoError> { return feedback.actionProducer }
    var dismissProducer: SignalProducer<(), NoError> { return feedback.dismissProducer }
}
