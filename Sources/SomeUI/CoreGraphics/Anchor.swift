//
//  Anchor.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import UIKit

public typealias Pos = CGPoint
public typealias Size = CGSize
public typealias Color = UIColor
public typealias Rect = CGRect

public let _tl = Anchor(0.0,0.0)
public let _tr = Anchor(1.0,0.0)
public let _bl = Anchor(0.0,1.0)
public let _br = Anchor(1.0,1.0)
public let _t = Anchor(0.5,0.0)
public let _b = Anchor(0.5,1.0)
public let _l = Anchor(0.0,0.5)
public let _r = Anchor(1.0,0.5)
public let _c = Anchor(0.5,0.5)


public let _topLeft = Anchor(0.0,0.0)
public let _topRight = Anchor(1.0,0.0)
public let _bottomLeft = Anchor(0.0,1.0)
public let _bottomRight = Anchor(1.0,1.0)
public let _top = Anchor(0.5,0.0)
public let _bottom = Anchor(0.5,1.0)
public let _left = Anchor(0.0,0.5)
public let _right = Anchor(1.0,0.5)
public let _center = Anchor(0.5,0.5)

public struct Anchor {
  public var x: CGFloat
  public var y: CGFloat
  public init() {
    x = 0
    y = 0
  }
  public init(_ x: CGFloat, _ y: CGFloat) {
    self.x = x
    self.y = y
  }
  public init(point: CGPoint) {
    self.x = point.x
    self.y = point.y
  }
  
  public static var left: Anchor = Anchor(0,0.5)
  public static var topLeft: Anchor = Anchor(0,0)
  public static var top: Anchor = Anchor(0.5,0)
  public static var topRight: Anchor = Anchor(1,0)
  public static var right: Anchor = Anchor(1,0.5)
  public static var bottomRight: Anchor = Anchor(1,1)
  public static var bottom: Anchor = Anchor(0.5,1)
  public static var bottomLeft: Anchor = Anchor(0,1)
  public static var center: Anchor = Anchor(0.5,0.5)
  
  public var alignment: NSTextAlignment {
    if x == 0.5 {
      return .center
    } else if x == 1 {
      return .right
    } else {
      return .left
    }
  }
}
