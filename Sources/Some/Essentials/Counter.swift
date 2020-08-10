//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

public protocol Countable {
  static var ids: Counter<Int> { get set }
}
extension Countable {
  public static var id: Int { ids.next() }
}

public struct Counter<Value: FixedWidthInteger & DataRepresentable>: RawRepresentable {
  public typealias RawValue = Value
  
  public var rawValue: Value
  public init?(rawValue: Value) {
    self.rawValue = rawValue
  }
  public init(_ rawValue: Value) {
    self.rawValue = rawValue
  }
  public init() {
    rawValue = -1
  }
  public mutating func next() -> Value {
    rawValue = rawValue &+ 1
    if rawValue == .max {
      rawValue = 0
    }
    return rawValue
  }
}

public struct NegativeCounter<Value: FixedWidthInteger & DataRepresentable>: RawRepresentable {
  public typealias RawValue = Value
  
  public var rawValue: Value
  public init?(rawValue: Value) {
    self.rawValue = rawValue
  }
  public init(_ rawValue: Value) {
    self.rawValue = rawValue
  }
  public init() {
    rawValue = 0
  }
  public mutating func next() -> Value {
    rawValue = rawValue &- 1
    if rawValue == .min {
      rawValue = 0
    }
    return rawValue
  }
}
