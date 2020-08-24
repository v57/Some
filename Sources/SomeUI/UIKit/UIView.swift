#if os(iOS)
//
//  UIView.swift
//  Some
//
//  Created by Димасик on 18/08/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

public enum VibrationStyle {
  case selection, light, medium, heavy, soft, rigid, success, error, warning
}
private let selection = UISelectionFeedbackGenerator()
private let light = UIImpactFeedbackGenerator(style: .light)
private let medium = UIImpactFeedbackGenerator(style: .medium)
private let heavy = UIImpactFeedbackGenerator(style: .heavy)
private let soft: UIImpactFeedbackGenerator = {
  if #available(iOS 13.0, *) {
    return UIImpactFeedbackGenerator(style: .soft)
  } else {
    return UIImpactFeedbackGenerator(style: .light)
  }
}()
private let rigid: UIImpactFeedbackGenerator = {
  if #available(iOS 13.0, *) {
    return UIImpactFeedbackGenerator(style: .rigid)
  } else {
    return UIImpactFeedbackGenerator(style: .light)
  }
}()
private let notification = UINotificationFeedbackGenerator()
public func vibrate(_ style: VibrationStyle = .selection) {
  if #available(iOS 10.0, *) {
    switch style {
    case .selection: selection.selectionChanged()
    case .light: light.impactOccurred()
    case .medium: medium.impactOccurred()
    case .heavy: heavy.impactOccurred()
    case .soft: soft.impactOccurred()
    case .rigid: rigid.impactOccurred()
    case .success: notification.notificationOccurred(.success)
    case .error: notification.notificationOccurred(.error)
    case .warning: notification.notificationOccurred(.warning)
    }
  }
}

// MARK: - properties
extension UIView {
  var cornerRadius: CGFloat {
    get { layer.cornerRadius }
    set {
      guard layer.cornerRadius != newValue else { return }
      layer.cornerRadius = newValue
    }
  }
  public var positionOnScreen: CGPoint {
    return superview!.convert(frame.origin, to: nil)
  }
  public var centerPositionOnScreen: CGPoint {
    return superview!.convert(center, to: nil)
  }
  public var frameOnScreen: CGRect {
    return CGRect(origin: positionOnScreen, size: frame.size)
  }
}

// MARK: - functions
extension UIView {
  public convenience init(size: CGSize) {
    self.init(frame: CGRect(origin: .zero, size: size))
  }
  public func addTap(_ selector: Selector?) {
    isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: self, action: selector)
    addGestureRecognizer(gesture)
  }
  public func addTap(_ target: Any?, _ selector: Selector?) {
    isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: target, action: selector)
    addGestureRecognizer(gesture)
  }
  public func removeSubviews() {
    subviews.forEach { $0.removeFromSuperview() }
  }
  public func addCircleLayer(_ color: UIColor ,width: CGFloat) {
    let o: CGFloat = 4
    let rect = CGRect(-o,-o,bounds.w+o+o,bounds.h+o+o)
    let layer = CAShapeLayer()
    layer.path = CGPath(ellipseIn: rect, transform: nil)
    layer.strokeColor = color.cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = width
    layer.frame = bounds
    self.layer.addSublayer(layer)
  }
  public func optimizeCorners() {
    // Huge change in performance by explicitly setting the below (even though default is supposedly NO)
    layer.masksToBounds = false
    // Performance improvement here depends on the size of your view
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.main.scale
  }
  public func bounce(from: CGFloat, vibrate: Bool = true) {
    guard animationsAvailable() else { return }
    if vibrate {
      if #available(iOS 10.0, *) {
        UISelectionFeedbackGenerator().selectionChanged()
      }
    }
    scale(from)
    jellyAnimation {
      self.scale(1.0)
    }
  }
  public func bounce() {
    bounce(from: 1.1)
  }
  public func bounce(completion: @escaping ()->()) {
    guard animationsAvailable() else { return }
    vibrate()
    scale(1.2)
    jellyAnimation ({
      self.scale(1.0)
    }, completion)
  }
  public func shetBounce() {
    guard animationsAvailable() else { return }
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = NSNumber(value: 1.5 as Float)
    animation.toValue = NSNumber(value: 1 as Float)
    animation.duration = 0.4
    animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
    animation.isRemovedOnCompletion = true
    layer.add(animation, forKey: "bounceAnimation")
  }
  public func errorAnimation() {
    layer.position.x += 10
    UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 10, options: [], animations: {
      self.layer.position.x -= 10
    }, completion: nil)
  }
  public func scale(_ s: CGFloat) {
    transform = CGAffineTransform(scaleX: s, y: s)
  }
  public func rotate(_ a: CGFloat) {
    transform = CGAffineTransform(rotationAngle: a)
  }
  public func replaceWithCopy() -> UIView {
    guard let view = snapshotView(afterScreenUpdates: false) else { return self }
    view.frame.origin = frame.origin
    superview?.insertSubview(view, aboveSubview: self)
    removeFromSuperview()
    return view
  }
  public func scale(from: Float, to: Float, animated: Bool, remove: Bool = true) {
    if animated && animationsAvailable() {
      let animation = CABasicAnimation(keyPath: "transform.scale")
      animation.fromValue = NSNumber(value: from)
      animation.toValue = NSNumber(value: to)
      animation.duration = atime
      animation.timingFunction = .default
      animation.isRemovedOnCompletion = remove
      animation.fillMode = CAMediaTimingFillMode.forwards
      layer.add(animation, forKey: "scale")
    } else {
      transform = CGAffineTransform(scaleX: CGFloat(to), y: CGFloat(to))
    }
  }
  public func downAnimation(to value: Float = 0.95) {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = NSNumber(value: 1.0)
    animation.toValue = NSNumber(value: value)
    animation.duration = 0.2
    animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
    animation.isRemovedOnCompletion = false
    animation.fillMode = CAMediaTimingFillMode.forwards
    layer.add(animation, forKey: "touch")
  }
  public func upAnimation(from value: Float = 0.95) {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = NSNumber(value: value)
    animation.toValue = NSNumber(value: 1.0)
    animation.duration = 0.4
    animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
    animation.isRemovedOnCompletion = true
    layer.add(animation, forKey: "touch")
  }
  public func hideAnimation() {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = NSNumber(value: 1)
    animation.toValue = NSNumber(value: 0.5)
    animation.duration = 0.2
    animation.isRemovedOnCompletion = true
    layer.add(animation, forKey: "hide")
  }
  public func showsAnimation() {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = NSNumber(value: 0.0)
    animation.toValue = NSNumber(value: 1.0)
    animation.duration = 0.4
    animation.isRemovedOnCompletion = true
    layer.add(animation, forKey: "hide")
  }
  public func addSubviews(_ subviews: [UIView]) {
    for view in subviews {
      addSubview(view)
    }
  }
  public func addSubviews(_ subviews: UIView...) {
    for view in subviews {
      addSubview(view)
    }
  }
  public func addSubviews(_ subviews: UIView?...) {
    for view in subviews {
      if view != nil {addSubview(view!)}
    }
  }
  public class func optimize(_ views: [UIView], backgroundColor: UIColor) {
    for view in views {
      view.isOpaque = true
      view.clipsToBounds = true
      view.backgroundColor = backgroundColor
      view.clearsContextBeforeDrawing = false
    }
  }
  public class func backgroundColor(_ views: [UIView]) {
    for view in views {
      view.backgroundColor = view.superview?.backgroundColor
    }
  }
  public func circle() {
    clipsToBounds = true
    layer.cornerRadius = frame.size.min / 2
  }
  
  /// blur
  public func addBlur(_ style: UIBlurEffect.Style = .light) {
    let effect = UIBlurEffect(style: .dark)
    let view = UIVisualEffectView(effect: effect)
    view.frame = frame
    addSubview(view)
  }
  public func addDarkBlur() {
    addBlur(.dark)
  }
  public func addLightBlur() {
    addBlur(.extraLight)
  }
  
  /// centering views
  public func centerViewsVertically(_ views: [UIView], offset: CGFloat = .margin) {
    var vheight: CGFloat = 0
    for view in views {
      vheight += view.frame.h + offset
    }
    var y = (frame.h - vheight) / 2
    //    let x = frame.width / 2
    for view in views {
      view.move(y: y, _top)
      y += view.frame.h + offset
    }
  }
  public func centerViewsHorisontally(_ views: [UIView], offset: CGFloat = .margin) {
    var hwidth: CGFloat = -offset
    for view in views {
      hwidth += view.frame.w + offset
    }
    var x = (frame.w - hwidth) / 2
    let y = frame.h / 2
    for view in views {
      view.move(Pos(x,y), _left)
      x += view.frame.w + offset
    }
  }
  
  
  /// shadows
  @discardableResult
  public func dropShadow(opacity: Float = 0.2, offset: CGFloat = 0, radius: CGFloat? = nil, color: UIColor = UIColor.black, usePath: Bool = true) -> Self {
    layer.masksToBounds = false
    layer.shadowColor = color.cgColor
    layer.shadowOffset = CGSize(width: 0.0, height: offset)
    layer.shadowOpacity = opacity
    if let radius = radius {
      layer.shadowRadius = radius
    }
    if usePath {
      updateShadow()
    }
    return self
  }
  func updateShadow() {
    layer.shadowPath = UIBezierPath(rect: bounds).cgPath
  }
  public func dropShadow(opacity: Float, offset: CGFloat, cornerRadius: CGFloat) {
    layer.masksToBounds = false
    layer.shadowColor = UIColor.black(0.2).cgColor
    layer.shadowOffset = CGSize(width: 0.0, height: offset)
    layer.shadowOpacity = opacity
    updateShadow(cornerRadius: cornerRadius)
  }
  public func updateShadow(cornerRadius: CGFloat) {
    var frame = bounds
    frame.x += 1
    frame.y += 1
    frame.w -= 2
    frame.h -= 2
    
    let shadowPath = UIBezierPath(roundedRect: frame, byRoundingCorners: .allCorners, cornerRadii: CGSize(cornerRadius,cornerRadius))
    layer.shadowPath = shadowPath.cgPath
  }
  public func dropCircleShadow(_ opacity: Float, offset: CGFloat) {
    layer.masksToBounds = false
    layer.shadowColor = UIColor.black(0.2).cgColor
    layer.shadowOffset = CGSize(width: 0.0, height: offset)
    layer.shadowOpacity = opacity
    updateCircleShadow()
  }
  public func updateCircleShadow() {
    layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
  }
  
  /// border
  @discardableResult
  public func setBorder(_ color: UIColor, _ width: CGFloat) -> Self {
    layer.borderColor = color.cgColor
    layer.borderWidth = width
    return self
  }
  public func set(borderWidth: CGFloat, animated: Bool) {
    if animated {
      let animation = CABasicAnimation(keyPath: "borderWidth")
      animation.fromValue = layer.borderWidth
      animation.toValue = borderWidth
      animation.timingFunction = .default
      animation.duration = atime
      layer.add(animation, forKey: "borderWidth")
    }
    layer.borderWidth = borderWidth
  }
  
  public func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    self.layer.mask = mask
  }
  
  /// lines
  public class func vline(_ pos: Pos, anchor: Anchor, height: CGFloat, color: UIColor) -> UIView {
    let view = UIView(frame: CGRect(pos, anchor, Size(1/UIScreen.main.scale, height)))
    view.backgroundColor = color
    return view
  }
  public class func hline(_ pos: Pos, anchor: Anchor, width: CGFloat, color: UIColor) -> UIView {
    let view = UIView(frame: CGRect(pos, anchor, Size(width, 1/UIScreen.main.scale)))
    view.backgroundColor = color
    return view
  }
  
  /// options default: .fade
  /// animated default: true
  @discardableResult
  public func destroy(options: DisplayOptions = .fade, animated: Bool = true) -> Self? {
    if animated && animationsAvailable() {
      switch options {
      case .fadeZoom(let zoom):
        animate ({
          self.scale(zoom)
          self.alpha = 0.0
        }) {
          self.alpha = 1.0
          self.scale(1.0)
          self.removeFromSuperview()
        }
      case .fade:
        animate({
          alpha = 0.0
        }) {
          self.removeFromSuperview()
          self.alpha = 1.0
        }
      case .slide:
        animate({
          alpha = 0.0
          frame.y += 10
        }) {
          self.removeFromSuperview()
          self.alpha = 1.0
          self.frame.y -= 10
        }
      case .anchor(let anchor):
        let size = frame.size
        animate({
          resize(.zero, anchor)
        }) {
          self.removeFromSuperview()
          self.resize(size, anchor)
        }
      case .vertical(let anchor):
        let size = frame.size
        animate({
          resize(Size(size.width,0), anchor)
        }) {
          self.removeFromSuperview()
          self.resize(size, anchor)
        }
      case .horizontal(let anchor):
        let size = frame.size
        animate({
          resize(Size(0,size.height), anchor)
        }) {
          self.removeFromSuperview()
          self.resize(size, anchor)
        }
      case .scale(let s):
        animate ({
          scale(s)
        }) {
          self.scale(1)
          self.removeFromSuperview()
        }
      }
    } else {
      self.removeFromSuperview()
    }
    return nil
  }
  public func display(_ view: UIView, options: DisplayOptions = .fade, animated: Bool = true) {
    addSubview(view)
    if animated && animationsAvailable() {
      switch options {
      case .fadeZoom(let zoom):
        view.scale(zoom)
        view.alpha = 0.0
        animate {
          view.alpha = 1.0
          view.scale(1.0)
        }
      case .fade:
        view.alpha = 0.0
        view.frame.y += 10
        animate {
          view.alpha = 1.0
          view.frame.y -= 10
        }
      case .slide:
        view.alpha = 0.0
        view.frame.y += 10
        animate {
          view.alpha = 1.0
          view.frame.y -= 10
        }
      case .anchor(let anchor):
        let size = view.frame.size
        view.resize(.zero, anchor)
        animate {
          view.resize(size, anchor)
        }
      case .vertical(let anchor):
        let size = view.frame.size
        view.resize(Size(size.width,0), anchor)
        animate {
          view.resize(size, anchor)
        }
      case .horizontal(let anchor):
        let size = view.frame.size
        view.resize(Size(0,size.height), anchor)
        animate {
          view.resize(size, anchor)
        }
      case .scale(let s):
        view.scale(s)
        animate {
          view.scale(1)
        }
      }
    }
  }
  public func addSubviewSafe(_ view: UIView) {
    guard view.superview == nil else { return }
    addSubview(view)
  }
}

public enum DisplayOptions {
  case fade, slide
  case anchor(Anchor)
  case vertical(Anchor)
  case horizontal(Anchor)
  case scale(CGFloat)
  case fadeZoom(CGFloat)
  public static var horizontalLeft: DisplayOptions = .horizontal(.left)
  public static var verticalLeft: DisplayOptions = .vertical(.left)
}
#endif
