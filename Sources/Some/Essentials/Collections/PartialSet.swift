//
//  ArraySyncSupport.swift
//  
//
//  Created by Dmitry Kozlov on 5/11/20.
//

import Foundation


public protocol Indexable {
  var index: Int { get }
  var count: Int { get }
  func combined(with range: Self) -> (combined: Self, clamped: (Self, Self))
  subscript(relative range: Range<Int>) -> Self { get }
}

public extension Indexable {
  var lowerBound: Int { index }
  var upperBound: Int { index + count }
  var range: Range<Int> { lowerBound..<upperBound }
  subscript(nonRelative range: Range<Int>) -> Self {
    self[relative: range.lowerBound - index ..< range.upperBound - index]
  }
  static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.upperBound < rhs.lowerBound
  }
  static func > (lhs: Self, rhs: Self) -> Bool {
    lhs.lowerBound > rhs.upperBound
  }
  func bounds(with range: Self) -> Bool {
    if lowerBound == range.lowerBound {
      return true
    } else if lowerBound < range.lowerBound {
      return upperBound >= range.lowerBound
    } else {
      return lowerBound <= range.upperBound
    }
  }
}
extension Indexed: Indexable where Value: RangeReplaceableCollection, Value.Index == Int {
  public var count: Int { value.count }
  public subscript(relative index: Int) -> Value.Element {
    value[index]
  }
  public subscript(nonRelative index: Int) -> Value.Element {
    value[index - self.index]
  }
  public func combined(with range: Indexed<Value>) -> (combined: Self, clamped: (Self, Self)) {
    let (combined, clamped) = value._merge(with: range, offset: index)
    return (combined as! Indexed<Value>, clamped as! (Indexed<Value>, Indexed<Value>))
  }
  public subscript(relative range: Range<Int>) -> Indexed<Value> {
    Indexed(index: range.lowerBound, value: value[relative: range])
  }
}
extension Range: Indexable where Bound == Int {
  public subscript(relative range: Range<Int>) -> Range<Int> {
    range
  }
  public var index: Int { lowerBound }
  public func excluding(range: Self) -> [Self] {
    if range.lowerBound <= lowerBound {
      if range.upperBound >= upperBound {
        return []
      } else {
        return [range.upperBound..<upperBound]
      }
    } else {
      if range.lowerBound >= upperBound {
        return [self]
      } else if range.upperBound >= upperBound {
        return [lowerBound..<range.lowerBound]
      } else {
        return [lowerBound..<range.lowerBound, range.upperBound..<upperBound]
      }
    }
  }
  public func combined(with range: Self) -> (combined: Self, clamped: (Self, Self)) {
    let combined = Swift.min(lowerBound, range.lowerBound)..<Swift.max(upperBound, range.upperBound)
    let clamped = self.clamped(to: range)
    return (combined, (clamped, clamped))
  }
}
extension RangeReplaceableCollection where Index == Int {
  public subscript(relative range: Range<Int>) -> Self {
    Self(self[range])
  }
  public var _count: Int { count }
  public func _merge(with: Any, offset: Int) -> (combined: Any, clamped: Any) {
    assert(with as? Indexed<Self> != nil)
    func clamped(array1: Indexed<Self>, array2: Indexed<Self>) -> Indexed<Self> {
      array2[nonRelative: array1.range.clamped(to: array2.range)]
    }
    let indexedSelf = Indexed(index: offset, value: self)
    let value = with as! Indexed<Self>
    let clampedOld = clamped(array1: value, array2: indexedSelf)
    let clampedNew = clamped(array1: indexedSelf, array2: value)
    let second = value.value
    let s1 = offset
    let c1 = count
    let e1 = s1 + c1
    let s2 = value.index
    let c2 = value.value.count
    let e2 = s2 + c2
    let index: Int
    var array: Self
    if s1 < s2 {
      index = s1
      if e1 > e2 {
        // first array fully eats second
        array = self
        array.replaceSubrange(with: value)
      } else {
        array = self + second[(s1 + c1 - s2)...]
      }
    } else {
      index = s2
      if e2 > e1 {
        array = second
      } else {
        array = second + self[(s2 + c2 - s1)...]
      }
    }
    let combined = Indexed<Self>(index: index, value: array)
    return (combined, (clampedOld, clampedNew))
  }
}

public struct PartialSet<R: Indexable> {
  public var body = [R]()
  public var count: Int { body.reduce(0, { $0 + $1.count }) }
  public init() {}
  public init(body: [R]) {
    self.body = body
  }
  public struct InsertResult {
    public var mergedPrefix = 0
    public var mergedSuffix = 0
    public var combined: R
    public var changed: [(R,R)] = []
    public var index = 0
    init(set: R) {
      self.combined = set
    }
  }
  public subscript(_ index: Int) -> R? {
    body.last(where: { $0.range.contains(index) })
  }
  @discardableResult
  public mutating func insert(_ set: R) -> InsertResult {
    var result = InsertResult(set: set)
    if body.isEmpty {
      body = [set]
    } else {
      for i in 0..<body.count {
        let range = body[i]
        if range.bounds(with: set) {
          let combineResult = range.combined(with: set)
          body[i] = combineResult.combined
          result.changed.append(combineResult.clamped)
          result.mergedPrefix += range.count
          while i + 1 < body.count && body[i].bounds(with: body[i + 1]) {
            result.mergedSuffix += body[i].count
            let combineResult = body[i].combined(with: body[i + 1])
            body[i] = combineResult.combined
            result.changed.append(combineResult.clamped)
            body.remove(at: i + 1)
          }
          result.index = i
          result.combined = body[i]
          return result
        } else if set < range {
          body.insert(set, at: i)
          result.index = i
          return result
        }
      }
      result.index = body.count
      body.append(set)
    }
    return result
  }
  public mutating func removeAll() {
    body = []
  }
  public func lastUnloadedGap() -> Range<Int> {
    guard body.count != 0 else { return 0..<0 }
    guard body.count > 1 else { return 0..<body[0].lowerBound }
    return body[body.count-2].upperBound..<body[body.count-1].lowerBound
  }
}

extension PartialSet: CustomStringConvertible {
  public var description: String {
    body.map { "\($0.lowerBound)..<\($0.upperBound)" }
      .joined(separator: " ") + "\(body)"
  }
}

extension PartialSet: DataRepresentable where R: DataRepresentable {
  public init(data: DataReader) throws {
    self.init(body: try data.next())
  }
  public func save(data: DataWriter) {
    data.append(body)
  }
}
