//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

// MARK:- Average
public struct AverageValue<T: FixedWidthInteger>: CustomStringConvertible, ExpressibleByIntegerLiteral {
  public static var empty: AverageValue<T> { AverageValue() }
  public var size = 0
  public var buffer = 0
  public var overflow = false
  public init() {
    size = 0
    buffer = 0
    overflow = false
  }
  public init(size: Int, buffer: Int, overflow: Bool) {
    self.size = size
    self.buffer = buffer
    self.overflow = overflow
  }
  public init(integerLiteral value: Int) {
    self.size = 1
    self.buffer = value
    self.overflow = false
  }
  public mutating func add(_ value: T) {
    defer { size += 1 }
    guard !overflow else { return }
    if size == 0 {
      buffer = Int(value)
    } else {
      var (value, overflow) = buffer.addingReportingOverflow(Int(value))
      if overflow {
        if size == 1 {
          self.overflow = true
        } else {
          compress()
          (value, overflow) = buffer.addingReportingOverflow(Int(value))
          if overflow {
            self.overflow = true
          } else {
            buffer = value
          }
        }
      } else {
        buffer = value
      }
    }
  }
  public mutating func reset(to value: T) {
    size = 1
    overflow = false
    buffer = Int(value)
  }
  public mutating func reset() {
    size = 0
    overflow = false
  }
  public func get(zero: T = 0) -> T {
    guard !overflow else { return T.max }
    switch size {
    case 0:
      return zero
    case 1:
      return T(buffer)
    default:
      return T(buffer / size)
    }
  }
  public mutating func compress() {
    guard size > 1 else { return }
    buffer = buffer / size
    size = 1
  }
  public var description: String {
    guard !overflow else { return "overflow" }
    switch size {
    case 0:
      return "empty"
    case 1:
      return "\(buffer)"
    default:
      return "\(buffer / size)"
    }
  }
}
extension AverageValue: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(size: data.next(), buffer: data.next(), overflow: data.next())
  }
  public func save(data: DataWriter) {
    data.append(size)
    data.append(buffer)
    data.append(overflow)
  }
}


// MARK:- Highest
public struct Highest<T: FixedWidthInteger>: CustomStringConvertible, ExpressibleByIntegerLiteral {
  public var value: T
  public var isEmpty: Bool { value == .min }
  public init(integerLiteral value: IntegerLiteralType) {
    self.value = T(value)
  }
  public init() {
    value = .min
  }
  public mutating func insert(_ value: T) {
    if self.value < value {
      self.value = value
    }
  }
  public var description: String { value.description }
}

// MARK:- Lowest
public struct Lowest<T: FixedWidthInteger>: CustomStringConvertible, ExpressibleByIntegerLiteral {
  public var value: T
  public var isEmpty: Bool { value == .max }
  public init(integerLiteral value: IntegerLiteralType) {
    self.value = T(value)
  }
  public init() {
    value = .max
  }
  public mutating func insert(_ value: T) {
    if self.value > value {
      self.value = value
    }
  }
  public var description: String { value.description }
}

// MARK:- MinMax
public struct MinMax<T: Comparable> {
  public var min: T!
  public var max: T!
  public var isEmpty: Bool { min == nil }
  public init() {}
  public mutating func insert(_ value: T) {
    if isEmpty {
      min = value
      max = value
    } else {
      min = Swift.min(min,value)
      max = Swift.max(max,value)
    }
  }
}
