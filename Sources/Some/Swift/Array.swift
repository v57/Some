//
//  array.swift
//  SomeFunctions
//
//  Created by Димасик on 2/12/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension Int {
  public func forEach(_ body: (Int) throws -> ()) rethrows {
    return try (0..<self).forEach(body)
  }
  public func map<T>(_ transform: (Int) throws -> (T)) rethrows -> [T] {
    return try (0..<self).map(transform)
  }
}
extension Array where Element: Hashable {
  public func unique() -> [Element] {
    var set = Set<Element>()
    return compactMap { set.insert($0).inserted ? $0 : nil }
  }
  public func set() -> Set<Element> {
    return Set(self)
  }
}

extension Array where Element: Equatable {
  public mutating func remove(contentsOf array: [Element]) {
    for object in array {
      self.remove(object)
    }
  }
  public mutating func remove(_ object: Element) {
    if let index = self.firstIndex(of: object) {
      self.remove(at: index)
    }
  }
  public mutating func insert(_ object: Element) {
    if contains(object) {
      return
    } else {
      append(object)
    }
  }
}


// MARK:- Extension Array
extension Array {
  public enum Override {
    case first, last, none
  }
  public static func create(_ build: (inout Array) -> ()) -> Array {
    var array = Array()
    build(&array)
    return array
  }
  public mutating func build(_ create: ()->(Element)) {
    append(create())
  }
  public mutating func append(_ newElement: Element, max: Int, override: Override) {
    assert(max > 0)
    guard count >= max else {
      append(newElement)
      return
    }
    switch override {
    case .first:
      removeFirst()
      append(newElement)
    case .last:
      removeLast()
      append(newElement)
    case .none:
      return
    }
  }
  public var any: Element { self[0..count-1] }
  public func shuffled() -> [Element] {
    var array = self
    array.shuffle()
    return array
  }
  public mutating func shuffle() {
    let range = 0..<count
    for i in range {
      swapAt(i, .random(in: range))
    }
  }
  public func safe(_ index: Int, _ error: Error) throws -> Element {
    guard index >= 0 && index < count else { throw error }
    return self[index]
  }
  public func safe(_ index: Int) -> Element! {
    guard index >= 0 && index < count else { return nil }
    return self[index]
  }
  public func first(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let end: Int = Swift.min(n, count)
    return self[0..<end]
  }
  public func first(_ n: Int, after: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start: Int = Swift.min(after, count - 1)
    let end: Int = Swift.min(after + n, count)
    return self[start..<end]
  }
  public func last(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start = Swift.max(count-n, 0)
    return self[start..<count]
  }
  public func last(_ n: Int, after: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start = Swift.max(count-n-after, 0)
    let end = Swift.max(0, count - after)
    return self[start..<end]
  }
  public func from(_ n: Int, max: Int) -> ArraySlice<Element> {
    guard count > n else { return [] }
    let end = Swift.min(count,n+max)
    return self[n..<end]
  }
  public func from(_ n: Int) -> ArraySlice<Element> {
    guard count > n else { return [] }
    return self[n...]
  }
  public func to(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    guard n >= 0 else { return [] }
    let to = Swift.min(count-1,n)
    return self[...to]
  }
  public func from(_ from: Int, to: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    guard from <= to else { return [] }
    guard to >= 0 else { return [] }
    let from = Swift.max(from,0)
    let to = Swift.min(to,count-1)
    return self[from...to]
  }
  public func right(_ index: Int) -> Element? {
    return safe(count-1-index)
  }
  public mutating func limit(_ count: Int) {
    guard self.count > count else { return }
    self = Array(self[0..<count])
  }
  public func dictionary<Key: Hashable>(key: (Element)->(Key)) -> [Key: Element] {
    var dictionary = [Key: Element]()
    forEach {
      dictionary[key($0)] = $0
    }
    return dictionary
  }
}

// MARK:- Binary search
public extension Array {
  @discardableResult
  mutating func binaryInsert<T: Comparable>(_ element: Element, _ value: (Element)->(T)) -> Index {
    let index = binaryClosest(value(element), value)
    insert(element, at: index)
    return index
  }
  func binarySearch<T: Comparable>(_ e: T, _ value: (Element)->(T)) -> Index? {
    var l = 0
    var h = self.count - 1
    return binarySearch(e, &l, &h, value)
  }
  func binaryClosest<T: Comparable>(_ element: T, _ value: (Element)->(T)) -> Index {
    guard count > 0 else { return 0 }
    if element < value(first!) {
      return 0
    } else if element > value(last!) {
      return count
    }
    var l = 0
    var h = self.count - 1
    return binarySearch(element, &l, &h, value) ?? l
  }
  @inline(__always)
  private func binarySearch<T: Comparable>(_ e: T, _ l: inout Int, _ h: inout Int, _ value: (Element)->(T)) -> Index? {
    while l <= h {
      let mid = (l + h) / 2
      let v = value(self[mid])
      if v < e {
        l = mid + 1
      } else if v > e {
        h = mid - 1
      } else {
        return mid
      }
    }
    return nil
  }
}
public extension Array where Element: Comparable {
  func search(_ i: Element) -> Index {
    return firstIndex(where: { i < $0 }) ?? count-1
  }
  @discardableResult
  mutating func binaryInsert(_ element: Element, ignoreIfExists: Bool = true) -> Index {
    let index = binaryClosest(element)
    if ignoreIfExists, let existed = safe(index), existed == element {
      // element is already here, so we don't need to add it
      return index
    } else {
      insert(element, at: index)
      return index
    }
  }
  func binarySearch(_ e: Element) -> Index? {
    var l = 0
    var h = self.count - 1
    return binarySearch(e, &l, &h)
  }
  func binaryClosest(_ element: Element) -> Index {
    guard count > 0 else { return 0 }
    if element < first! {
      return 0
    } else if element > last! {
      return count
    }
    var l = 0
    var h = self.count - 1
    return binarySearch(element, &l, &h) ?? l
  }
  @inline(__always)
  private func binarySearch(_ e: Element, _ l: inout Int, _ h: inout Int) -> Index? {
    while l <= h {
      let mid = (l + h) / 2
      let v = self[mid]
      if v < e {
        l = mid + 1
      } else if v > e {
        h = mid - 1
      } else {
        return mid
      }
    }
    return nil
  }
}

// MARK:- Safe Array
public class SafeArray<Element> {
  private var array = [Element]()
  private let queue: DispatchQueue
  public init() {
    queue = DispatchQueue(label: "safe-items", attributes: .concurrent)
  }
  subscript(index: Int) -> Element {
    get {
      return queue.read { array[index] }
    } set {
      queue.write { self.array[index] = newValue }
    }
  }
  public var isEmpty: Bool {
    return queue.read { array.isEmpty }
  }
  public var count: Int {
    return queue.read { array.count }
  }
  public func append(_ element: Element) {
    queue.write {
      self.array.append(element)
    }
  }
  public func removeFirst() -> Element {
    return queue.read { self.array.removeFirst() }
  }
  public func insert(_ element: Element, at index: Int) {
    queue.write {
      self.array.insert(element, at: index)
    }
  }
}
