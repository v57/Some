//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/25/20.
//

import Swift

public extension UInt {
  static func random() -> UInt {
    return x64 ? UInt(UInt64.random()) : UInt(UInt32.random())
  }
  static func random(max: UInt) -> UInt {
    return x64 ? UInt(UInt64.random(max: max)) : UInt(UInt64.random(max: max))
  }
  static func random(min: UInt, max: UInt) -> UInt {
    return x64 ? UInt(UInt64.random(min: min, max: max)) : UInt(UInt64.random(min: min, max: max))
  }
  static func seed(_ x: Int, _ y: Int) -> UInt {
    return x64 ? UInt(UInt64.seed(x,y)) : UInt(UInt32.seed(x,y))
  }
  static func seed() -> UInt { .seed(psd, .unique) }
  private static var _unique: UInt = 0
  static var unique: UInt {
    _unique += 1
    return _unique
  }
}

public extension Int {
  static func random() -> Int {
    return x64 ? Int(Int64.random()) : Int(Int32.random())
  }
  static func random(max: Int) -> Int {
    return x64 ? Int(Int64.random(max: max)) : Int(Int64.random(max: max))
  }
  static func random(min: Int, max: Int) -> Int {
    return x64 ? Int(Int64.random(min: min, max: max)) : Int(Int64.random(min: min, max: max))
  }
  static func seed(_ x: Int, _ y: Int) -> Int {
    return x64 ? Int(Int64.seed(x,y)) : Int(Int32.seed(x,y))
  }
  static func seed() -> Int { .seed(psd, .unique) }
  private static var _unique: Int = 0
  static var unique: Int {
    _unique += 1
    return _unique
  }

  func uint64() -> UInt64 {
    return UInt64(UInt(bitPattern: self))
  }
  func uint32() -> UInt32 {
    return UInt32(UInt(bitPattern: self))
  }
}

public extension UInt64 {
  static func random() -> UInt64 { random(in: min...max) }
  static func random(max: UInt64) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  static func random(max: UInt) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  static func random(max: Int) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  static func random(min: UInt64, max: UInt64) -> UInt64 {
    return min + .random(max: max - min)
  }
  static func random(min: UInt, max: UInt) -> UInt64 {
    let min = UInt64(min)
    let max = UInt64(max)
    return min + .random(max: max - min)
  }
  static func random(min: Int, max: Int) -> UInt64 {
    let min = UInt64(min)
    let max = UInt64(max)
    return min + .random(max: max - min)
  }

  static func seed(_ x: UInt64, _ y: UInt64) -> UInt64 {
    var y = y
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ 0xc0c1_fa9907_1488_00) &+ 13763125891376312589) & 0xffffffffffffffff
    let inner = (y &* (y &* y &* 1573115731 &+ 789221789221) &+ 13763125891376312589) & 0xffffffffffffffff
    return inner
  }
  static func seed(_ x: Int, _ y: Int) -> UInt64 {
    return seed(UInt64(bitPattern: Int64(x)), UInt64(bitPattern: Int64(y)))
  }
  static func seed() -> UInt64 { return .seed(psd, .unique) }
  private static var _unique: UInt64 = 0
  static var unique: UInt64 {
    _unique += 1
    return _unique
  }
  func int64() -> Int64 {
    return Int64(bitPattern: self)
  }
  #if __LP64__
  func int() -> Int {
    return Int(bitPattern: UInt(self))
  }
  func uint() -> UInt {
    return UInt(self)
  }
  #endif
}

public extension UInt32 {
  static func random() -> UInt32 { random(in: min...max) }

  static func random(max: UInt32) -> UInt32 {
    random(in: 0...max)
  }
  static func random(max: UInt) -> UInt32 {
    random(max: UInt32(max))
  }
  static func random(max: Int) -> UInt32 {
    random(max: UInt32(max))
  }

  static func random(min: UInt32, max: UInt32) -> UInt32 {
    return random(in: min...max)
  }
  static func random(min: UInt, max: UInt) -> UInt32 {
    let min = UInt32(min)
    let max = UInt32(max)
    return random(in: min...max)
  }
  static func random(min: Int, max: Int) -> UInt32 {
    let min = UInt32(min)
    let max = UInt32(max)
    return random(in: min...max)
  }

  static func seed(_ x: UInt32, _ y: UInt32) -> UInt32 {
    var y = y
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ 19990303) &+ 1376312589) & 0xffffffff
    let inner = (y &* (y &* y &* 15731 &+ 789221) &+ 1376312589) & 0xffffffff
    return inner
  }
  static func seed(_ x: Int, _ y: Int) -> UInt32 {
    return seed(x.uint32(), y.uint32())
  }
  static func seed() -> UInt32 { return .seed(psd, .unique) }
  private static var _unique: UInt32 = 0
  static var unique: UInt32 {
    _unique += 1
    return _unique
  }
  func int32() -> Int32 {
    return Int32(bitPattern: self)
  }
  #if !__LP64__
  func int() -> Int {
    return Int(bitPattern: UInt(self))
  }
  func uint() -> UInt {
    return UInt(self)
  }
  #endif
}

public extension Int64 {
  static func random() -> Int64 { return Int64(bitPattern: UInt64.random()) }
  static func random(max: Int64) -> Int64 {
    return Int64(Double.random() * Double(max))
  }
  static func random(max: Int) -> Int64 {
    return Int64(Double.random() * Double(max))
  }
  static func random(min: Int64, max: Int64) -> Int64 {
    return min + .random(max: max - min)
  }
  static func random(min: Int, max: Int) -> Int64 {
    let min = Int64(min)
    let max = Int64(max)
    return min + .random(max: max - min)
  }

  static func seed(_ x: Int64, _ y: Int64) -> Int64 {
    return UInt64.seed(x.uint64(), y.uint64()).int64()
  }
  static func seed(_ x: Int, _ y: Int) -> Int64 {
    return UInt64.seed(x.uint64(), y.uint64()).int64()
  }
  static func seed() -> Int64 { return .seed(psd, .unique) }
  private static var _unique: Int64 = 0
  static var unique: Int64 {
    _unique += 1
    return _unique
  }
  func uint64() -> UInt64 {
    return UInt64(bitPattern: self)
  }
}

public extension Int32 {
  static func random() -> Int32 { return Int32(bitPattern: UInt32.random()) }
  static func random(max: Int32) -> Int32 {
    return Int32(Double.random() * Double(max))
  }
  static func random(max: Int) -> Int32 {
    return Int32(Double.random() * Double(max))
  }
  static func random(min: Int32, max: Int32) -> Int32 {
    return min + .random(max: max - min)
  }
  static func random(min: Int, max: Int) -> Int32 {
    let min = Int32(min)
    let max = Int32(max)
    return min + .random(max: max - min)
  }

  static func seed(_ x: Int32, _ y: Int32) -> Int32 {
    return UInt32.seed(x.uint32(), y.uint32()).int32()
  }
  static func seed(_ x: Int, _ y: Int) -> Int32 {
    return UInt32.seed(x.uint32(), y.uint32()).int32()
  }
  static func seed() -> Int32 { return .seed(psd, .unique) }
  private static var _unique: Int32 = 0
  static var unique: Int32 {
    _unique += 1
    return _unique
  }
  func uint32() -> UInt32 {
    return UInt32(bitPattern: self)
  }
}

public extension UInt16 {
  static func random() -> UInt16 {
    return UInt16(UInt32.random() >> 16)
  }
}
