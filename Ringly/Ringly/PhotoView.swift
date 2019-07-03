import AVFoundation
import Photos
import ReactiveCocoa

class PhotoView : UIView
{
    fileprivate let titleView = PhotoTitleView.newAutoLayout()

    // image captures
    var imageView : UIImageView = UIImageView.newAutoLayout()
    var originalImage : UIImage?
    
    // share button
    let shareButton = ButtonControl.newAutoLayout()
    
    // filter view
    let filterView : UIView = UIView.newAutoLayout()
    var frameWidth : CGFloat?
    let gemDecal = UIImageView.init(image: UIImage(asset: .ringlyGem))
    let wordDecal = UIImageView.init(image: UIImage(asset: .ringlyWord))
    let iconDecal = UIImageView.init(image: UIImage(asset: .ringlyIcon))

    // filter buttons
    let ringlyGem : UIButton = UIButton.newAutoLayout()
    var gemOn : Bool = false
    
    let ringlyIcon : UIButton = UIButton.newAutoLayout()
    var iconOn : Bool = false

    let ringlyWord : UIButton = UIButton.newAutoLayout()
    var wordOn : Bool = false

    // view that is currently being dragged
    var currentView : UIView?

    
    // initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    // setup of view
    private func setup()
    {
        addSubview(titleView)
        titleView.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        titleView.autoSet(dimension: .height, to: 100)
        
        // share label
        shareButton.title = "SHARE"
        shareButton.font = .gothamBook(14)
        self.addSubview(shareButton)
        shareButton.autoSetDimensions(to: CGSize(width: 200, height: 50))


        // setup image
        self.addSubview(imageView)

        imageView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)

        filterView.backgroundColor = UIColor.clear

        self.addSubview(filterView)
        
        // layout of photo view
        imageView.autoMatch(dimension: .height, to: .width, of: imageView)
        imageView.autoPinEdgeToSuperview(edge: .leading)
        imageView.autoPinEdgeToSuperview(edge: .trailing)
        imageView.autoPin(edge: .top, to: .bottom, of: titleView)
        
        filterView.autoMatch(dimension: .width, to: .width, of: imageView)
        filterView.autoPinEdgeToSuperview(edge: .trailing)
        filterView.autoPin(edge: .top, to: .top, of: imageView)
        filterView.autoPin(edge: .bottom, to: .bottom, of: imageView)
        
        self.initFilterButtons()
        
        shareButton.autoConstrain(attribute: .top, to: .bottom, of: self, multiplier: 0.88)
        shareButton.autoAlignAxis(toSuperviewAxis: .vertical)
    }
    
    
    func updateImage(_ image: UIImage) {
        imageView.image = image
    }
    
    func initFilterButtons()
    {
        // setup filter buttons
        ringlyIcon.showsTouchWhenHighlighted = true
        ringlyIcon.setImage(UIImage(asset: .ringlyIcon), for: .normal)
        self.addSubview(ringlyIcon)
        ringlyIcon.contentMode = .scaleAspectFit
        ringlyIcon.autoConstrain(attribute: .width, to: .width, of: filterView, multiplier: 0.08)
        ringlyIcon.autoConstrain(attribute: .height, to: .width, of: self.ringlyIcon, multiplier: 1.125)
        ringlyIcon.autoPinEdgeToSuperview(edge: .left, inset: 40)
        ringlyIcon.autoConstrain(attribute: .top, to: .bottom, of: self, multiplier: 0.76)
        ringlyIcon.alpha = 0.5
        ringlyIcon.addTarget(self, action: #selector(self.iconFilter), for: .touchUpInside)
        iconDecal.alpha = 0.0
        iconDecal.clipsToBounds = true
        filterView.addSubview(iconDecal)
        
        ringlyWord.showsTouchWhenHighlighted = true
        ringlyWord.setImage(UIImage(asset: .ringlyWord), for: .normal)
        self.addSubview(ringlyWord)
        ringlyWord.contentMode = .scaleAspectFit
        ringlyWord.autoConstrain(attribute: .height, to: .width, of: filterView, multiplier: 0.11)
        ringlyWord.autoConstrain(attribute: .width, to: .height, of: self.ringlyWord, multiplier: 2.278)
        ringlyWord.autoAlignAxis(toSuperviewAxis: .vertical)
        ringlyWord.autoAlign(axis: .horizontal, toSameAxisOf: ringlyIcon)
        ringlyWord.alpha = 0.5
        ringlyWord.addTarget(self, action: #selector(self.wordFilter), for: .touchUpInside)
        wordDecal.alpha = 0.0
        wordDecal.clipsToBounds = true
        filterView.addSubview(wordDecal)

        ringlyGem.showsTouchWhenHighlighted = true
        ringlyGem.setImage(UIImage(asset: .ringlyGem), for: .normal)
        self.addSubview(ringlyGem)
        ringlyGem.contentMode = .scaleAspectFit
        ringlyGem.autoConstrain(attribute: .width, to: .width, of: filterView, multiplier: 0.10)
        ringlyGem.autoConstrain(attribute: .height, to: .width, of: self.ringlyGem, multiplier: 1.125)
        ringlyGem.autoPinEdgeToSuperview(edge: .right, inset: 40)
        ringlyGem.autoAlign(axis: .horizontal, toSameAxisOf: ringlyIcon)
        ringlyGem.alpha = 0.5
        ringlyGem.addTarget(self, action: #selector(self.gemFilter), for: .touchUpInside)
        gemDecal.alpha = 0.0
        gemDecal.clipsToBounds = true
        filterView.addSubview(gemDecal)
        
        // add pan gesture for moving around decals
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        filterView.addGestureRecognizer(panGesture)
        
        // add pinch gesture for changing decal size
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(_:)))
        filterView.addGestureRecognizer(pinchGesture)
    }
    
    func gemFilter()
    {
        gemOn = !gemOn
        gemDecal.center = CGPoint(x: filterView.frame.width - 60, y: 60)
        if gemOn {
            ringlyGem.alpha = 1.0
            gemDecal.alpha = 1.0
        }
        else {
            ringlyGem.alpha = 0.5
            gemDecal.alpha = 0.0
        }
    }
    
    func wordFilter()
    {
        wordOn = !wordOn
        wordDecal.center = CGPoint(x: filterView.frame.width/2.0, y: filterView.frame.height - 40)
        if wordOn {
            ringlyWord.alpha = 1.0
            wordDecal.alpha = 1.0
        }
        else {
            ringlyWord.alpha = 0.5
            wordDecal.alpha = 0.0
        }
    }
    
    func iconFilter()
    {
        iconOn = !iconOn
        iconDecal.center = CGPoint(x: 60, y: 60)
        if iconOn {
            ringlyIcon.alpha = 1.0
            iconDecal.alpha = 1.0
        }
        else {
            ringlyIcon.alpha = 0.5
            iconDecal.alpha = 0.0
        }
    }
    
    func handlePanGesture(_ panRecognizer: UIPanGestureRecognizer)
    {
        switch panRecognizer.state {
        case .began:
            let point = panRecognizer.location(in: filterView)
            currentView = filterView.subviews.first(where: { $0.point(inside: $0.convert(point, from: filterView), with: nil) } )
        case .changed:
            let point = panRecognizer.translation(in: self.filterView)
            if let currentView = self.currentView {
                let newFrame = CGRect(x: filterView.frame.origin.x + currentView.frame.origin.x + point.x,
                                     y: filterView.frame.origin.y + currentView.frame.origin.y + point.y,
                                     width: currentView.frame.width,
                                     height: currentView.frame.height)
                if filterView.frame.contains(newFrame) {
                    currentView.center = CGPoint(x: currentView.center.x + point.x,
                                                 y: currentView.center.y + point.y)
                    panRecognizer.setTranslation(.zero, in: self.filterView)
                }
            }
        case .ended:
            currentView = nil
        default:
            break
        }
    }
    
    func handlePinchGesture(_ pinch: UIPinchGestureRecognizer)
    {
        switch pinch.state {
        case .began:
            let point = pinch.location(in: filterView)
            currentView = filterView.subviews.first(where: { $0.point(inside: $0.convert(point, from: filterView), with: nil) } )
        case .changed:
            if let currentView = self.currentView {
                let oldFrame = UIView(frame: currentView.frame)
                oldFrame.transform = CGAffineTransform(scaleX: pinch.scale, y: pinch.scale)
                if filterView.frame.contains(oldFrame.frame) {
                    currentView.transform = CGAffineTransform(scaleX: pinch.scale, y: pinch.scale)
                }
            }
        case .ended:
            currentView = nil
            pinch.scale = 1
        default:
            break
        }
    }
}

extension PhotoView
{
    var backButton: UIButton { return titleView.backButton }
    var exitButton: UIButton { return titleView.exitButton }
}
