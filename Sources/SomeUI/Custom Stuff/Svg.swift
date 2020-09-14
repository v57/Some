#if canImport(UIKit)
//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/10/20.
//

import UIKit
import Some

enum ParsingError: Error {
  case corrupted
}
extension IndexingIterator {
  mutating func tryNext() throws -> Element {
    guard let value = self.next() else { throw ParsingError.corrupted }
    return value
  }
}

extension Substring {
  func double() throws -> Double {
    guard let double = Double(self) else { throw ParsingError.corrupted }
    return double
  }
  func cgFloat() throws -> CGFloat {
    try CGFloat(double())
  }
  func cgPoint() throws -> CGPoint {
    try split(separator: ",").cgPoint()
  }
}
extension Array where Element == Substring {
  func cgPoint() throws -> CGPoint {
    guard count == 2 else { throw ParsingError.corrupted }
    return try CGPoint(x: self[0].double(), y: self[1].double())
  }
}

public extension String {
  func svg() -> UIBezierPath? {
    let split = replacingOccurrences(of: "|\n", with: "")
    .lazy.split(separator: " ")
    var iterator = split.makeIterator()
    let path = UIBezierPath()
    do {
      while let next = iterator.next() {
        guard next.count > 0 else { continue }
        switch next.first! {
        case "M":
          let point = try next.dropFirst().cgPoint()
          path.move(to: point)
        case "L":
          let point = try next.dropFirst().cgPoint()
          path.addLine(to: point)
        case "Z":
          path.close()
        case "C":
          let a = try next.dropFirst().cgPoint()
          let b = try iterator.tryNext().cgPoint()
          let c = try iterator.tryNext().cgPoint()
          path.addCurve(to: c, controlPoint1: a, controlPoint2: b)
        default:
          throw ParsingError.corrupted
        }
      }
      path.normalize()
      return path
    } catch {
      print(error)
      return nil
    }
  }
}

extension UIBezierPath {
  func normalize() {
    let bounds = self.bounds
    apply(CGAffineTransform(translationX: -bounds.x, y: -bounds.y))
  }
}
#endif
