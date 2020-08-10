//
//  set.swift
//  SomeFunctions
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

prefix operator **
prefix operator ***
prefix operator ..
public prefix func **<T: Sequence>(l: T) -> Set<T.Element> {
  Set(l)
}
public prefix func **<T: Hashable>(l: T) -> Set<T> {
  [l]
}
public prefix func **<T: Hashable>(l: [T]) -> Set<T> {
  Set(l)
}
public prefix func ..<T: Sequence>(l: T) -> Array<T.Element> {
  Array(l)
}

public extension Set {
  static func += (l: inout Set, r: Set) {
    l.formUnion(r)
  }
  static func -= (l: inout Set, r: Set) {
    l.subtract(r)
  }
  static func + (l: Set, r: Set) -> Set {
    return l.union(r)
  }
  static func - (l: Set, r: Set) -> Set {
    return l.subtracting(r)
  }
  static func += <T: Sequence>(l: inout Set, r: T) where T.Element == Element {
    for e in r { l.insert(e) }
  }
  static func -= <T: Sequence>(l: inout Set, r: T) where T.Element == Element {
    for e in r { l.remove(e) }
  }
  mutating func merge(to set: Set) -> (added: Set, removed: Set) {
    let added = set - self
    let removed = self - set
    self = set
    return (added,removed)
  }
}


public class SafeSet<T: Hashable> {
  private var set: Set<T>
  private let queue: DispatchQueue
  public init() {
    set = Set<T>()
    queue = DispatchQueue(label: "safe-items", attributes: .concurrent)
  }
  public var count: Int {
    var count = 0
    queue.read {
      count = set.count
    }
    return count
  }
  public func insert(_ item: T) {
    queue.write {
      self.set.insert(item)
    }
  }
  public func remove(_ item: T) {
    queue.write {
      self.set.remove(item)
    }
  }
  public func contains(_ item: T) -> Bool {
    var contains = false
    queue.read {
      contains = set.contains(item)
    }
    return contains
  }
}
