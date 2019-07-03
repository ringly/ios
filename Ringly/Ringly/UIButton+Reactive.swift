import ReactiveSwift
import UIKit

extension Reactive where Base: UIButton
{
    func image(for state: UIControlState) -> BindingTarget<UIImage?>
    {
        return makeBindingTarget(on: UIScheduler(), { button, image in
            button.setImage(image, for: state)
        })
    }
}
