#if canImport(CoreGraphics)
//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 30/10/2020.
//

import CoreGraphics

public extension Array where Element == Int {
  func points(size: CGSize, max: Int?, min: Int?, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> [CGPoint] {
    let min = min ?? self.min()!
    let max = max ?? self.max()!
    let w = size.width
    let h = size.height
    var points = [CGPoint]()
    for (i, v) in enumerated() {
      let v = v - min
      let x = CGFloat(i) / CGFloat(count-1) * w
      let y: CGFloat = h - h * CGFloat(v) / CGFloat(max)
      points.append(.init(x: x + offsetX, y: y + offsetY))
    }
    return points
  }
}
public extension Array where Element == CGPoint {
  var curves: [(CGPoint, CGPoint, CGPoint)] {
    var f = first!
    return dropFirst().map {
      let t = $0
      var a = f
      a.x += (t.x - a.x)/2
      var b = t
      b.x -= (t.x - f.x)/2
      f = t
      return (t, a, b)
    }
  }
  var cv: [(CGPoint, CGPoint, CGPoint)] {
    curves
  }
}
public extension CGMutablePath {
  func addCurvedLines(_ points: [CGPoint]) {
    move(to: points.first!)
    points.cv.forEach {
      addCurve(to: $0.0, control1: $0.1, control2: $0.2)
    }
  }
  func closeBottom(_ size: CGSize) {
    addLine(to: CGPoint(x: size.width, y: size.height))
    addLine(to: CGPoint(x: 0, y: size.height))
  }
}
#endif
