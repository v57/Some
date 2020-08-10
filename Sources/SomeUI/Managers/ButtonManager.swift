#if os(iOS)
//
//  ButtonGesture.swift
//  Some
//
//  Created by Димасик on 5/23/18.
//  Copyright © 2018 Димасик. All rights reserved.
//

import UIKit
import SomeFunctions

public final class ButtonActions {
  fileprivate var gesture: ButtonGesture
  fileprivate init(gesture: ButtonGesture) {
    self.gesture = gesture
  }
}
public extension ButtonActions {
  var toggle: B {
    gesture.addTapGesture()
    return gesture.toggleActions
  }
  @discardableResult
  func onToggle(action: @escaping (Bool)->()) -> Self {
    toggle.next(action).store(in: gesture)
    return self
  }
  var hold: E { return gesture.holdActions }
  @discardableResult
  func onHold(action: @escaping ()->()) -> Self {
    hold.next(action).store(in: gesture)
    return self
  }
  var forceTouch: E { return gesture.forceTouchActions }
  @discardableResult
  func onForceTouch(action: @escaping ()->()) -> Self {
    forceTouch.next(action).store(in: gesture)
    return self
  }
  var touch: E {
    gesture.addTapGesture()
    return gesture.touchActions
  }
  @discardableResult
  func onTouch(action: @escaping ()->()) -> Self {
    touch.next(action).store(in: gesture)
    return self
  }
  @discardableResult
  func set(animations: ButtonAnimations) -> Self {
    gesture.animations = animations
    return self
  }
  @discardableResult
  func set(toggle: Bool, style: ButtonToggleStyle) -> Self {
    gesture.toggleStyle = style
    gesture.toggleStyle.apply(view: gesture.currentView, manager: gesture)
    gesture.set(toggle: toggle, animated: false)
    gesture.animations.animate1 {
      self.gesture.down(force: 0)
    }
    return self
  }
  @discardableResult
  func set(toggle: Bool, animated: Bool = false) -> Self {
    let a = gesture.forceOffset
    gesture.set(toggle: toggle, animated: animated)
    if a != gesture.forceOffset {
      gesture.animations.animate1 {
        self.gesture.down(force: 0)
      }
    }
    return self
  }
  @discardableResult
  func set(shadow: ShadowType) -> Self {
    gesture.options[.hasShadow] = true
    let opacity: Float = 0.2
    switch shadow {
    case .square:
      gesture.currentView.dropShadow(opacity: opacity)
    case .rounded(radius: let radius):
      gesture.currentView.dropShadow(opacity: opacity, offset: 0, cornerRadius: radius)
    case .circle:
      gesture.currentView.dropCircleShadow(opacity, offset: 0)
    }
    gesture.currentView.layer.shadowRadius = 16
    return self
  }
  func removeShadow() {
    gesture.options[.hasShadow] = false
  }
}


public extension UIView {
  var buttonActions: ButtonActions {
    if let gesture = gestureRecognizers?.find(ButtonGesture.self) {
      return ButtonActions(gesture: gesture)
    } else {
      let gesture = ButtonGesture(view: self)
      addGestureRecognizer(gesture)
      return ButtonActions(gesture: gesture)
    }
  }
}

public enum ShadowType {
  case square, circle, rounded(radius: CGFloat)
}

open class ButtonToggleStyle {
  public static var `default`: ButtonToggleStyle { return Push() }
  public static var border: ButtonToggleStyle { return Border() }
  public init() {}
  open func apply(view: UIView, manager: ButtonGesture) {}
  open func enable(view: UIView, manager: ButtonGesture, animated: Bool) {}
  open func disable(view: UIView, manager: ButtonGesture, animated: Bool) {}
  private class Border: ButtonToggleStyle {
    override func apply(view: UIView, manager: ButtonGesture) {
      view.layer.borderColor = UIColor.system.cgColor
      view.layer.borderWidth = 0.0
    }
    override func enable(view: UIView, manager: ButtonGesture, animated: Bool) {
      view.set(borderWidth: 3, animated: animated)
    }
    override func disable(view: UIView, manager: ButtonGesture, animated: Bool) {
      view.set(borderWidth: 0, animated: animated)
    }
  }
  private class Push: ButtonToggleStyle {
    override func enable(view: UIView, manager: ButtonGesture, animated: Bool) {
      manager.forceOffset = 0.5
      animateif(animated) {
        view.alpha = 0.5
      }
    }
    override func disable(view: UIView, manager: ButtonGesture, animated: Bool) {
      manager.forceOffset = 0.0
      animateif(animated) {
        view.alpha = 1.0
      }
    }
  }
}

open class ButtonAnimations {
  public static var `default`: ButtonAnimations { Push() }
  public static var push: ButtonAnimations { Push() }
  public static var none: ButtonAnimations { ButtonAnimations() }
  public init() {}
  open func animate1(animation: @escaping ()->()) {
    animation()
  }
  open func animate2(animation: @escaping ()->(), completion: @escaping ()->()) {
    animation()
    completion()
  }
  open func down(manager: ButtonGesture, force: CGFloat) {
  }
  open func down(manager: ButtonGesture) {
  }
  open func up(manager: ButtonGesture) {
  }
  private class Push: ButtonAnimations {
    var _force: CGFloat = 0.0
    override func animate1(animation: @escaping ()->()) {
      jellyAnimation {
        animation()
      }
    }
    override func animate2(animation: @escaping ()->(), completion: @escaping ()->()) {
      animate(0.1, animation, completion: completion)
    }
    override func down(manager: ButtonGesture, force: CGFloat) {
      push(manager: manager, force: force)
    }
    override func down(manager: ButtonGesture) {
      push(manager: manager, force: 0.3)
    }
    override func up(manager: ButtonGesture) {
      push(manager: manager, force: 0.0)
    }
    func push(manager: ButtonGesture, force: CGFloat) {
      let force = min(force + manager.forceOffset,1.0)
      guard force != _force else { return }
      _force = force
      let s = (1.0 - (force / 5))
      manager.currentView.scale(s)
      if manager.options[.hasShadow] {
        manager.currentView.layer.shadowOpacity = 0.5 + 0.5 * Float(force)
        manager.currentView.layer.shadowRadius = 16 - 16 * force
      }
    }
  }
}

public enum ButtonOptions: UInt8 {
  case touch, hold, forceTouch, toggle
  case hasShadow
  case isToggle
}

private class ButtonTap: UITapGestureRecognizer {
  unowned var gesture: ButtonGesture
  init(gesture: ButtonGesture) {
    self.gesture = gesture
    super.init(target: gesture.view, action: #selector(UIView._tap(gesture:)))
    gesture.currentView.addGestureRecognizer(self)
  }
}
@available(iOS 13.0, *)
private class ButtonHover: UIHoverGestureRecognizer {
  unowned var gesture: ButtonGesture
  init(gesture: ButtonGesture) {
    self.gesture = gesture
    super.init(target: gesture.view, action: #selector(UIView._hover(gesture:)))
    gesture.currentView.addGestureRecognizer(self)
  }
  var isInside = false
  var offset: CGFloat = 0
  @objc func hover() {
    switch state {
    case .began:
      let s = gesture.view!.frame.size.max
      offset = 1 - s / (s + 20)
      gesture.forceOffset -= offset
      gesture.downAnimated(force: gesture.forceOffset)
    case .changed: break
    default:
      gesture.forceOffset += offset
      gesture.downAnimated(force: gesture.forceOffset)
    }
  }
}

public class ButtonGesture: ForceTouchGestureRecognizer, PipeStorage {
  public var pipes: Set<S> = []
  public var options = ButtonOptions.Set64()
  unowned var currentView: UIView
  var toggleActions = B()
  var holdActions = E()
  var forceTouchActions = E()
  var touchActions = E()
  var animations: ButtonAnimations = .default
  var toggleStyle: ButtonToggleStyle = .default
  private var tapGesture: UITapGestureRecognizer!
  private var hoverGesture: UIGestureRecognizer!
  
  public var forceOffset: CGFloat = 0.0
  var forceTriggered = false
  private var ignoreTouchEnded = false
  private var version = 0
  private var beganTime: Double = 0.0
  private var isTouchInside = false
  init(view: UIView) {
    currentView = view
    view.isUserInteractionEnabled = true
    super.init(target: view, action: #selector(UIView._hold(gesture:)))
    minimumPressDuration = 0.2
  }
}

private extension ButtonGesture {
  func tapped() {
    let t = forceOffset
    touch()
    if forceOffset != t {
      up()
    } else {
      downUp()
    }
    vibrate(.light)
  }
  func holding() {
    var force: CGFloat?
    if screen.forceTouchAvailable {
      force = self.force
    }
    switch self.state {
    case .began:
      forceTriggered = false
      ignoreTouchEnded = false
      beganTime = Time.abs
      version += 1
      isTouchInside = true
      if let force = force {
        if force == 1 {
          self.forceTriggered = true
          vibrate(.medium)
        }
        down(force: force)
      } else {
        down()
      }
    case .changed:
      if isTouchInside {
        let location = self.location(in: currentView)
        let pos = currentView.bounds.anchor(.center)
        let frame = CGRect(center: pos, size: currentView.bounds.size / 0.8)
        isTouchInside = frame.contains(location)
        if isTouchInside, let force = force {
          down(force: force)
          if shouldForceTouch && force > 0.8 {
            up()
          } else if forceTriggered {
            if force < 0.5 {
              forceTriggered = false
              ignoreTouchEnded = true
              touch()
              vibrate(.medium)
            }
          } else {
            if force == 1.0 {
              self.forceTriggered = true
              vibrate(.medium)
            }
          }
        } else {
          up()
        }
      } else {
        let location = self.location(in: currentView)
        isTouchInside = currentView.bounds.contains(location)
        if isTouchInside && force == nil {
          down()
        }
      }
    case .ended:
      guard isTouchInside else { return }
      isTouchInside = false
      
      if !ignoreTouchEnded {
        touch()
        vibrate(.light)
      }
      let time = Time.abs - beganTime
      if time < 0.1 && self.force < 0.3 {
        downUp()
      } else {
        up()
      }
    case .cancelled:
      guard isTouchInside else { return }
      isTouchInside = false
      up()
    default: break
    }
  }
}

private extension ButtonGesture {
  var shouldToggle: Bool { !toggleActions.isEmpty }
  var shouldForceTouch: Bool { !forceTouchActions.isEmpty }
  var shouldHold: Bool { !holdActions.isEmpty }
  var shouldTouch: Bool { !touchActions.isEmpty }
  var holdDuration: CFTimeInterval {
    if shouldHold || shouldForceTouch {
      return 0.5
    } else {
      return 0.1
    }
  }
  func addTapGesture() {
    guard tapGesture == nil else { return }
    tapGesture = ButtonTap(gesture: self)
    if #available(iOS 13.0, *) {
      hoverGesture = ButtonHover(gesture: self)
    }
  }
  func set(toggle: Bool, animated: Bool) {
    guard toggle != options[.isToggle] else { return }
    options[.isToggle] = toggle
    if toggle {
      toggleStyle.enable(view: currentView, manager: self, animated: animated)
    } else {
      toggleStyle.disable(view: currentView, manager: self, animated: animated)
    }
    toggleActions.send(toggle)
  }
}

private extension ButtonGesture {
  func hold() {
    holdActions.send()
  }
  func forceTouch() {
    forceTouchActions.send()
  }
  func toggle() {
    let toggle = !options[.isToggle]
    set(toggle: toggle, animated: true)
  }
  func touch() {
    if shouldToggle {
      toggle()
    }
    touchActions.send()
  }
}

private extension ButtonGesture {
  func up() {
    self.animations.animate1 {
      self.animations.up(manager: self)
    }
  }
  func down(force: CGFloat) {
    animations.down(manager: self, force: force)
  }
  func down() {
    animations.animate1 {
      self.animations.down(manager: self)
    }
  }
  func downAnimated(force: CGFloat) {
    animations.animate1 {
      self.animations.down(manager: self, force: force)
    }
  }
  func downUp() {
    version += 1
    let v = version
    animations.animate2(animation: {
      self.animations.down(manager: self)
    }, completion: { [weak self] in
      guard let self = self else { return }
      guard self.version == v else { return }
      self.animations.animate1 {
        self.animations.up(manager: self)
      }
    })
  }
}

private extension UIView {
  @available(iOS 13.0, *)
  @objc func _hover(gesture: ButtonHover) {
    // gesture.hover()
  }
  @objc func _tap(gesture: ButtonTap) {
    gesture.gesture.tapped()
  }
  @objc func _hold(gesture: ButtonGesture) {
    gesture.holding()
  }
}
#endif
