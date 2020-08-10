//
//  CGFloat.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics

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

extension CGFloat {
  public var degrees: CGFloat { self * radian }
  public var radians: CGFloat { self * degree }
  public static var margin: CGFloat = 12
  public static var margin2: CGFloat = 24
  public static var miniMargin: CGFloat = 8
  public static var miniMargin2: CGFloat = 16
  public static func random() -> CGFloat {
    return CGFloat(NativeType.random())
  }
  public static func random(max: CGFloat) -> CGFloat {
    return CGFloat(NativeType.random(max: NativeType(max)))
  }
  public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat(NativeType.random(min: NativeType(min), max: NativeType(max)))
  }
  public static func seed(_ x: Int, _ y: Int) -> CGFloat {
    return CGFloat(NativeType.seed(x, y))
  }
  public static func seed() -> CGFloat {
    return CGFloat(NativeType.seed())
  }
}

public func increment2d(_ x: inout CGFloat, _ y: inout CGFloat, _ width: CGFloat) {
  x += 1
  if x >= width {
    x = 0
    y += 1
  }
}
