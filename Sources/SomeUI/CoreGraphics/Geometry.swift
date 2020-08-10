
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreGraphics

// MARK:- Geometry
public struct CGLine {
  public var start: CGPoint
  public var end: CGPoint
  public init(_ start: CGPoint, _ end: CGPoint) {
    self.start = start
    self.end = end
  }
  public init() {
    start = .zero
    end = .zero
  }
  public func intersects(_ line: CGLine) -> Bool {
    let start1 = start
    let end1 = end
    let start2 = line.start
    let end2 = line.end
    
    let dir1 = CGPoint(x: end1.x - start1.x, y: end1.y - start1.y)
    let dir2 = CGPoint(x: end2.x - start2.x, y: end2.y - start2.y)
    
    let a1 = -dir1.y
    let b1 = +dir1.x
    let d1 = -(a1*start1.x + b1*start1.y)
    
    let a2 = -dir2.y
    let b2 = +dir2.x
    let d2 = -(a2*start2.x + b2*start2.y)
    
    let l2s = a2*start1.x + b2*start1.y + d2
    let l2e = a2*end1.x + b2*end1.y + d2
    
    let l1s = a1*start2.x + b1*start2.y + d1
    let l1e = a1*end2.x + b1*end2.y + d1
    
    if l2s * l2e >= 0 || l1s * l1e >= 0 {
      return false
    }
    return true
  }
}
public struct CGPolygon {
  public static var beamSize: CGFloat = 1000
  public var points: [CGPoint]
  public var lines: LazyMapSequence<Range<Int>, CGLine> {
    (0..<points.count).lazy.map(line)
  }
  public init(points: [CGPoint]) {
    self.points = points
  }
  public init(_ points: CGPoint...) {
    self.points = points
  }
  public func line(at index: Int) -> CGLine {
    precondition(index < points.count)
    if index == points.count - 1 {
      return CGLine(points[index], points[0])
    } else {
      return CGLine(points[index], points[index + 1])
    }
  }
  public func containts(_ point: CGPoint) -> Bool {
    let pointLine = CGLine(CGPoint(point.x, point.y),
                           CGPoint(point.x + CGPolygon.beamSize, point.y))
    return lines.filter(pointLine.intersects).count & 1 != 0
  }
}

// MARK: Angle
public extension CGFloat {
  func shortestAngle(to angle: CGFloat) -> CGFloat {
    var angle = (angle - self).truncatingRemainder(dividingBy: π2)
    if (angle >= π) {
      angle = angle - π2
    }
    if (angle <= -π) {
      angle = angle + π2
    }
    return angle
  }
}

// MARK:- Vec
public extension CGVector {
  var angle: CGFloat { atan2(dy, dx) }
  init() {
    self.init(dx: 0, dy: 0)
  }
  init(point: CGPoint) {
    self.init(dx: point.x, dy: point.y)
  }
  init(angle: CGFloat) {
    self.init(dx: cos(angle), dy: sin(angle))
  }
  mutating func offset(_ dx: CGFloat, dy: CGFloat) {
    self.dx += dx
    self.dy += dy
  }
  var length: CGFloat { sqrt(sqLenght) }
  var sqLenght: CGFloat { dx * dx + dy * dy }
  func normalized() -> CGVector {
    let len = length
    return len > 0 ? self / len : CGVector.zero
  }
  mutating func normalize() {
    self = normalized()
  }
  func distanceTo(_ vector: CGVector) -> CGFloat {
    (self - vector).length
  }
  static func + (left: CGVector, right: CGVector) -> CGVector {
    CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
  }
  static func += (left: inout CGVector, right: CGVector) {
    left = left + right
  }
  static func - (left: CGVector, right: CGVector) -> CGVector {
    CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
  }
  static func -= (left: inout CGVector, right: CGVector) {
    left = left - right
  }
  static func * (left: CGVector, right: CGVector) -> CGVector {
    CGVector(dx: left.dx * right.dx, dy: left.dy * right.dy)
  }
  static func *= (left: inout CGVector, right: CGVector) {
    left = left * right
  }
  static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
    CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
  }
  static func *= (vector: inout CGVector, scalar: CGFloat) {
    vector = vector * scalar
  }
  static func / (left: CGVector, right: CGVector) -> CGVector {
    CGVector(dx: left.dx / right.dx, dy: left.dy / right.dy)
  }
  static func /= (left: inout CGVector, right: CGVector) {
    left = left / right
  }
  static func / (vector: CGVector, scalar: CGFloat) -> CGVector {
    CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
  }
  static func /= (vector: inout CGVector, scalar: CGFloat) {
    vector = vector / scalar
  }
}
public func lerp(start: CGVector, end: CGVector, t: CGFloat) -> CGVector {
  CGVector(dx: start.dx + (end.dx - start.dx)*t, dy: start.dy + (end.dy - start.dy)*t)
}

// MARK:- Transform
extension CGAffineTransform {
  static func scale(_ s: CGFloat) -> CGAffineTransform {
    return CGAffineTransform(scaleX: s, y: s)
  }
}
