//
//  Statistics.swift
//  
//
//  Created by Dmitry Kozlov on 4/6/20.
//

import Foundation

// MARK:- StatisticsTabs
public struct StatisticsTabs {
  public var levels: [StatisticsTab<LimitedArray<Int>>]
  public var unlimitedTab: StatisticsTab<[Int]>?
  public init(levels: [StatisticsTab<LimitedArray<Int>>]) {
    self.levels = levels
  }
  public init() {
    self.levels = []
  }
  public mutating func addTab(size: Int, time: Time) {
    levels.append(StatisticsTab(data: LimitedArray<Int>(count: size), interval: time / Time(size), buffer: AverageValue(), bufferTime: 0))
  }
  public mutating func addAll() {
    unlimitedTab = StatisticsTab(data: [], interval: Time.minute.mcs, buffer: AverageValue(), bufferTime: 0)
  }
  @discardableResult
  public mutating func add(_ value: Int) -> ([Int], Bool) {
    add(value, .mcs)
  }
  @discardableResult
  public mutating func add(_ value: Int, _ time: Time) -> ([Int], Bool) {
    var updated = [Int]()
    for i in 0..<levels.count {
      if levels[i].add(value, time) != nil {
        updated.append(i)
      }
    }
    let unlimitedUpdated = unlimitedTab?.add(value, time) != nil
    return (updated, unlimitedUpdated)
  }
}

// MARK:- Protocols
public protocol StatisticsData: Collection {
  associatedtype Element
  mutating func append(_ newElement: Element)
}
extension LimitedArray: StatisticsData {}
extension Array: StatisticsData {}
public protocol StatisticsBuffer {
  mutating func bufferAdd(_ value: Int)
  func bufferGet() -> Int
  mutating func bufferReset(to value: Int)
}
extension AverageValue: StatisticsBuffer where T == Int {
  public mutating func bufferAdd(_ value: Int) {
    add(value)
  }
  public func bufferGet() -> Int {
    get()
  }
  public mutating func bufferReset(to value: Int) {
    reset(to: value)
  }
}
extension Highest: StatisticsBuffer where T == Int {
  public mutating func bufferAdd(_ value: Int) {
    insert(value)
  }
  public func bufferGet() -> Int {
    value
  }
  public mutating func bufferReset(to value: Int) {
    self.value = value
  }
}
extension Lowest: StatisticsBuffer where T == Int {
  public mutating func bufferAdd(_ value: Int) {
    insert(value)
  }
  public func bufferGet() -> Int {
    value
  }
  public mutating func bufferReset(to value: Int) {
    self.value = value
  }
}

// MARK:- StatisticsTab
public struct StatisticsTab<C: StatisticsData> where C.Element == Int {
  public var buffer: StatisticsBuffer
  public var bufferTime: Time
  
  public var data: C
  public let interval: Time
  
  public init(data: C, interval: Time, buffer: StatisticsBuffer, bufferTime: Time) {
    self.buffer = buffer
    self.bufferTime = bufferTime
    self.data = data
    self.interval = interval
  }
  
  @discardableResult
  public mutating func add(_ value: Int, _ time: Time) -> Int? {
    assert(time > bufferTime)
    if time - bufferTime >= interval {
      let bufferResult = buffer.bufferGet()
      data.append(bufferResult)
      buffer.bufferReset(to: value)
      return value
    } else {
      buffer.bufferAdd(value)
      return nil
    }
  }
}

// MARK:- LimitedArray
public struct LimitedArray<Element> {
  public let limit: Int
  public var position = 0
  public var array: [Element]
  public init(count: Int) {
    self.limit = count
    array = Array()
    array.reserveCapacity(count)
  }
  public mutating func append(_ element: Element) {
    if array.count < limit {
      array.append(element)
      position += 1
    } else {
      add(position: 1)
      array[position] = element
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

extension Array where Element: BinaryInteger {
  var average: Element {
    count > 0 ? reduce(0, +) / Element(count) : 0
  }
}


// MARK:- Array map
public protocol ArrayMap: CustomDebugStringConvertible, CustomReflectable, CustomStringConvertible, MutableCollection, RandomAccessCollection, RangeReplaceableCollection where Indices == Range<Int> {
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

public extension Time {
  var fromMcs: Time { self / 1_000_000 }
  var mcs: Time { self * 1_000_000 }
  static var mcs: Time {
    var tv = timeval()
    gettimeofday(&tv, nil)
    return Time(tv.tv_sec) * 1_000_000 + Time(tv.tv_usec)
  }
}
