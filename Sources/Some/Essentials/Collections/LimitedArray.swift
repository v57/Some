//
//  LimitedArray.swift
//  StatisticsTest
//
//  Created by Dmitry Kozlov on 29/10/2020.
//

import Swift

// MARK: - LimitedArray
public struct LimitedArray<Element> {
  public let limit: Int
  public var position = 0
  public var array: [Element]
  public var alignedArray: [Element] {
    if position == 0 {
      return array
    } else {
      return Array(array[position...]) + Array(array[..<position])
    }
    
  }
  public init(count: Int) {
    self.limit = count
    array = Array()
    array.reserveCapacity(count)
  }
  public mutating func append(_ element: Element) {
    if array.count < limit {
      array.append(element)
    } else {
      array[position] = element
      add(position: 1)
    }
  }
  public mutating func add(position: Int) {
    self.position = (self.position + position) % limit
  }
  public func convert(_ position: Int) -> Int {
    (self.position + position) % limit
  }
}
extension LimitedArray: ArrayMap {
  public var startIndex: Int { 0 }
  public var endIndex: Int { array.count }
  public init() {
    limit = 0
    array = []
  }
  public subscript(position: Int) -> Element {
    get { array[convert(position)] }
    set { array[convert(position)] = newValue }
  }
  // Todo: scroll array
  public subscript(bounds: Range<Int>) -> [Element] {
    get { Array(array[bounds]) }
    set { array[bounds] = ArraySlice(newValue) }
  }
}
extension LimitedArray: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    limit = try data.next()
    position = try data.next()
    array = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(limit)
    data.append(position)
    data.append(array)
  }
}

extension Array where Element: BinaryInteger {
  var average: Element {
    count > 0 ? reduce(0, +) / Element(count) : 0
  }
}


// MARK: - Array map
public protocol ArrayMap: CustomDebugStringConvertible, CustomReflectable, CustomStringConvertible, RandomAccessCollection, MutableCollection, RangeReplaceableCollection where Indices == Range<Int> {
  var array: [Element] { get set }
  var startIndex: Int { get }
  var endIndex: Int { get }
  init()
  // subscript(position: Int) -> Element { get set }
  // subscript(bounds: Range<Int>) -> SubSequence { get set }
}
extension ArrayMap {
  // CustomDebugStringConvertible
  public var debugDescription: String { array.debugDescription }
  // CustomReflectable
  public var customMirror: Mirror { array.customMirror }
  // CustomStringConvertible
  public var description: String { array.description }
  // ExpressibleByArrayLiteral (not conforms to it)
  public typealias ArrayLiteralElement = Element
  // RangeReplaceableCollection
  public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: __owned C) where C : Collection, Self.Element == C.Element {
    array.replaceSubrange(subrange, with: newElements)
  }
  public subscript(range: ClosedRange<Int>) -> SubSequence {
    self[range.lowerBound..<range.upperBound+1]
  }
  public subscript(range: PartialRangeFrom<Int>) -> SubSequence {
    self[range.lowerBound..<endIndex]
  }
  public subscript(range: PartialRangeUpTo<Int>) -> SubSequence {
    self[startIndex..<range.upperBound]
  }
  public subscript(range: PartialRangeThrough<Int>) -> SubSequence {
    self[startIndex..<range.upperBound+1]
  }
  @available (*, deprecated, message: "Use Range<Int>. Other range expressions will crash for some reason")
  @inlinable public subscript<R>(r: R) -> Self.SubSequence where R : RangeExpression, Self.Index == R.Bound {
    fatalError()
  }
}
