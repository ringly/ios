import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class TabBarView<Item: TabBarViewItem>: UIView where Item: Equatable
{
    // MARK: - Items

    /// The items displayed by the tab bar view.
    let items = MutableProperty([Item]())

    /// The currently selected item.
    let selectedItem = MutableProperty(Item?.none)

    // MARK: - Tapped Selected Item

    /// A backing pipe for `tappedSelectedItemSignal`.
    fileprivate let tappedSelectedItemPipe = Signal<Item, NoError>.pipe()

    /// A signal that will send a value when the user taps an already-selected item.
    var tappedSelectedItemSignal: Signal<Item, NoError> { return tappedSelectedItemPipe.0 }

    // MARK: - Subviews

    /// The current controls displayed by the tab bar.
    fileprivate let controls = MutableProperty([TabBarViewItemControl<Item>]())

    /// The stack view used to display subviews.
    fileprivate let stack = UIStackView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add the stack view
        stack.axis = .horizontal
        stack.alignment = .fill

        addSubview(stack)
        stack.autoPinEdgesToSuperviewEdges()

        // bind the current controls to the currently selected item
        controls <~ items.producer.map({ [weak self] items in
            items.map({ [weak self] item -> TabBarViewItemControl<Item> in
                let control = TabBarViewItemControl<Item>.newAutoLayout()
                control.item.value = item

                if let strong = self
                {
                    control.controlSelected <~ strong.selectedItem.producer
                        // if the selected item is equal to the item that created this control, set the control to
                        // selected. this means that duplicate items should not be used, as they would behave strangely.
                        .map({ $0 == item })

                        // tear down binding once items are changed
                        .take(until: strong.items.producer.skip(first: 1).void)
                }

                return control
            })
        })

        controls.producer.combinePrevious([]).skip(first: 1).startWithValues({ [weak stack] previous, current in
            guard let strong = stack else { return }

            // remove old controls and add new controls
            previous.forEach({
                strong.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })

            current.forEach(strong.addArrangedSubview)

            // ensure all tabs are the same size
            zip(current.dropLast(), current.dropFirst()).forEach({ a, b in
                a.autoMatch(dimension: .width, to: .width, of: b)
            })
        })

        // a producer that sends a value when a control is tapped
        let tappedProducer = controls.producer.flatMap(.latest, transform: { controls in
            SignalProducer.merge(controls.map({ control in
                control.item.producer.sample(on: SignalProducer(control.reactive.controlEvents(.touchUpInside)).void).skipNil()
            }))
        })

        // Bind the selected item to the selected control - this still allows manual updates, and updates that occur
        // when the items are changed. If the selected item is tapped again, send it to the `tappedSelectedItemPipe`.
        tappedProducer.startWithValues({ [weak self] item in
            guard let strong = self else { return }

            if strong.selectedItem.value != item
            {
                strong.selectedItem.value = item
            }
            else
            {
                strong.tappedSelectedItemPipe.1.send(value: item)
            }
        })
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

// MARK: - Item Protocol
protocol TabBarViewItem
{
    var title: String { get }
    var image: UIImage? { get }
}

// MARK: - Item Controls
private final class TabBarViewItemControl<Item: TabBarViewItem>: UIControl where Item: Equatable
{
    // MARK: - Item

    /// The item displayed by this control.
    let item = MutableProperty(Item?.none)

    /// Whether or not this control is selected
    let controlSelected = MutableProperty(false)

    // MARK: - Appearance

    /// The appearance of this control.
    let appearance = MutableProperty(TabBarViewAppearance.defaultAppearance)

    // MARK: - Initialization
    func setup()
    {
        isAccessibilityElement = true

        let image = UIImageView.newAutoLayout()
        image.isAccessibilityElement = false
        image.contentMode = .center
        addSubview(image)

        let label = UILabel.newAutoLayout()
        label.isAccessibilityElement = false
        label.textAlignment = .center
        addSubview(label)

        [image, label].forEach({ $0.autoFloatInSuperview(alignedTo: .vertical) })

        image.autoConstrain(attribute: 
            .horizontal,
            to: .top,
            of: self,
            offset: 25
        )

        label.autoPinEdgeToSuperview(edge: .bottom, inset: 10)

        item.producer.startWithValues({ [weak self] item in
            self?.accessibilityLabel = item?.title

            label.attributedText = (item?.title.uppercased()).map({ title in
                UIFont.gothamBold(7).track(.controlsTracking, title).attributedString
            })

            image.image = item?.image?.withRenderingMode(.alwaysTemplate)
        })

        appearance.producer.combineLatest(with: controlSelected.producer)
            .startWithValues({ [weak self] appearance, selected in
                let tintColor = selected ? appearance.selectedTintColor : appearance.tintColor
                label.textColor = tintColor
                image.tintColor = tintColor

                self?.accessibilityTraits = selected
                    ? UIAccessibilityTraitSelected & UIAccessibilityTraitButton
                    : UIAccessibilityTraitButton
            })
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

// MARK: - Appearance
struct TabBarViewAppearance
{
    let tintColor: UIColor
    let selectedTintColor: UIColor
}

extension TabBarViewAppearance
{
    static var defaultAppearance: TabBarViewAppearance
    {
        return TabBarViewAppearance(
            tintColor: UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0),
            selectedTintColor: UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
        )
    }
}
