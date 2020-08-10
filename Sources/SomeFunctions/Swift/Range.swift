//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 27/10/2019.
//

import Foundation

#if canImport(ObjectiveC)
public extension Range where Bound == Int {
  var ns: NSRange { NSRange(location: lowerBound, length: count) }
}
#endif

public extension Range {
  init(safe a: Bound, b: Bound) {
    if a > b {
      self = a..<b
    } else {
      self = b..<a
    }
  }
  func mapBounds<T>(_ transform: (Bound)->(T)) -> Range<T> {
    transform(lowerBound)..<transform(upperBound)
  }
  var start: Bound {
    get {
      return lowerBound
    } set {
      self = newValue..<upperBound
    }
  }
  var end: Bound {
    get {
      return upperBound
    } set {
      self = lowerBound..<newValue
    }
  }
}
public extension Range where Bound: BinaryInteger {
  var length: Bound {
    get {
      return upperBound - lowerBound
    } set {
      self = lowerBound..<lowerBound + newValue
    }
  }
}
public extension ClosedRange where Bound: Randomizable {
  var random: Bound { return .random(in: lowerBound...upperBound) }
  func mapBounds<T>(_ transform: (Bound)->(T)) -> ClosedRange<T> {
    transform(lowerBound)...transform(upperBound)
  }
}
