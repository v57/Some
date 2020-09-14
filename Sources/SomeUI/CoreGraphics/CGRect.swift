#if os(iOS)
//
//  CGRect.swift
//  mutating funcs
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Димасик. All rights reserved.
//

import CoreGraphics

extension CGRect {
  public init(_ pos: Pos, _ anchor: Anchor, _ size: Size) {
    self.init(origin: Pos(pos.x - size.width * anchor.x, pos.y - size.height * anchor.y), size: size)
  }
  public init(size: CGSize) {
    self.init(origin: .zero, size: size)
  }
  public func anchor(_ anchor: Anchor) -> Pos {
    let w = size.width * anchor.x
    let h = size.height * anchor.y
    let x = self.x + w
    let y = self.y + h
    return Pos(x,y)
  }
  public init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
    self.init(x: x, y: y, width: width, height: height)
  }
  public init(_ x: Int, _ y: Int, _ width: Int, _ height: Int) {
    self.init(x: x, y: y, width: width, height: height)
  }
  public init(_ x: Double, _ y: Double, _ width: Double, _ height: Double) {
    self.init(x: x, y: y, width: width, height: height)
  }
  public init(frame: CGRect, size: CGSize) {
    self.init(x: (frame.w - size.width) / 2, y: (frame.h - size.height) / 2, width: size.width, height: size.height)
  }
  public init(center: CGPoint, size: CGSize) {
    self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
  }
  public static func size(_ w: CGFloat, _ h: CGFloat) -> CGRect {
    return CGRect(size: CGSize(w,h))
  }
  
  public var x: CGFloat {
    get { origin.x }
    set { origin.x = newValue }
  }
  public var y: CGFloat {
    get { origin.y }
    set { origin.y = newValue }
  }
  public var w: CGFloat {
    get { size.width }
    set { size.width = newValue }
  }
  public var h: CGFloat {
    get { size.height }
    set { size.height = newValue }
  }
  public var topLeft: CGPoint {
    get { origin }
    set { origin = newValue }
  }
  
  
  public var top: CGPoint {
    get {
      return CGPoint(x-w*0.5,y)
    }
    set {
      origin = CGPoint(newValue.x-w*0.5,newValue.y)
    }
  }
  public var topRight: CGPoint {
    get {
      return CGPoint(x+w,y)
    }
    set {
      origin = CGPoint(x-w,y)
    }
  }
  public var right: CGPoint {
    get {
      return CGPoint(x+w,y+h*0.5)
    }
    set {
      origin = CGPoint(newValue.x-w,newValue.y-h*0.5)
    }
  }
  public var bottomRight: CGPoint {
    get {
      return CGPoint(x+w,y+h)
    }
    set {
      origin = CGPoint(newValue.x-w,newValue.y-h)
    }
  }
  public var bottom: CGPoint {
    get {
      return CGPoint(x+w*0.5,y+h)
    }
    set {
      origin = CGPoint(newValue.x-w*0.5,newValue.y-h)
    }
  }
  public var bottomLeft: CGPoint {
    get {
      return CGPoint(x,y+h)
    }
    set {
      origin = CGPoint(newValue.x,newValue.y-h)
    }
  }
  public var left: CGPoint {
    get {
      return CGPoint(x,y+h*0.5)
    }
    set {
      origin = CGPoint(newValue.x,newValue.y-h*0.5)
    }
  }
  public var center: CGPoint {
    get { CGPoint(x+w*0.5,y+h*0.5) }
    set { origin = CGPoint(newValue.x-w*0.5,newValue.y-h*0.5) }
  }
  
  public mutating func moveX(_ x: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x - size.width * anchor.x, y: y, width: size.width, height: size.height)
  }
  public mutating func moveY(_ y: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x, y: y - size.height * anchor.y, width: size.width, height: size.height)
  }
  public mutating func move(_ pos: CGPoint, _ anchor: Anchor) {
    self = CGRect(x: pos.x - size.width * anchor.x, y: pos.y - size.height * anchor.y, width: size.width, height: size.height)
  }
  
  public mutating func resize(width: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x - (width - size.width) * anchor.x, y: y, width: width, height: size.height)
  }
  public mutating func resize(height: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x, y: y - (height - size.height) * anchor.y, width: size.width, height: height)
  }
  public mutating func resize(_ size: CGSize, _ anchor: Anchor) {
    self = CGRect(x: x - (w - size.width) * anchor.x, y: y - (h - size.height) * anchor.y, width: w, height: h)
  }
  public mutating func resize(_ width: CGFloat, _ height: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x - (width - size.width) * anchor.x, y: y - (height - size.height) * anchor.y, width: width, height: height)
  }
  
  public mutating func extend(width: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x - width * anchor.x, y: y, width: size.width + width, height: size.height)
  }
  public mutating func extend(height: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x, y: y - height * anchor.y, width: size.width, height: size.height + height)
  }
  public mutating func extend(_ width: CGFloat, _ height: CGFloat, _ anchor: Anchor) {
    self = CGRect(x: x - width * anchor.x, y: y - height * anchor.y, width: size.width + width, height: size.height + height)
  }
  public mutating func extend(_ size: CGSize, _ anchor: Anchor) {
    self = CGRect(x: x - size.width * anchor.x, y: y - size.height * anchor.y, width: self.w + size.width, height: self.h + size.height)
  }
}

public func + (left: CGRect, right: CGRect) -> CGSize {
  return CGSize(max(left.x + left.w, right.x + right.w), max(left.y + left.h, right.y + right.h))
}
public func + (left: CGRect, right: CGRect) -> CGRect {
  var rect = CGRect()
  rect.x = min(left.x, right.x)
  return CGRect(x: left.x + right.x, y: left.y + right.y, width: left.w + right.w, height: left.h + right.h)
}
public func + (left: CGRect, right: CGPoint) -> CGRect {
  return CGRect(x: left.x + right.x, y: left.y + right.y, width: left.w, height: left.h)
}
public func + (left: CGRect, right: CGSize) -> CGRect {
  return CGRect(x: left.x, y: left.y, width: left.w + right.width, height: left.h + right.height)
}

public func += (left: inout CGRect, right: CGRect) {
  left = left + right
}
public func += (left: inout CGRect, right: CGPoint) {
  left = left + right
}
public func += (left: inout CGRect, right: CGSize) {
  left = left + right
}

public func - (left: CGRect, right: CGRect) -> CGRect {
  return CGRect(x: left.x - right.x, y: left.y - right.y, width: left.w - right.w, height: left.h - right.h)
}
public func - (left: CGRect, right: CGPoint) -> CGRect {
  return CGRect(x: left.x - right.x, y: left.y - right.y, width: left.w, height: left.h)
}
public func - (left: CGRect, right: CGSize) -> CGRect {
  return CGRect(x: left.x, y: left.y, width: left.w - right.width, height: left.h - right.height)
}

public func -= (left: inout CGRect, right: CGRect) {
  left = left - right
}
public func -= (left: inout CGRect, right: CGPoint) {
  left = left - right
}
public func -= (left: inout CGRect, right: CGSize) {
  left = left - right
}

public func * (left: CGRect, right: CGRect) -> CGRect {
  return CGRect(x: left.x * right.x, y: left.y * right.y, width: left.w * right.w, height: left.h * right.h)
}
public func * (left: CGRect, right: CGPoint) -> CGRect {
  return CGRect(x: left.x * right.x, y: left.y * right.y, width: left.w, height: left.h)
}
public func * (left: CGRect, right: CGSize) -> CGRect {
  return CGRect(x: left.x, y: left.y, width: left.w * right.width, height: left.h * right.height)
}
public func * (left: CGRect, right: CGFloat) -> CGRect {
  return CGRect(x: left.x * right, y: left.y * right, width: left.w * right, height: left.h * right)
}

public func *= (left: inout CGRect, right: CGRect) {
  left = left * right
}
public func *= (left: inout CGRect, right: CGPoint) {
  left = left * right
}
public func *= (left: inout CGRect, right: CGSize) {
  left = left * right
}

public func / (left: CGRect, right: CGRect) -> CGRect {
  return CGRect(x: left.x / right.x, y: left.y / right.y, width: left.w / right.w, height: left.h / right.h)
}
public func / (left: CGRect, right: CGPoint) -> CGRect {
  return CGRect(x: left.x / right.x, y: left.y / right.y, width: left.w, height: left.h)
}
public func / (left: CGRect, right: CGSize) -> CGRect {
  return CGRect(x: left.x, y: left.y, width: left.w / right.width, height: left.h / right.height)
}
public func / (left: CGRect, right: CGFloat) -> CGRect {
  return CGRect(x: left.x / right, y: left.y / right, width: left.w / right, height: left.h / right)
}

public func /= (left: inout CGRect, right: CGRect) {
  left = left / right
}
public func /= (left: inout CGRect, right: CGPoint) {
  left = left / right
}
public func /= (left: inout CGRect, right: CGSize) {
  left = left / right
}
public func /= (left: inout CGRect, right: CGFloat) {
  left = left / right
}
#endif
