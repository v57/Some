//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Foundation

public struct SortedArray<Element: Comparable>: EasierCollection, Equatable {
  public typealias SubSequence = ArraySlice<Element>
  
  public var array: [Element]
  public var count: Int { array.count }
  public init(arrayLiteral elements: Element...) {
    self.array = elements.sorted()
  }
  public init(_ array: [Element]) {
    self.array = array.sorted()
  }
  public init(sorted array: [Element]) {
    self.array = array
  }
  public init() {
    self.array = []
  }
  public func contains(_ element: Element) -> Bool {
    index(of: element) != nil
  }
  public func index(of element: Element) -> Int? {
    self.array.binarySearch(element)
  }
  @discardableResult
  public mutating func insert(_ element: Element) -> Int {
    self.array.binaryInsert(element)
  }
  public mutating func remove(_ element: Element) -> Int? {
    if let index = index(of: element) {
      self.array.remove(at: index)
      return index
    } else {
      return nil
    }
  }
  public mutating func merge(to array: SortedArray) -> (added: [Element], removed: [Element]) {
    let added = array.array.filter { self.array.binarySearch($0) == nil }
    let removed = self.array.filter { !array.contains($0) }
    self = array
    return (added,removed)
  }
  public mutating func removeAll() {
    self.array.removeAll()
  }
}
extension SortedArray: Hashable where Element: Hashable {}
public extension SortedArray where Element: ComparsionValue {
  func at(_ value: Element.ValueToCompare) -> Element? {
    if let index = index(of: value) {
      return array[index]
    } else {
      return nil
    }
  }
  func index(of value: Element.ValueToCompare) -> Int? {
    if let index = array.binarySearch(value, { $0._valueToCompare }) {
      return index
    } else {
      return nil
    }
  }
  mutating func remove(_ value: Element.ValueToCompare) -> Int? {
    if let index = index(of: value) {
      array.remove(at: index)
      return index
    } else {
      return nil
    }
  }
}
extension SortedArray: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    self.init(sorted: try data.next())
  }
  public func save(data: DataWriter) {
    data.append(array)
  }
}
