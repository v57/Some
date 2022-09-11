#if canImport(CoreGraphics)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 30/10/2020.
//

import CoreGraphics

// MARK: CGPath
public extension CGPath {
  func image(color: UIColor, size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    defer { UIGraphicsEndImageContext() }
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.setFillColor(color.cgColor)
    context.addPath(self)
    context.drawPath(using: .eoFill)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
  func image(color: UIColor) -> UIImage? {
    image(color: color, size: boundingBox.size)
  }
  func image(fitting size: CGSize, color: UIColor) -> UIImage? {
    fitting(size).image(color: color, size: size)
  }
  func template(size: CGSize) -> UIImage? {
    fitting(size).image(color: .black, size: size)?.withRenderingMode(.alwaysTemplate)
  }
  func filling(_ target: CGSize) -> CGPath {
    resize(to: target, fill: true)
  }
  func fitting(_ target: CGSize) -> CGPath {
    resize(to: target, fill: false)
  }
  func resize(to target: CGSize, fill: Bool) -> CGPath {
    let box = boundingBox
    let size = box.size
    var o: CGPoint
    let s: CGFloat
    let sx = target.width / size.width
    let sy = target.height / size.height
    if (sx > sy && fill) || (sx < sy && !fill) {
      s = sx
      o = CGPoint(0, (target.height - size.height * s) / 2)
    } else {
      s = sy
      o = CGPoint((target.width - size.width * s) / 2, 0)
    }
    o.x -= box.minX * s
    o.y -= box.minY * s
    let path = UIBezierPath(cgPath: self)
    path.apply(.offset(o.x, o.y).scale(s))
    return path.cgPath
  }
  var bezier: UIBezierPath {
    UIBezierPath(cgPath: self)
  }
}

// MARK: Array
public extension Array where Element == Int {
  func points(size: CGSize, max: Int?, min: Int?, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> [CGPoint] {
    let min = min ?? self.min()!
    let max = max ?? self.max()!
    let w = size.width
    let h = size.height
    var points = [CGPoint]()
    if count == 1 {
      points.append(.init(x: offsetX, y: offsetY + h * 0.2))
    } else {
      for (i, v) in enumerated() {
        let v = v - min
        let x = CGFloat(i) / CGFloat(count-1) * w
        let y: CGFloat = h - h * CGFloat(v) / CGFloat(max)
        points.append(.init(x: x + offsetX, y: y + offsetY))
      }
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

// MARK: CGMutablePath
public extension CGMutablePath {
  func addCurvedLines(_ points: [CGPoint], extend: CGFloat = 0) {
    guard !points.isEmpty else { return }
    var first = points.first!
    first.x -= extend
    move(to: first)
    addLine(to: points.first!)
    points.cv.forEach {
      addCurve(to: $0.0, control1: $0.1, control2: $0.2)
    }
    var last = points.last!
    last.x += extend
    addLine(to: last)
  }
  func closeBottom(_ size: CGSize) {
    addLine(to: CGPoint(x: size.width, y: size.height))
    addLine(to: CGPoint(x: 0, y: size.height))
  }
}
#endif
