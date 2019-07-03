import UIKit

final class AlertContentView: UIView
{
    // MARK: - Views
    var contentView: UIView?
    {
        didSet
        {
            oldValue?.removeFromSuperview()

            if let view = contentView
            {
                contentViewContainer.addSubview(view)
                view.autoPinEdgesToSuperviewEdges()
            }
        }
    }

    var controlsView: UIView?
    {
        didSet
        {
            oldValue?.removeFromSuperview()

            if let view = controlsView
            {
                controlsViewContainer.addSubview(view)
                view.autoPinEdgesToSuperviewEdges()
            }
        }
    }

    // MARK: - Subviews
    fileprivate let contentViewContainer = UIView.newAutoLayout()
    fileprivate let controlsViewContainer = UIView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(contentViewContainer)
        addSubview(controlsViewContainer)

        contentViewContainer.autoPinEdgeToSuperview(edge: .top)
        contentViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 40)
        contentViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 40)

        controlsViewContainer.autoPin(edge: .top, to: .bottom, of: contentViewContainer)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 40)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 40)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .bottom, inset: 40)
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
}
