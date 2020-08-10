//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/25/20.
//

import Foundation

public extension Double {
  func devide(by: Double) -> Double { self / by }
  func string(precision: Int) -> String {
    String(format: "%.\(precision)f", self)
  }
  static func random() -> Double { .random(in: 0...1) }
  static func seed(_ x: Int, _ y: Int) -> Double {
    return Double(UInt64.seed(x, y)) / Double(0xffffffffffffffff)
  }
  static func seed(_ x: UInt64, _ y: UInt64) -> Double {
    return Double(UInt64.seed(x, y)) / Double(0xffffffffffffffff)
  }
  static func seed() -> Double { .seed(psd, .unique) }
}

public extension Float {
  static func random() -> Float { .random(in: 0...1) }
  static func seed(_ x: Int, _ y: Int) -> Float {
    return Float(UInt32.seed(x, y)) / Float(0xffffffff)
  }
  static func seed() -> Float { .seed(psd, .unique) }
}
