//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/25/20.
//

import Foundation

public extension Collection where Element: FixedWidthInteger {
  var average: Element {
    if count == 0 {
      return 0
    } else {
      return reduce(0, +) / Element(count)
    }
  }
}
public extension Collection where Element: BinaryFloatingPoint {
  var average: Element {
    if count == 0 {
      return 0
    } else {
      return reduce(0, +) / Element(count)
    }
  }
}

public extension Collection {
  func mapSet<T>(_ transform: (Element)->(T)) -> Set<T> {
    var set = Set<T>()
    set.reserveCapacity(count)
    forEach { set.insert(transform($0)) }
    return set
  }
}

public extension LazySequence {
  func compactMap<T>(as type: T.Type) -> LazyMapSequence<LazyFilterSequence<LazyMapSequence<Base, T?>>, T> {
    compactMap { $0 as? T }
  }
}

public extension Sequence {
  func compactMap<T>(as type: T.Type) -> [T] {
    compactMap { $0 as? T }
  }
  func compactMap<T>() -> [T] {
    compactMap(as: T.self)
  }
  func firstMap<T>(as: T.Type) -> T? {
    first { $0 is T } as? T
  }
  func firstMap<T>() -> T? {
    first { $0 is T } as? T
  }
  func sum<T: Numeric>(by: (Element)->(T)) -> T {
    var a: T = 0
    for n in self {
      a += by(n)
    }
    return a
  }
  func find<T>(_ type: T.Type) -> T? {
    for element in self {
      if let element = element as? T {
        return element
      }
    }
    return nil
  }
}

