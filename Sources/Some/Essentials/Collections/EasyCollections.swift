//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

// MARK:- EasyCollection
public protocol EasyCollection: CustomDebugStringConvertible,
  CustomReflectable,
  CustomStringConvertible,
  MutableCollection,
  RandomAccessCollection,
  RangeReplaceableCollection
where SubSequence == ArraySlice<Element>, Indices == Range<Int> {
  var array: [Element] { get set }
  func convertIndex(_ index: Int) -> Int
}
public extension EasyCollection {
  var debugDescription: String { array.debugDescription }
  var customMirror: Mirror { array.customMirror }
  var description: String { array.description }
  var startIndex: Int { array.startIndex }
  var endIndex: Int { array.endIndex }
  subscript(position: Int) -> Element {
    get {
      return array[convertIndex(position)]
    }
    set(newValue) {
      array[convertIndex(position)] = newValue
    }
  }
  
  subscript(bounds: Range<Int>) -> SubSequence {
    get {
      let bounds = convertIndex(bounds.lowerBound)..<convertIndex(bounds.upperBound)
      return array[bounds]
    } set {
      let bounds = convertIndex(bounds.lowerBound)..<convertIndex(bounds.upperBound)
      array[bounds] = newValue
    }
  }
  subscript(range: ClosedRange<Int>) -> SubSequence {
    return self[range.lowerBound..<range.upperBound+1]
  }
  subscript(range: PartialRangeFrom<Int>) -> SubSequence {
    return self[range.lowerBound..<endIndex]
  }
  subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
    return self[startIndex..<range.upperBound]
  }
  subscript(range: PartialRangeThrough<Int>) -> SubSequence {
    return self[startIndex..<range.upperBound+1]
  }
  @available (*, deprecated, message: "Use Range<Int>. Other range expressions will crash for some reason")
  @inlinable subscript<R>(r: R) -> Self.SubSequence where R : RangeExpression, Self.Index == R.Bound {
    fatalError()
  }
  func convertIndex(_ index: Int) -> Int { index }
  mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: __owned C) where C : Collection, Self.Element == C.Element {
    array.replaceSubrange(subrange, with: newElements)
  }
}

// MARK:- EasierCollection
public protocol EasierCollection:
  EasyCollection,
  ExpressibleByArrayLiteral
where ArrayLiteralElement == Element {
  init(_ array: [Element])
}
public extension EasierCollection {
  init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
  init() {
    self.init([])
  }
}
