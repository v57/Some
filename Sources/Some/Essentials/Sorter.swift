//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/11/2020.
//

import Swift

public enum ComparsionResult {
  case less, greater, equal
}
public enum SortOrder {
  case ascending, descending
}
public struct Descending<T: Comparable>: Comparable {
  public var value: T
  public init(_ value: T) {
    self.value = value
  }
  public static func == (lhs: Self, rhs: Self) -> Bool { rhs.value == lhs.value }
  public static func < (lhs: Self, rhs: Self) -> Bool { rhs.value < lhs.value }
  public static func <= (lhs: Self, rhs: Self) -> Bool { rhs.value <= lhs.value }
  public static func >= (lhs: Self, rhs: Self) -> Bool { rhs.value >= lhs.value }
  public static func > (lhs: Self, rhs: Self) -> Bool { rhs.value > lhs.value }
}
public struct Sorter<T> {
  public var comparsions = [((T,T)->(ComparsionResult))]()
  public init() {}
  public struct Container: Comparable {
    public let value: T
    public let sorter: Sorter
    public static func == (l: Self, r: Self) -> Bool {
      l.sorter.compare(l.value, r.value) == .equal
    }
    public static func < (l: Self, r: Self) -> Bool {
      l.sorter.compare(l.value, r.value) == .less
    }
    public static func <= (l: Self, r: Self) -> Bool {
      l.sorter.compare(l.value, r.value) != .greater
    }
    public static func > (l: Self, r: Self) -> Bool {
      l.sorter.compare(l.value, r.value) == .greater
    }
    public static func >= (l: Self, r: Self) -> Bool {
      l.sorter.compare(l.value, r.value) != .less
    }
  }
}
public extension Sorter {
  func comparable(for value: T) -> Container {
    Container(value: value, sorter: self)
  }
  mutating func append(_ comparsion: @escaping (T,T)->(ComparsionResult)) {
    comparsions.append(comparsion)
  }
  mutating func append<U: Comparable>(_ comparable: @escaping (T)->(U), _ order: SortOrder = .ascending) {
    append {
      let a = comparable($0)
      let b = comparable($1)
      if a == b {
        return .equal
      } else if a < b {
        switch order {
        case .ascending:
          return .less
        case .descending:
          return .greater
        }
      } else {
        switch order {
        case .ascending:
          return .greater
        case .descending:
          return .less
        }
      }
    }
  }
  mutating func trueFirst(_ path: KeyPath<T, Bool>) {
    append {
      let a = $0[keyPath: path]
      let b = $1[keyPath: path]
      if a {
        if b {
          return .equal
        } else {
          return .less
        }
      } else if b {
        return .greater
      } else {
        return .equal
      }
    }
  }
  mutating func falseFirst(_ path: KeyPath<T, Bool>) {
    append {
      let a = $0[keyPath: path]
      let b = $1[keyPath: path]
      if a {
        if b {
          return .equal
        } else {
          return .greater
        }
      } else if b {
        return .less
      } else {
        return .equal
      }
    }
  }
  func sort(_ a: T, _ b: T) -> Bool {
    compare(a, b) != .greater
  }
  func compare(_ a: T, _ b: T) -> ComparsionResult {
    for compare in comparsions {
      switch compare(a,b) {
      case .equal:
        break
      case .greater:
        return .greater
      case .less:
        return .less
      }
    }
    return .greater
  }
}
public extension Array {
  func sorted(using sorter: Sorter<Element>) -> Array {
    sorted(by: sorter.sort)
  }
  mutating func binaryInsert(_ element: Element, using sorter: Sorter<Element>, ignoreIfExists: Bool = true, replace: Bool = false) -> Index {
    binaryInsert(element, sorter.comparable)
  }
}
