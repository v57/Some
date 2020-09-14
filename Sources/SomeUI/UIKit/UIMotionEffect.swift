#if canImport(UIKit)
//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/4/20.
//

import UIKit

public extension UIView {
  func motion() -> UIMotionEffectGroup {
    let group = UIMotionEffectGroup()
    addMotionEffect(group)
    return group
  }
}

public extension UIMotionEffectGroup {
  private func append(_ effect: UIMotionEffect) -> Self {
    if motionEffects == nil {
      motionEffects = [effect]
    } else {
      motionEffects!.append(effect)
    }
    return self
  }
  @discardableResult
  func c(_ amount: CGFloat) -> Self {
    cx(amount).cy(amount)
  }
  @discardableResult
  func cx(_ amount: CGFloat) -> Self {
    append(.centerX(amount))
  }
  @discardableResult
  func cy(_ amount: CGFloat) -> Self {
    append(.centerY(amount))
  }
  @discardableResult
  func rotateX(_ amount: CGFloat = 1) -> Self {
    append(.rotateX(amount))
  }
  @discardableResult
  func rotateY(_ amount: CGFloat = 1) -> Self {
    append(.rotateY(amount))
  }
}

public extension UIMotionEffect {
  static func centerY(_ amount: CGFloat = 10) -> UIMotionEffect {
    let effect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
    effect.minimumRelativeValue = -amount
    effect.maximumRelativeValue = amount
    return effect
  }
  static func centerX(_ amount: CGFloat = 10) -> UIMotionEffect {
    let effect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
    effect.minimumRelativeValue = -amount
    effect.maximumRelativeValue = amount
    return effect
  }
  static func rotateX(_ amount: CGFloat = 1) -> UIMotionEffect {
    let effect = UIInterpolatingMotionEffect(keyPath: "transform.rotation.y", type: .tiltAlongHorizontalAxis)
    effect.minimumRelativeValue = -amount
    effect.maximumRelativeValue = amount
    return effect
  }
  static func rotateY(_ amount: CGFloat = 1) -> UIMotionEffect {
    let effect = UIInterpolatingMotionEffect(keyPath: "transform.rotation.x", type: .tiltAlongVerticalAxis)
    effect.minimumRelativeValue = -amount
    effect.maximumRelativeValue = amount
    return effect
  }
}
#endif
