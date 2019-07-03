import ReactiveSwift
import UIKit
import enum Result.NoError

final class ReviewsPositiveViewController: UIViewController
{
    // MARK: - View Loading
    fileprivate let feedback = ReviewsFeedbackView.newAutoLayout()

    override func loadView()
    {
        let view = ReviewsInsetView()
        self.view = view

        feedback.model = ReviewsFeedbackView.Model(
            emoji: tr(.reviewsPositiveEmoji),
            titleText: tr(.reviewsPositiveTitle),
            bodyText: tr(.reviewsPositiveBody),
            actionTitle: tr(.reviewsPositiveAction),
            dismissTitle: tr(.reviewsPositiveDismiss)
        )

        view.contentView.addSubview(feedback)
        feedback.autoFloatInSuperview()
    }

    // MARK: - Button Producers
    var actionProducer: SignalProducer<(), NoError> { return feedback.actionProducer }
    var dismissProducer: SignalProducer<(), NoError> { return feedback.dismissProducer }
}
