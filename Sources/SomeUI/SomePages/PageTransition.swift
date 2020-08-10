#if os(iOS)
//
//  PageTransition.swift
//  Some
//
//  Created by Димасик on 11/2/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension SomeMain {
  private func push(page: SomePage) {
    //    let left: SomePage? = pages.last
    //    let right = page
    //    let transition = right.pageTransition
  }
}

open class PageTransition {
  var main: SomeMain { SomeUI.main! }
  public static var `default`: ()->(PageTransition) = { .push }
  public static var none: PageTransition {
    return PageTransition()
  }
  
  public weak var left: SomePage?
  public weak var right: SomePage!
  public var isAnimated: Bool = false
  public var isFromView: Bool { false }
  public init() {}
  
  func push(left: SomePage?, right: SomePage, animated: Bool) {
    self.left = left
    self.right = right
    isAnimated = animated
    if animated {
      opening()
      animation(type: .normal, opening: true, {
        self.open()
      }, completion: {
        self.opened()
      })
    } else {
      _opening()
      _open()
      _opened()
    }
  }
  func back(animated: Bool) {
    if animated {
      closing()
      animation(type: .normal, opening: false, {
        self.close()
      }, completion: {
        self.closed()
      })
    } else {
      _closing()
      _close()
      _closed()
    }
  }
  
  open func animation(type: AnimationType, opening: Bool, _ animations: @escaping ()->(), completion: @escaping ()->()) {
    animationSettings(time: 0.3, curve: .easeOut) {
      animate(animations, completion: completion)
    }
  }
  
  open func opening() {
    _opening()
  }
  open func open() {
    _open()
  }
  open func opened() {
    _opened()
  }
  
  open func closing() {
    _closing()
  }
  open func close() {
    _close()
  }
  open func closed() {
    _closed()
  }
  public enum AnimationType {
    case normal, slide, swipe
  }
  public enum ShouldClose {
    case no, swipe, slide
    var animation: AnimationType {
      switch self {
      case .no:
        return .slide
      case .slide:
        return .slide
      case .swipe:
        return .swipe
      }
    }
  }
  public class Slide {
    public var rightStart: CGPoint
    public var rightStartOffset: CGPoint
    public var rightStartCenter: CGPoint
    public var start: CGPoint
    public var position: CGPoint
    public var offset: CGPoint {
      return position - start
    }
    public var distance: CGFloat {
      return start.distance(to: position)
    }
    public var rightOffset: CGPoint {
      return position - rightStart
    }
    init(start: CGPoint, view: UIView) {
      rightStart = start
      self.start = start
      rightStartOffset = view.frame.origin
      rightStartCenter = view.center
      position = start
    }
  }
  public var slide: Slide!
  public var slideType: SlideDirection = .right
  
  open func shouldClose(velocity: CGPoint) -> ShouldClose {
    if distance > 140 {
      return .slide
    } else if speed(of: velocity) > 1000 {
      return .swipe
    } else {
      return .no
    }
  }
  public var distance: CGFloat {
    switch slideType {
    case .right:
      return slide.offset.x
    case .left:
      return -slide.offset.x
    case .down:
      return slide.offset.y
    case .up:
      return -slide.offset.y
    case .any:
      return slide.offset.length
    }
  }
  public func speed(of velocity: CGPoint) -> CGFloat {
    switch slideType {
    case .right:
      return velocity.x
    case .left:
      return -velocity.x
    case .down:
      return velocity.y
    case .up:
      return -velocity.y
    case .any:
      return velocity.length
    }
  }
  
  open var customSlide: Bool {
    return false
  }
  
  public func leftSwipe(gesture: UIPanGestureRecognizer) {
    let position = gesture.location(in: main.view)
    switch gesture.state {
    case .began:
      slideType = .right
      swipeBegan(position: position)
    case .changed:
      swipeChanged(position: position)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: main.view)
      swipeEnded(velocity: velocity)
    default:
      slide = nil
    }
  }
  public func rightSwipe(gesture: UIPanGestureRecognizer) {
    let position = gesture.location(in: main.view)
    switch gesture.state {
    case .began:
      slideType = .left
      swipeBegan(position: position)
    case .changed:
      swipeChanged(position: position)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: main.view)
      swipeEnded(velocity: velocity)
    default:
      slide = nil
    }
  }
  public func swipeBegan(position: CGPoint) {
    slide = Slide(start: position, view: right)
    slideBegan()
  }
  public func swipeChanged(position: CGPoint) {
    slide.position = position
    slideChanged()
  }
  public func swipeEnded(velocity: CGPoint) {
    let sc = shouldClose(velocity: velocity)
    let closing = sc != .no
    let type = sc.animation
    
    willSlide(closing: closing)
    animation(type: type, opening: !closing, {
      self.slide(closing: closing)
    }, completion: {
      self.didSlide(closing: closing)
    })
    slide = nil
  }
  
  open func slideBegan() {
    if right.shouldHideLeft {
      _displayLeft()
      if !customSlide {
        left!.frame.w = 0
      }
    }
  }
  open func slideChanged() {
    if !customSlide {
      if right.shouldHideLeft {
        left!.frame.w = slide.offset.x
      }
      right.frame.x = slide.rightOffset.x
    }
  }
  open func willSlide(closing: Bool) {
    if closing {
      _closing()
    }
  }
  open func slide(closing: Bool) {
    if closing {
      if !customSlide {
        if right.shouldHideLeft {
          left!.frame.w = screen.width
        }
        right.frame.x = screen.width
      }
      _close()
    } else {
      if !customSlide {
        if right.shouldHideLeft {
          left!.frame.w = 0
        }
        right.frame.x = 0
      }
    }
  }
  open func didSlide(closing: Bool) {
    if closing {
      _closed()
    } else {
      if right.shouldHideLeft {
        left?.removeFromSuperview()
      }
    }
  }
  
  public func lefts(_ lefts: (SomePage)->()) {
    if let left = left {
      lefts(left)
    }
  }
  public func rights(_ rights: (SomePage)->()) {
    rights(right)
  }
}

open class PageTransitionFromView: PageTransition {
  let settings: FromViewSettings
  public var view: UIView! {
    return settings.view
  }
  public var cornerRadius: CGFloat {
    return settings.cornerRadius
  }
  public var isTransparent: Bool {
    return settings.isTransparent
  }
  override public var isFromView: Bool { true }
  public init(settings: FromViewSettings) {
    self.settings = settings
    super.init()
  }
  open func set(view: UIView) {
    settings.view = view
  }
}

private extension PageTransition {
  func _opening() {
    main.view.isUserInteractionEnabled = false
    left?.endEditing(true)
    left?.isClosing = false
    left?.willHide()
    right.fullscreen()
    right.willShow()
    main.mainView.addSubview(right)
    main.navigation.push(right)
    if !right.shouldHideLeft {
      if right.overlay == nil {
        right.overlay = PageOverlay.default()
      }
      right.overlay!.page = left
    }
    main.pages.append(right)
  }
  func _open() {
    if !right.shouldHideLeft {
      right.overlay?.open()
    }
  }
  func _opened() {
    main.view.isUserInteractionEnabled = true
    left?.didHide()
    right.didShow()
    right.firstShow = false
    if right.shouldHideLeft {
      left?.removeFromSuperview()
    }
  }
  
  func _closing() {
    right.endEditing(true)
    right.isClosing = true
    right.willHide()
    if let left = left {
      _displayLeft()
      left.willShow()
    }
    main.navigation.goBack()
    main.pages.removeLast()
  }
  func _close() {
    right.overlay?.close()
  }
  func _closed() {
    right.didHide()
    right._close()
    right.removeFromSuperview()
    right.overlay?.closed()
    
    left?.didShow()
    left?.firstShow = false
  }
  func _displayLeft() {
    guard let left = left else { return }
    guard left.superview == nil else { return }
    left.fullscreen()
    main.mainView.insertSubview(left, belowSubview: right)
  }
}

public enum TransitionDragState {
  case waiting, starting, dragging
}

public extension SomePage {
  var shouldHideLeft: Bool {
    return isFullscreen && isSolid
  }
  var isSolid: Bool {
    return _background.isSolid
  }
  func fullscreen() {
    dframe = screenFrame
  }
}

public enum SlideDirection {
  case left, right, down, up, any
}
#endif
