#if os(iOS)
//
//  CGSize.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics

public extension CGSize {
  init(_ square: CGFloat) {
    self = CGSize(width: square, height: square)
  }
  init(_ width: CGFloat, _ height: CGFloat) {
    self = CGSize(width: width, height: height)
  }
  mutating func rotate() {
    swap(&width, &height)
  }
  mutating func minSquare() {
    if width > height {
      width = height
    } else {
      height = width
    }
  }
  mutating func maxSquare() {
    if width > height {
      height = width
    } else {
      width = height
    }
  }
  func fitting(_ size: CGSize) -> CGSize {
    let scale = Swift.min(size.width / width, size.height / height)
    return self * scale
  }
  func filling(_ size: CGSize) -> CGSize {
    let scale = Swift.max(size.width / width, size.height / height)
    return self * scale
  }
  func fitting(_ minSize: CGFloat) -> CGSize {
    let min = self.min
    guard min > minSize else { return self }
    var scale = min / minSize
    let size = self / scale
    
    let maxSize = minSize * 2
    let max = size.max
    guard max > maxSize else { return self }
    scale = max / maxSize
    return self / scale
  }
  func verticalGrid(in container: CGSize, spacing: CGFloat) -> CGSize {
    CGSize(container.width.fill(width, spacing: 16), height)
  }
  func verticalGrid(in containerWidth: CGFloat, spacing: CGFloat) -> CGSize {
    CGSize(containerWidth.fill(width, spacing: 16), height)
  }
  func horizontalGrid(in container: CGSize, spacing: CGFloat) -> CGSize {
    CGSize(width, container.height.fill(height, spacing: 16))
  }
  func horizontalGrid(in containerHeight: CGFloat, spacing: CGFloat) -> CGSize {
    CGSize(width, containerHeight.fill(height, spacing: 16))
  }
  
  var frame: CGRect { CGRect(origin: .zero, size: self) }
  var minX: CGFloat { 0 }
  var midX: CGFloat { width / 2 }
  var maxX: CGFloat { width }
  var minY: CGFloat { 0 }
  var midY: CGFloat { height / 2 }
  var maxY: CGFloat { height }
  
  var center: CGPoint { CGPoint(width / 2, height / 2) }
  var top: CGPoint { CGPoint(width / 2, 0) }
  var left: CGPoint { CGPoint(0, height / 2) }
  var right: CGPoint { CGPoint(width,height / 2) }
  var bottom: CGPoint { CGPoint(width / 2, height) }
  var topRight: CGPoint { CGPoint(width, 0) }
  var bottomRight: CGPoint { CGPoint(width, height) }
  var topLeft: CGPoint { CGPoint(0, 0) }
  var bottomLeft: CGPoint { CGPoint(0, height) }
  var min: CGFloat { Swift.min(width, height) }
  var max: CGFloat { Swift.max(width, height) }
  static func + (left: CGSize, right: CGSize) -> CGSize {
    CGSize(width: left.width + right.width, height: left.height + right.height)
  }
  static func - (left: CGSize, right: CGSize) -> CGSize {
    CGSize(width: left.width - right.width, height: left.height - right.height)
  }
  static func * (left: CGSize, right: CGSize) -> CGSize {
    CGSize(left.width * right.width, left.height * right.height)
  }
  static func / (left: CGSize, right: CGSize) -> CGSize {
    CGSize(left.width / right.width, left.height / right.height)
  }
  static func * (left: CGSize, right: CGFloat) -> CGSize {
    CGSize(width: left.width * right, height: left.height * right)
  }
  static func / (left: CGSize, right: CGFloat) -> CGSize {
    CGSize(width: left.width / right, height: left.height / right)
  }
}

extension CGSize: Comparable {
  public static func <(lhs: CGSize, rhs: CGSize) -> Bool {
    return lhs.width < rhs.width || lhs.height < rhs.height
  }
}

extension CGSize: Hashable {
  public func hash(into hasher: inout Hasher) {
    width.hash(into: &hasher)
    height.hash(into: &hasher)
  }
}

#endif
