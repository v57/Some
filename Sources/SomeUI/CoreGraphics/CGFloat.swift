#if os(iOS)
//
//  CGFloat.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics
import Some

public let π = CGFloat.pi
public let π_2 = CGFloat.pi/2
public let π_4 = CGFloat.pi/4
public let π2 = CGFloat.pi*2
public let π4 = CGFloat.pi*4
public let degree = π / 180
public let radian = 180 / π

postfix operator °
postfix func ° (l: inout CGFloat) -> CGFloat {
  return l * degree
}

public extension CGFloat {
  var int: Int { Int(self) }
  var degrees: CGFloat { self * radian }
  var radians: CGFloat { self * degree }
  static var margin: CGFloat = 12
  static var margin2: CGFloat = 24
  static var miniMargin: CGFloat = 8
  static var miniMargin2: CGFloat = 16
  static func random() -> CGFloat { .random(in: 0..<1) }
  static func seed(_ x: Int, _ y: Int) -> CGFloat {
    return CGFloat(NativeType.seed(x, y))
  }
  static func seed() -> CGFloat {
    return CGFloat(NativeType.seed())
  }
  func fill(_ itemSize: CGFloat) -> CGFloat {
    let items = (self / itemSize).rounded(.down)
    return (self / items).rounded(.down)
  }
  func fill(_ itemSize: CGFloat, spacing: CGFloat) -> CGFloat {
    (self + spacing).fill(itemSize + spacing) - spacing
  }
}

public func increment2d(_ x: inout CGFloat, _ y: inout CGFloat, _ width: CGFloat) {
  x += 1
  if x >= width {
    x = 0
    y += 1
  }
}
#endif
