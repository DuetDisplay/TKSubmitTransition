import Foundation
import UIKit

@IBDesignable
open class TKTransitionSubmitButton : UIButton, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    lazy var spiner: SpinerLayer! = {
        let s = SpinerLayer(frame: self.frame)
        self.layer.addSublayer(s)
        return s
    }()
    
    @IBInspectable open var spinnerColor: UIColor = UIColor.white {
        didSet {
            spiner.spinnerColor = spinnerColor
        }
    }
    
    open var didEndFinishAnimation : (()->())? = nil

    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
	let shrinkCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval  = 0.1
	@IBInspectable open var normalCornerRadius: NSNumber = 0.0 {
		didSet {
			self.layer.cornerRadius = CGFloat(normalCornerRadius.doubleValue)
		}
    }

	var isInOriginalState: Bool = true
	
    var cachedTitle: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }
	
    func setup() {
        self.clipsToBounds = true
        spiner.spinnerColor = spinnerColor
    }

    open func startLoadingAnimation() {
		isInOriginalState = false
		self.cachedTitle = title(for: UIControl.State())
		self.setTitle("", for: UIControl.State())
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.layer.cornerRadius = self.frame.height / 2
            }, completion: { (done) -> Void in
                self.shrink()
                Timer.schedule(delay: self.shrinkDuration - 0.25) { timer in
                    self.spiner.animation()
                }
        }) 
        
    }

    open func startFinishAnimation(_ delay: TimeInterval,_ animation: CAMediaTimingFunction? = nil, completion:(()->())?) {
		isInOriginalState = false
        Timer.schedule(delay: delay) { timer in
            self.didEndFinishAnimation = completion
            self.expand(animation)
            self.spiner.stopAnimation()
        }
    }

    open func animate(_ duration: TimeInterval,_ animation: CAMediaTimingFunction? = nil, completion:(()->())?) {
        startLoadingAnimation()
        startFinishAnimation(duration, animation, completion: completion)
    }

    open func setOriginalState() {
        self.returnToOriginalState()
        self.spiner.stopAnimation()
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let a = anim as! CABasicAnimation
        if a.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            Timer.schedule(delay: 1) { timer in
                self.returnToOriginalState()
            }
        }
    }
    
    open func returnToOriginalState() {
		if !isInOriginalState {
			self.layer.removeAllAnimations()
			self.setTitle(self.cachedTitle, for: UIControl.State())
			self.spiner.stopAnimation()
			self.layer.cornerRadius = CGFloat(self.normalCornerRadius.doubleValue)
			isInOriginalState = true
		}
    }
    
    func shrink() {
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
		shrinkAnim.fillMode = CAMediaTimingFillMode.forwards
        shrinkAnim.isRemovedOnCompletion = false
        layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)
    }
    
    func expand(_ animation: CAMediaTimingFunction? = nil) {
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        expandAnim.fromValue = 1.0
        expandAnim.toValue = 26.0
        expandAnim.timingFunction = animation ?? expandCurve
        expandAnim.duration = 0.3
        expandAnim.delegate = self
		expandAnim.fillMode = CAMediaTimingFillMode.forwards
        expandAnim.isRemovedOnCompletion = false
        layer.add(expandAnim, forKey: expandAnim.keyPath)
    }
    
}
