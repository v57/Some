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
