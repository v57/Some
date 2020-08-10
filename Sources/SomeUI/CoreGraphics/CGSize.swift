#if os(iOS)
//
//  CGSize.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics

extension CGSize {
  public init(_ square: CGFloat) {
    self = CGSize(width: square, height: square)
  }
  public init(_ width: CGFloat, _ height: CGFloat) {
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
  public func fitting(_ minSize: CGFloat) -> CGSize {
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
  public var frame: CGRect {
    return CGRect(origin: .zero, size: self)
  }
  public var center: CGPoint {
    return CGPoint(width / 2, height / 2)
  }
  public var top: CGPoint {
    return CGPoint(width/2,0)
  }
  public var left: CGPoint {
    return CGPoint(0,height/2)
  }
  public var right: CGPoint {
    return CGPoint(width,height/2)
  }
  public var bottom: CGPoint {
    return CGPoint(width/2,height)
  }
  public var topRight: CGPoint {
    return CGPoint(width, 0)
  }
  public var bottomRight: CGPoint {
    return CGPoint(width, height)
  }
  public var topLeft: CGPoint {
    return CGPoint(0, 0)
  }
  public var bottomLeft: CGPoint {
    return CGPoint(0, height)
  }
  public var min: CGFloat {
    return Swift.min(width,height)
  }
  public var max: CGFloat {
    return Swift.max(width,height)
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

public func + (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width + right.width, height: left.height + right.height)
}
public func - (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(width: left.width - right.width, height: left.height - right.height)
}
public func * (left: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: left.width * right, height: left.height * right)
}
public func * (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(left.width * right.width, left.height * right.height)
}
public func / (left: CGSize, right: CGFloat) -> CGSize {
  return CGSize(width: left.width / right, height: left.height / right)
}
public func / (left: CGSize, right: CGSize) -> CGSize {
  return CGSize(left.width / right.width, left.height / right.height)
}
#endif
