//
//  CGPoint.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics


public extension CGPoint {
  init(vector: CGVector) {
    self.init(x: vector.dx, y: vector.dy)
  }
  init(angle: CGFloat) {
    self.init(x: cos(angle), y: sin(angle))
  }
  init(_ x: CGFloat, _ y: CGFloat) {
    self = CGPoint(x: x, y: y)
  }
  mutating func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
    x += dx
    y += dy
    return self
  }
  var length: CGFloat {
    sqrt(x * x + y * y)
  }
  var lengthSquared: CGFloat {
    x * x + y * y
  }
  var normalized: CGPoint {
    let len = length
    return len > 0 ? self / len : CGPoint.zero
  }
  var angle: CGFloat { atan2(y, x) }
  mutating func normalize() {
    self = normalized
  }
  func distance(to point: CGPoint) -> CGFloat {
    return (self - point).length
  }
  func direction(to point: CGPoint) -> CGVector {
    let dx = x - point.x
    let dy = y - point.y
    let dist2 = dx * dx + dy * dy
    let x = dx * dx / dist2
    let y = dy * dy / dist2
    return CGVector(dx: x, dy: y)
  }
  func angle(to point: CGPoint) -> CGFloat {
    direction(to: point).angle
  }
  static func == (left: CGPoint, right: CGPoint) -> Bool {
    return left.x == right.x && left.y == right.y
  }
  static func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
  }
  static func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
  }
  static func + (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
  }
  static func += (left: inout CGPoint, right: CGVector) {
    left = left + right
  }
  static func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
  }
  static func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
  }
  static func - (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x - right.dx, y: left.y - right.dy)
  }
  static func -= (left: inout CGPoint, right: CGVector) {
    left = left - right
  }
  static func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
  }
  static func *= (left: inout CGPoint, right: CGPoint) {
    left = left * right
  }
  static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
  }
  static func *= (point: inout CGPoint, scalar: CGFloat) {
    point = point * scalar
  }
  static func * (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x * right.dx, y: left.y * right.dy)
  }
  static func *= (left: inout CGPoint, right: CGVector) {
    left = left * right
  }
  static func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
  }
  static func /= (left: inout CGPoint, right: CGPoint) {
    left = left / right
  }
  static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
  }
  static func /= (point: inout CGPoint, scalar: CGFloat) {
    point = point / scalar
  }
  static func / (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x / right.dx, y: left.y / right.dy)
  }
  static func /= (left: inout CGPoint, right: CGVector) {
    left = left / right
  }
}
