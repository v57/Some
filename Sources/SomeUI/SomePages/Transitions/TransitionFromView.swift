//
//  FromView.swift
//  Some
//
//  Created by Димасик on 11/21/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit
import SomeFunctions

public enum TransitionState {
  case preInit, postInit
  case preAnimation, postAnimation
  case preCompletion, postCompletion
}

public enum TransitionSlideState {
  case willChange, didChange
}

public protocol TransitionCustomAnimations {
  /// Current page events
  func opening(transition: PageTransition, with state: TransitionState)
  func closing(transition: PageTransition, with state: TransitionState)
  
  /// Previous page receives those events
  func pushing(transition: PageTransition, with state: TransitionState)
  func back(transition: PageTransition, with state: TransitionState)
  
  /// Slide events
  func closing(transition: PageTransition, time: CGFloat, state: TransitionSlideState)
  func back(transition: PageTransition, time: CGFloat, state: TransitionSlideState)
}

public class FromViewSettings {
  public var view: UIView!
  public var cornerRadius: CGFloat = 0.0
  public var viewIsTransparent: ()->(Bool) = { false }
  public var shouldHideView = true
  public var insertIndex = -1
  public var moveView = true
  public var isTransparent: Bool {
    get {
      return viewIsTransparent()
    } set {
      viewIsTransparent = { newValue }
    }
  }
  public init(view: UIView, cornerRadius: CGFloat, isTransparent: Bool) {
    self.view = view
    self.cornerRadius = cornerRadius
    if isTransparent {
      viewIsTransparent = { true }
    }
  }
  public init() {
    
  }
}

extension PageTransition {
  public static func from(view settings: FromViewSettings) -> PageTransition {
    return FromView(settings: settings)
  }
}

private class Snapshot {
  let fromFrame: CGRect
  let toFrame: CGRect
  
  weak var pv: UIView?
  let pc: CGPoint
  let s: CGFloat
  let ss: CGFloat
  
  let ppc: CGFloat
  
  init(page: SomePage, view: UIView) {
    fromFrame = view.frameOnScreen
    toFrame = page.frame
    pv = view.superview
    pc = view.center
    let a = view.frame.w
    ppc = page.cornerRadius
    s = a / toFrame.w
    ss = a / toFrame.size.max
  }
}

private class FromView: PageTransitionFromView {
  var background: BackgroundTransitionView!
  private var snapshot: Snapshot!
  var moveView: Bool = true
  var slideView: Bool = false
  var fade: Bool = false
  var fadePage: Bool = false
  var viewOpened = false
  
  override init(settings: FromViewSettings) {
    super.init(settings: settings)
    moveView = settings.moveView
  }
  
  override func set(view: UIView) {
    if let right = right, main.currentPage == right {
      super.set(view: view)
    } else {
      super.set(view: view)
    }
  }
  override func animation(type: PageTransition.AnimationType, opening: Bool, _ animations: @escaping () -> (), completion: @escaping () -> ()) {
    switch type {
    case .normal, .slide:
      animationSettings(time: 0.3, curve: .easeInOut) {
        animate(animations, completion: completion)
      }
    case .swipe:
      jellyAnimation(animations, completion)
    }
  }
  override func opening() {
    (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .preInit)
    (right as? TransitionCustomAnimations)?.opening(transition: self, with: .preInit)
    defer {
      (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .postInit)
      (right as? TransitionCustomAnimations)?.opening(transition: self, with: .postInit)
    }
    
    //    let mainView = main.mainView
    fadePage = isTransparent
    if fadePage {
      right.alpha = 0.0
    }
    right.fullscreen()
    snapshot = Snapshot(page: right, view: view)
    
    if right.shouldHideLeft && !right.background.isVisible {
      background = BackgroundTransitionView(frame: snapshot.fromFrame, isSolid: false)
      background.fade = fade
      background.hide()
      main.mainView.addSubview(background)
      background.radius = cornerRadius
    }
    
    super.opening()
    
    if let layer = view.layer.presentation() {
      let frame = view.superview!.convert(layer.frame, to: nil)
      right.scaleToFill(to: frame)
    } else {
      right.scaleToFill(to: snapshot.fromFrame)
    }
    
    viewOpen()
    
    right.cornerRadius = cornerRadius / snapshot.s
    
  }
  override public func open() {
    super.open()
    _open()
  }
  func _open() {
    (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .preAnimation)
    (right as? TransitionCustomAnimations)?.opening(transition: self, with: .preAnimation)
    defer {
      (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .postAnimation)
      (right as? TransitionCustomAnimations)?.opening(transition: self, with: .postAnimation)
    }
    
    if fadePage {
      right.alpha = 1.0
    }
    right.scale(1)
    background?.show()
    if moveView {
      right.frame.origin = snapshot.toFrame.origin
      if slideView {
        if let background = background {
          background.radius = cornerRadius / snapshot.s
          background.set(frame: right.frame)
        }
      } else {
        if settings.shouldHideView {
          view.alpha = 0
        }
        offsetView()
      }
    } else {
      offsetView()
    }
    
  }
  override func opened() {
    super.opened()
    _opened()
  }
  func _opened() {
    (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .preCompletion)
    (right as? TransitionCustomAnimations)?.opening(transition: self, with: .preCompletion)
    defer {
      (left as? TransitionCustomAnimations)?.pushing(transition: self, with: .postCompletion)
      (right as? TransitionCustomAnimations)?.opening(transition: self, with: .postCompletion)
    }
    
    if right.isFullscreen {
      right.cornerRadius = 0
    }
    if moveView {
      if slideView {
        if isAnimated {
          wait(0.15) {
            animate(0.15,self.offsetView) {
              self.background?.completion()
              self.openedHideView()
            }
          }
        } else {
          offsetView()
          openedHideView()
        }
      } else {
        background?.completion()
        if settings.shouldHideView {
          openedHideView()
        }
      }
    }
    
  }
  
  private func openedHideView() {
    //    viewRemove()
    viewClose(isHidden: !right.shouldHideLeft)
  }
  
  override func closing() {
    super.closing()
    _closing()
  }
  func _closing() {
    (left as? TransitionCustomAnimations)?.back(transition: self, with: .preInit)
    (right as? TransitionCustomAnimations)?.closing(transition: self, with: .preInit)
    defer {
      (left as? TransitionCustomAnimations)?.back(transition: self, with: .postInit)
      (right as? TransitionCustomAnimations)?.closing(transition: self, with: .postInit)
    }
    
    fadePage = isTransparent
    if fadePage {
      right.alpha = 1.0
    }
    if moveView && view == nil {
      moveView = false
    }
    if viewOpened {
      viewClose(isHidden: false)
    }
    snapshot = Snapshot(page: right, view: view)
    if right.shouldHideLeft {
      background = BackgroundTransitionView(frame: snapshot.toFrame, isSolid: false)
      background.fade = fade
      background.show()
      main.mainView.insertSubview(background, aboveSubview: left!)
    }
    if moveView {
      viewOpen()
      if slideView {
        viewSlide()
      } else {
        if settings.shouldHideView {
          view.alpha = 0
        }
      }
    }
  }
  override func close() {
    super.close()
    _close()
  }
  func _close() {
    (left as? TransitionCustomAnimations)?.back(transition: self, with: .preAnimation)
    (right as? TransitionCustomAnimations)?.closing(transition: self, with: .preAnimation)
    defer {
      (left as? TransitionCustomAnimations)?.back(transition: self, with: .postAnimation)
      (right as? TransitionCustomAnimations)?.closing(transition: self, with: .postAnimation)
    }
    
    if fadePage {
      right.alpha = 0.0
    }
    
    background?.hide()
    background?.set(frame: snapshot.fromFrame)
    
    right.scaleToFill(to: snapshot.fromFrame)
    if moveView {
      if slideView {
        viewUnslide()
      } else {
        view.alpha = 1
      }
    }
    background?.radius = cornerRadius
    right.cornerRadius = cornerRadius / snapshot.s
  }
  override func closed() {
    super.closed()
    _closed()
  }
  func _closed() {
    (left as? TransitionCustomAnimations)?.back(transition: self, with: .preCompletion)
    (right as? TransitionCustomAnimations)?.closing(transition: self, with: .preCompletion)
    defer {
      (left as? TransitionCustomAnimations)?.back(transition: self, with: .postCompletion)
      (right as? TransitionCustomAnimations)?.closing(transition: self, with: .postCompletion)
    }
    
    if fadePage {
      right.alpha = 1.0
    }
    background?.completion()
    viewClose(isHidden: false)
  }
  
  func offsetView() {
    right.fullscreen()
    if right.isFullscreen {
      right.cornerRadius = screen.cornerRadius
    } else {
      right.cornerRadius = snapshot.ppc
    }
    if moveView && slideView {
      view.frame.y = -view.frame.h
    }
    if let background = background {
      background.radius = screen.cornerRadius
      background.set(frame: right.frame)
    }
  }
  
  func viewClose(isHidden: Bool) {
    guard moveView else { return }
    guard viewOpened else { return }
    viewOpened = false
    view.removeFromSuperview()
    view.center = snapshot.pc
    if !slideView {
      view.alpha = 1.0
    }
    view.scale(1.0)
    snapshot.pv?.addSubview(view)
    view.isHidden = isHidden
  }
  
  func viewOpen() {
    guard !viewOpened else { return }
    guard moveView else { return }
    viewOpened = true
    if settings.insertIndex >= 0 {
      right.insertSubview(view, at: settings.insertIndex)
    } else {
      right.addSubview(view)
    }
    view.isHidden = false
    view.scaleFit(to: snapshot.toFrame, anchor: .top)
  }
  
  func viewSlide() {
    guard slideView else { return }
    view.frame.y = -view.frame.h
  }
  func viewUnslide() {
    guard slideView else { return }
    view.frame.y = 0
  }
  
  override var customSlide: Bool {
    return true
  }
  override func slideBegan() {
    super.slideBegan()
    _closing()
  }
  
  var maxDistance: CGFloat {
    return min(screen.width,screen.height)
  }
  var time: CGFloat {
    var time = 1 - (distance / maxDistance)
    time = min(time,1)
    time = max(time,0)
    return time
  }
  override func slideChanged() {
    super.slideChanged()
    let time = self.time
    
    (left as? TransitionCustomAnimations)?.back(transition: self, time: time, state: .willChange)
    (right as? TransitionCustomAnimations)?.closing(transition: self, time: time, state: .willChange)
    defer {
      (left as? TransitionCustomAnimations)?.back(transition: self, time: time, state: .didChange)
      (right as? TransitionCustomAnimations)?.closing(transition: self, time: time, state: .didChange)
    }
    
    let minScale = snapshot.toFrame.scale(toFill: snapshot.fromFrame)
    let s = keyFrame(from: minScale, to: 1, time: time)
    let ss = keyFrame(from: 0.2, to: 0.8, time: time)
    //    let t = keyFrame(from: -0.8, to: 0.8, time: time)
    right.scale(s)
    //    view.alpha = 1-time
    
    //    from+(to-from)*time
    
    //    let a = minScale
    //    let b = time
    //    let c = slide.offset
    //    let d = slide.start
    //    let e = slide.rightStart
    //    let f = right.frame.size
    //    let g = snapshot.fromFrame.center
    //    let h = slide.rightStartCenter
    //    var pos = (c+e+f/2)+(g-(c+e+f/2))*(1-(a+(1-a)*b))-(g-(c+e+f/2)+(g-(c+e+f/2))*(1-(a+(1-a)*b)))*(0.8*b)
    
    var pos = slide.offset
    pos += slide.start
    pos -= slide.rightStart * s
    pos += Pos(right.frame.w/2,right.frame.h/2)
    pos += slide.rightStartOffset
    pos = keyFrame(from: pos, to: snapshot.fromFrame.center, time: 1-s)
    //    pos += (snapshot.fromFrame.center - pos) * (1-s)
    //    if time > 0.5 {
    pos = keyFrame(from: pos, to: slide.rightStartCenter, time: ss)
    //        }
    right.center = pos
    background?.set(frame: right.frame)
    
    let radius: CGFloat
    if right.isFullscreen {
      radius = screen.cornerRadius
    } else {
      radius = snapshot.ppc
    }
    
    let cornerRadius = keyFrame(from: self.cornerRadius, to: radius, time: time)
    right.cornerRadius = cornerRadius / s
    background?.radius = cornerRadius
  }
  override func willSlide(closing: Bool) {
    super.willSlide(closing: closing)
    
  }
  override func slide(closing: Bool) {
    super.slide(closing: closing)
    if closing {
      _close()
    } else {
      _open()
    }
  }
  override func didSlide(closing: Bool) {
    super.didSlide(closing: closing)
    if closing {
      _closed()
    } else {
      _opened()
    }
  }
  private func keyFrame(from: CGFloat, to: CGFloat, time: CGFloat) -> CGFloat {
    return from + (to - from) * time
  }
  private func keyFrame(from: CGPoint, to: CGPoint, time: CGFloat) -> CGPoint {
    return from + (to - from) * time
  }
  
}

private extension UIView {
  @discardableResult
  func scaleFit(to frame: CGRect, anchor: Anchor) -> CGFloat  {
    let s = frame.size.min/self.frame.size.max
    scale(s)
    let frame = CGRect(origin: .zero, size: frame.size)
    move(frame.anchor(anchor), anchor)
    return s
  }
  func scaleToFill(to frame: CGRect)  {
    let s = frame.size.max / (self.frame.size.min / self.transform.a)
    //    self.frame.size = frame.size * s
    //    resolutionChanged()
    scale(s)
    self.frame = frame
  }
}

private extension CGRect {
  func scale(toFill frame: CGRect) -> CGFloat {
    return frame.size.max / self.size.min
  }
}

private class BackgroundTransitionView: DFView {
  let v: UIView!
  let imageView: UIImageView!
  var radius: CGFloat {
    get { v.layer.cornerRadius }
    set {
      guard !isSolid else { return }
      v.cornerRadius = newValue
    }
  }
  
  let isSolid: Bool
  var fade: Bool = true
  init(frame: CGRect, isSolid: Bool) {
    self.isSolid = isSolid
    if isSolid {
      v = nil
      imageView = nil
    } else {
      v = UIView(frame: frame)
      v.clipsToBounds = true
      
      imageView = UIImageView(frame: screen.frame)
      imageView.contentMode = UIView.ContentMode.scaleAspectFill
      imageView.clipsToBounds = true
      imageView.image = backgroundImage
      imageView.frame.origin = .zero - v.frame.origin
      v.addSubview(imageView)
    }
    super.init(frame: screen.frame)
    if !isSolid {
      addSubview(v)
    }
  }
  
  func hide() {
    guard fade else { return }
    backgroundColor = .clear
  }
  
  func show() {
    guard fade else { return }
    backgroundColor = .black(0.8)
    radius = screen.cornerRadius
  }
  
  func set(frame: CGRect) {
    if !isSolid {
      v.frame = frame
      imageView.frame.origin = .zero - frame.origin
    }
  }
  
  func completion() {
    removeFromSuperview()
  }
  
  required init(coder: NSCoder) { fatalError() }
}
