//
//  random.swift
//  SomeFunctions
//
//  Created by Димасик on 2/12/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public protocol Randomizable: Comparable {
  static func random(in range: ClosedRange<Self>) -> Self
}
extension Int: Randomizable {}
extension Int8: Randomizable {}
extension Int16: Randomizable {}
extension Int32: Randomizable {}
extension Int64: Randomizable {}

extension UInt: Randomizable {}
extension UInt8: Randomizable {}
extension UInt16: Randomizable {}
extension UInt32: Randomizable {}
extension UInt64: Randomizable {}

extension Bool: Randomizable {
  // unlocks a = Bool(1)
  init<T: Comparable & ExpressibleByIntegerLiteral>(_ int: T) {
    self = int > 0
  }
  public static func random(in range: ClosedRange<Bool>) -> Bool {
    return Bool(Int.random(in: 0...1))
  }
  public static func < (lhs: Bool, rhs: Bool) -> Bool {
    !lhs && rhs
  }
}
extension Double: Randomizable {}
extension Float: Randomizable {}


let psd = 1488_911_420
let x64 = MemoryLayout<Int>.size == MemoryLayout<Int64>.size

postfix operator %
public postfix func % (l: Int) -> Bool {
  return Double(l) > Double.random(in: 1...100)
}
public postfix func % (l: Double) -> Bool {
  return Double(l) > Double.random(in: 1...100)
}
infix operator ..: RangeFormationPrecedence
public func ..<T: Randomizable>(l: T, r: T) -> T {
  T.random(in: l...r)
}

public extension Bool {
  static func random() -> Bool { Int.random(in: 0...1) == 0 ? false : true }
  static func seed() -> Bool { UInt32.seed() < UInt32.max / 2 }
}






