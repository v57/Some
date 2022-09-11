#if os(iOS)

//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import Some

extension ProgressProtocol {
  public func value() -> CGFloat {
    return CGFloat(completed) / CGFloat(total)
  }
  public func value() -> Float {
    return Float(completed) / Float(total)
  }
  public func value() -> Double {
    return Double(completed) / Double(total)
  }
}

open class LoadingView: UIView {
  open var disableAnimations = false {
    didSet {
      if disableAnimations != oldValue && animating {
        if disableAnimations {
          stopAnimating()
        } else {
          startAnimating()
        }
      }
    }
  }
  private var _value: CGFloat = 0.0
  open var value: CGFloat {
    get {
      return _value
    }
    set {
      guard _value != newValue else { return }
      _value = newValue
      animating = false
      valueChanged()
    }
  }
  open var shows: Bool = true {
    didSet {
      if oldValue != self.shows {
        if self.shows {
          show()
        } else {
          hide()
        }
      }
    }
  }
  open var animating: Bool = false {
    didSet {
      if oldValue != self.animating {
        if self.animating {
          shows = true
          if !disableAnimations {
            startAnimating()
          }
        } else {
          if !disableAnimations {
            stopAnimating()
          }
        }
      }
    }
  }
  
  public init(center: CGPoint) {
    super.init(frame: CGRect(center.x,center.y,0,0))
    draw()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open func valueChanged() {}
  open func startAnimating() {}
  open func stopAnimating() {}
  open func draw() {}
  
  open func show() {
    alpha = 1.0
  }
  
  open func hide() {
    if self.superview == nil {
      alpha = 0.0
    } else {
      animate ({ [self] in
        alpha = 0.0
      }) {
        self.animating = false
      }
    }
  }
  open func hideAndRemove() {
    if self.superview == nil {
      alpha = 0.0
    } else {
      animate ({self.alpha = 0.0}) {
        self.animating = false
        self.removeFromSuperview()
      }
    }
  }
  
  open weak var currentProgress: ProgressProtocol?
  open var followInterval: Double = 0.5
  private var followHandler: (()->())?
  open func follow(progress: ProgressProtocol, handler: (()->())?) {
    followHandler = handler
    currentProgress = progress
    if progress.completed == 0 {
      animating = true
    }
    progressTick()
  }
  open func progressTick() {
    guard let progress = currentProgress else {
      stopFollowing()
      return
    }
    CATransaction.begin()
    CATransaction.setAnimationDuration(followInterval)
    self.value = progress.value()
    CATransaction.commit()
    if progress.isCancelled || progress.isCompleted {
      stopFollowing()
    } else {
      wait(followInterval) { [weak self] in
        self?.progressTick()
      }
    }
  }
  
  open func stopFollowing() {
    followHandler?()
    currentProgress = nil
    destroy()
  }
  
  public func mt(shows: Bool) {
    mainThread {
      self.shows = shows
    }
  }
  public func mt(value: CGFloat) {
    mainThread {
      self.value = value
    }
  }
}

open class ProgressLabel: UILabel {
  open weak var currentProgress: Progress?
  open var followInterval: Double = 0.5
  private var followHandler: (()->())?
  open var format: ((Progress)->(String))?
  open func follow(progress: Progress, handler: (()->())?) {
    followHandler = handler
    currentProgress = progress
    progressTick()
  }
  open func progressTick() {
    guard let progress = currentProgress else {
      stopFollowing()
      return
    }
    if let format = format {
      text = format(progress)
    } else {
      text = "\(Int(progress.value() * 100.0))%"
    }
    if progress.isCancelled {
      stopFollowing()
    } else {
      wait(followInterval) { [weak self] in
        self?.progressTick()
      }
    }
  }
  
  open func stopFollowing() {
    followHandler?()
    currentProgress = nil
    destroy()
  }
}



open class LoadingViewDefault: LoadingView {
  override open func valueChanged() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let array = [c1,c2,c3,c4,c5]
    for (i,c) in array.enumerated() {
      let v = value * 8 - 2
      let fi = CGFloat(i)
      let dist = (v - fi).magnitude
      let v2 = 1 - min(dist/2,1.0)
      c.transform = CATransform3DMakeScale(v2, v2, 1);
    }
    CATransaction.commit()
  }
  
  override open func startAnimating() {
    c1.add(c1a, forKey: "Loading Animation")
    c2.add(c2a, forKey: "Loading Animation")
    c3.add(c3a, forKey: "Loading Animation")
    c4.add(c4a, forKey: "Loading Animation")
    c5.add(c5a, forKey: "Loading Animation")
  }
  
  override open func stopAnimating() {
    c1.removeAllAnimations()
    c2.removeAllAnimations()
    c3.removeAllAnimations()
    c4.removeAllAnimations()
    c5.removeAllAnimations()
  }
  
  override open func draw() {
    let arr = [c1,c2,c3,c4,c5]
    for a in arr {
      a.fillColor = color
      a.opacity = 1.0
      a.strokeColor = UIColor.clear.cgColor
      let rad = radius / 2 - 2
      let start: CGFloat = -.pi / 2.0
      let end: CGFloat = .pi * 1.5 + 0.0001
      a.path = UIBezierPath(arcCenter: CGPoint(), radius: rad, startAngle: start, endAngle: end, clockwise: false).cgPath
      a.transform = CATransform3DMakeScale(0.25, 0.25, 1.0)
    }
    c1.position = CGPoint(x: -radius*2, y: radius)
    c2.position = CGPoint(x: -radius, y: radius)
    c3.position = CGPoint(x: 0, y: radius)
    c4.position = CGPoint(x: radius, y: radius)
    c5.position = CGPoint(x: radius*2, y: radius)
    
    let aar = [c1a,c2a,c3a,c4a,c5a]
    for (i,b) in aar.enumerated() {
      let a = CABasicAnimation(keyPath: "transform.scale")
      a.autoreverses = true
      a.fromValue = NSNumber(value: 0.25)
      a.toValue = NSNumber(value: 1.0)
      a.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
      a.duration = 1.0 / 4
      b.isRemovedOnCompletion = false
      b.duration = 0.5 * 7 / 4
      b.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * 0.5 / 4
      b.repeatCount = Float.infinity
      b.animations = [a]
    }
    
    self.layer.addSublayer(c1)
    self.layer.addSublayer(c2)
    self.layer.addSublayer(c3)
    self.layer.addSublayer(c4)
    self.layer.addSublayer(c5)
  }
  
  private let radius: CGFloat = 10
  private let c1 = CAShapeLayer()
  private let c2 = CAShapeLayer()
  private let c3 = CAShapeLayer()
  private let c4 = CAShapeLayer()
  private let c5 = CAShapeLayer()
  private let c1a = CAAnimationGroup()
  private let c2a = CAAnimationGroup()
  private let c3a = CAAnimationGroup()
  private let c4a = CAAnimationGroup()
  private let c5a = CAAnimationGroup()
  
  private let color: CGColor
  
  public init(center: CGPoint, color: UIColor = .highlighted) {
    self.color = color.cgColor
    super.init(center: center)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}


open class LoadingViewImage: LoadingView {
  override open func valueChanged() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shapeLayer.strokeEnd = self.value
    CATransaction.commit()
  }
  override open func startAnimating() {
    shapeLayer.strokeStart = 0.8
    shapeLayer.strokeEnd = 0.0
    shapeLayer.add(loadingAnimation, forKey: "Loading Animation")
  }
  override open func stopAnimating() {
    shapeLayer.removeAllAnimations()
  }
  override open func draw() {
    logo.center = CGPoint()
    self.addSubview(logo)
    
    backgroundLayer.path = UIBezierPath(arcCenter: CGPoint(), radius: radius - 10, startAngle: 0, endAngle: π2 - 0.0001, clockwise: true).cgPath
    backgroundLayer.position = CGPoint(x: 0, y: 0)
    backgroundLayer.fillColor = UIColor.clear.cgColor
    backgroundLayer.strokeColor = bgColor.cgColor
    backgroundLayer.lineWidth = 1.0
    backgroundLayer.strokeStart = 0.0
    backgroundLayer.strokeEnd = 1.0
    
    shapeLayer.path = UIBezierPath(arcCenter: CGPoint(), radius: radius - 10, startAngle: -.pi / 2, endAngle: .pi * 1.5 + 0.0001, clockwise: true).cgPath
    shapeLayer.position = CGPoint(x: 0, y: 0)
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = mainColor.cgColor
    shapeLayer.lineWidth = 2.0
    shapeLayer.strokeStart = 0.0
    shapeLayer.strokeEnd = 0.0
    
    loadingAnimation.duration = 1.0
    loadingAnimation.repeatCount = .infinity
    loadingAnimation.fromValue = NSNumber(value: 0.0 as Float)
    loadingAnimation.toValue = NSNumber(value: .pi*2 as Double)
    loadingAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    
    stopAnimation.fromValue = NSNumber(value: 1.5 as Float)
    stopAnimation.toValue = NSNumber(value: 1 as Float)
    stopAnimation.duration = 0.2
    stopAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
    
    
    self.layer.addSublayer(backgroundLayer)
    self.layer.addSublayer(shapeLayer)
  }
  
  private let logo = UIImageView(image: UIImage(named: "LogoIcon"))
  private let radius: CGFloat = 50
  
  private let shapeLayer = CAShapeLayer()
  private let backgroundLayer = CAShapeLayer()
  
  private let loadingAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
  private let stopAnimation = CABasicAnimation(keyPath: "transform.scale")
  
  private let mainColor: UIColor
  private let bgColor: UIColor
  
  public init(center: CGPoint, color: UIColor = .highlighted, backgroundColor: UIColor = .light) {
    mainColor = color
    bgColor = backgroundColor
    super.init(center: center)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}




#endif
