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

public func animation(_ path: String, function: AnimationFunction, from: CGFloat, to: CGFloat, steps: Int = 10) -> CAKeyframeAnimation {
  var values = [CGFloat](repeating: 0, count: steps)
  var time: CGFloat = 0.0
  let timeStep: CGFloat = 1.0 / CGFloat(steps-1)
  
  for i in 0..<steps {
    var value = to - from
    value *= function(time)
    value += from
    values[i] = value
    
    time += timeStep
  }
  
  let animation = CAKeyframeAnimation(keyPath: path)
  animation.calculationMode = CAAnimationCalculationMode.linear
  animation.values = values
  return animation
}

private var currentAnimation: AnimationFunction = Animation.default
private var animationTree = [Animation]()
public typealias AnimationFunction = (_ time: CGFloat) -> CGFloat
public class Animation {
  let function: AnimationFunction
  init(function: @escaping AnimationFunction) {
    self.function = function
  }
  public static func start(_ duration: Double, function: @escaping AnimationFunction = Animation.default) {
    CATransaction.begin()
    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0, 0, 1, 1))
    CATransaction.setAnimationDuration(duration)
    let animation = Animation(function: function)
    animationTree.append(animation)
    currentAnimation = function
  }
  public static func completion(_ block: @escaping ()->()) {
    CATransaction.setCompletionBlock(block)
  }
  public static func end() {
    CATransaction.commit()
    animationTree.removeLast()
    if let last = animationTree.last {
      currentAnimation = last.function
    } else {
      currentAnimation = Animation.default
    }
  }
  public static func `default`(time: CGFloat) -> CGFloat {
    let p = pow(time,2)
    return p / (p + pow(1-time,2))
  }
  public static func linear(time: CGFloat) -> CGFloat {
    return time
  }
  public static func ease(time: CGFloat) -> CGFloat {
    let p = pow(time,2)
    return p / (p + pow(1-time,2))
  }
}

public extension CALayer {
  @discardableResult
  func animate(_ keyPath: String, to value: Any?) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: keyPath)
    animation.fromValue = self.value(forKeyPath: keyPath)
    animation.toValue = value
    animation.timingFunction = .default
    animation.duration = atime
    add(animation, forKey: keyPath)
    setValue(value, forKeyPath: keyPath)
    return animation
  }
  @discardableResult
  func animate(_ keyPath: String, to value: Any?, edit: (CABasicAnimation)->()) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: keyPath)
    animation.fromValue = self.value(forKeyPath: keyPath)
    animation.toValue = value
    animation.timingFunction = .default
    animation.duration = atime
    edit(animation)
    add(animation, forKey: keyPath)
    setValue(value, forKeyPath: keyPath)
    return animation
  }
}

extension UIView {
  private func hasAnimation(_ name: String) -> Bool {
    return layer.animation(forKey: name) != nil
  }
  private var animated: Bool {
    return animationTree.count > 0
  }
  public func move(_ pos: Pos, _ anchor: Anchor) {
    let end = Pos(pos.x + frame.w * (0.5 - anchor.x), pos.y + frame.h * (0.5 - anchor.y))
    if animated {
      if hasAnimation("moveX") || hasAnimation("moveY") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      
      let x = animation("position.x", function: currentAnimation, from: center.x, to: end.x)
      let y = animation("position.y", function: currentAnimation, from: center.y, to: end.y)
      layer.add(x, forKey: "moveX")
      layer.add(y, forKey: "moveY")
    }
    center = end
  }
  public func offset(_ x: CGFloat, _ y: CGFloat) {
    let end = Pos(center.x + x, center.y + y)
    if animated {
      if hasAnimation("moveX") || hasAnimation("moveY") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      let x = animation("position.x", function: currentAnimation, from: center.x, to: end.x)
      let y = animation("position.y", function: currentAnimation, from: center.y, to: end.y)
      layer.add(x, forKey: "moveX")
      layer.add(y, forKey: "moveY")
    }
    center = end
  }
  public func move(x: CGFloat, _ anchor: Anchor) {
    let end = x + frame.w * (0.5 - anchor.x)
    if animated {
      if hasAnimation("moveX") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      let anim = animation("position.x", function: currentAnimation, from: center.x, to: end)
      layer.add(anim, forKey: "moveX")
    }
    center = Pos(end, center.y)
  }
  public func move(y: CGFloat, _ anchor: Anchor) {
    let end = y + frame.h * (0.5 - anchor.y)
    if animated {
      if hasAnimation("moveY") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      let anim = animation("position.y", function: currentAnimation, from: center.y, to: end)
      layer.add(anim, forKey: "moveY")
    }
    center = Pos(center.x, end)
  }
  public func move(_ pos: CGPoint, _ anchor: Anchor, _ path: CGPath) {
    let end = Pos(pos.x + frame.w * (0.5 - anchor.x), pos.y + frame.h * (0.5 - anchor.y))
    
    let animation = CAKeyframeAnimation(keyPath: "position")
    animation.path = path
    animation.duration = atime
    animation.repeatCount = 1
    animation.isRemovedOnCompletion = true
    animation.calculationMode = CAAnimationCalculationMode.paced
    animation.timingFunctions = [CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)]
    layer.add(animation, forKey: "move")
    center = end
  }
  public func offset(x: CGFloat) {
    let end = center.x + x
    if animated {
      if hasAnimation("moveX") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      let x = animation("position.x", function: currentAnimation, from: center.x, to: end)
      layer.add(x, forKey: "moveX")
    }
    center = Pos(end, center.y)
  }
  public func offset(y: CGFloat) {
    let end = center.y + y
    if animated {
      if hasAnimation("moveY") {
        if let layer = layer.presentation() {
          center = layer.position
        }
      }
      let y = animation("position.y", function: currentAnimation, from: center.y, to: end)
      layer.add(y, forKey: "moveY")
    }
    center = Pos(center.x, end)
  }
  public func resize(_ size: Size, _ anchor: Anchor) {
    let pos = frame.anchor(anchor)
    let new = Rect(pos, anchor, size)
    frame = new
  }
  public func resize(width: CGFloat, _ anchor: Anchor) {
    let pos = frame.anchor(anchor)
    let new = Rect(pos, anchor, Size(width,frame.h))
    frame = new
  }
  
  public func resize(height: CGFloat, _ anchor: Anchor) {
    let pos = frame.anchor(anchor)
    let new = Rect(pos, anchor, Size(frame.w,height))
    frame = new
  }
}

func animationsAvailable() -> Bool {
  return !(Device.lowPowerMode && SomeSettings.lowPowerMode.disableAnimations)
}

private var delegates = Set<AnimationDelegate>()
private final class AnimationDelegate: NSObject, CAAnimationDelegate {
  let callback: () -> Void
  init(callback: @escaping () -> Void) {
    self.callback = callback
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    self.callback()
    delegates.remove(self)
  }
  
  @objc func animationDidStop(_ animationId: String?, finished: NSNumber, context: UnsafeMutableRawPointer) {
    self.callback()
    delegates.remove(self)
  }
}

public extension CAAnimation {
  func completion(_ completion: @escaping ()->()) {
    let delegate = AnimationDelegate(callback: completion)
    delegates.insert(delegate)
    self.delegate = delegate
  }
}

/// default animation time
public var atime: Double = 0.25
private var curveUI = UIView.AnimationCurve.easeInOut
private var curveCA = curveUI.ca

extension UIView.AnimationCurve {
  public static var `default`: UIView.AnimationCurve { return curveUI }
  public var ca: CAMediaTimingFunction {
    switch self {
    case .easeIn: return .easeIn
    case .easeOut: return .easeOut
    case .easeInOut: return .easeInOut
    case .linear: return .linear
    @unknown default:
      return .easeInOut
    }
  }
}

extension CAMediaTimingFunction {
  public static var easeIn: CAMediaTimingFunction { .init(name: CAMediaTimingFunctionName.easeIn) }
  public static var easeOut: CAMediaTimingFunction { .init(name: CAMediaTimingFunctionName.easeOut) }
  public static var easeInOut: CAMediaTimingFunction { .init(name: CAMediaTimingFunctionName.easeInEaseOut) }
  public static var linear: CAMediaTimingFunction { .init(name: CAMediaTimingFunctionName.linear) }
  public static var `default`: CAMediaTimingFunction { curveCA }
}


public func animationSettings(time: Double, curve: UIView.AnimationCurve, animations: ()->()) {
  let t = atime
  let c = curveUI
  let cc = curveCA
  atime = time
  curveUI = curve
  curveCA = curve.ca
  animations()
  atime = t
  curveUI = c
  curveCA = cc
}


public func animateKeyboard(_ time: TimeInterval = 0.25, block: @escaping () -> ()) {
  if time == 0 {
    UIView.animate(withDuration: 0.1, animations: block)
  } else {
    UIView.beginAnimations(nil, context: nil)
    UIView.setAnimationDuration(time)
    UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: 7)!)
    UIView.setAnimationBeginsFromCurrentState(true)
    block()
    UIView.commitAnimations()
  }
}

public func animate(time: TimeInterval, curve: UIView.AnimationCurve, animations: () -> Void, completion: (() -> Void)? = nil) {
  guard animationsAvailable() else {
    animations()
    completion?()
    return
  }
  
  UIView.beginAnimations(nil, context: nil)
  
  if let completion = completion {
    let wrapper = AnimationDelegate(callback: completion)
    delegates.insert(wrapper)
    UIView.setAnimationDelegate(wrapper)
    UIView.setAnimationDidStop(#selector(AnimationDelegate.animationDidStop(_:finished:context:)))
  }
  
  UIView.setAnimationDuration(time)
  UIView.setAnimationDelay(0)
  UIView.setAnimationCurve(curve)
  let a = isAnimating
  isAnimating = true
  animations()
  isAnimating = a
  UIView.commitAnimations()
}
public func animate(_ animations: () -> ()) {
  animate(time: atime, curve: .default, animations: animations, completion: nil)
}

public func animate(_ time: Double, _ animations: () -> ()) {
  animate(time: time, curve: .default, animations: animations, completion: nil)
}
public func animate(_ time: Double, _ animations: () -> (), completion: @escaping () -> ()) {
  animate(time: time, curve: .default, animations: animations, completion: completion)
}
public func animate(_ animations: () -> (), completion: @escaping () -> ()) {
  animate(time: atime, curve: .default, animations: animations, completion: completion)
}
public func noAnimation(_ actionsWithoutAnimation: ()->()) {
  if isAnimating {
    UIView.performWithoutAnimation {
      isAnimating = false
      actionsWithoutAnimation()
      isAnimating = true
    }
  } else {
    actionsWithoutAnimation()
  }
}
public var isAnimating: Bool = false

public func animateif(_ animated: Bool, _ animations: () -> ()) {
  animated ? animate(animations) : animations()
}
public func animateif(_ animated: Bool, _ animations: () -> (), _ completion: @escaping ()->()) {
  if animated {
    animate(animations, completion: completion)
  } else {
    animations()
    completion()
  }
}

private func _animate(time: TimeInterval, curve: UIView.AnimationCurve, animations: () -> Void, completion: (() -> Void)? = nil) {
  animate(time: time, curve: curve, animations: animations, completion: completion)
}
private func _animate(_ animations: () -> ()) {
  animate(animations)
}
private func _animate(_ time: Double, _ animations: () -> ()) {
  animate(time,animations)
}
private func _animate(_ time: Double, _ animations: () -> (), completion: @escaping () -> ()) {
  animate(time,animations,completion: completion)
}
private func _animate(_ animations: () -> (), completion: @escaping () -> ()) {
  animate(animations, completion: completion)
}

extension UIView {
  public func animate(time: TimeInterval, curve: UIView.AnimationCurve, animations: () -> Void, completion: (() -> Void)? = nil) {
    _animate(time: time, curve: curve, animations: animations, completion: completion)
  }
  public func animate(_ animations: () -> ()) {
    _animate(animations)
  }
  public func animate(_ time: Double, _ animations: () -> ()) {
    _animate(time,animations)
  }
  public func animate(_ time: Double, _ animations: () -> (), completion: @escaping () -> ()) {
    _animate(time,animations,completion: completion)
  }
  public func animate(_ animations: () -> (), completion: @escaping () -> ()) {
    _animate(animations, completion: completion)
  }
  
  public static func an(_ t: TimeInterval, _ dl: TimeInterval, _ d: CGFloat, _ v: CGFloat, _ o: UIView.AnimationOptions, _ a: @escaping ()->(), _  c: ((Bool)->())?) {
    guard animationsAvailable() else {
      a()
      c?(true)
      return
    }
    var b = a
    if !isAnimating {
      b = {
        isAnimating = true
        a()
        isAnimating = false
      }
    }
    UIView.animate(withDuration: t,
                   delay: dl,
                   usingSpringWithDamping: d,
                   initialSpringVelocity: v,
                   options: o,
                   animations: b,
                   completion: c)
  }
}
public func animateif(_ animated: Bool, using animator: (@escaping ()->(), @escaping ()->())->(), _ a: @escaping ()->(), _ c: @escaping ()->()) {
  if animated {
    animator(a,c)
  } else {
    a()
    c()
  }
}
public func animateif(_ animated: Bool, using animator: (@escaping ()->())->(), _ a: @escaping ()->()) {
  if animated {
    animator(a)
  } else {
    a()
  }
}
public func jellyAnimation(_ a: @escaping ()->()) {
  UIView.an(0.5, 0, 0.5, 3, [.allowUserInteraction], a, nil)
}
public func jellyAnimation(_ a: @escaping ()->(), _ c: @escaping ()->()) {
  UIView.an(0.5, 0, 0.5, 3, [.allowUserInteraction], a, { _ in c() })
}
public func smoothAnimation(_ a: @escaping ()->(), _ c: @escaping ()->()) {
  UIView.an(0.5, 0, 1, 1, [.allowUserInteraction], a, { _ in c() })
}
public func smoothAnimation(_ a: @escaping ()->()) {
  UIView.an(0.5, 0, 1, 1, [.allowUserInteraction], a, nil)
}

public func jellyAnimation2(_ a: @escaping ()->()) {
  UIView.an(0.5, 0, 0.7, 2, [.allowUserInteraction], a, nil)
}
public func jellyAnimation2(_ a: @escaping ()->(), _ c: @escaping ()->()) {
  UIView.an(0.5, 0, 0.7, 2, [.allowUserInteraction], a, { _ in c() })
}

public func errorAnimation(_ a: @escaping ()->()) {
  UIView.an(1, 0, 0.1, 10, [.allowUserInteraction], a, nil)
}
public func errorAnimation(_ a: @escaping ()->(), _ c: @escaping ()->()) {
  UIView.an(1, 0, 0.1, 10, [.allowUserInteraction], a, { _ in c() })
}
#endif
