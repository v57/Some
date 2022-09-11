//
//  File.swift
//  File
//
//  Created by Dmitry Kozlov on 26.08.2021.
//

import CoreGraphics

public extension CGAffineTransform {
  static func scale(_ s: CGFloat) -> Self {
    CGAffineTransform(scaleX: s, y: s)
  }
  static func scale(x: CGFloat, y: CGFloat) -> Self {
    CGAffineTransform(scaleX: x, y: y)
  }
  static func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self {
    CGAffineTransform(translationX: x, y: y)
  }
  static func offset(_ x: CGFloat, _ y: CGFloat) -> Self {
    CGAffineTransform(translationX: x, y: y)
  }
  static func rotated(by angle: CGFloat) -> Self {
    CGAffineTransform(rotationAngle: angle)
  }
  var scaleX: CGFloat {
    get { a }
    set { a = newValue }
  }
  var scaleY: CGFloat {
    get { d }
    set { d = newValue }
  }
  var scale: CGFloat {
    get { scaleX }
    set {
      scaleX = newValue
      scaleY = newValue
    }
  }
  var offset: CGPoint {
    get { CGPoint(tx, ty) }
    set {
      tx = newValue.x
      ty = newValue.y
    }
  }
  func scale(_ s: CGFloat) -> Self {
    scaledBy(x: s, y: s)
  }
  func scale(x: CGFloat, y: CGFloat) -> Self {
    scaledBy(x: x, y: y)
  }
  func offset(_ x: CGFloat, _ y: CGFloat) -> Self {
    translatedBy(x: x, y: y)
  }
  func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self {
    translatedBy(x: x, y: y)
  }
}
