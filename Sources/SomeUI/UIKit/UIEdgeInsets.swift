#if os(iOS)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 8/4/20.
//

import UIKit

public extension UIEdgeInsets {
  static func l(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = UIEdgeInsets()
    insets.left = inset
    return insets
  }
  static func r(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = UIEdgeInsets()
    insets.right = inset
    return insets
  }
  static func t(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = UIEdgeInsets()
    insets.top = inset
    return insets
  }
  static func b(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = UIEdgeInsets()
    insets.bottom = inset
    return insets
  }
  static func lr(_ inset: CGFloat) -> UIEdgeInsets {
    l(inset).r(inset)
  }
  static func tb(_ inset: CGFloat) -> UIEdgeInsets {
    t(inset).b(inset)
  }
  static func fs(_ inset: CGFloat) -> UIEdgeInsets {
    lr(inset).tb(inset)
  }
  static func - (a: UIEdgeInsets, b: UIEdgeInsets) -> UIEdgeInsets {
    UIEdgeInsets(top: a.top - b.top, left: a.left - b.left, bottom: a.bottom - b.bottom, right: a.right - b.right)
  }
  static func + (a: UIEdgeInsets, b: UIEdgeInsets) -> UIEdgeInsets {
    UIEdgeInsets(top: a.top + b.top, left: a.left + b.left, bottom: a.bottom + b.bottom, right: a.right + b.right)
  }
  
  func l(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = self
    insets.left = inset
    return insets
  }
  func r(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = self
    insets.right = inset
    return insets
  }
  func t(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = self
    insets.top = inset
    return insets
  }
  func b(_ inset: CGFloat) -> UIEdgeInsets {
    var insets = self
    insets.bottom = inset
    return insets
  }
  func lr(_ inset: CGFloat) -> UIEdgeInsets {
    l(inset).r(inset)
  }
  func tb(_ inset: CGFloat) -> UIEdgeInsets {
    t(inset).b(inset)
  }
  func fs(_ inset: CGFloat) -> UIEdgeInsets {
    lr(inset).tb(inset)
  }
  var topLeft: CGPoint {
    return CGPoint(left,top)
  }
  var width: CGFloat {
    return left + right
  }
  var height: CGFloat {
    return top + bottom
  }
  @inline(__always)
  func inset(rect: CGRect) -> CGRect {
    return rect.inset(by: self)
  }
}
#endif
