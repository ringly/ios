import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class SelectBirthDateViewController: UIViewController
{
    // MARK: - Subviews
    fileprivate let picker = SelectBirthDatePickerView.newAutoLayout()
    fileprivate let button = ButtonControl.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let label = UILabel.newAutoLayout()
        label.attributedText = UIFont.gothamBook(18).track(250, tr(.activityBirthDatePrompt))
            .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))

        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        view.addSubview(label)

        let height = DeviceScreenHeight.current
        label.autoPinEdgeToSuperview(edge: .top, inset: height.select(four: 10, five: 20, preferred: 40))
        label.autoAlignAxis(toSuperviewAxis: .vertical)
        label.autoSet(dimension: .width, to: 200)

        let pickerContainer = UIView.newAutoLayout()
        view.addSubview(pickerContainer)

        pickerContainer.autoPin(edge: .top, to: .bottom, of: label, offset: 10)
        pickerContainer.autoPinEdgeToSuperview(edge: .left)
        pickerContainer.autoPinEdgeToSuperview(edge: .right)

        view.addSubview(picker)
        picker.autoSet(dimension: .width, to: 315)
        picker.autoSet(dimension: .height, to: 300, relation: .lessThanOrEqual)
        picker.autoFloatInSuperview()

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            picker.autoSet(dimension: .height, to: 300)
        })

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultLow, forConstraints: {
            picker.autoPinEdgeToSuperview(edge: .top)
            picker.autoPinEdgeToSuperview(edge: .bottom)
        })

        button.title = trUpper(.finished)
        view.addSubview(button)

        button.autoSetDimensions(to: CGSize(width: 156, height: 50))
        button.autoPinEdgeToSuperview(edge: .bottom, inset: height.select(four: 10, five: 20, preferred: 60))
        button.autoAlignAxis(toSuperviewAxis: .vertical)
        button.autoPin(edge: .top, to: .bottom, of: pickerContainer, offset: 10)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // determine the current calendar and year
        picker.configuration <~ Calendar.currentCalendarProducer
            .combineLatest(with: UIApplication.shared.significantDateProducer)
            .map({ calendar, date in
                // disallow registration by < 14 year olds, to avoid under 13 year olds registering
                (calendar, calendar.component(.year, from: date) - SelectBirthDateViewController.minimumAge)
            })
            .skipRepeats(==)

            // update the picker when configuration changes
            .map({ calendar, endYear in
                (calendar: calendar, startYear: 1900, endYear: endYear)
            })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        DispatchQueue.main.async(execute: { [weak self] in
            self?.picker.selectDefaultDate(
                year: self?.initialDateComponents?.year ?? 1986,
                month: self?.initialDateComponents?.month ?? 1,
                day: self?.initialDateComponents?.day ?? 1
            )
        })
    }

    var initialDateComponents: DateComponents?

    // MARK: - Producers
    var selectedDateComponentsProducer: SignalProducer<DateComponents, NoError>
    {
        return picker.selectedDateComponentsProducer
            .sample(on: SignalProducer(button.reactive.controlEvents(.touchUpInside)).void)
            .skipNil()
    }

    fileprivate static let minimumAge = 14
}

final class SelectBirthDatePickerView: UIView
{
    // MARK: - Configuration

    /// The configuration type for a birth date picker view.
    typealias Configuration = (calendar: Calendar, startYear: Int, endYear: Int)

    /// The current configuration of this picker view.
    let configuration = MutableProperty(Configuration?.none)

    // MARK: - Selection

    /// A backing property for the year component of `selectedDate`.
    fileprivate let selectedYear = MutableProperty(Int?.none)

    /// A backing property for the month component of `selectedDate`.
    fileprivate let selectedMonth = MutableProperty(Int?.none)

    /// A backing property for the day component of `selectedDate`.
    fileprivate let selectedDay = MutableProperty(Int?.none)

    /// Selects a date.
    ///
    /// - Parameters:
    ///   - year: The year component.
    ///   - month: The month component.
    ///   - day: The day component.
    func selectDefaultDate(year: Int, month: Int, day: Int)
    {
        // helper functions for individual components
        func select(table: UITableView, value: Int, rangeProperty: MutableProperty<Range<Int>?>)
        {
            if let range = rangeProperty.value, value < range.upperBound
            {
                let path = IndexPath(row: value - range.lowerBound, section: 0)
                table.scrollToRow(at: path, at: .middle, animated: false)
            }
        }

        // select individual components in order, since the ranges may not have been created for the smaller components
        // if we have not selected a value for the larger components.
        select(table: yearTable, value: year, rangeProperty: yearRange)
        select(table: monthTable, value: month, rangeProperty: monthRange)
        select(table: dayTable, value: day, rangeProperty: dayRange)
    }

    /// The currently selected date.
    var selectedDateComponentsProducer: SignalProducer<DateComponents?, NoError>
    {
        let calendarProducer = configuration.producer.mapOptional({ $0.calendar })

        let parametersProducer = SignalProducer.combineLatest(
            calendarProducer,
            selectedYear.producer.skipRepeats(==),
            selectedMonth.producer.skipRepeats(==),
            selectedDay.producer.skipRepeats(==)
        ).map(unwrap).skipRepeatsOptional(==)

        return parametersProducer.mapOptional({ calendar, year, month, day in
            var components = DateComponents()
            components.calendar = calendar
            components.year = year
            components.month = month
            components.day = day
            return components
        })
    }

    // MARK: - Picker Views

    /// The table view used for picking months.
    fileprivate let monthTable = UITableView(frame: .zero, style: .plain)

    /// The table view used for picking days.
    fileprivate let dayTable = UITableView(frame: .zero, style: .plain)

    /// The table view used for picking years.
    fileprivate let yearTable = UITableView(frame: .zero, style: .plain)

    // MARK: - Component Ranges

    /// The range of years, displayed in `yearTable`.
    fileprivate let yearRange = MutableProperty(Range<Int>?.none)

    /// The range of months in the current year, displayed in `monthTable`.
    fileprivate let monthRange = MutableProperty(Range<Int>?.none)

    /// The range of days in the current month, displayed in `dayTable`.
    fileprivate let dayRange = MutableProperty(Range<Int>?.none)

    // MARK: - Separators

    /// The separator at the top of the selected items.
    fileprivate let topSeparator = UIView()

    /// The separator at the bottom of the selected items.
    fileprivate let bottomSeparator = UIView()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // use a mask view to provide gradient fadeout
        mask = BirthDatePickerMaskView()

        // add subviews
        [monthTable, dayTable, yearTable].forEach({ table in
            table.registerCellType(BirthDatePickerCell.self)

            table.backgroundColor = .clear
            table.decelerationRate = UIScrollViewDecelerationRateFast
            table.rowHeight = SelectBirthDatePickerView.rowHeight
            table.separatorStyle = .none
            table.showsVerticalScrollIndicator = false

            table.dataSource = self
            table.delegate = self
            addSubview(table)
        })

        [topSeparator, bottomSeparator].forEach({ separator in
            separator.backgroundColor = .white
            addSubview(separator)
        })

        // update ranges to current configuration and selection
        let calendarProducer = configuration.producer.mapOptional({ $0.calendar })

        yearRange <~ configuration.producer.mapOptionalFlat { calendarConfiguration in
            if calendarConfiguration.endYear + 1 > calendarConfiguration.startYear {
                return calendarConfiguration.startYear..<(calendarConfiguration.endYear + 1)
            } else {
                let maxBirthYear = 2017 - SelectBirthDateViewController.minimumAge
                return calendarConfiguration.startYear..<maxBirthYear
            }
        }

        monthRange <~ calendarProducer.combineLatest(with: selectedYear.producer)
            .map(unwrap)
            .mapOptionalFlat({ calendar, year in
                var components = DateComponents()
                components.year = year

                return calendar.date(from: components).flatMap({ date in
                    calendar.range(of: .month, in: .year, for: date)
                })
            })

        dayRange <~ SignalProducer.combineLatest(calendarProducer, selectedYear.producer, selectedMonth.producer)
            .map(unwrap)
            .mapOptionalFlat({ calendar, year, month in
                var components = DateComponents()
                components.year = year
                components.month = month

                return calendar.date(from: components).flatMap({ date in
                    calendar.range(of: .day, in: .month, for: date)
                })
            })

        // update table views when ranges change
        let pickers = [
            (yearRange, yearTable, selectedYear),
            (monthRange, monthTable, selectedMonth),
            (dayRange, dayTable, selectedDay)
        ]

        pickers.forEach({ rangeProperty, table, selectedProperty in
            rangeProperty.producer.skipRepeats(==).combinePrevious(nil).skip(first: 1).startWithValues({ previous, current in
                // update the number of rows in the table view to match the new range
                if let previousRange = previous, let currentRange = current, previousRange.lowerBound == currentRange.lowerBound
                {
                    if currentRange.count > previousRange.count
                    {
                        table.insertRows(at: (previousRange.count..<currentRange.count).map({ row in
                            IndexPath(row: row, section: 0)
                        }), with: .fade)
                    }
                    else if previousRange.count > currentRange.count
                    {
                        table.deleteRows(at: (currentRange.count..<previousRange.count).map({ row in
                            IndexPath(row: row, section: 0)
                        }), with: .fade)
                    }
                }
                else
                {
                    table.reloadData()
                }

                // do not allow selected properties to have invalid values
                selectedProperty.pureModify({ optional in
                    unwrap(optional, current).map({ value, range in
                        value >= range.upperBound ? range.upperBound - 1 : value
                    })
                })
            })
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

    // MARK: - Layout
    fileprivate static let rowHeight: CGFloat = 45
    fileprivate static let separatorHeight: CGFloat = 1

    override func layoutSubviews()
    {
        super.layoutSubviews()

        mask?.frame = bounds

        // table layout
        let size = bounds.size
        let sidePadding: CGFloat = 14
        let monthWidth: CGFloat = 170
        let dayWidth: CGFloat = 60
        let yearWidth = size.width - monthWidth - dayWidth - sidePadding * 2

        monthTable.frame = CGRect(
            x: sidePadding,
            y: 0,
            width: monthWidth,
            height: size.height
        )

        dayTable.frame = CGRect(
            x: sidePadding + monthWidth,
            y: 0,
            width: dayWidth,
            height: size.height
        )

        yearTable.frame = CGRect(
            x: sidePadding + monthWidth + dayWidth,
            y: 0,
            width: yearWidth + sidePadding,
            height: size.height
        )

        // table insets
        [monthTable, dayTable, yearTable].forEach({ table in
            table.contentInset = UIEdgeInsets(
                horizontal: 0,
                vertical: (size.height - SelectBirthDatePickerView.rowHeight) / 2
            )
        })

        // separators layout
        topSeparator.frame = CGRect(
            x: 0,
            y: size.height / 2 - SelectBirthDatePickerView.rowHeight / 2 - SelectBirthDatePickerView.separatorHeight,
            width: size.width,
            height: SelectBirthDatePickerView.separatorHeight
        )

        bottomSeparator.frame = CGRect(
            x: 0,
            y: size.height / 2 + SelectBirthDatePickerView.rowHeight / 2,
            width: size.width,
            height: SelectBirthDatePickerView.separatorHeight
        )
    }
}

extension SelectBirthDatePickerView
{
    // MARK: - Table View Selection
    
    fileprivate func select<Value>(table: UITableView,
                                   year: () -> Value,
                                   month: () -> Value,
                                   day: () -> Value)
        -> Value
    {
        switch table
        {
        case yearTable:
            return year()
        case monthTable:
            return month()
        case dayTable:
            return day()
        default:
            fatalError("Invalid table view \(table)")
        }
    }
}

extension SelectBirthDatePickerView: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return select(
            table: tableView,
            year: { yearRange },
            month: { monthRange },
            day: { dayRange }
        ).value?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueCellOfType(BirthDatePickerCell.self, forIndexPath: indexPath)

        func attributes(_ string: String) -> NSAttributedString
        {
            return string.attributes(color: .white, font: .gothamBook(18), tracking: 250)
        }

        cell.label.attributedText = configuration.value.map({ calendar, startYear, endYear in
            attributes(select(
                table: tableView,
                year: { String(startYear + indexPath.row) },
                month: { calendar.standaloneMonthSymbols[indexPath.row].uppercased() },
                day: { String(1 + indexPath.row) }
            )).attributedString
        })

        return cell
    }
}

extension SelectBirthDatePickerView: UITableViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        guard let tableView = scrollView as? UITableView else { return }

        let offset = tableView.contentOffset.y + tableView.contentInset.top
        let index = Int(round(offset / SelectBirthDatePickerView.rowHeight))
        let constrainedIndex = min(max(0, index), max(tableView.numberOfRows(inSection: 0) - 1, 0))

        let (indexOffset, property) = select(
            table: tableView,
            year: { (configuration.value?.startYear ?? 0, selectedYear) },
            month: { (1, selectedMonth) },
            day: { (1, selectedDay) }
        )

        property.value = constrainedIndex + indexOffset
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        let y = targetContentOffset.pointee.y
        let rowHeight = SelectBirthDatePickerView.rowHeight
        let inset = scrollView.contentInset.top

        targetContentOffset.pointee.y = rowHeight * round((y + inset) / rowHeight) - inset
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }
}

// MARK: - Views

/// The cell used to display a line in a birth date picker.
private final class BirthDatePickerCell: UITableViewCell
{
    let label = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)

        label.autoPinEdgeToSuperview(edge: .left)
        label.autoPinEdgeToSuperview(edge: .right)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
}

/// The view used to mask the alpha of a birth date picker.
private final class BirthDatePickerMaskView: UIView
{
    // MARK: - Initialization
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - Drawing
    fileprivate override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let gradient = CGGradient.create([
            (0, UIColor(white: 0, alpha: 0)),
            (1, UIColor(white: 0, alpha: 0.5))
        ]) else { return }

        let size = bounds.size

        let topGradientEnd = size.height / 2 - SelectBirthDatePickerView.rowHeight / 2 - SelectBirthDatePickerView.separatorHeight
        let bottomGradientEnd = size.height / 2 + SelectBirthDatePickerView.rowHeight / 2 + SelectBirthDatePickerView.separatorHeight

        context.drawLinearGradient(gradient,
            start: .zero,
            end: CGPoint(x: 0, y: topGradientEnd),
            options: []
        )

        context.drawLinearGradient(gradient,
            start: CGPoint(x: 0, y: size.height),
            end: CGPoint(x: 0, y: bottomGradientEnd),
            options: []
        )

        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: topGradientEnd, width: size.width, height: bottomGradientEnd - topGradientEnd))
    }
}
