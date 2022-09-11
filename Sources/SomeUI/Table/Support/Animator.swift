#if os(iOS)
//
//  Animator.swift
//  SomeTable
//
//  Created by Dmitry on 7/18/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import Foundation

public class Animator {
  public static var current: Animator?
  public static var locks = 0
  public static var isAnimating: Bool {
    return locks > 0
  }
  public static func animate(_ animator: Animator?, animations: @escaping ()->()) {
    if let animator = animator {
      animator.animate(animations)
    } else {
      animations()
    }
  }
  
  public static func lock() {
    locks += 1
  }
  public static func unlock() {
    locks -= 1
    #if DEBUG
    assert(locks >= 0)
    #endif
  }
  public static func animationMode(_ animations: ()->()) {
    lock()
    animations()
    unlock()
  }
  public static var none: Animator {
    return Animator(animated: false)
  }
  public static var `default`: Animator {
    return Animator(animated: true)
  }
  public var animations = [()->()]()
  public var completions = [()->()]()
  public var isEmpty: Bool {
    return (animations.isEmpty && completions.isEmpty)
  }
  public var isAnimated: Bool = true
  public var isAnimating: Bool = false
  public var isCompleted: Bool = false
  public var ignoreAnimations: Bool = false
  public var delay: Double = 0.0
  
  #if DEBUG
  public let createdAt: FunctionInfo
  public init(fn: String = #function, fl: String = #file, ln: Int = #line) {
    createdAt = FunctionInfo(fn,fl,ln)
  }
  public init(animated: Bool, fn: String = #function, fl: String = #file, ln: Int = #line) {
    isAnimated = animated
    createdAt = FunctionInfo(fn,fl,ln)
  }
  #else
  public init() {
    
  }
  public init(animated: Bool) {
    self.isAnimated = animated
  }
  #endif
  
  public func animate(_ animation: @escaping ()->()) {
    if isAnimated {
      animations.append(animation)
    } else {
      Animator.current = self
      defer { Animator.current = nil }
      animation()
    }
  }
  public func completion(_ completion: @escaping ()->()) {
    if isAnimated && !isCompleted {
      completions.append(completion)
    } else {
      Animator.current = self
      defer { Animator.current = nil }
      completion()
    }
  }
  
  public func animation() {
    let previous = Animator.current
    Animator.current = self
    defer { Animator.current = previous }
    animations.forEach { $0() }
    animations.removeAll()
  }
  public func completed() {
    let previous = Animator.current
    Animator.current = self
    defer { Animator.current = previous }
    completions.forEach { $0() }
    completions.removeAll()
  }
  public func animate(using: (_ animation: @escaping ()->(), _ completion: @escaping ()->())->()) {
    guard !ignoreAnimations else { return }
    guard isAnimated else {
      isCompleted = true
      return }
    isAnimating = true
    completions.append {
      self.isAnimating = false
      self.isCompleted = true
    }
    
    using(animation,completed)
    #if DEBUG
    wait(5) { [weak self] in
      guard self != nil else { return }
    //  print("\n\n")
    //  print("error: Animator not deinited in 5 seconds :(. Giving you some info")
    //  print("Created at: \(self!.createdAt)")
    //  print("\n\n")
      // fatalError("Animator not deinited in 5 seconds. Created from \(self!.createdAt)")
    }
    #endif
  }
}

private func wait(_ time: Double, _ block: @escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time, execute: block)
}
#endif
