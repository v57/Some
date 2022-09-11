//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Foundation

/**
 Sorted array, that uses binary tree to search and insert elements.
 ```
 var array = SortedArray<Int>()
 array.insert(5)
 array.insert(1)
 array.insert(6)
 array.insert(5)
 print(array) // prints [1,5,6]
 ```
 */
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
}
public extension SortedArray {
  func contains(_ element: Element) -> Bool {
    index(of: element) != nil
  }
  func index(of element: Element) -> Int? {
    self.array.binarySearch(element)
  }
  @inlinable func filter(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> Self {
    try SortedArray(sorted: array.filter(isIncluded))
  }
  @discardableResult
  mutating func insert(_ element: Element) -> Int {
    self.array.binaryInsert(element)
  }
  @discardableResult
  mutating func remove(_ element: Element) -> Indexed<Element>? {
    if let index = index(of: element) {
      let element = self.array[index]
      array.remove(at: index)
      return Indexed(index, element)
    } else {
      return nil
    }
  }
  mutating func merge(to array: SortedArray) -> (added: [Element], removed: [Element]) {
    let added = array.array.filter { self.array.binarySearch($0) == nil }
    let removed = self.array.filter { !array.contains($0) }
    self = array
    return (added,removed)
  }
  mutating func removeAll() {
    self.array.removeAll()
  }
  func select(_ range: Range<Element>) -> Range<Int> {
    let start = array.binaryClosest(range.lowerBound)
    let end = array.binaryClosest(range.upperBound)
    return start..<end
  }
  func select(_ range: ClosedRange<Element>) -> ClosedRange<Int> {
    let start = array.binaryClosest(range.lowerBound)
    let end = array.binaryClosest(range.upperBound)
    return start...end
  }
}
extension SortedArray: Hashable where Element: Hashable {}
public extension SortedArray where Element: ComparsionValue {
  mutating func at(_ value: Element.ValueToCompare, create: ()->(Element)) -> (index: Index, element: Element) {
    if let index = index(of: value) {
      return (index, array[index])
    } else {
      let value = create()
      let index = insert(value)
      return (index, value)
    }
  }
  func at(_ value: Element.ValueToCompare) -> Element? {
    if let index = index(of: value) {
      return array[index]
    } else {
      return nil
    }
  }
  mutating func at(_ value: Element.ValueToCompare, default: ()->(Element)) -> Element {
    if let index = index(of: value) {
      return array[index]
    } else {
      let element = `default`()
      insert(element)
      return element
    }
  }
  func contains(_ value: Element.ValueToCompare) -> Bool {
    return at(value) != nil
  }
  func index(of value: Element.ValueToCompare) -> Int? {
    if let index = array.binarySearch(value, \._valueToCompare) {
      return index
    } else {
      return nil
    }
  }
  @discardableResult
  mutating func remove(_ value: Element.ValueToCompare) -> Indexed<Element>? {
    if let index = index(of: value) {
      let element = array[index]
      array.remove(at: index)
      return index.indexed(element)
    } else {
      return nil
    }
  }
  
  // MARK: - Range functions
  func select(_ range: Range<Element.ValueToCompare>) -> Range<Int> {
    let start = array.binaryClosest(range.lowerBound, \._valueToCompare)
    let end = array.binaryClosest(range.upperBound, \._valueToCompare)
    return start..<end
  }
  @discardableResult
  mutating func remove(_ range: Range<Element.ValueToCompare>) -> [Element] {
    let range = select(range)
    let elements = Array(array[range])
    array.removeSubrange(range)
    return elements
  }
  func contains(in range: Range<Element.ValueToCompare>) -> Bool {
    return !select(range).isEmpty
  }
  subscript(_ range: Range<Element.ValueToCompare>) -> ArraySlice<Element> {
    array[select(range)]
  }
  
  // MARK:- Closed range functions
  func select(_ range: ClosedRange<Element.ValueToCompare>) -> ClosedRange<Int> {
    let start = array.binaryClosest(range.lowerBound, \._valueToCompare)
    let end = array.binaryClosest(range.upperBound, \._valueToCompare)
    return start...end
  }
  @discardableResult
  mutating func remove(_ range: ClosedRange<Element.ValueToCompare>) -> [Element] {
    let range = select(range)
    let elements = Array(array[range])
    array.removeSubrange(range)
    return elements
  }
  func contains(in range: ClosedRange<Element.ValueToCompare>) -> Bool {
    return !select(range).isEmpty
  }
  subscript(_ range: ClosedRange<Element.ValueToCompare>) -> ArraySlice<Element> {
    array[select(range)]
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
