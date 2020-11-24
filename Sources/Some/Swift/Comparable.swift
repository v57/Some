//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

public protocol ComparableValue: Comparable {
  associatedtype Element: Comparable
  var comparableValue: Element { get }
}
public extension Comparable {
  func limit(in range: Range<Self>) -> Self {
    if self < range.lowerBound {
      return range.lowerBound
    } else if self > range.upperBound {
      return range.upperBound
    } else {
      return self
    }
  }
  func isIn(_ range: Range<Self>) -> Bool {
    range.contains(self)
  }
  func isIn(_ range: ClosedRange<Self>) -> Bool {
    range.contains(self)
  }
  mutating func change(to value: Self) {
    if self != value {
      self = value
    }
  }
  mutating func set(max: Self) {
    if max > self {
      self = max
    }
  }
  mutating func set(min: Self) {
    if min < self {
      self = min
    }
  }
}

extension ComparableValue {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue == rhs.comparableValue
  }
  public static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue < rhs.comparableValue
  }
  public static func <=(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue <= rhs.comparableValue
  }
  public static func >=(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue >= rhs.comparableValue
  }
  public static func >(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue > rhs.comparableValue
  }
}


public protocol TwoValueEquatable : Equatable {
  associatedtype A: Equatable
  associatedtype B: Equatable
  var a: A { get }
  var b: B { get }
}
public extension TwoValueEquatable {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.a == rhs.a && lhs.b == rhs.b
  }
}
public protocol TwoValueComparable: TwoValueEquatable, Comparable where A: Comparable, B: Comparable {
  
}
public extension TwoValueComparable {
  static func <(lhs: Self, rhs: Self) -> Bool {
    lhs.a < rhs.a || (lhs.a == rhs.a && lhs.b < rhs.b)
  }
}

public struct TwoValue<A: Comparable, B: Comparable>: TwoValueComparable {
  public var a: A
  public var b: B
  public init(_ a: A, _ b: B) {
    self.a = a
    self.b = b
  }
}
public struct TwoValueContainer<A: Comparable, B: Comparable, C>: TwoValueComparable {
  public var a: A
  public var b: B
  public var container: C
  public init(_ a: A, _ b: B, _ c: C) {
    self.a = a
    self.b = b
    self.container = c
  }
}
