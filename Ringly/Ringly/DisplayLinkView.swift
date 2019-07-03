import UIKit

class DisplayLinkView: UIView
{
    deinit
    {
        displayLink?.link.invalidate()
    }

    // MARK: - Animation
    fileprivate var displayLink: (link: CADisplayLink, target: NonRetainedTarget)?
    
    override func didMoveToWindow()
    {
        super.didMoveToWindow()
        
        if window != nil && displayLink == nil
        {
            let target = NonRetainedTarget()
            target.callback = { [weak self] in self?.displayLinkCallback($0) }

            let displayLink = CADisplayLink(target: target, selector: #selector(NonRetainedTarget.displayLinkCallback(_:)))
            displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
            self.displayLink = (link: displayLink, target: target)
        }
        else if window == nil && displayLink != nil
        {
            displayLink?.link.invalidate()
            displayLink = nil
        }
    }
    
    func disableDisplayLink() {
        self.displayLink?.link.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    @nonobjc func displayLinkCallback(_ displayLink: CADisplayLink) {}
}

private class NonRetainedTarget: NSObject
{
    var callback: (CADisplayLink) -> () = { _ in }

    @objc func displayLinkCallback(_ displayLink: CADisplayLink)
    {
        callback(displayLink)
    }
}
