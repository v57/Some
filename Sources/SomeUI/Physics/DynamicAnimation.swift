//
//  File.swift
//  
//
//  Created by Дмитрий Козлов on 29.01.2021.
//

#if canImport(UIKit)
import UIKit

public class DynamicAnimation: NSObject, UIDynamicItem, UIDynamicAnimatorDelegate {
  public static var animationsEnabled: Bool = true
  public static func disable(_ execute: ()->()) {
    animationsEnabled = false
    defer { animationsEnabled = true }
    execute()
  }
  private var animator: UIDynamicAnimator! = UIDynamicAnimator()
  private var behavior: UIAttachmentBehavior!
  
  public var from: CGFloat
  public var to: CGFloat
  var current: CGFloat {
    didSet {
      if current == target {
        callback(to)
      } else {
        callback(from + (current / target) * (to - from))
      }
    }
  }
  var callback: (CGFloat)->()
  var target: CGFloat
  var completions = [()->()]()
  public init(from: CGFloat, to: CGFloat, damping: CGFloat, frequency: CGFloat, callback: @escaping (CGFloat)->()) {
    self.from = from
    self.to = to
    self.current = 0
    self.callback = callback
    target = .random(in: 100..<1000)
    super.init()
    // Target physics location is slightly greater than needed so it won't be too slow on the end of animation
    behavior = UIAttachmentBehavior(item: self, attachedToAnchor: CGPoint(0, target*1.2))
    behavior.damping = damping
    behavior.frequency = frequency
    behavior.length = 0
    animator.delegate = self
  }
  @discardableResult
  public func then(_ callback: @escaping ()->()) -> Self {
    completions.append(callback)
    return self
  }
  @discardableResult
  public func start() -> Self {
    animator.addBehavior(behavior)
    return self
  }
  public var center: CGPoint {
    get { CGPoint(0, current) }
    set { set(value: newValue.y) }
  }
  public var bounds: CGRect {
    get { CGRect(0,0,1,1) }
    set { }
  }
  public var transform: CGAffineTransform {
    get { CGAffineTransform() }
    set { }
  }
  func set(value: CGFloat) {
    if value.rounded() >= target {
      completed()
    } else {
      current = value
    }
  }
  func completed() {
    current = target
    animator = nil
    behavior = nil
    completions.forEach { $0() }
    completions.removeAll()
  }
  public func cancel() {
    animator = nil
    behavior = nil
  }
  public func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
    completed()
  }
  public func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator) {
    
  }
}

@propertyWrapper
public struct DynamicInt<T: BinaryInteger> {
  public var animator: DynamicUnstoredInteger<T>
  public var wrappedValue: T {
    didSet { animator.animate(to: wrappedValue, animated: DynamicAnimation.animationsEnabled) }
  }
  public init(wrappedValue: T) {
    self.wrappedValue = wrappedValue
    self.animator = DynamicUnstoredInteger(wrappedValue)
  }
  public var projectedValue: O<T> {
    animator.pipe
  }
}


public class DynamicUnstoredInteger<T: BinaryInteger> {
  private weak var animation: DynamicAnimation! {
    didSet {
      oldValue?.cancel()
    }
  }
  public var rawValue: T? { pipe.rawValue }
  public var damping: CGFloat
  public var frequency: CGFloat
  public var pipe: O<T>
  public init(_ current: T? = nil, damping: CGFloat = 1, frequency: CGFloat = 1) {
    self.pipe = O(current)
    self.damping = damping
    self.frequency = frequency
  }
  public func animate(to: T, animated: Bool = true) {
    if let from = pipe.rawValue {
      guard to != from else { return }
      if animated {
        animation = DynamicAnimation(from: CGFloat(from), to: CGFloat(to), damping: 1, frequency: 1) {
          self.pipe.send(T($0))
        }.start()
      } else {
        pipe.send(to)
      }
    } else {
      pipe.send(to)
    }
  }
}

#endif
