//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

public struct Indexed<Value> {
  public var index: Int
  public var value: Value
  public init(_ index: Int, _ value: Value) {
    self.index = index
    self.value = value
  }
  public init(index: Int, value: Value) {
    self.index = index
    self.value = value
  }
}
public extension Indexed {
  func map<U>(_ transform: (Value)->(U)) -> Indexed<U> {
    Indexed<U>(index, transform(value))
  }
  func singleItemArray() -> Indexed<[Value]> {
    Indexed<[Value]>(index, [value])
  }
}
extension Indexed: ComparsionValue {
  public var _valueToCompare: Int { index }
}

public extension ArraySlice {
  var indexed: Indexed<[Element]> { Indexed(startIndex, Array(self)) }
}
public extension RangeReplaceableCollection where Index == Int {
  subscript(indexed index: Int) -> Indexed<Element> {
    get { Indexed(index: index, value: self[index]) }
  }
  mutating func replaceSubrange<C: Collection>(with indexed: Indexed<C>) where C.Element == Element {
    replaceSubrange(indexed.index..<(indexed.index + indexed.value.count), with: indexed.value)
  }
}
public extension Int {
  func indexed<Value>(_ value: Value) -> Indexed<Value> {
    Indexed(index: self, value: value)
  }
  func indexed<C: Collection>(_ value: C) -> Indexed<[C.Element]> {
    Indexed(index: self, value: Array(value))
  }
}
extension Indexed where Value: Collection, Value.Index == Int {
  public var range: Range<Int> { index..<index+value.count }
  public func enumerate(from: Int, _ body: (Int, Indexed<Value.Element>, inout Bool)->()) {
    var stop = false
    for (i, element) in value[from...].enumerated() {
      body(i + from, Indexed<Value.Element>(index + i + from, element), &stop)
      if stop {
        return
      }
    }
  }
  public func enumerate(_ body: (Int, Indexed<Value.Element>, inout Bool)->()) {
    var stop = false
    for (i, element) in value.enumerated() {
      body(i, Indexed<Value.Element>(index + i, element), &stop)
      if stop {
        return
      }
    }
  }
}
public extension BidirectionalCollection {
  func indexed(_ body: (Indexed<Element>)->()) {
    enumerated().forEach {
      body(Indexed(index: $0.offset, value: $0.element))
    }
  }
}

extension Indexed: DataRepresentable where Value: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(index: data.next(), value: data.next())
  }
  public func save(data: DataWriter) {
    data.append(index)
    data.append(value)
  }
}
