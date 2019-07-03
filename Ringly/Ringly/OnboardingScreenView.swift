import UIKit

/// The phone screen view displayed in the onboarding fake phone.
final class OnboardingScreenView: UIView
{
    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // required information for drawing
        let size = bounds.size
        
        // draw the initial background gradient
        guard let backgroundGradient = CGGradient.create([
            (0, UIColor(white: 0.33, alpha: 1)),
            (1, UIColor(white: 0.27, alpha: 1))
        ]) else { return }

        context.drawLinearGradient(backgroundGradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        
        // draw the color overlay gradient
        guard let colorGradient = CGGradient.create([
            (0, UIColor(red: 0.9519, green: 0.4838, blue: 0.4821, alpha: 0.9)),
            (1, UIColor(red: 0.7759, green: 0.551, blue: 0.7441, alpha: 0.9))
        ]) else { return }
        
        context.drawLinearGradient(colorGradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        
        // draw the final gloss gradient
        guard let glossGradient = CGGradient.create([
            (0, UIColor(white: 1, alpha: 0.1)),
            (1, UIColor(white: 1, alpha: 0))
        ]) else { return }

        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: size.width, y: 0))
        context.addLine(to: CGPoint(x: 0, y: size.height * 1.25))
        context.closePath()
        context.clip()
        
        context.drawLinearGradient(glossGradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
    }
}
